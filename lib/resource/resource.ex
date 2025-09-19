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
      ]
    ]
  }

  use Spark.Dsl.Extension,
    sections: [@translations],
    transformers: [
      AshTranslation.Resource.Transformers.CreateTranslationResource
    ]
end
