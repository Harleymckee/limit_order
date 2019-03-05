defmodule LimitOrder.Repo do
  use Ecto.Repo,
    otp_app: :limit_order,
    adapter: Ecto.Adapters.Postgres
end
