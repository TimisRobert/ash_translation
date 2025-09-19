defmodule AshTranslation.Test.Cldr do
  use Cldr,
    providers: [AshTranslation],
    locales: ["it", "en", "de"]
end
