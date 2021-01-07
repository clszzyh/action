defmodule Action.Github do
  @moduledoc """
  https://docs.github.com/en/free-pro-team@latest/actions/reference/context-and-expression-syntax-for-github-actions#github-context
  """

  alias Action.Api
  alias Tentacat.Client
  require Logger

  @type t :: %__MODULE__{
          client: Client.t(),
          repository_name: binary(),
          repository_owner: binary(),
          event_name: binary(),
          event: map()
        }

  @type invoke_result :: Tentacat.response()
  @type resp :: HTTPoison.Response.t()

  @enforce_keys [:client, :repository_name, :repository_owner, :event_name, :event]
  defstruct @enforce_keys

  @spec invoke(t(), (any(), any(), any() -> result), nil) :: result when result: any()
  @spec invoke(t(), (any(), any(), any(), any() -> result), [any() | []]) :: result
        when result: any()
  @spec invoke(t(), (any(), any(), any(), any(), any() -> result), [any()]) :: result
        when result: any()
  def invoke(me, f, extra \\ nil)

  def invoke(%__MODULE__{} = me, f, nil) when is_function(f, 3) do
    apply(f, normalize(me))
  end

  def invoke(%__MODULE__{} = me, f, [_] = extra) when is_function(f, 4) do
    apply(f, normalize(me) ++ extra)
  end

  def invoke(%__MODULE__{} = me, f, [_ | _] = extra) when is_function(f, 5) do
    apply(f, normalize(me) ++ extra)
  end

  defp normalize(%__MODULE__{
         client: client,
         repository_owner: repository_owner,
         repository_name: repository_name
       }) do
    [client, repository_owner, repository_name]
  end

  @spec init(binary() | nil) :: {:ok, t()} | {:error, binary()}
  def init(arg \\ nil)

  def init(binary) when is_binary(binary) do
    IO.puts(binary)
    %{token: token, repository: repository} = data = Jason.decode!(binary, keys: :atoms)
    [_, repository_name | []] = String.split(repository, "/")

    {:ok,
     struct(
       __MODULE__,
       Map.merge(data, %{
         repository_name: repository_name,
         client: Client.new(%{access_token: Api.get_input("TOKEN") || token})
       })
     )}
  end

  def init(nil) do
    "GITHUB"
    |> Api.get_input()
    |> case do
      nil -> {:error, "Not found `GITHUB` env"}
      env -> init(env)
    end
  end
end
