defmodule ElmWebRtcWeb.VideoChannel do
  use Phoenix.Channel
  alias ElmWebrtcWeb.Presence

  def join("videoroom:" <> _channel, _message, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.user_id, %{
        user_id: socket.assigns.user_id,
        online_at: inspect(System.system_time(:millisecond))
      })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  def handle_in("peer-message", %{"body" => body}, socket) do
    broadcast_from!(socket, "peer-message", %{body: body})
    {:noreply, socket}
  end

  def handle_in("text-message", %{"body" => body}, socket) do
    broadcast_from!(socket, "text-message", %{body: body, sender: socket.assigns.user_id})
    {:noreply, socket}
  end
end
