defmodule LimitOrder.Orderbook do
  require IEx

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

  def state(agent) do
    bids = get_tree(agent, "buy")
    asks = get_tree(agent, "sell")

    # TODO: need to figure out way I dont have to call reverse here
    bids = Enum.reverse(:orddict.fold(fn _key, value, acc -> acc ++ value end, [], bids))
    asks = :orddict.fold(fn _key, value, acc -> acc ++ value end, [], asks)

    dict = %{asks: asks, bids: bids}

    {:ok, agent, dict}
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
      # price: order["price"],
      size: order["size"] || order["remaining_size"]
    }

    dict = get_tree(agent, order.side)

    IO.puts("is key")

    # IO.inspect(order)

    # IO.inspect(dict)
    # IO.inspect(order)
    # IO.inspect(:orddict.is_key(order.price, dict))

    # IEx.pry()
    # case :orddict.is_key(order.price, dict) do
    #   {:ok, agent} ->

    # end

    {:ok, agent} =
      if :orddict.is_key(order.price, dict) do
        IO.puts("if")

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
        IO.puts("else")
        dict = :orddict.store(order.price, [order], dict)

        agent
        |> update_tree(order.side, dict)

        agent
        |> update_orders_by_id(order)

        {:ok, agent}
      end

    IO.puts("added")

    {:ok, agent}
  end

  def remove(agent, order_id) do
    IO.puts("remove")

    IO.puts("lookup order by id")
    IO.inspect(order_id)
    # get id lookup table from agent
    orders_by_id =
      agent
      # TODO: change its name from get_tree
      |> get_tree(:orders_by_id)

    order =
      Map.get(orders_by_id, order_id)
      |> IO.inspect()

    if order do
      dict = get_tree(agent, order.side)

      IO.puts("fetch price node")
      # IO.inspect(dict)
      IO.inspect(order)
      node = :orddict.fetch(order.price, dict)

      IO.puts("remove 3")

      orders = node

      orders = List.delete(orders, order)
      IO.inspect(node)
      IO.inspect(orders)

      dict =
        if Enum.count(orders) == 0 do
          IO.puts("remove price row")
          {_value, dict} = :orddict.take(order.price, dict)
          dict
        else
          IO.puts("update orders list")
          :orddict.store(order.price, orders, dict)
        end

      orders_by_id = Map.delete(orders_by_id, order.id)

      agent
      |> update_tree(order.side, dict)

      Agent.update(agent, &Map.put(&1, :orders_by_id, orders_by_id))
    end

    {:ok, agent}
  end

  def match(agent, match) do
    size = Decimal.new(match["size"])
    price = Decimal.new(match["price"])
    dict = get_tree(agent, match["side"])

    IO.puts("match grab")

    node = :orddict.fetch(price |> Decimal.to_float(), dict)
    # ASSERT node
    order = Enum.find(node, fn order -> order.id == match["maker_order_id"] end)

    IO.puts("match calc")

    order =
      Map.merge(order, %{
        # formatting 0e^-8 as scientific val not just 0
        size:
          Decimal.sub(Decimal.new(order.size), size) |> Decimal.to_float() |> Float.to_string()
      })

    orders = node

    dict =
      :orddict.update(
        order.price,
        fn value ->
          Enum.map(value, fn old_order ->
            if old_order.id == order.id do
              order
            else
              old_order
            end
          end)
        end,
        dict
      )

    agent
    |> update_tree(order.side, dict)

    agent
    |> update_orders_by_id(order)

    IO.puts("match updated")
    # orders_by_id = Map.put(orders_by_id, order.id, order)
    IO.inspect(order)

    if Decimal.equal?(Decimal.new(order.size), 0) do
      remove(agent, order.id)
    end

    {:ok, agent}
  end

  # # price of null indicates market order
  # def change(%{price: nil} = change) do
  # end

  def change(agent, _change) do
    IEx.pry()
    IO.inspect("change")
    {:ok, agent}

    # size = Decimal.new(change.new_size)
    # price = Decimal.new(change.price)
    # order = Decimal.new(change.order_id)
  end
end
