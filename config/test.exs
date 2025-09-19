import Config

config :ex_cldr,
  default_locale: "en",
  default_backend: AshTranslation.Test.Cldr,
  json_library: Jason

config :ash_translation, ash_domains: [AshTranslation.Test.Domain]

config :logger, level: :warning
