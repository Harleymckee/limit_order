defmodule LimitOrder.Repo.Migrations.AddTimescale do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE"
    execute "SELECT create_hypertable('coinbase_updates', 'time')"
    execute "CREATE USER grafana"
    execute "GRANT SELECT ON coinbase_updates to grafana"
  end
end
