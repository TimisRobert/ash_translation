defmodule AshTranslation do
  @moduledoc false

  def cldr_backend_provider(config) do
    module = __MODULE__
    backend = config.backend
    info = AshTranslation.Resource.Info

    quote location: :keep, bind_quoted: [module: module, backend: backend, info: info] do
      defmodule AshTranslation do
        def translate(resource) do
          locale = unquote(backend).get_locale()
          chain = fallback_chain(resource, locale)
          unquote(module).translate(resource, locale.cldr_locale_name, fallback_chain: chain)
        end

        def translate_field(resource, field) do
          locale = unquote(backend).get_locale()
          chain = fallback_chain(resource, locale)

          unquote(module).translate_field(
            resource,
            field,
            locale.cldr_locale_name,
            fallback_chain: chain
          )
        end

        defp fallback_chain(resource, locale) do
          case unquote(info).translations_fallback_chain(resource) do
            {:ok, fun} when is_function(fun, 1) ->
              fun.(locale.cldr_locale_name)

            {:ok, {mod, fun, args}} ->
              apply(mod, fun, [locale.cldr_locale_name | args])

            _ ->
              case Cldr.Locale.fallback_locales(locale) do
                {:ok, locales} ->
                  locales
                  |> Enum.map(& &1.cldr_locale_name)
                  |> Enum.reject(&(&1 == :und))

                _ ->
                  [locale.cldr_locale_name]
              end
          end
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
    keys =
      for key <- path ++ [:translations] do
        case key do
          # for list indices
          k when is_integer(k) -> Access.at(k)
          # for map keys
          k -> Access.key(k)
        end
      end

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
      |> Enum.reduce(resource, fn relationship, resource ->
        Map.update!(resource, relationship.name, fn
          %Ash.NotLoaded{} = field -> field
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

  def translate(%{translations: translations} = resource, locale, opts)
      when map_size(translations) > 0 do
    chain = Keyword.get(opts, :fallback_chain, [locale])

    resource =
      Ash.Resource.Info.relationships(resource)
      |> Enum.reduce(resource, fn relationship, resource ->
        Map.update!(resource, relationship.name, fn
          %Ash.NotLoaded{} = field -> field
          field when is_list(field) -> Enum.map(field, &translate(&1, locale, opts))
          field -> translate(field, locale, opts)
        end)
      end)

    AshTranslation.Resource.Info.translations_fields!(resource)
    |> Enum.reduce(resource, fn field, resource ->
      Map.update!(resource, field, fn original ->
        find_in_chain(translations, chain, field) || original
      end)
    end)
  end

  def translate(resource, _locale, _opts) do
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

  def translate_field(%{translations: translations} = resource, field, _locale, opts)
      when map_size(translations) > 0 do
    chain = Keyword.get(opts, :fallback_chain, [])
    find_in_chain(translations, chain, field) || Map.get(resource, field)
  end

  def translate_field(resource, field, _locale, _opts) do
    Map.get(resource, field)
  end

  defp find_in_chain(translations, chain, field) do
    Enum.find_value(chain, fn locale ->
      case Map.get(translations, locale) do
        nil -> nil
        locale_translations -> Map.get(locale_translations, field)
      end
    end)
  end
end
