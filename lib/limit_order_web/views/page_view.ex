defmodule LimitOrderWeb.PageView do
  use Phoenix.LiveView

  @topic "book"

  def render(assigns) do
    ~L"""
    <div class="">
      <table>
        <%= if @orders do %>
          <%= for order <- @orders do %>
            <tr>
              <td>
                <%= order.price %>
              </td>
              <td>
                <%= order.orders |> Jason.encode! %>
              </td>
            </tr>
          <% end %>
        <% end %>
      </table>
    </div>
    """
  end

  def mount(_session, socket) do
    Phoenix.PubSub.subscribe(LimitOrder.PubSub, @topic, link: true)

    {:ok, assign(socket, orders: nil)}
  end

  def handle_info(payload, socket) do
    orders =
      Enum.map(payload, fn {k, v} ->
        %{price: k, orders: v}
      end)

    {:noreply, assign(socket, orders: orders)}
  end
end
