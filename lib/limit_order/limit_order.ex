defmodule LimitOrder.Coinbase do
  alias LimitOrder.{Orderbook, PublicClient}
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

    IO.puts("new product created")

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

    process_message(books_agent, payload)
  end

  def process_message(books_agent, %{"type" => "subscriptions"} = payload) do
    IO.puts("new subscription")
    IO.inspect(payload)
    # TODO: new product here / new agent here

    {:ok, %{books_agent: books_agent}}
  end

  def should_load_orderbook?(books_agent, %{"product_id" => product_id, "sequence" => sequence}) do
    sequences = Agent.get(books_agent, &Map.get(&1, :sequences))

    if sequences[product_id] == -2 or sequences[product_id] == sequence do
      true
    else
      false
    end
  end

  # def process_message(books_agent, payload) when should_load_orderbook?(books_agent, payload) do
  #   load_orderbook(books_agent, product_id)
  # end

  def process_message(books_agent, payload) do
    product_id = payload["product_id"]
    type = payload["type"]
    sequence = payload["sequence"]

    # TODO: make side task
    changeset = LimitOrder.CoinbaseUpdate.changeset(%LimitOrder.CoinbaseUpdate{}, payload)

    LimitOrder.Repo.insert!(changeset)

    book_agent = Agent.get(books_agent, &Map.get(&1, product_id))
    sequences = Agent.get(books_agent, &Map.get(&1, :sequences))
    queues = Agent.get(books_agent, &Map.get(&1, :queues))

    IO.puts("process message")

    IO.inspect(sequences[product_id])
    IO.inspect(payload)

    if sequences[product_id] < 0 do
      IO.puts("queue spot")

      IO.inspect(queues)

      # order book snapshot not loaded yet
      queues = Map.put(queues, product_id, queues[product_id] ++ payload)

      Agent.update(books_agent, &Map.put(&1, :queues, queues))
    end

    # # TODO: can this be in handle frame?
    # if sequences[product_id] == -2 do
    #   IO.puts("LOAD BOOK")
    #   load_orderbook(books_agent, product_id)
    #   # RETURN
    # end

    # if should_load_orderbook?(books_agent, payload) do
    #   IO.puts("LOAD BOOK")
    #   load_orderbook(books_agent, product_id)
    # end

    cond do
      should_load_orderbook?(books_agent, payload) ->
        load_orderbook(books_agent, product_id)

      sequences[product_id] == -1 ->
        {:ok, %{books_agent: books_agent}}

      sequence <= sequences[product_id] ->
        {:ok, %{books_agent: books_agent}}

      true ->
        sequences = Map.put(sequences, product_id, sequence)
        Agent.update(books_agent, &Map.put(&1, :sequences, sequences))

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

        # changeset = LimitOrder.CoinbaseUpdate.changeset(%LimitOrder.CoinbaseUpdate{}, payload)

        # LimitOrder.Repo.insert!(changeset)

        {:ok, %{books_agent: books_agent}}
    end

    # if sequences[product_id] == -1 do
    #   # TODO RETURN void
    # end

    # if sequence <= sequences[product_id] do
    #   # TODO RETURN void
    # end

    # # TODO: can this be in handle frame?
    # if sequences[product_id] == sequence do
    #   load_orderbook(books_agent, product_id)
    #   # RETURN
    # end
  end

  # move to own module? is a http req to get orderbook
  def get_product_orderbook(product_id) do
    case PublicClient.get("/products/#{product_id}/book?level=3") do
      {:ok, %HTTPoison.Response{body: body}} ->
        body
    end
  end

  def load_orderbook(books_agent, product_id) do
    queues = Agent.get(books_agent, &Map.get(&1, :queues))
    sequences = Agent.get(books_agent, &Map.get(&1, :sequences))

    queues = Map.put(queues, product_id, [])
    sequences = Map.put(sequences, product_id, -1)

    Agent.update(books_agent, &Map.put(&1, :queues, queues))
    Agent.update(books_agent, &Map.put(&1, :sequences, sequences))

    IO.puts("cool")

    data = get_product_orderbook(product_id)

    IO.inspect(data)

    product_agent = Agent.get(books_agent, &Map.get(&1, product_id))

    # may be async
    {:ok, product_agent} = Orderbook.state(product_agent, data)
    IO.puts("yas")

    sequences = Map.put(sequences, product_id, data["sequence"])
    Agent.update(books_agent, &Map.put(&1, :sequences, sequences))
    queues = Agent.get(books_agent, &Map.get(&1, :queues))
    IO.puts("ok")

    Enum.each(queues[product_id], fn data ->
      process_message(books_agent, data)
    end)

    IO.puts("ok")

    queues = Map.put(queues, product_id, [])
    Agent.update(books_agent, &Map.put(&1, :queues, queues))

    # Update State
    Agent.update(books_agent, &Map.put(&1, product_id, product_agent))

    IO.puts("made it through load orderbook")
    {:ok, %{books_agent: books_agent}}
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
