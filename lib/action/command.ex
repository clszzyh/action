defmodule Action.Command do
  @moduledoc """
  https://github.com/actions/toolkit/blob/main/packages/core/src/command.ts

  ## Example

  iex> a = %#{__MODULE__}{command: "name", properties: %{foo: :bar, hello: :world}, message: "ok"}
  iex> inspect(a)
  "::name $foo=$bar,$hello=$world::ok"
  """

  @type t :: %__MODULE__{
          command: binary(),
          message: binary(),
          properties: %{atom() => binary() | atom()}
        }

  @enforce_keys [:command, :message]
  defstruct @enforce_keys ++ [properties: %{}]

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

  def escape(str, %{} = replacement) when is_binary(str) do
    String.replace(str, Map.keys(replacement), fn x -> replacement[x] end)
  end

  def escape(str, replacement) when is_atom(str), do: escape(to_string(str), replacement)
end
