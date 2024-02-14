defmodule CEM.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :cem,
      version: @version,
      elixir: "~> 1.15",
      description: description(),
      package: package(),
      docs: docs(),
      source_url: "https://github.com/epfahl/pairing_heap",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [
        :logger,
        :observer,
        :wx,
        :runtime_tools
      ]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:nimble_options, "~> 1.1"},
      {:pairing_heap, "~> 0.2.0"}
    ]
  end

  defp description() do
    "An Elixir framework for using the cross-entropy method for optimization."
  end

  defp package() do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Eric Pfahl"],
      licenses: ["MIT"],
      links: %{
        GitHub: "https://github.com/epfahl/cem"
      }
    ]
  end

  defp docs() do
    [
      main: "CEM",
      extras: ["README.md"]
    ]
  end
end
