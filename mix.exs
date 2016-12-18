defmodule Crawlie.Mixfile do
  use Mix.Project

  @version "0.1.1"

  def project do
    [
      app: :crawlie,
      version: @version,
      elixir: "~> 1.3",

      package: package(),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),

      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls": :test,
        "coveralls.html": :test,
        "test": :test,
      ],
      docs: docs,
   ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :httpoison]]
  end

  defp docs do
    [
      main: "readme",
      source_url: "https://github.com/nietaki/crawlie",
      extras: ["README.md"],
      assets: ["assets"],
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:gen_stage, "~> 0.10.0"},
      {:httpoison, "~> 0.10.0"},
      {:heap, "~> 1.0.1"},
      # testing and documentation
      {:ex_doc, "~> 0.14.3", only: :dev},
      {:inch_ex, "~> 0.5.5", only: :dev},
      {:excoveralls, "~> 0.4", only: :test},
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Jacek Królikowski <nietaki@gmail.com>"],
      links: %{"GitHub" => "https://github.com/nietaki/crawlie"},
      description: description,
    ]
  end

  defp description do
    """
    A simple but competent Elixir web crawler library (to be) powered by GenStage.

    Don't use the package quite yet please, it's very much a work in progress.
    `0.2.0` should be the first relatively useful release.
    """
  end
end
