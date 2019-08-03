defmodule LimitOrderWeb.PageView do
  use Phoenix.LiveView

  @topic "book"

  def render(assigns) do
    ~L"""
    <div class="">
      <table>
        <%= if @asks do %>
          <%= for ask <- @asks do %>
            <tr>
              <td>
                <%= ask.price %>
              </td>
              <td>
                <%= ask.size %>
              </td>
            </tr>
          <% end %>
        <% end %>
        <tr>
          <td>
            spread
          </td>
        </tr>
        <%= if @bids do %>
          <%= for bid <- @bids do %>
            <tr>
              <td>
                <%= bid.price %>
              </td>
              <td>
                <%= bid.size %>
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

    {:ok, assign(socket, bids: nil, asks: nil)}
  end

  def handle_info(payload, socket) do
    {:noreply, assign(socket, bids: payload.bids, asks: payload.asks)}
  end
end
