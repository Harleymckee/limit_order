defmodule LimitOrderWeb.PageController do
  use LimitOrderWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
