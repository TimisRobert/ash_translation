# Get Started with AshTranslation

## Installation

Add the dependency to your `mix.exs` file and include `:ash_translation` in your `.formatter.exs`:

```elixir
# In mix.exs
{:ash_translation, "~> 0.2.0"}

# In .formatter.exs
import_deps: [..., :ash_translation]
```

If you are using Cldr, add AshTranslation to your providers:

```elixir
use Cldr,
  providers: [AshTranslation],
  locales: ["it", "en"]
```

## Adding to a resource

To add translations to a resource, add the extension to the resource:

```elixir
use Ash.Resource,
  extensions: [..., AshTranslation.Resource]

translations do
  # Set `public?` to true or add `:translations` to the action's accept list for public access
  public? true
  # Add the fields you want to translate
  fields [:name, :description]
  # Add the locales, except the default locale since it will be directly on the resource
  locales [:it]
  # If you are using Cldr
  locales MyApp.Cldr.AshTranslation.locale_names()
end
```

## Example usage

First, we need to create a domain:

```elixir
defmodule MyApp.Domain do
  use Ash.Domain

  resources do
    resource MyApp.Post
  end
end
```

Then let's create a resource for it:

```elixir
defmodule MyApp.Post do
  @moduledoc false

  use Ash.Resource,
    domain: MyApp.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshTranslation.Resource]

  attributes do
    uuid_v7_primary_key :id
    attribute :title, :string, public?: true
    attribute :body, :string, public?: true
  end

  actions do
    defaults [:read, :destroy, update: :*, create: :*]
  end

  translations do
    public? true
    fields [:title, :body]
    locales [:it]
  end
end
```

With the setup complete, let's explore how to manage translations.
The extension will define two embedded resources, Translations and Translations.Fields that will look like this:

```elixir
defmodule MyApp.Post.Translations do
  use Ash.Resource, data_layer: :embedded

  attributes do
    attribute :it, MyApp.Post.Translations.Fields
  end
end

defmodule MyApp.Post.Translations.Fields do
  use Ash.Resource, data_layer: :embedded

  attributes do
    attribute :title, :string, public?: true
    attribute :body, :string, public?: true
  end
end
```

The extension adds these to the original resource as an attribute:

```elixir
defmodule MyApp.Post do
  ...
  attributes do
    ...
    attribute :translations, MyApp.Post.Translations, public?: true
  end
  ...
end
```

By doing so, we can leverage the Ash framework to do the validation, storage and casting of the translation data.

Now we can use our resource like any other and have translations added by passing a map composed of locale keys and as values another map having the fields we want translated.

```elixir
post =
  Ash.Changeset.for_create(MyApp.Post, :create, %{
    title: "Title",
    body: "Body",
    # Like so
    translations: %{
      it: %{
        title: "Titolo",
        body: "Corpo"
      }
    }
  })
  |> Ash.create!()
```

To translate our struct, we can call `translate/2` or to translate just a field and have it returned `translate_field/3`

```elixir
post_it = AshTranslation.translate(post, :it)
%{title: "Titolo", body: "Corpo"} = post_it

"Titolo" = AshTranslation.translate_field(post, :title, :it)
```

# Full example with Phoenix Liveview, Ash and Cldr

First we need to install and configure Cldr, then add to the Cldr module the AshTranslation provider:

```elixir
defmodule MyApp.Cldr do
  use Cldr,
    providers: [AshTranslation],
    locales: ["it", "en"]
end
```

This allows us to leverage Cldr for managing available locales and the current locale, rather than handling it manually.

Let's use the resource we have defined above, and replace in translations the locales with:

```elixir
translations do
  locales MyApp.Cldr.AshTranslation.locale_names()
end
```

Now let's create a form to create/update the Post resource:

```elixir
defmodule MyAppWeb.Post.FormComponent do
  @moduledoc false
  use MyAppWeb, :live_component

  alias AshPhoenix.Form
  alias MyApp.Cldr
  alias MyApp.Post

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mt-12">
      <.simple_form
        for={@form}
        id="post-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          type="select"
          label={gettext("Language")}
          field={@form[:locale]}
          options={locale_options()}
        />
        <.input
          class={hide_input?(@form[:locale]) && "hidden"}
          label={gettext("Title")}
          field={@form[:title]}
        />

        <.inputs_for :let={translations} field={@form[:translations]}>
          <.inputs_for
            :let={field}
            :for={locale <- Cldr.AshTranslation.locale_names()}
            field={translations[locale]}
          >
            <.input
              class={hide_translation_input?(@form[:locale], locale) && "hidden"}
              label={gettext("Title")}
              field={field[:title]}
            />
          </.inputs_for>
        </.inputs_for>
        <.input
          class={hide_input?(@form[:locale]) && "hidden"}
          type="textarea"
          label={gettext("Body")}
          field={@form[:body]}
        />

        <.inputs_for :let={translations} field={@form[:translations]}>
          <.inputs_for
            :let={field}
            :for={locale <- Cldr.AshTranslation.locale_names()}
            field={translations[locale]}
          >
            <.input
              class={hide_translation_input?(@form[:locale], locale) && "hidden"}
              type="textarea"
              label={gettext("Body")}
              field={field[:body]}
            />
          </.inputs_for>
        </.inputs_for>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{post: post} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(assigns.live_action, post)}
  end

  @impl true
  def handle_event("validate", %{"post" => params}, socket) do
    form = Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"post" => params}, socket) do
    save_post(socket, socket.assigns.live_action, params)
  end

  defp save_post(socket, :edit, params) do
    case Form.submit(socket.assigns.form, params: params) do
      {:ok, post} ->
        notify_parent({:saved, post})

        {:noreply,
         socket
         |> put_flash(:info, gettext("Post updated successfully"))
         |> push_patch(to: socket.assigns.patch, replace: true)}

      {:error, form} ->
        {:noreply, assign(socket, :form, form)}
    end
  end

  defp save_post(socket, :new, params) do
    case Form.submit(socket.assigns.form, params: params) do
      {:ok, post} ->
        notify_parent({:saved, post})

        {:noreply,
         socket
         |> put_flash(:info, gettext("Post created successfully"))
         |> push_navigate(to: socket.assigns.patch.(post))}

      {:error, form} ->
        {:noreply, assign(socket, :form, form)}
    end
  end

  defp assign_form(socket, :new, _) do
    form =
      Form.for_create(Post, :create,
        as: "post",
        forms: [auto?: true]
      )
      |> AshTranslation.add_forms(Cldr.AshTranslation.locale_names())

    assign(socket, :form, to_form(form))
  end

  defp assign_form(socket, :edit, post) do
    form =
      Form.for_update(post, :update,
        as: "post",
        forms: [auto?: true]
      )
      |> AshTranslation.add_forms(Cldr.AshTranslation.locale_names())

    assign(socket, :form, to_form(form))
  end

  defp hide_input?(field) do
    field.value && to_string(field.value) != to_string(default_locale())
  end

  defp hide_translation_input?(field, locale) do
    !field.value || to_string(field.value) != to_string(locale)
  end

  defp default_locale do
    Cldr.default_locale().cldr_locale_name
  end

  defp current_locale do
    Cldr.get_locale().cldr_locale_name
  end

  defp locale_options do
    [default_locale() | Cldr.AshTranslation.locale_names()]
    |> Enum.map(&{Cldr.LocaleDisplay.display_name!(&1), &1})
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
```

Here we have used the Phoenix `.inputs_for` component to manage the nested embedded resource translations, then when creating the form we used the helper in AshTranslation `add_forms/1` to add the necessary forms.

We use CSS to hide translation inputs rather than conditional rendering to preserve input data when switching languages.

The form component can now be used to create or update posts, along with the translations.

Now we can make a LiveView to display a post:

```elixir
defmodule MyAppWeb.PostLive.Show do
  use MyAppWeb, :live_view

  alias MyApp.Cldr
  alias MyApp.Post

  @impl true
  def render(assigns) do
    ~H"""
    <h1>
      <%= @post.title %>
    </h1>
    <p>
      <%= @post.body %>
    </p>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    post =
      Ash.get!(Post, id)
      |> Cldr.AshTranslation.translate(post)

    {:ok, socket |> assign(:post, post)}
  end
end
```

Cldr handles passing the current locale to AshTranslation, which can be set using various strategies, such as [Cldr.Plug](https://hexdocs.pm/ex_cldr_plugs/readme.html).
