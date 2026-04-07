defmodule HabitWaveWebWeb.HabitLive.Index do
  use HabitWaveWebWeb, :live_view

  alias HabitWaveWeb.Habits
  alias HabitWaveWeb.Habits.Habit

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        習慣一覧
        <:actions>
          <.link patch={~p"/habits/new"}>
            <.button variant="primary">新規作成</.button>
          </.link>
        </:actions>
      </.header>
      <ul>
        <%= for habit <- @habits do %>
          <li>
            {habit.title}
            <.link patch={~p"/habits/#{habit.id}/edit"}>編集</.link>
            <.link phx-click="delete" phx-value-id={habit.id} data-confirm="削除しますか?">
              削除
            </.link>
          </li>
        <% end %>
      </ul>

      <%= if @live_action in [:new, :edit]do %>
        <.modal
          id="habit-modal"
          show
          on_cancel={JS.patch(~p"/habits")}
        >
          <.live_component
            module={HabitWaveWebWeb.HabitLive.FormComponent}
            id={@habit.id || :new}
            action={@live_action}
            habit={@habit}
            current_scope={@current_scope}
          />
        </.modal>
      <% end %>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    {:ok, assign(socket, habits: Habits.list_habits(user_id))}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    user_id = socket.assigns.current_scope.user.id
    {:noreply, assign(socket, habit: Habits.get_habit!(String.to_integer(id), user_id))}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, habit: %{start_date: Date.utc_today()})}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    user_id = socket.assigns.current_scope.user.id
    habit = Habits.get_habit!(String.to_integer(id), user_id)
    {:ok, _} = Habits.delete_habit(habit)

    {:noreply, assign(socket, habits: Habits.list_habits(user_id))}
  end

  def handle_info(HabitWaveWebWeb.HabitLive.FormComponent, {:saved, _habit}, socket) do
    user_id = socket.assigns.current_scope.user.id

    {:noreply,
     socket |> assign(habits: Habits.list_habits(user_id)) |> push_patch(to: ~p"/habits")}
  end
end
