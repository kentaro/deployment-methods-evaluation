defmodule TargetApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TargetApp.Supervisor]

    children =
      [
        # Children for all targets
        # Starts a worker by calling: TargetApp.Worker.start_link(arg)
        # {TargetApp.Worker, arg},
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: TargetApp.Worker.start_link(arg)
      # {TargetApp.Worker, arg},
    ]
  end

  def children(_target) do
    # Start a node through which local code changes are deployed
    # only when the device is running in the develop environment
    if Application.get_env(:target_app, :env) == :dev do
      System.cmd("epmd", ["-daemon"])
      Node.start(:"hot_upload_test@nerves.local")
      Node.set_cookie(Application.get_env(:mix_tasks_upload_hotswap, :cookie))
    end
    [
      # Children for all targets except host
      # Starts a worker by calling: TargetApp.Worker.start_link(arg)
      # {TargetApp.Worker, arg},
      {Task.Supervisor, name: TargetApp.EchoServer.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> TargetApp.EchoServer.accept(9849) end}, restart: :permanent)
    ]
  end

  def target() do
    Application.get_env(:target_app, :target)
  end
end
