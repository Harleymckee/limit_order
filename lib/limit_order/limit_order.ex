defmodule LimitOrder.Coinbase do
  use WebSockex
  require Logger

  def start_link() do
    {:ok, pid} = WebSockex.start("wss://ws-feed.pro.coinbase.com", __MODULE__, %{})

    WebSockex.send_frame(
      pid,
      {:text,
       Jason.encode!(%{
         "type" => "subscribe",
         "product_ids" => ["ETH-BTC"],
         "channels" => ["full"]
       })}
    )

    {:ok, pid}
  end

  def handle_connect(_conn, state) do
    IO.inspect("Inside connect handler")
    {:ok, state}
  end

  def handle_disconnect(%{reason: reason}, state) do
    Logger.warn("websocket closing: #{inspect(reason)}")
    {:ok, state}
  end

  def handle_frame({:text, payload}, state) do
    payload = Jason.decode!(payload)
    changeset = LimitOrder.CoinbaseUpdate.changeset(%LimitOrder.CoinbaseUpdate{}, payload)

    LimitOrder.Repo.insert!(changeset)
    |> IO.inspect()

    {:ok, state}
  end

  def terminate(reason, state) do
    IO.puts(
      "WebSockex for remote debbugging on port #{state.port} terminating with reason: #{
        inspect(reason)
      }"
    )

    exit(:normal)
  end
end
