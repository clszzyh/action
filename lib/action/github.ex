defmodule Action.Github do
  @moduledoc """
  https://docs.github.com/en/free-pro-team@latest/actions/reference/context-and-expression-syntax-for-github-actions#github-context
  """

  alias Action.Api
  alias Tentacat.Client

  @type t :: %__MODULE__{
          client: Client.t(),
          sha: binary(),
          repository_name: binary(),
          repository_owner: binary(),
          event_name: binary(),
          event: map(),
          state: atom(),
          result: term()
        }
  @enforce_keys [:client, :sha, :repository_name, :repository_owner, :event_name, :event]
  defstruct @enforce_keys ++ [:result, state: :ok]

  @spec init(binary() | nil) :: {:ok, t()} | {:error, binary() | atom()}
  def init(arg \\ nil)

  def init(binary) when is_binary(binary) do
    %{token: token, repository: repository} = data = Jason.decode!(binary, keys: :atoms)
    [_, repository_name | []] = String.split(repository, "/")

    {:ok,
     struct(
       __MODULE__,
       Map.merge(data, %{
         repository_name: repository_name,
         client: Client.new(%{access_token: token})
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
