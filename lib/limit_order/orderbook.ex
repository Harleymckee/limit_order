defmodule LimitOrder.Orderbook do
  def start_link(_opts) do
    bids = :orddict.new()
    asks = :orddict.new()

    Agent.start_link(fn ->
      %{
        bids: bids,
        asks: asks,
        orders_by_id: %{}
      }
    end)
  end

  def get_tree(agent, "buy") do
    Agent.get(agent, &Map.get(&1, :bids))
  end

  def get_tree(agent, "sell") do
    Agent.get(agent, &Map.get(&1, :asks))
  end

  def get_tree(agent, :orders_by_id) do
    Agent.get(agent, &Map.get(&1, :orders_by_id))
  end

  def update_tree(agent, "buy", update) do
    Agent.update(agent, &Map.put(&1, :bids, update))
  end

  def update_tree(agent, "sell", update) do
    Agent.update(agent, &Map.put(&1, :asks, update))
  end

  def update_tree(agent, :orders_by_id, update) do
    Agent.update(agent, &Map.put(&1, :orders_by_id, update))
  end

  def state(agent, book) do
    Enum.each(book["bids"], fn order ->
      add(agent, %{
        "id" => Enum.at(order, 2),
        "side" => "buy",
        "price" => Enum.at(order, 0),
        "size" => Enum.at(order, 1)
      })
    end)

    Enum.each(book["asks"], fn order ->
      add(agent, %{
        "id" => Enum.at(order, 2),
        "side" => "sell",
        "price" => Enum.at(order, 0),
        "size" => Enum.at(order, 1)
      })
    end)

    # note there is a !book case in node code which seems to init rb tree
    {:ok, agent}
  end

  def update_orders_by_id(agent, order) do
    orders_by_id =
      agent
      |> get_tree(:orders_by_id)

    orders_by_id = Map.put(orders_by_id, order.id, order)

    agent
    |> update_tree(:orders_by_id, orders_by_id)
  end

  def process_message(agent, key) do
    tree = get_tree(agent, key)
  end

  def add(agent, order) do
    IO.puts("add")

    order = %{
      id: order["order_id"] || order["id"],
      side: order["side"],
      price: Decimal.new(order["price"]) |> Decimal.to_float(),
      size: order["size"] || order["remaining_size"]
      # sequence: order["s11equence"]
    }

    IO.inspect(order)

    dict = get_tree(agent, order.side)

    if :orddict.is_key(order.price, dict) do
      node = :orddict.fetch(order.price, dict)
      dict = :orddict.store(order.price, node ++ [order], dict)

      # agent =
      agent
      |> update_tree(order.side, dict)

      # agent =
      agent
      |> update_orders_by_id(order)

      {:ok, agent}
    else
      dict = :orddict.store(order.price, [order], dict)

      agent
      |> update_tree(order.side, dict)

      agent
      |> update_orders_by_id(order)

      {:ok, agent}
    end
  end

  def remove(agent, order_id) do
    # IO.inspect("cool")
    IO.inspect("remove")

    orders_by_id =
      agent
      |> get_tree(:orders_by_id)

    IO.puts("ok")

    # IO.inspect(orders_by_id)
    # IO.inspect(order_id)
    # ## TODO verify this work once sync is finished

    order = Map.get(orders_by_id, order_id)

    dict = get_tree(agent, order.side)

    IO.puts("ok")

    node = :orddict.fetch(order.price, dict)

    IO.puts("ok")

    IO.inspect(node)

    orders = node

    IO.inspect(orders)
    IO.inspect(order)

    orders = List.delete(orders, order)

    IO.puts("ok")
    IO.inspect(orders)

    # dict = :orddict.store(order.price, node ++ [order], dict)

    dict =
      if Enum.count(orders) == 0 do
        :orddict.take(order.price, dict)
      else
        :orddict.store(order.price, orders, dict)
      end

    IO.puts("cool")

    orders_by_id = Map.delete(orders_by_id, order.id)

    agent
    |> update_tree(order.side, dict)

    Agent.put(agent, :orders_by_id, orders_by_id)

    IO.inspect("remove success?")

    # # {:ok, agent}
    {:ok, agent}
  end

  def match(agent, _change) do
    IO.inspect("match")
    {:ok, agent}
  end

  # # price of null indicates market order
  # def change(%{price: nil} = change) do
  # end

  def change(agent, _change) do
    IO.inspect("change")
    {:ok, agent}

    # size = Decimal.new(change.new_size)
    # price = Decimal.new(change.price)
    # order = Decimal.new(change.order_id)
  end
end
