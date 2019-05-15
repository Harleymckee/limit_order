defmodule LimitOrder.PublicClient do
  use HTTPoison.Base

  def process_request_url(url) do
    "https://api.pro.coinbase.com" <> url
  end

  def process_response_body(body) do
    body
    |> Jason.decode!()
  end
end
