defmodule Owl.IOTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  test inspect(&Owl.IO.confirm/1) do
    assert capture_io([input: "\n"], fn ->
             refute Owl.IO.confirm()
           end) == "Are you sure? [yN]: "

    assert capture_io([input: "y"], fn ->
             assert Owl.IO.confirm(message: "Really?")
           end) == "Really? [yN]: "

    assert capture_io([input: ""], fn ->
             assert Owl.IO.confirm(message: Owl.Tag.new("Really?", :red), default: true)
           end) == "\e[31mReally?\e[39m\e[49m [Yn]: \e[0m"

    assert capture_io([input: "YES\ny"], fn ->
             assert Owl.IO.confirm(message: "Really?")
           end) == "Really? [yN]: \e[31munknown choice\e[39m\e[49m\e[0m\nReally? [yN]: "
  end

  test inspect(&Owl.IO.input/1) do
    assert capture_io([input: "\n"], fn ->
             assert Owl.IO.input(optional: true, label: "optional input:") == nil
           end) == "optional input:\n\e[34m> \e[39m\e[49m\e[0m"

    assert capture_io([input: "hello world\n"], fn ->
             assert Owl.IO.input() == "hello world"
           end) == "\e[34m> \e[39m\e[49m\e[0m"

    assert capture_io([input: "33\n"], fn ->
             assert Owl.IO.input(cast: :integer) == 33
           end) == "\e[34m> \e[39m\e[49m\e[0m"

    assert capture_io([input: "3a\n3\n101\n18"], fn ->
             assert Owl.IO.input(cast: {:integer, min: 18, max: 100}) == 18
           end) ==
             """
             \e[34m> \e[39m\e[49m\e[0m\e[31mnot an integer\e[39m\e[49m\e[0m
             \e[34m> \e[39m\e[49m\e[0m\e[31mmust be greater than or equal to 18\e[39m\e[49m\e[0m
             \e[34m> \e[39m\e[49m\e[0m\e[31mmust be less than or equal to 100\e[39m\e[49m\e[0m
             \e[34m> \e[39m\e[49m\e[0m
             """
             |> String.trim_trailing()

    assert capture_io([input: "password\n"], fn ->
             assert Owl.IO.input(secret: true) == "password"
           end) == "\e[34m> \e[39m\e[49m\e[0m"

    assert capture_io([input: "password\n"], fn ->
             assert Owl.IO.input(secret: true, label: "Multi\n  line prompt:") == "password"
           end) == "Multi\n  line prompt:\n\e[34m> \e[39m\e[49m\e[0m"
  end

  test inspect(&Owl.IO.select/2) do
    assert capture_io([input: "2\n"], fn ->
             assert Owl.IO.select(["one", "two", "three"]) == "two"
           end) ==
             """
             \e[34m1\e[39m\e[49m. one
             \e[34m2\e[39m\e[49m. two
             \e[34m3\e[39m\e[49m. three\e[0m

             \e[34m> \e[39m\e[49m\e[0m
             """
             |> String.trim_trailing()

    assert capture_io(fn ->
             assert Owl.IO.select(["one"]) == "one"
           end) == "Autoselect: one\n"

    assert capture_io([input: "2\n"], fn ->
             assert ~D[2001-01-01]
                    |> Date.range(~D[2001-01-03])
                    |> Enum.to_list()
                    |> Owl.IO.select(render_as: &Date.to_iso8601/1, label: "Please select a date") ==
                      ~D[2001-01-02]
           end) ==
             """
             \e[34m1\e[39m\e[49m. 2001-01-01
             \e[34m2\e[39m\e[49m. 2001-01-02
             \e[34m3\e[39m\e[49m. 2001-01-03\e[0m

             Please select a date
             \e[34m> \e[39m\e[49m\e[0m
             """
             |> String.trim_trailing()
  end

  test inspect(&Owl.IO.multiselect/2) do
    assert capture_io([input: "11\n1\n1,3"], fn ->
             assert Owl.IO.multiselect(["one", "two", "three"],
                      min: 2,
                      label: "Select 2 numbers:",
                      render_as: &String.upcase/1
                    ) == ["one", "three"]
           end) ==
             """
             \e[34m1\e[39m\e[49m. ONE
             \e[34m2\e[39m\e[49m. TWO
             \e[34m3\e[39m\e[49m. THREE\e[0m

             Select 2 numbers:
             \e[34m> \e[39m\e[49m\e[0m\e[31munknown values: '\\v'\e[39m\e[49m\e[0m
             Select 2 numbers:
             \e[34m> \e[39m\e[49m\e[0m\e[31mthe number of elements must be greater than or equal to 2\e[39m\e[49m\e[0m
             Select 2 numbers:
             \e[34m> \e[39m\e[49m\e[0m
             """
             |> String.trim_trailing()

    assert capture_io([input: "\n"], fn ->
             assert Owl.IO.multiselect(["one"]) == []
           end) == "\e[34m1\e[39m\e[49m. one\e[0m\n\n\e[34m> \e[39m\e[49m\e[0m"

    assert_raise(ArgumentError, fn ->
      Owl.IO.multiselect(["one"], min: 2)
    end)
  end

  test inspect(&Owl.IO.open_in_editor/1) do
    System.put_env("ELIXIR_EDITOR", "echo 'new data' >> __FILE__")
    assert Owl.IO.open_in_editor("data\n") == "data\nnew data\n"

    System.put_env("ELIXIR_EDITOR", "echo 'new data' >>")
    assert Owl.IO.open_in_editor("data\n") == "data\nnew data\n"
  after
    System.delete_env("ELIXIR_EDITOR")
  end
end