defmodule Action.Command do
  @moduledoc """
  https://github.com/actions/toolkit/blob/main/packages/core/src/command.ts

  ## Example

      iex> a = %#{__MODULE__}{command: "name", properties: %{foo: :bar, hello: :world}, message: "ok"}
      iex> inspect(a)
      "::name $foo=$bar,$hello=$world::ok"
  """

  @type property_key :: atom
  @type property_value :: binary() | atom()
  @type message :: binary()
  @type t :: %__MODULE__{
          command: binary(),
          message: message(),
          properties: %{property_key() => property_value()}
        }

  @enforce_keys [:command]
  defstruct @enforce_keys ++ [message: "", properties: %{}]

  defimpl Inspect do
    @message_replacement %{
      "%" => "%25",
      "\r" => "%0D",
      "\n" => "%0A"
    }

    @property_replacement %{
      "%" => "%25",
      "\r" => "%0D",
      "\n" => "%0A",
      ":" => "%3A",
      "," => "%2C"
    }

    @command_string "::"
    @comma ","

    alias Action.Command

    def inspect(%{command: command, message: message, properties: %{} = properties}, _) do
      properties_str =
        Enum.map_join(properties, @comma, fn {k, v} ->
          "$#{k}=$#{Command.escape(v, @property_replacement)}"
        end)

      properties_str = if properties_str == "", do: "", else: " " <> properties_str

      message = Command.escape(message, @message_replacement)
      "#{@command_string}#{command}#{properties_str}#{@command_string}#{message}"
    end
  end

  @spec escape(property_value(), map()) :: binary()
  def escape(str, %{} = replacement) when is_binary(str) do
    String.replace(str, Map.keys(replacement), fn x -> replacement[x] end)
  end

  def escape(str, replacement) when is_atom(str), do: escape(to_string(str), replacement)

  @spec issue(binary() | t(), term()) :: :ok
  def issue(command, rest \\ nil)
  def issue(%__MODULE__{} = cmd, nil), do: IO.puts(inspect(cmd))
  def issue(command, rest), do: issue(init(command, rest))

  @spec init(binary(), term()) :: t()
  def init(command, rest \\ nil)
  def init(command, nil), do: %__MODULE__{command: command}

  def init(command, message) when is_binary(message),
    do: %__MODULE__{command: command, message: message}

  def init(command, message) when is_atom(message),
    do: %__MODULE__{command: command, message: to_string(message)}

  def init(command, {k, v, value}) do
    %__MODULE__{command: command, message: value, properties: %{k => v}}
  end
end
