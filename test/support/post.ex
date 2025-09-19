defmodule AshTranslation.Test.Post do
  @moduledoc false

  use Ash.Resource,
    domain: AshTranslation.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshTranslation.Resource]

  attributes do
    uuid_v7_primary_key :id
    attribute :title, :string, public?: true
    attribute :body, :string, public?: true
  end

  relationships do
    belongs_to :author, AshTranslation.Test.Author
  end

  actions do
    defaults [:read, :destroy, update: :*, create: :*]
  end

  translations do
    public? true
    fields [:title, :body]
    locales AshTranslation.Test.Cldr.AshTranslation.locale_names()
  end
end
