defmodule LimitOrder.OrderBook.Test do
  alias LimitOrder.Orderbook
  use LimitOrder.DataCase, async: true
  doctest Orderbook

  test "add" do
    {:ok, agent} = Orderbook.start_link([])

    struct = %{
      "bids" => [
        %{
          "id" => "id-2",
          "side" => "buy",
          "price" => 201,
          "size" => 10
        },
        %{
          "id" => "id",
          "side" => "buy",
          "price" => 200,
          "size" => 10
        }
      ],
      "asks" => []
    }

    {:ok, agent} = Orderbook.add(agent, Enum.at(struct["bids"], 0))
    {:ok, agent} = Orderbook.add(agent, Enum.at(struct["bids"], 1))
    # TODO: figure out naming
    {:ok, state, book} = Orderbook.state(agent)

    # TODO: deal with keys matching
    struct = %{
      bids: [
        %{
          id: "id-2",
          side: "buy",
          price: 201,
          size: 10
        },
        %{
          id: "id",
          side: "buy",
          price: 200,
          size: 10
        }
      ],
      asks: []
    }

    assert book == struct
  end

  test "remove" do
    {:ok, agent} = Orderbook.start_link([])

    api_state = %{
      "bids" => [
        [201, 10, "id-2"],
        [201, 10, "id-3"],
        [200, 10, "id"]
      ],
      "asks" => []
    }

    Orderbook.state(agent, api_state)
    Orderbook.remove(agent, "id-3")

    {:ok, agent, book} = Orderbook.state(agent)

    assert book == %{
             bids: [
               %{
                 id: "id-2",
                 side: "buy",
                 price: 201,
                 size: 10
               },
               %{
                 id: "id",
                 side: "buy",
                 price: 200,
                 size: 10
               }
             ],
             asks: []
           }
  end

  test "get" do
  end

  describe "match" do
    test "partial match" do
    end

    test "full match" do
    end
  end

  describe "change" do
    test "normal" do
    end

    test "market order" do
    end
  end
end
