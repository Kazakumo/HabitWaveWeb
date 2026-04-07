defmodule HabitWaveWebWeb.HabitLive.FormComponent do
  use HabitWaveWebWeb, :live_component
  alias HabitWaveWeb.Habits

  def render(assigns) do
    ~H"""
    <div>
      <.header>{@title}</.header>
      <.form for={@form} id="habit-form" phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input field={@form[:title]} label="タイトル" required />
        <.input field={@form[:interval_days]} type="number" label="間隔（日）" min="1" required />
        <.input field={@form[:start_date]} type="date" label="開始日" required />
        <.input field={@form[:is_active]} type="checkbox" label="有効" />
        <.button variant="primary" phx-disable-with="保存中...">保存</.button>
      </.form>
    </div>
    """
  end

  def update(%{habit: habit} = assigns, socket) do
    changeset = Habits.change_habit(habit)
    {:ok, socket |> assign(assigns) |> assign(:form, to_form(changeset))}
  end

  def handle_event("validate", %{"habit" => params}, socket) do
    form =
      Habits.change_habit(socket.assigns.habit, params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"habit" => params}, socket) do
    case socket.assigns.action do
      :new -> Habits.create_habit(params, socket.assigns.current_scope.user.id)
      :edit -> Habits.update_habit(socket.assigns.habit, params)
    end
    |> case do
      {:ok, habit} ->
        notify_parent({:saved, habit})
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
