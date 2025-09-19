defmodule AshTranslation do
  @moduledoc false

  def cldr_backend_provider(config) do
    module = __MODULE__
    backend = config.backend
    info = AshTranslation.Resource.Info

    quote location: :keep, bind_quoted: [module: module, backend: backend, info: info] do
      defmodule AshTranslation do
        def translate(resource) do
          locale = unquote(backend).get_locale().cldr_locale_name
          unquote(module).translate(resource, locale)
        end

        def translate_field(resource, field) do
          locale = unquote(backend).get_locale().cldr_locale_name
          unquote(module).translate_field(resource, field, locale)
        end

        def locale_names() do
          known_locales = unquote(backend).known_locale_names()
          default_locale = unquote(backend).default_locale().cldr_locale_name
          Enum.reject(known_locales, &(&1 == default_locale))
        end
      end
    end
  end

  def add_forms(form, locales, path \\ [])

  def add_forms(%{action: :create} = form, locales, path) do
    do_add_forms(form, locales, path)
  end

  def add_forms(form, locales, path) do
    keys = for key <- path ++ [:translations], do: Access.key(key)

    if get_in(form.original_data, keys) do
      form
    else
      do_add_forms(form, locales, path)
    end
  end

  defp do_add_forms(form, locales, path) do
    form = AshPhoenix.Form.add_form(form, path ++ [:translations])

    Enum.reduce(locales, form, fn locale, form ->
      AshPhoenix.Form.add_form(form, path ++ [:translations, locale])
    end)
  end

  def translate(%{translations: translations} = resource, locale)
      when map_size(translations) > 0 do
    translations = Map.get(resource.translations, locale) || %{}

    resource =
      Ash.Resource.Info.relationships(resource)
      |> Enum.filter(fn
        %Ash.Resource.Relationships.BelongsTo{} -> false
        _ -> true
      end)
      |> Enum.reduce(resource, fn relationship, resource ->
        Map.update!(resource, relationship.name, fn
          field when is_list(field) -> Enum.map(field, &translate(&1, locale))
          field -> translate(field, locale)
        end)
      end)

    AshTranslation.Resource.Info.translations_fields!(resource)
    |> Enum.reduce(resource, fn field, resource ->
      Map.update!(resource, field, fn original ->
        Map.get(translations, field) || original
      end)
    end)
  end

  def translate(resource, _locale) do
    resource
  end

  def translate_field(%{translations: translations} = resource, field, locale)
      when map_size(translations) > 0 do
    translations = Map.get(resource.translations, locale) || %{}
    Map.get(translations, field) || Map.get(resource, field)
  end

  def translate_field(resource, _field, _locale) do
    resource
  end
end
