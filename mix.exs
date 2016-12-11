defmodule Crawlie.Mixfile do
  use Mix.Project

  def project do
    [
      app: :crawlie,
      version: "0.1.0",
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
   ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
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
      {:gen_stage, "~> 0.9.0"},
      {:httpoison, "~> 0.10.0"},
      # testing and documentation
      {:ex_doc, "~> 0.14.3", only: :dev},
      {:inch_ex, "~> 0.5.5", only: :dev},
      {:excoveralls, "~> 0.4", only: :test},
    ]
  end

  defp package do
    %{licenses: ["MIT"],
      maintainers: ["Jacek Królikowski"],
      links: %{"GitHub" => "https://github.com/nietaki/crawlie"}}
  end
end
