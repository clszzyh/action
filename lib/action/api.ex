defmodule Action.Api do
  @moduledoc """
  https://github.com/actions/toolkit/blob/main/packages/core/src/core.ts
  """

  alias Action.Command

  # @type put_commands :: :mask | :path | :output | :echo
  # @type get_commands :: :input | :debug

  @typep key :: Command.property_key()
  @typep value :: Command.property_value()
  @typep message :: Command.message()

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

  @spec warning(message()) :: :ok
  def warning(message), do: Command.issue("warning", message)

  @spec error(message()) :: :ok
  def error(message), do: Command.issue("error", message)

  @spec debug(message()) :: :ok
  def debug(message), do: Command.issue("debug", message)

  @spec debug? :: boolean()
  def debug?, do: System.get_env("RUNNER_DEBUG") == "1"

  @spec get_input(binary()) :: binary() | nil
  def get_input(name), do: System.get_env("INPUT_#{name}")

  @spec get_state(binary()) :: binary() | nil
  def get_state(name), do: System.get_env("STATE_#{name}")
end
