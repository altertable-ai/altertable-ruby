require "testcontainers"

# In CI the mock is provided as a GitHub Actions service container already
# bound to localhost:15001, so we skip spinning one up ourselves.
unless ENV["CI"]
  container = Testcontainers::DockerContainer
    .new("ghcr.io/altertable-ai/altertable-mock:latest", image_create_options: { "platform" => "linux/amd64" })
    .with_exposed_port(15001)
    .with_env("ALTERTABLE_MOCK_API_KEYS", "test_pk_abc123")
    .with_wait_for(:logs, /Starting Product Analytics HTTP server/, timeout: 30)

  container.start

  mapped_port = container.mapped_port(15001)
  ENV["ALTERTABLE_MOCK_PORT"] = mapped_port.to_s

  at_exit { container.stop }
end
