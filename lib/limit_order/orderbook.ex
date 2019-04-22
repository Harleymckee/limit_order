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

  def process_message(agent, key) do
    tree = get_tree(agent, key)
  end

  def update_tree(agent, "buy", update) do
    Agent.update(agent, &Map.put(&1, :bids, update))
  end

  def update_tree(agent, "sell", update) do
    Agent.update(agent, &Map.put(&1, :asks, update))
  end

  def add(agent, order) do
    IO.puts("add")

    order = %{
      id: order["order_id"] || order["id"],
      side: order["side"],
      price: Decimal.new(order["price"]) |> Decimal.to_float(),
      size: order["size"] || order["remaining_size"],
      sequence: order["sequence"]
    }

    dict = get_tree(agent, order.side)

    if :orddict.is_key(order.price, dict) do
      node = :orddict.fetch(order.price, dict)
      dict = :orddict.store(order.price, node ++ [order], dict)

      agent
      |> update_tree(order.side, dict)

      {:ok, agent}
    else
      dict = :orddict.store(order.price, [order], dict)

      agent
      |> update_tree(order.side, dict)

      {:ok, agent}
    end
  end

  def remove(agent, _order_id) do
    # IO.inspect("cool")
    IO.inspect("remove")

    # agent = Agent.get(agent, :order_by_id)

    # # make a get funtion for order
    # order = agent[order_id]

    # tree = get_tree(agent, order.side)

    # node = RedBlackTree.get(tree, order.price)

    # ## assert tree and node

    # orders = node.orders

    # orders = List.delete(orders, order)

    # tree =
    #   if Enum.count(orders) == 0 do
    #     RedBlackTree.remove(tree, node)
    #   else
    #     tree
    #   end

    # {:ok, order_by_id} = Map.delete(agent, order.id, order)

    # Agent.put(agent, order.side, tree)
    # Agent.put(agent, :order_by_id, order_by_id)

    # {:ok, agent}
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
