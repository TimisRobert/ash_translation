defmodule AshTranslation.MixProject do
  use Mix.Project

  @version "0.2.4"

  def project do
    [
      app: :ash_translation,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      aliases: aliases(),
      docs: docs(),
      description: "An Ash extension for managing translations on a resource.",
      source_url: "https://github.com/TimisRobert/ash_translation",
      homepage_url: "https://github.com/TimisRobert/ash_translation"
    ]
  end

  defp elixirc_paths(:test) do
    ["lib", "test/support"]
  end

  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs() do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: [
        {"README.md", title: "Home"},
        "documentation/tutorials/get-started-with-ash-trans.md",
        "documentation/dsls/DSL:-AshTranslation.Resource.md"
      ],
      groups_for_extras: [
        Tutorials: ~r'documentation/tutorials',
        Reference: ~r"documentation/dsls"
      ],
      groups_for_modules: [
        Extension: [
          AshTranslation.Resource
        ],
        Introspection: [
          AshTranslation.Resource.Info
        ]
      ]
    ]
  end

  defp package do
    [
      name: :ash_translation,
      licenses: ["MIT"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*
      CHANGELOG* documentation),
      links: %{
        GitHub: "https://github.com/TimisRobert/ash_translation"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_cldr, "~> 2.42.0", only: [:test], optional: true},
      {:ex_doc, github: "elixir-lang/ex_doc", only: [:dev, :test], runtime: false},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:git_ops, "~> 2.6.1", only: [:dev]},
      {:ash, "~> 3.5"},
      {:ash_phoenix, "~> 2.3"}
    ]
  end

  defp aliases() do
    [
      docs: [
        "spark.cheat_sheets",
        "docs",
        "spark.replace_doc_links",
        "spark.cheat_sheets_in_search"
      ],
      "spark.formatter": "spark.formatter --extensions AshTranslation.Resource",
      "spark.cheat_sheets": "spark.cheat_sheets --extensions AshTranslation.Resource",
      "spark.cheat_sheets_in_search":
        "spark.cheat_sheets_in_search --extensions AshTranslation.Resource"
    ]
  end
end
