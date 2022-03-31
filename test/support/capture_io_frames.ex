defmodule CaptureIOFrames do
  import ExUnit.CaptureIO

  @separator "#@(₴?$0"
  def render_separator, do: IO.write(@separator)

  def capture_io_frames(callback, opts \\ []) when is_function(callback, 2) do
    capture_io(fn ->
      live_screen_pid =
        ExUnit.Callbacks.start_supervised!(
          {Owl.LiveScreen, Keyword.merge([terminal_width: 50], opts)}
        )

      callback.(
        live_screen_pid,
        fn ->
          GenServer.call(live_screen_pid, :render)
          render_separator()
        end
      )

      Owl.LiveScreen.stop(live_screen_pid)
    end)
    |> String.split(@separator, trim: true)
  end
end
