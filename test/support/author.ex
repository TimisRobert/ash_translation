defmodule AshTranslation.Test.Author do
  @moduledoc false

  use Ash.Resource,
    domain: AshTranslation.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshTranslation.Resource]

  attributes do
    uuid_v7_primary_key :id
    attribute :name, :string, public?: true
  end

  actions do
    defaults [:read, :destroy, update: :*, create: :*]
  end

  relationships do
    has_many :posts, AshTranslation.Test.Post
  end

  translations do
    public? true
    fields [:name]
    locales AshTranslation.Test.Cldr.AshTranslation.locale_names()
  end
end
