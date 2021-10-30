defmodule Crawlie.Mixfile do
  use Mix.Project

  # VERSION BUMPING CHECKLIST
  # - update CHANGELOG.md, with GitHub Issues along other things
  # - update the version here
  # - update "Installation" section in the README with the new version
  # - check if README is outdated
  # - make sure there's no obviously missing docs
  # - build and publish the hex package
  #   - mix hex.build
  #   - mix hex.publish

  @source_url "https://github.com/nietaki/crawlie"
  @version "1.0.0"


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
      docs: docs()
   ]
  end

  def application do
    [
      applications: [:logger, :httpoison, :pqueue],
      mod: {Crawlie.Application, []}
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      assets: ["assets"],
      formatters: ["html"]
    ]
  end

  defp deps do
    [
      {:gen_stage, "~> 0.12.0"},
      {:flow, "~> 0.12.0"},
      {:httpoison, "~> 0.10.0"},
      {:pqueue, "~> 1.5"},
      {:meck, "~> 0.8", only: :test},
      # testing and documentation
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.4", only: :test}
    ]
  end

  defp package do
    [
      description: "A simple Elixir web crawler library powered by GenStage.",
      licenses: ["MIT"],
      maintainers: ["Jacek Królikowski <nietaki@gmail.com>"],
      links: %{
        "Changelog" => "https://hexdocs.com/crawlie",
        "Usage example" => "https://github.com/nietaki/crawlie_example",
        "GitHub" => @source_url
      },
    ]
  end
end
