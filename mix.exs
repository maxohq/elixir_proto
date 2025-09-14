defmodule ElixirProto.MixProject do
  use Mix.Project

  @version "0.1.6"
  @source_url "https://github.com/maxohq/elixir_proto"

  def project do
    [
      app: :elixir_proto,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Co-located tests
      test_paths: ["test", "lib"],
      test_pattern: "*_test.exs",

      # Hex
      package: package(),
      description: description(),

      # Docs
      name: "ElixirProto",
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:maxo_test_iex, "~> 0.1", only: [:test]},
      {:benchee, "~> 1.0", only: :dev}
    ]
  end

  defp description do
    """
    A compact serialization library for Elixir that uses schema indices and fixed tuples
    for space-efficient binary serialization with schema evolution support. Inspired by Protobuf.
    """
  end

  defp package do
    [
      name: "elixir_proto",
      files: ~w(lib test README.md CHANGELOG.md LICENSE mix.exs),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Benchmarks" => "#{@source_url}/blob/main/BENCHMARK_RESULTS.md"
      },
      maintainers: ["Roman Heinrich"]
    ]
  end

  defp docs do
    [
      main: "readme",
      name: "ElixirProto",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/elixir_proto",
      source_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md",
        "BENCHMARK_RESULTS.md",
        "benchmark_output_latest.txt",
        "PITCH.md"
      ]
    ]
  end
end
