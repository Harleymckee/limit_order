defmodule LimitOrder.CoinbaseUpdate do
  @moduledoc """
  Schema and changesets for capturing coinbase update
  """
  use Ecto.Schema
  import Ecto.{Query, Changeset}, warn: false

  @type t :: %__MODULE__{}
  schema "coinbase_updates" do
    field(:type, :string)
    field(:time, :string)
    field(:sequence, :integer)
    field(:trade_id, :integer)
    field(:product_id, :string)
    field(:order_id, :string)
    field(:stop_type, :string)
    field(:stop_price, :string)
    field(:taker_fee_rate, :string)
    field(:private, :boolean)
    field(:size, :string)
    field(:remaining_size, :string)
    field(:reason, :string)
    field(:price, :string)
    field(:side, :string)
    field(:order_type, :string)
    field(:funds, :string)
    field(:new_size, :string)
    field(:old_size, :string)
    field(:new_funds, :string)
    field(:old_funds, :string)

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [
      :type,
      :time,
      :sequence,
      :trade_id,
      :product_id,
      :order_id,
      :stop_type,
      :stop_price,
      :taker_fee_rate,
      :private,
      :size,
      :remaining_size,
      :reason,
      :price,
      :side,
      :order_type,
      :funds,
      :new_size,
      :old_size,
      :new_funds,
      :old_funds
    ])

    # |> validate_required()
  end
end
