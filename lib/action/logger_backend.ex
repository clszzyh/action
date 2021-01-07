defmodule Action.LoggerBackend do
  @moduledoc """
  A github action logger backend.

  ## Usage

      config :logger,
        backends: [:console, #{__MODULE__}]
  """

  @behaviour :gen_event

  @type level :: Logger.level()
  @type message :: Logger.message()
  @type metadata :: Logger.metadata()

  @type t :: %__MODULE__{
          level: level(),
          metadata: [atom()] | :all,
          flush_interval: non_neg_integer,
          format: Logger.Formatter.pattern()
        }

  @default_flush_interval 1000
  @default_format "$time $metadata[$level] $message\n"

  defstruct level: :debug,
            metadata: [],
            flush_interval: @default_flush_interval,
            format: @default_format

  @impl true
  def init(__MODULE__) do
    configure(%__MODULE__{}, [])
  end

  @impl true
  def handle_call({:configure, opts}, state) do
    {:ok, state} = configure(state, opts)
    {:ok, :ok, state}
  end

  @impl true
  def handle_event({_level, gl, {Logger, _, _, _}}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({_level, _gl, {Logger, _, _, _}} = event, %__MODULE__{level: nil} = state) do
    log(event, state)
  end

  def handle_event({level, _gl, {Logger, _, _, _}} = event, %__MODULE__{level: min_level} = state) do
    if Logger.compare_levels(level, min_level) == :lt do
      {:ok, state}
    else
      log(event, state)
    end
  end

  def handle_event(:flush, state) do
    {:ok, state}
  end

  def handle_event(_, state) do
    {:ok, state}
  end

  @impl true
  def handle_info(_, state) do
    {:ok, state}
  end

  @impl true
  def terminate(_reason, _state) do
    :ok
  end

  # @spec configure(t(), keyword()) :: {:ok, t()}
  defp configure(%__MODULE__{} = state, opts) do
    %{format: format} = state |> Map.merge(struct!(__MODULE__, opts))
    state |> Map.put(:format, Logger.Formatter.compile(format)) |> schedule_flush()
  end

  # @spec schedule_flush(t()) :: {:ok, t()}
  defp schedule_flush(%__MODULE__{} = state) do
    Process.send_after(self(), :flush, state.flush_interval)
    {:ok, state}
  end

  defp take_metadata(metadata, :all), do: metadata

  defp take_metadata(metadata, keys) do
    Enum.reduce(keys, [], fn key, acc ->
      case Keyword.fetch(metadata, key) do
        {:ok, val} -> [{key, val} | acc]
        :error -> acc
      end
    end)
  end

  defp log(
         {level, _, {Logger, msg, datetime, metadata}},
         %__MODULE__{format: format, metadata: keys} = state
       ) do
    output = Logger.Formatter.format(format, level, msg, datetime, take_metadata(metadata, keys))

    :ok = Action.Api.logger(level, to_string(output))

    {:ok, state}
  end
end
