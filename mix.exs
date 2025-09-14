defmodule ElixirProto.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_proto,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      ## co-located tests
      test_paths: ["test", "lib"],
      test_pattern: "*_test.exs"
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
      {:maxo_test_iex, "~> 0.1", only: [:test]},
      {:benchee, "~> 1.0", only: :dev}
    ]
  end
end
