defmodule Phoenix.ComponentVerifyTest do
  use ExUnit.Case, async: true

  @moduletag :after_verify
  import ExUnit.CaptureIO

  test "validate required attributes" do
    warnings =
      capture_io(:stderr, fn ->
        defmodule RequiredAttrs do
          use Phoenix.Component

          attr :name, :any, required: true
          attr :phone, :any
          attr :email, :any, required: true

          def func(assigns), do: ~H[]

          def line, do: __ENV__.line + 4

          def render(assigns) do
            ~H"""
            <.func/>
            """
          end
        end
      end)

    line = get_line(__MODULE__.RequiredAttrs)

    assert warnings =~ """
           missing required attribute "email" for component \
           Phoenix.ComponentVerifyTest.RequiredAttrs.func/1
             test/phoenix_component/verify_test.exs:#{line}: (file)
           """

    assert warnings =~ """
           missing required attribute "name" for component \
           Phoenix.ComponentVerifyTest.RequiredAttrs.func/1
             test/phoenix_component/verify_test.exs:#{line}: (file)
           """
  end

  test "validate undefined attributes" do
    warnings =
      capture_io(:stderr, fn ->
        defmodule UndefinedAttrs do
          use Phoenix.Component

          attr :class, :any
          def func(assigns), do: ~H[]

          def line, do: __ENV__.line + 4

          def render(assigns) do
            ~H"""
            <.func width="btn" size={@size} phx-no-format />
            """
          end
        end
      end)

    line = get_line(__MODULE__.UndefinedAttrs)

    assert warnings =~ """
           undefined attribute "size" for component \
           Phoenix.ComponentVerifyTest.UndefinedAttrs.func/1
             test/phoenix_component/verify_test.exs:#{line}: (file)
           """

    assert warnings =~ """
           undefined attribute "width" for component \
           Phoenix.ComponentVerifyTest.UndefinedAttrs.func/1
             test/phoenix_component/verify_test.exs:#{line}: (file)
           """
  end

  test "validates attrs and slots for external function components" do
    warnings =
      capture_io(:stderr, fn ->
        defmodule External do
          use Phoenix.Component
          attr :id, :string, required: true

          slot :named do
            attr :attr, :any, required: true
          end

          def render(assigns), do: ~H[]
        end

        defmodule ExternalCalls do
          use Phoenix.Component

          def line, do: __ENV__.line + 4

          def render(assigns) do
            ~H"""
            <External.render>
            <:named />
            </External.render>
            """
          end
        end
      end)

    line = get_line(__MODULE__.ExternalCalls)

    assert warnings =~ """
           missing required attribute "id" for component \
           Phoenix.ComponentVerifyTest.External.render/1
             test/phoenix_component/verify_test.exs:#{line}: (file)
           """

    assert warnings =~ """
           missing required attribute "attr" in slot "named" for component \
           Phoenix.ComponentVerifyTest.External.render/1
             test/phoenix_component/verify_test.exs:#{line + 1}: (file)
           """
  end

  test "validate literal types" do
    warnings =
      capture_io(:stderr, fn ->
        defmodule TypeAttrs do
          use Phoenix.Component, global_prefixes: ~w(myprefix-)

          attr :any, :any
          attr :string, :string
          attr :atom, :atom
          attr :boolean, :boolean
          attr :integer, :integer
          attr :float, :float
          attr :list, :list
          attr :global, :global

          def func(assigns), do: ~H[]

          def global_line, do: __ENV__.line + 4

          def global_render(assigns) do
            ~H"""
            <.func global="global" />
            <.func phx-click="click" id="id"/>
            """
          end

          def any_line, do: __ENV__.line + 4

          def any_render(assigns) do
            ~H"""
            <.func any="any" />
            <.func any={:any} />
            <.func any={true} />
            <.func any={1} />
            <.func any={1.0} />
            <.func any={[]} />
            <.func any={nil} />
            """
          end

          def render_string_line, do: __ENV__.line + 4

          def string_render(assigns) do
            ~H"""
            <.func string="string" />
            <.func string={:string} />
            <.func string={true} />
            <.func string={1} />
            <.func string={1.0} />
            <.func string={[]} />
            <.func string={nil} />
            """
          end

          def render_atom_line, do: __ENV__.line + 4

          def atom_render(assigns) do
            ~H"""
            <.func atom="atom" />
            <.func atom={:atom} />
            <.func atom={true} />
            <.func atom={1} />
            <.func atom={1.0} />
            <.func atom={[]} />
            <.func atom={nil} />
            """
          end

          def render_boolean_line, do: __ENV__.line + 4

          def boolean_render(assigns) do
            ~H"""
            <.func boolean="boolean" />
            <.func boolean={:boolean} />
            <.func boolean={true} />
            <.func boolean={1} />
            <.func boolean={1.0} />
            <.func boolean={[]} />
            <.func boolean={nil} />
            """
          end

          def render_integer_line, do: __ENV__.line + 4

          def integer_render(assigns) do
            ~H"""
            <.func integer="integer" />
            <.func integer={:integer} />
            <.func integer={true} />
            <.func integer={1} />
            <.func integer={1.0} />
            <.func integer={[]} />
            <.func integer={nil} />
            """
          end

          def render_float_line, do: __ENV__.line + 4

          def float_render(assigns) do
            ~H"""
            <.func float="float" />
            <.func float={:float} />
            <.func float={true} />
            <.func float={1} />
            <.func float={1.0} />
            <.func float={[]} />
            <.func float={nil} />
            """
          end

          def render_list_line, do: __ENV__.line + 4

          def list_render(assigns) do
            ~H"""
            <.func list="list" />
            <.func list={:list} />
            <.func list={true} />
            <.func list={1} />
            <.func list={1.0} />
            <.func list={[]} />
            <.func list={nil} />
            """
          end
        end
      end)

    line = get_line(__MODULE__.TypeAttrs, :global_line)

    assert warnings =~ """
           global attribute "global" in component \
           Phoenix.ComponentVerifyTest.TypeAttrs.func/1 \
           may not be provided directly
             test/phoenix_component/verify_test.exs:#{line}: (file)
           """

    line = get_line(__MODULE__.TypeAttrs, :render_string_line)

    for {value, offset} <- [
          {:string, 1},
          {true, 2},
          {1, 3},
          {1.0, 4},
          {[], 5},
          {nil, 6}
        ] do
      assert warnings =~ """
             attribute "string" in component \
             Phoenix.ComponentVerifyTest.TypeAttrs.func/1 \
             must be a :string, got: #{inspect(value)}
               test/phoenix_component/verify_test.exs:#{line + offset}: (file)
             """
    end

    line = get_line(__MODULE__.TypeAttrs, :render_atom_line)

    for {value, offset} <- [
          {"atom", 0},
          {1, 3},
          {1.0, 4},
          {[], 5}
        ] do
      assert warnings =~ """
             attribute "atom" in component \
             Phoenix.ComponentVerifyTest.TypeAttrs.func/1 \
             must be an :atom, got: #{inspect(value)}
               test/phoenix_component/verify_test.exs:#{line + offset}: (file)
             """
    end

    line = get_line(__MODULE__.TypeAttrs, :render_boolean_line)

    for {value, offset} <- [
          {"boolean", 0},
          {:boolean, 1},
          {1, 3},
          {1.0, 4},
          {[], 5},
          {nil, 6}
        ] do
      assert warnings =~ """
             attribute "boolean" in component \
             Phoenix.ComponentVerifyTest.TypeAttrs.func/1 \
             must be a :boolean, got: #{inspect(value)}
               test/phoenix_component/verify_test.exs:#{line + offset}: (file)
             """
    end

    line = get_line(__MODULE__.TypeAttrs, :render_integer_line)

    for {value, offset} <- [
          {"integer", 0},
          {:integer, 1},
          {true, 2},
          {1.0, 4},
          {[], 5},
          {nil, 6}
        ] do
      assert warnings =~ """
             attribute "integer" in component \
             Phoenix.ComponentVerifyTest.TypeAttrs.func/1 \
             must be an :integer, got: #{inspect(value)}
               test/phoenix_component/verify_test.exs:#{line + offset}: (file)
             """
    end

    line = get_line(__MODULE__.TypeAttrs, :render_float_line)

    for {value, offset} <- [
          {"float", 0},
          {:float, 1},
          {true, 2},
          {1, 3},
          {[], 5},
          {nil, 6}
        ] do
      assert warnings =~ """
             attribute "float" in component \
             Phoenix.ComponentVerifyTest.TypeAttrs.func/1 \
             must be a :float, got: #{inspect(value)}
               test/phoenix_component/verify_test.exs:#{line + offset}: (file)
             """
    end

    line = get_line(__MODULE__.TypeAttrs, :render_list_line)

    for {value, offset} <- [
          {"list", 0},
          {:list, 1},
          {true, 2},
          {1, 3},
          {1.0, 4},
          {nil, 6}
        ] do
      assert warnings =~ """
             attribute "list" in component \
             Phoenix.ComponentVerifyTest.TypeAttrs.func/1 \
             must be a :list, got: #{inspect(value)}
               test/phoenix_component/verify_test.exs:#{line + offset}: (file)
             """
    end
  end

  test "validates attr values" do
    warnings =
      capture_io(:stderr, fn ->
        defmodule AttrValues do
          use Phoenix.Component

          attr :attr, :string, values: ["foo", "bar", "baz"]
          def func_string(assigns), do: ~H[]

          attr :attr, :atom, values: [:foo, :bar, :baz]
          def func_atom(assigns), do: ~H[]

          def line, do: __ENV__.line + 2

          def render(assigns) do
            ~H"""
            <.func_string attr="boom" />
            <.func_atom attr={:boom} />
            <.func_string attr={@string} />
            <.func_atom attr={@atom} />
            """
          end
        end
      end)

    line = get_line(__MODULE__.AttrValues, :line)

    assert warnings =~ """
           attribute "attr" in component \
           Phoenix.ComponentVerifyTest.AttrValues.func_string/1 \
           must be one of ["foo", "bar", "baz"], got: "boom"
             test/phoenix_component/verify_test.exs:#{line + 2}: (file)
           """

    assert warnings =~ """
           attribute "attr" in component \
           Phoenix.ComponentVerifyTest.AttrValues.func_atom/1 \
           must be one of [:foo, :bar, :baz], got: :boom
             test/phoenix_component/verify_test.exs:#{line + 3}: (file)
           """
  end

  test "validates slot attr values" do
    warnings =
      capture_io(:stderr, fn ->
        defmodule SlotAttrValues do
          use Phoenix.Component

          slot :named do
            attr :string, :string, values: ["foo", "bar", "baz"]
            attr :atom, :atom, values: [:foo, :bar, :baz]
          end

          def func(assigns), do: ~H[]

          def line, do: __ENV__.line + 2

          def render(assigns) do
            ~H"""
            <.func>
              <:named string="boom" atom={:boom} />
              <:named string={@string} atom={@atom} />
            </.func>
            """
          end
        end
      end)

    line = get_line(__MODULE__.SlotAttrValues, :line)

    assert warnings =~ """
           attribute "string" in slot "named" for component \
           Phoenix.ComponentVerifyTest.SlotAttrValues.func/1 \
           must be one of ["foo", "bar", "baz"], got: "boom"
             test/phoenix_component/verify_test.exs:#{line + 3}: (file)
           """

    assert warnings =~ """
           attribute "atom" in slot "named" for component \
           Phoenix.ComponentVerifyTest.SlotAttrValues.func/1 \
           must be one of [:foo, :bar, :baz], got: :boom
             test/phoenix_component/verify_test.exs:#{line + 3}: (file)
           """
  end

  test "validate required slots" do
    warnings =
      capture_io(:stderr, fn ->
        defmodule RequiredSlots do
          use Phoenix.Component

          slot :inner_block, required: true

          def func(assigns), do: ~H[]

          slot :named, required: true

          def func_named_slot(assigns), do: ~H[]

          def line, do: __ENV__.line + 2

          def render(assigns) do
            ~H"""
            <!-- no default slot provided -->
            <.func/>

            <!-- with an empty default slot -->
            <.func></.func>

            <!-- with content in the default slot -->
            <.func>Hello!</.func>

            <!-- no named slots provided -->
            <.func_named_slot/>

            <!-- with an empty named slot -->
            <.func_named_slot>
              <:named />
            </.func_named_slot>

            <!-- with content in the named slots -->
            <.func_named_slot>
              <:named>
                Hello!
              </:named>
            </.func_named_slot>

            <!-- with entires for the named slot -->
            <.func_named_slot>
              <:named>
                Hello,
              </:named>
              <:named>
                World!
              </:named>
            </.func_named_slot>
            """
          end
        end
      end)

    line = get_line(__MODULE__.RequiredSlots)

    assert warnings =~ """
           missing required slot "inner_block" for component \
           Phoenix.ComponentVerifyTest.RequiredSlots.func/1
             test/phoenix_component/verify_test.exs:#{line + 3}: (file)
           """

    assert warnings =~ """
           missing required slot "named" for component \
           Phoenix.ComponentVerifyTest.RequiredSlots.func_named_slot/1
             test/phoenix_component/verify_test.exs:#{line + 12}: (file)
           """
  end

  test "validate slot attr types" do
    warnings =
      capture_io(:stderr, fn ->
        defmodule SlotAttrs do
          use Phoenix.Component

          slot :slot do
            attr :any, :any
            attr :string, :string
            attr :atom, :atom
            attr :boolean, :boolean
            attr :integer, :integer
            attr :float, :float
            attr :list, :list
            attr :global, :global
          end

          def func(assigns), do: ~H[]

          def render_global_line, do: __ENV__.line + 5

          def render_global(assigns) do
            ~H"""
            <.func>
              <:slot global="global" />
              <:slot phx-click="click" id="id" />
            </.func>
            """
          end

          def render_any_line, do: __ENV__.line + 5

          def render_any(assigns) do
            ~H"""
            <.func>
              <:slot any />
              <:slot any="any" />
              <:slot any={:any} />
              <:slot any={true} />
              <:slot any={1} />
              <:slot any={1.0} />
              <:slot any={[]} />
            </.func>
            """
          end

          def render_string_line, do: __ENV__.line + 5

          def render_string(assigns) do
            ~H"""
            <.func>
              <:slot string="string" />
              <:slot string={:string} />
              <:slot string={true} />
              <:slot string={1} />
              <:slot string={1.0} />
              <:slot string={[]} />
              <:slot string={nil} />
            </.func>
            """
          end

          def render_atom_line, do: __ENV__.line + 5

          def render_atom(assigns) do
            ~H"""
            <.func>
              <:slot atom="atom" />
              <:slot atom={:atom} />
              <:slot atom={true} />
              <:slot atom={1} />
              <:slot atom={1.0} />
              <:slot atom={[]} />
              <:slot atom={nil} />
            </.func>
            """
          end

          def render_boolean_line, do: __ENV__.line + 5

          def render_boolean(assigns) do
            ~H"""
            <.func>
              <:slot boolean="boolean" />
              <:slot boolean={:boolean} />
              <:slot boolean={true} />
              <:slot boolean={1} />
              <:slot boolean={1.0} />
              <:slot boolean={[]} />
              <:slot boolean={nil} />
            </.func>
            """
          end

          def render_integer_line, do: __ENV__.line + 5

          def render_integer(assigns) do
            ~H"""
            <.func>
              <:slot integer="integer" />
              <:slot integer={:integer} />
              <:slot integer={true} />
              <:slot integer={1} />
              <:slot integer={1.0} />
              <:slot integer={[]} />
              <:slot integer={nil} />
            </.func>
            """
          end

          def render_float_line, do: __ENV__.line + 5

          def render_float(assigns) do
            ~H"""
            <.func>
              <:slot float="float" />
              <:slot float={:float} />
              <:slot float={true} />
              <:slot float={1} />
              <:slot float={1.0} />
              <:slot float={[]} />
              <:slot float={nil} />
            </.func>
            """
          end

          def render_list_line, do: __ENV__.line + 5

          def render_list(assigns) do
            ~H"""
            <.func>
              <:slot list="list" />
              <:slot list={:list} />
              <:slot list={true} />
              <:slot list={1} />
              <:slot list={1.0} />
              <:slot list={[]} />
              <:slot list={nil} />
            </.func>
            """
          end
        end
      end)

    line = get_line(__MODULE__.SlotAttrs, :render_global_line)

    assert warnings =~ """
           global attribute "global" \
           in slot \"slot\" \
           for component Phoenix.ComponentVerifyTest.SlotAttrs.func/1 \
           may not be provided directly
             test/phoenix_component/verify_test.exs:#{line}: (file)
           """

    line = get_line(__MODULE__.SlotAttrs, :render_string_line)

    for {value, offset} <- [
          {:string, 1},
          {true, 2},
          {1, 3},
          {1.0, 4},
          {[], 5},
          {nil, 6}
        ] do
      assert warnings =~ """
             attribute "string" \
             in slot \"slot\" \
             for component Phoenix.ComponentVerifyTest.SlotAttrs.func/1 \
             must be a :string, got: #{inspect(value)}
               test/phoenix_component/verify_test.exs:#{line + offset}: (file)
             """
    end

    line = get_line(__MODULE__.SlotAttrs, :render_atom_line)

    for {value, offset} <- [
          {"atom", 0},
          {1, 3},
          {1.0, 4},
          {[], 5}
        ] do
      assert warnings =~ """
             attribute "atom" \
             in slot \"slot\" \
             for component Phoenix.ComponentVerifyTest.SlotAttrs.func/1 \
             must be an :atom, got: #{inspect(value)}
               test/phoenix_component/verify_test.exs:#{line + offset}: (file)
             """
    end

    line = get_line(__MODULE__.SlotAttrs, :render_boolean_line)

    for {value, offset} <- [
          {"boolean", 0},
          {:boolean, 1},
          {1, 3},
          {1.0, 4},
          {[], 5},
          {nil, 6}
        ] do
      assert warnings =~ """
             attribute "boolean" \
             in slot \"slot\" \
             for component Phoenix.ComponentVerifyTest.SlotAttrs.func/1 \
             must be a :boolean, got: #{inspect(value)}
               test/phoenix_component/verify_test.exs:#{line + offset}: (file)
             """
    end

    line = get_line(__MODULE__.SlotAttrs, :render_integer_line)

    for {value, offset} <- [
          {"integer", 0},
          {:integer, 1},
          {true, 2},
          {1.0, 4},
          {[], 5},
          {nil, 6}
        ] do
      assert warnings =~ """
             attribute "integer" \
             in slot \"slot\" \
             for component Phoenix.ComponentVerifyTest.SlotAttrs.func/1 \
             must be an :integer, got: #{inspect(value)}
               test/phoenix_component/verify_test.exs:#{line + offset}: (file)
             """
    end

    line = get_line(__MODULE__.SlotAttrs, :render_float_line)

    for {value, offset} <- [
          {"float", 0},
          {:float, 1},
          {true, 2},
          {1, 3},
          {[], 5},
          {nil, 6}
        ] do
      assert warnings =~ """
             attribute "float" \
             in slot \"slot\" \
             for component Phoenix.ComponentVerifyTest.SlotAttrs.func/1 \
             must be a :float, got: #{inspect(value)}
               test/phoenix_component/verify_test.exs:#{line + offset}: (file)
             """
    end

    line = get_line(__MODULE__.SlotAttrs, :render_list_line)

    for {value, offset} <- [
          {"list", 0},
          {:list, 1},
          {true, 2},
          {1, 3},
          {1.0, 4},
          {nil, 6}
        ] do
      assert warnings =~ """
             attribute "list" \
             in slot \"slot\" \
             for component Phoenix.ComponentVerifyTest.SlotAttrs.func/1 \
             must be a :list, got: #{inspect(value)}
               test/phoenix_component/verify_test.exs:#{line + offset}: (file)
             """
    end
  end

  test "validates required slot attrs" do
    warnings =
      capture_io(:stderr, fn ->
        defmodule RequiredSlotAttrs do
          use Phoenix.Component

          slot :slot do
            attr :attr, :string, required: true
          end

          def func(assigns) do
            ~H"""
            <div>
            <%= render_slot(@slot) %>
            </div>
            """
          end

          def line(), do: __ENV__.line + 4

          def render(assigns) do
            ~H"""
            <.func>
            <:slot />
            <:slot attr="foo" />
            <:slot>
            foo
            </:slot>
            <:slot attr="bar">
            bar
            </:slot>
            <:slot {[attr: "bar"]} />
            </.func>
            """
          end
        end
      end)

    line = get_line(__MODULE__.RequiredSlotAttrs)

    assert warnings =~ """
           missing required attribute "attr" \
           in slot "slot" \
           for component \
           Phoenix.ComponentVerifyTest.RequiredSlotAttrs.func/1
             test/phoenix_component/verify_test.exs:#{line + 1}: (file)
           """

    assert warnings =~ """
           missing required attribute "attr" \
           in slot "slot" \
           for component \
           Phoenix.ComponentVerifyTest.RequiredSlotAttrs.func/1
             test/phoenix_component/verify_test.exs:#{line + 3}: (file)
           """
  end

  test "validates undefined slots" do
    warnings =
      capture_io(:stderr, fn ->
        defmodule UndefinedSlots do
          use Phoenix.Component

          attr :attr, :any

          def fun_no_slots(assigns), do: ~H[]

          slot :inner_block

          def func(assigns), do: ~H[]

          slot :named

          def func_undefined_slot_attrs(assigns), do: ~H[]

          def line, do: __ENV__.line + 2

          def render(assigns) do
            ~H"""
            <!-- undefined default slot -->
            <.fun_no_slots>
              hello
            </.fun_no_slots>

            <!-- undefined named slot -->
            <.func>
            <:undefined />
            </.func>

            <!-- named slot with undefined attrs -->
            <.func_undefined_slot_attrs>
            <:named undefined />
            <:named undefined="undefined" />
            </.func_undefined_slot_attrs>
            """
          end
        end
      end)

    line = get_line(__MODULE__.UndefinedSlots)

    assert warnings =~ """
           undefined slot "inner_block" for component \
           Phoenix.ComponentVerifyTest.UndefinedSlots.fun_no_slots/1
             test/phoenix_component/verify_test.exs:#{line + 3}: (file)
           """

    assert warnings =~ """
           undefined slot "undefined" for component \
           Phoenix.ComponentVerifyTest.UndefinedSlots.func/1
             test/phoenix_component/verify_test.exs:#{line + 9}: (file)
           """

    assert warnings =~ """
           undefined attribute "undefined" \
           in slot "named" \
           for component \
           Phoenix.ComponentVerifyTest.UndefinedSlots.func_undefined_slot_attrs/1
             test/phoenix_component/verify_test.exs:#{line + 14}: (file)
           """

    assert warnings =~ """
           undefined attribute "undefined" \
           in slot "named" \
           for component \
           Phoenix.ComponentVerifyTest.UndefinedSlots.func_undefined_slot_attrs/1
             test/phoenix_component/verify_test.exs:#{line + 15}: (file)
           """
  end

  test "validates calls for locally defined components" do
    warnings =
      capture_io(:stderr, fn ->
        defmodule LocalComponents do
          use Phoenix.Component

          attr :attr, :string, required: true

          def public(assigns) do
            ~H"""
            <%= @attr %>
            """
          end

          attr :attr, :string, required: true

          defp private(assigns) do
            ~H"""
            <%= @attr %>
            """
          end

          def line, do: __ENV__.line + 2

          def render(assigns) do
            ~H"""
            <.public />
            <.private />
            """
          end
        end
      end)

    line = get_line(__MODULE__.LocalComponents)

    assert warnings =~ """
           missing required attribute "attr" \
           for component \
           Phoenix.ComponentVerifyTest.LocalComponents.public/1
             test/phoenix_component/verify_test.exs:#{line + 2}: (file)
           """

    assert warnings =~ """
           missing required attribute "attr" \
           for component \
           Phoenix.ComponentVerifyTest.LocalComponents.private/1
             test/phoenix_component/verify_test.exs:#{line + 3}: (file)
           """
  end

  test "global includes" do
    import Phoenix.LiveViewTest

    defmodule GlobalIncludes do
      use Phoenix.Component

      attr :id, :any, required: true
      attr :rest, :global, include: ~w(form)
      def button(assigns), do: ~H|<button id={@id} {@rest}>button</button>|
      def any_render(assigns), do: ~H|<.button id="123" form="my-form" />|
    end

    assigns = %{id: "abc", form: "my-form"}

    assert render_component(&GlobalIncludes.button/1, assigns) ==
             "<button id=\"abc\" form=\"my-form\">button</button>"
  end

  defp get_line(module, fun \\ :line) do
    apply(module, fun, [])
  end
end
