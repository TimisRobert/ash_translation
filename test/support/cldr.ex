defmodule AshTranslation.Test.Cldr do
  use Cldr,
    providers: [AshTranslation],
    locales: ["it", "en", "de", "de-AT"]
end
