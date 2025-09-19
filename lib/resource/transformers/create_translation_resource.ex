defmodule AshTranslation.Resource.Transformers.CreateTranslationResource do
  @moduledoc false

  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer

  @impl true
  def transform(dsl) do
    module = Transformer.get_persisted(dsl, :module)
    translations_module_name = Module.concat([module, Translations])
    translations_fields_module_name = Module.concat([module, Translations, Fields])

    define_translations_fields(translations_fields_module_name, dsl)
    define_translations(translations_module_name, translations_fields_module_name, dsl)

    opts = [
      name: :translations,
      type: translations_module_name,
      public?: AshTranslation.Resource.Info.translations_public?(dsl)
    ]

    {:ok, attribute} = Transformer.build_entity(Ash.Resource.Dsl, [:attributes], :attribute, opts)

    dsl = Transformer.add_entity(dsl, [:attributes], attribute)

    {:ok, dsl}
  end

  defp define_translations_fields(module_name, dsl) do
    attributes =
      AshTranslation.Resource.Info.translations_fields!(dsl)
      |> Enum.map(&Ash.Resource.Info.attribute(dsl, &1))

    Module.create(
      module_name,
      quote location: :keep do
        use Ash.Resource, data_layer: :embedded

        attributes do
          for attr <- unquote(Macro.escape(attributes)) do
            attribute attr.name, attr.type do
              public? true
              constraints attr.constraints
            end
          end
        end
      end,
      Macro.Env.location(__ENV__)
    )
  end

  defp define_translations(module_name, translation_module_name, dsl) do
    locales = AshTranslation.Resource.Info.translations_locales!(dsl)

    Module.create(
      module_name,
      quote location: :keep do
        use Ash.Resource, data_layer: :embedded

        attributes do
          for locale <- unquote(locales) do
            attribute locale, unquote(translation_module_name), public?: true
          end
        end
      end,
      Macro.Env.location(__ENV__)
    )
  end
end
