defmodule AshTranslation.Test.Tag do
  @moduledoc false

  use Ash.Resource,
    domain: AshTranslation.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshTranslation.Resource]

  attributes do
    uuid_v7_primary_key :id
    attribute :name, :string, public?: true
  end

  relationships do
    belongs_to :post, AshTranslation.Test.Post
  end

  actions do
    defaults [:read, :destroy, update: :*, create: :*]
  end

  translations do
    public? true
    fields [:name]
    locales AshTranslation.Test.Cldr.AshTranslation.locale_names()
  end
end
