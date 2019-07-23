defmodule LimitOrder.Repo.Migrations.CreateCoinbaseUpdates do
  use Ecto.Migration

  def change do
    create table(:coinbase_updates) do
      add :type, :string
      add :time, :string
      add :sequence, :string
      add :trade_id, :integer
      add :product_id, :string
      add :order_id, :string
      add :profile_id, :string
      add :stop_type, :string
      add :stop_price, :string
      add :taker_fee_rate, :string
      add :private, :boolean
      add :size, :string
      add :remaining_size, :string
      add :reason, :string
      add :price, :string
      add :side, :string
      add :order_type, :string
      add :funds, :string
      add :new_size, :string
      add :old_size, :string
      add :new_funds, :string
      add :old_funds, :string

      timestamps()
    end
  end
end
