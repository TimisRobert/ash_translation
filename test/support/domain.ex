defmodule AshTranslation.Test.Domain do
  use Ash.Domain

  resources do
    resource AshTranslation.Test.Author
    resource AshTranslation.Test.Post
    resource AshTranslation.Test.Tag
  end
end
