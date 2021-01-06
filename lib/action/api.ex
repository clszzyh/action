defmodule Action.Api do
  @moduledoc """
  https://github.com/actions/toolkit/blob/main/packages/core/src/core.ts
  """

  alias Action.Command

  @type key :: Command.property_key()
  @type value :: Command.property_value()
  @type message :: Command.message()
  @type level :: Logger.level()

  @spec add_mask(message()) :: :ok
  def add_mask(secret), do: Command.issue("add-mask", secret)

  @spec set_output(key(), value(), message() | nil) :: :ok
  def set_output(k, v, value \\ nil), do: Command.issue("set-output", {k, v, value})

  @spec save_state(key(), value(), message() | nil) :: :ok
  def save_state(k, v, value \\ nil), do: Command.issue("save-state", {k, v, value})

  @spec add_path(message()) :: :ok
  def add_path(path) do
    :ok = Command.issue("add-path", path)
    paths = System.get_env("PATH", "")
    :ok = System.put_env("PATH", "#{path}:#{paths}")
    :ok
  end

  @spec set_echo(boolean) :: :ok
  def set_echo(true), do: Command.issue("echo", "on")
  def set_echo(false), do: Command.issue("echo", "off")

  @spec span(message(), (() -> result)) :: result when result: term()
  def span(name, f) do
    :ok = group(name)
    result = f.()
    :ok = end_group()
    result
  end

  @spec group(message()) :: :ok
  def group(name), do: Command.issue("group", name)

  @spec end_group :: :ok
  def end_group, do: Command.issue("endGroup")

  @spec logger(level(), message()) :: :ok
  @doc """
      :emergency | :alert | :critical | :error | :warning | :warn | :notice | :info | :debug
  """
  def logger(:error, message), do: error(message)
  def logger(:warning, message), do: warning(message)
  def logger(:warn, message), do: warning(message)
  def logger(:debug, message), do: debug(message)
  def logger(_, message), do: IO.write(message)

  @spec warning(message()) :: :ok
  def warning(message), do: Command.issue("warning", message)

  @spec error(message()) :: :ok
  def error(message), do: Command.issue("error", message)

  @spec debug(message()) :: :ok
  def debug(message) do
    if debug?() do
      Command.issue("debug", message)
    else
      IO.write(message)
    end
  end

  @spec debug? :: boolean()
  def debug?, do: System.get_env("RUNNER_DEBUG") == "1"

  @spec get_input(binary()) :: binary() | nil
  def get_input(name), do: System.get_env("INPUT_#{name}")

  @spec get_state(binary()) :: binary() | nil
  def get_state(name), do: System.get_env("STATE_#{name}")
end
