defmodule Mix.Tasks.Ecto.MigrateTest do
  use ExUnit.Case, async: true

  import Mix.Tasks.Ecto.Migrate, only: [run: 2]

  defmodule Repo do
    def start_link do
      Process.put(:started, true)
      :ok
    end

    def priv do
      "hello"
    end

    def __repo__ do
      true
    end
  end

  test "runs the migrator" do
    run [to_string(Repo), "--no-start"], fn _, _, _, _ ->
      Process.put(:migrated, true)
    end
    assert Process.get(:migrated)
    assert Process.get(:started)
  end

  test "runs the migrator yielding the repository and migrations path" do
    run [to_string(Repo), "--no-start"], fn repo, path, direction, strategy ->
      assert repo == Repo
      assert path == "hello/migrations"
      assert direction == :up
      assert strategy == [all: true, no_start: true]
    end
  end
end
