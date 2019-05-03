defmodule LimitOrder.Coinbase do
  alias LimitOrder.Orderbook
  use WebSockex
  require Logger

  def start_link() do
    {:ok, books_agent} =
      Agent.start_link(fn ->
        %{
          queues: %{},
          sequences: %{}
        }
      end)

    {:ok, books_agent} = new_product(books_agent, "ETH-BTC")

    {:ok, wesocket_process} =
      WebSockex.start("wss://ws-feed.pro.coinbase.com", __MODULE__, %{books_agent: books_agent})

    WebSockex.send_frame(
      wesocket_process,
      {:text,
       Jason.encode!(%{
         "type" => "subscribe",
         "product_ids" => ["ETH-BTC"],
         "channels" => ["full"]
       })}
    )

    {:ok, wesocket_process}
  end

  defp new_product(books_agent, product_id) do
    {:ok, orderbook_process} = Orderbook.start_link([])
    IO.inspect(orderbook_process)
    IO.puts("new orderbook")

    Agent.update(books_agent, &Map.put(&1, product_id, orderbook_process))

    queues = Agent.get(books_agent, &Map.get(&1, :queues))
    sequences = Agent.get(books_agent, &Map.get(&1, :sequences))

    queues = Map.put(queues, product_id, [])
    sequences = Map.put(sequences, product_id, -2)

    Agent.update(books_agent, &Map.put(&1, :queues, queues))
    Agent.update(books_agent, &Map.put(&1, :sequences, sequences))

    {:ok, books_agent}
  end

  def handle_connect(_conn, state) do
    IO.inspect("Inside connect handler")
    {:ok, state}
  end

  def handle_disconnect(%{reason: reason}, state) do
    Logger.warn("websocket closing: #{inspect(reason)}")
    {:ok, state}
  end

  def handle_frame(
        {:text, %{"product_id" => nil} = payload},
        %{books_agent: books_agent} = state
      ) do
    IO.puts("no product id")
    payload = Jason.decode!(payload)
    changeset = LimitOrder.CoinbaseUpdate.changeset(%LimitOrder.CoinbaseUpdate{}, payload)

    LimitOrder.Repo.insert!(changeset)

    IO.inspect(payload)

    product_id = payload["product_id"]

    IO.inspect(product_id)

    {:ok, state}
  end

  def handle_frame({:text, payload}, %{books_agent: books_agent} = state) do
    payload = Jason.decode!(payload)
    product_id = payload["product_id"]
    type = payload["type"]

    book_agent = Agent.get(books_agent, &Map.get(&1, product_id))

    if type == "subscriptions" do
      # TODO
      nil
    end

    # # MORE TODO:
    # # Sequence Stuff

    {:ok, book_agent} =
      case type do
        "open" ->
          Orderbook.add(book_agent, payload)

        "done" ->
          Orderbook.remove(book_agent, payload["order_id"])

        "match" ->
          Orderbook.match(book_agent, payload)

        "change" ->
          Orderbook.change(book_agent, payload)

        _ ->
          IO.inspect("check me out")
          # TODO: show limit and market orders and trades
          IO.inspect(payload)
          {:ok, book_agent}
      end

    # Update State
    Agent.update(books_agent, &Map.put(&1, product_id, book_agent))

    changeset = LimitOrder.CoinbaseUpdate.changeset(%LimitOrder.CoinbaseUpdate{}, payload)

    LimitOrder.Repo.insert!(changeset)

    {:ok, %{books_agent: books_agent}}
  end

  def load_orderbook(books_agent, product_id) do
    queues = Agent.get(books_agent, &Map.get(&1, :queues))
    sequences = Agent.get(books_agent, &Map.get(&1, :sequences))

    queues = Map.put(queues, product_id, [])
    sequences = Map.put(sequences, product_id, -1)

    Agent.update(books_agent, &Map.put(&1, :queues, queues))
    Agent.update(books_agent, &Map.put(&1, :sequences, sequences))
  end

  def process_message(data) do
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
