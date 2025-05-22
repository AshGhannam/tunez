defmodule Tunez.Music.Calculations.SecondsToMinutes do
  use Ash.Resource.Calculation
  # @impl true
  # def calculate(tracks, _opts, _context) do
  #   Enum.map(tracks, fn %{duration_seconds: duration} ->
  #     seconds =
  #       rem(duration, 60)
  #       |> Integer.to_string()
  #       |> String.pad_leading(2, "0")

  #     "#{div(duration, 60)}:#{seconds}"
  #   end)
  # end

  @impl true
  def expression(_opts, _context) do
    expr(
      fragment("? / 60 || to_char(? * interval '1s', ':SS')", duration_seconds, duration_seconds)
    )
  end
end
