defmodule AshTranslation.Resource do
  @translations %Spark.Dsl.Section{
    name: :translations,
    schema: [
      public?: [
        type: :boolean,
        default: false,
        doc: """
        Whether the embedded resource should be public or not
        """
      ],
      locales: [
        type: {:list, :atom},
        default: [],
        doc: """
        The locales to add to the translations resource
        """
      ],
      fields: [
        type: {:list, :atom},
        default: [],
        doc: """
        A list of fields to add to the translation fields
        """
      ],
      fallback_chain: [
        type: {:or, [{:mfa_or_fun, 1}, nil]},
        default: nil,
        doc: """
        A function that takes a locale atom and returns a list of locale atoms to try in fallback order.
        When using the CLDR provider, the default fallback chain is computed from CLDR's fallback_locales.
        Override this to customize the fallback behavior, e.g. for cross-script fallbacks.
        """
      ]
    ]
  }

  use Spark.Dsl.Extension,
    sections: [@translations],
    transformers: [
      AshTranslation.Resource.Transformers.CreateTranslationResource
    ]
end
