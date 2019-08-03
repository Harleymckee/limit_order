defmodule LimitOrderWeb.PageController do
  use LimitOrderWeb, :controller
  alias Phoenix.LiveView

  def index(conn, _) do
    LiveView.Controller.live_render(conn, LimitOrderWeb.PageView, session: %{})
  end
end
