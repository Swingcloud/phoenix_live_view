# Form bindings

## A note about form helpers

LiveView works with the existing `Phoenix.HTML` form helpers.
If you want to use helpers such as [`text_input/2`](`Phoenix.HTML.Form.text_input/2`),
etc. be sure to `use Phoenix.HTML` at the top of your LiveView.
If your application was generated with Phoenix v1.6, then `mix phx.new`
automatically uses `Phoenix.HTML` when you `use MyAppWeb, :live_view` or
`use MyAppWeb, :live_component` in your modules.

Using the generated `:live_view` and `:live_component` helpers will also
`import MyAppWeb.ErrorHelpers`, a module generated as part of your application
where `error_tag/2` resides (usually located at `lib/my_app_web/views/error_helpers.ex`).
You are welcome to change the `ErrorHelpers` module as you prefer.

## Form Events

To handle form changes and submissions, use the `phx-change` and `phx-submit`
events. In general, it is preferred to handle input changes at the form level,
where all form fields are passed to the LiveView's callback given any
single input change, but individual inputs may also track their own changes.
For example, to handle real-time form validation and saving, your form would
use both `phx-change` and `phx-submit` bindings:

```
<.form :let={f} for={@changeset} phx-change="validate" phx-submit="save">
  <%= label f, :username %>
  <%= text_input f, :username %>
  <%= error_tag f, :username %>

  <%= label f, :email %>
  <%= text_input f, :email %>
  <%= error_tag f, :email %>

  <%= submit "Save" %>
</.form>
```

Next, your LiveView picks up the events in `handle_event` callbacks:

    def render(assigns) ...

    def mount(_params, _session, socket) do
      {:ok, assign(socket, %{changeset: Accounts.change_user(%User{})})}
    end

    def handle_event("validate", %{"user" => params}, socket) do
      changeset =
        %User{}
        |> Accounts.change_user(params)
        |> Map.put(:action, :insert)

      {:noreply, assign(socket, changeset: changeset)}
    end

    def handle_event("save", %{"user" => user_params}, socket) do
      case Accounts.create_user(user_params) do
        {:ok, user} ->
          {:noreply,
           socket
           |> put_flash(:info, "user created")
           |> redirect(to: Routes.user_path(MyAppWeb.Endpoint, MyAppWeb.User.ShowView, user))}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, changeset: changeset)}
      end
    end

The validate callback simply updates the changeset based on all form input
values, then assigns the new changeset to the socket. If the changeset
changes, such as generating new errors, [`render/1`](`c:Phoenix.LiveView.render/1`)
is invoked and the form is re-rendered.

Likewise for `phx-submit` bindings, the same callback is invoked and
persistence is attempted. On success, a `:noreply` tuple is returned and the
socket is annotated for redirect with `Phoenix.LiveView.redirect/2` to
the new user page, otherwise the socket assigns are updated with the errored
changeset to be re-rendered for the client.

You may wish for an individual input to use its own change event or to target
a different component. This can be accomplished by annotating the input itself
with `phx-change`, for example:

```
<.form :let={f} for={@changeset} phx-change="validate" phx-submit="save">
  ...
  <%= label f, :county %>
  <%= text_input f, :email, phx_change: "email_changed", phx_target: @myself %>
</.form>
```

Then your LiveView or LiveComponent would handle the event:

```elixir
def handle_event("email_changed", %{"user" => %{"email" => email}}, socket) do
  ...
end
```

_Note_: only the individual input is sent as params for an input marked with `phx-change`.

## `phx-feedback-for`

For proper form error tag updates, the error tag must specify which
input it belongs to. This is accomplished with the `phx-feedback-for` attribute,
which specifies the name (or id, for backwards compatibility) of the input it belongs to.
Failing to add the `phx-feedback-for` attribute will result in displaying error
messages for form fields that the user has not changed yet (e.g. required
fields further down on the page).

For example, your `MyAppWeb.ErrorHelpers` may use this function:

    def error_tag(form, field) do
      form.errors
      |> Keyword.get_values(field)
      |> Enum.map(fn error ->
        content_tag(:span, translate_error(error),
          class: "invalid-feedback",
          phx_feedback_for: input_name(form, field)
        )
      end)
    end

Now, any DOM container with the `phx-feedback-for` attribute will receive a
`phx-no-feedback` class in cases where the form fields has yet to receive
user input/focus. The following CSS rules are generated in new projects
to hide the errors:

    .phx-no-feedback.invalid-feedback, .phx-no-feedback .invalid-feedback {
      display: none;
    }

## Number inputs

Number inputs are a special case in LiveView forms. On programmatic updates,
some browsers will clear invalid inputs. So LiveView will not send change events
from the client when an input is invalid, instead allowing the browser's native
validation UI to drive user interaction. Once the input becomes valid, change and
submit events will be sent normally.

```heex
<input type="number">
```

This is known to have a plethora of problems including accessibility, large numbers
are converted to exponential notation, and scrolling can accidentally increase or
decrease the number.

One alternative is the `inputmode` attribute, which may serve your application's needs
and users much better. According to [Can I Use?](https://caniuse.com/#search=inputmode),
the following is supported by 86% of the global market (as of Sep 2021):

```heex
<input type="text" inputmode="numeric" pattern="[0-9]*">
```

## Password inputs

Password inputs are also special cased in `Phoenix.HTML`. For security reasons,
password field values are not reused when rendering a password input tag. This
requires explicitly setting the `:value` in your markup, for example:

```heex
<%= password_input f, :password, value: input_value(f, :password) %>
<%= password_input f, :password_confirmation, value: input_value(f, :password_confirmation) %>
<%= error_tag f, :password %>
<%= error_tag f, :password_confirmation %>
```

## Nested inputs

Nested inputs are handled using `inputs_for` form helpers. There are two versions
of `inputs_for` - one that takes an anonymous function and one that doesn't. The version
that takes an anonymous function won't work properly with LiveView as it prevents rendering
of LiveComponents. Instead of using this:

```heex
<%= inputs_for f, :friend, fn fp -> %>
  <%= text_input fp, :url %>
<% end %>
```

you should use this:

```heex
<%= for fp <- inputs_for(f, :friends) do %>
  <%= hidden_inputs_for(fp) %>
  <%= text_input fp, :name %>
<% end %>
```

Note that you will need to include a call to `hidden_inputs_for` as the version of inputs_for that does not take an anonymous function also does not automatically generate any necessary hidden fields for tracking ids of Ecto associations.

## File inputs

LiveView forms support [reactive file inputs](uploads.md),
including drag and drop support via the `phx-drop-target`
attribute:

```heex
<div class="container" phx-drop-target={@uploads.avatar.ref}>
    ...
    <.live_file_input upload={@uploads.avatar} />
</div>
```

See `Phoenix.Component.live_file_input/1` for more.

## Submitting the form action over HTTP

The `phx-trigger-action` attribute can be added to a form to trigger a standard
form submit on DOM patch to the URL specified in the form's standard `action`
attribute. This is useful to perform pre-final validation of a LiveView form
submit before posting to a controller route for operations that require
Plug session mutation. For example, in your LiveView template you can
annotate the `phx-trigger-action` with a boolean assign:

```heex
<.form :let={f} for={@changeset}
  action={Routes.reset_password_path(@socket, :create)}
  phx-submit="save"
  phx-trigger-action={@trigger_submit}>
```

Then in your LiveView, you can toggle the assign to trigger the form with the current
fields on next render:

    def handle_event("save", params, socket) do
      case validate_change_password(socket.assigns.user, params) do
        {:ok, changeset} ->
          {:noreply, assign(socket, changeset: changeset, trigger_submit: true)}

        {:error, changeset} ->
          {:noreply, assign(socket, changeset: changeset)}
      end
    end

Once `phx-trigger-action` is true, LiveView disconnects and then submits the form.

## Recovery following crashes or disconnects

By default, all forms marked with `phx-change` and having `id`
attribute will recover input values automatically after the user has
reconnected or the LiveView has remounted after a crash. This is
achieved by the client triggering the same `phx-change` to the server
as soon as the mount has been completed.

**Note:** if you want to see form recovery working in development, please
make sure to disable live reloading in development by commenting out the
LiveReload plug in your `endpoint.ex` file or by setting `code_reloader: false`
in your `config/dev.exs`. Otherwise live reloading may cause the current page
to be reloaded whenever you restart the server, which will discard all form
state.

For most use cases, this is all you need and form recovery will happen
without consideration. In some cases, where forms are built step-by-step in a
stateful fashion, it may require extra recovery handling on the server outside
of your existing `phx-change` callback code. To enable specialized recovery,
provide a `phx-auto-recover` binding on the form to specify a different event
to trigger for recovery, which will receive the form params as usual. For example,
imagine a LiveView wizard form where the form is stateful and built based on what
step the user is on and by prior selections:

    <form id="wizard" phx-change="validate_wizard_step" phx-auto-recover="recover_wizard">

On the server, the `"validate_wizard_step"` event is only concerned with the
current client form data, but the server maintains the entire state of the wizard.
To recover in this scenario, you can specify a recovery event, such as `"recover_wizard"`
above, which would wire up to the following server callbacks in your LiveView:

    def handle_event("validate_wizard_step", params, socket) do
      # regular validations for current step
      {:noreply, socket}
    end

    def handle_event("recover_wizard", params, socket) do
      # rebuild state based on client input data up to the current step
      {:noreply, socket}
    end

To forgo automatic form recovery, set `phx-auto-recover="ignore"`.

## JavaScript client specifics

The JavaScript client is always the source of truth for current input values.
For any given input with focus, LiveView will never overwrite the input's current
value, even if it deviates from the server's rendered updates. This works well
for updates where major side effects are not expected, such as form validation
errors, or additive UX around the user's input values as they fill out a form.

For these use cases, the `phx-change` input does not concern itself with disabling
input editing while an event to the server is in flight. When a `phx-change` event
is sent to the server, the input tag and parent form tag receive the
`phx-change-loading` CSS class, then the payload is pushed to the server with a
`"_target"` param in the root payload containing the keyspace of the input name
which triggered the change event.

For example, if the following input triggered a change event:

```heex
<input name="user[username]"/>
```

The server's `handle_event/3` would receive a payload:

    %{"_target" => ["user", "username"], "user" => %{"username" => "Name"}}

The `phx-submit` event is used for form submissions where major side effects
typically happen, such as rendering new containers, calling an external
service, or redirecting to a new page.

On submission of a form bound with a `phx-submit` event:

1. The form's inputs are set to `readonly`
2. Any submit button on the form is disabled
3. The form receives the `"phx-submit-loading"` class

On completion of server processing of the `phx-submit` event:

1. The submitted form is reactivated and loses the `"phx-submit-loading"` class
2. The last input with focus is restored (unless another input has received focus)
3. Updates are patched to the DOM as usual

To handle latent events, the `<button>` tag of a form can be annotated with
`phx-disable-with`, which swaps the element's `innerText` with the provided
value during event submission. For example, the following code would change
the "Save" button to "Saving...", and restore it to "Save" on acknowledgment:

```heex
<button type="submit" phx-disable-with="Saving...">Save</button>
```

You may also take advantage of LiveView's CSS loading state classes to
swap out your form content while the form is submitting. For example,
with the following rules in your `app.css`:

    .while-submitting { display: none; }
    .inputs { display: block; }

    .phx-submit-loading .while-submitting { display: block; }
    .phx-submit-loading .inputs { display: none; }

You can show and hide content with the following markup:

```heex
<form phx-change="update">
  <div class="while-submitting">Please wait while we save our content...</div>
  <div class="inputs">
    <input type="text" name="text" value={@text}>
  </div>
</form>
```

Additionally, we strongly recommend including a unique HTML "id" attribute on the form.
When DOM siblings change, elements without an ID will be replaced rather than moved,
which can cause issues such as form fields losing focus.

## Triggering `phx-` form events with JavaScript

Often it is desirable to trigger an event on a DOM element without explicit
user interaction on the element. For example, a custom form element such as a
date picker or custom select input which utilizes a hidden input element to
store the selected state.

In these cases, the event functions on the DOM API can be used, for example
to trigger a `phx-change` event:

```
document.getElementById("my-select").dispatchEvent(
  new Event("input", {bubbles: true})
)
```

When using a client hook, `this.el` can be used to determine the element as
outlined in the "Client hooks" documentation.

It is also possible to trigger a `phx-submit` using a "submit" event:

```
document.getElementById("my-form").dispatchEvent(
  new Event("submit", {bubbles: true, cancelable: true})
)
```
