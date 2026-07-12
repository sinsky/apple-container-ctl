# 🍎 Apple Container & Socktainer Management Scripts

A collection of setup and management scripts designed for seamless Docker and Container CLI workflows on macOS (Apple Silicon / Apple Container environment).

These scripts automatically manage required tools (`pitchfork`, `gum`) via `mise`, run the long-running resident proxy process (`socktainer`) as a managed daemon using `pitchfork`, and provide beautiful interactive terminal UIs (TUIs) powered by `gum`.

---

## 🔍 1. Overview & Core Commands

### ① `container` Command (`/usr/local/bin/container`)
Apple's native macOS Container CLI platform.
- **Behavior**: Subcommands trigger system API server or lightweight VM state changes and **return immediately** upon completion.
- **Key System Commands**:
  - `container system start` : Starts Apple Container system services and background daemons.
  - `container system stop` : Gracefully shuts down all Apple Container services and running containers.
  - `container system status` : Displays the operational status of system services.

### ② `socktainer` Command (`/opt/socktainer/bin/socktainer`)
A bridge proxy tool that connects standard Docker CLI commands to Apple Container by forwarding requests over a UNIX/HTTP socket (`~/.socktainer/container.sock`) and providing a local DNS server (port 2054).
- **Behavior**: Runs as a **long-running foreground daemon process**. Docker commands directed to the `socktainer` Docker context only function while this process remains running.
- **Solution**: We use **`pitchfork`** (installed automatically via `mise`) to manage `socktainer` in the background, handle readiness checks, tail logs, and ensure reliable lifecycle management.

---

## 📁 2. Project Structure

```
my-custom-scripts/
├── mise.toml         # Tool version management (pitchfork, gum)
├── pitchfork.toml    # Daemon configuration for resident socktainer process
├── check.sh          # Preflight check script to verify tool installations via which
├── manage.sh         # Interactive TUI dashboard powered by gum
├── start.sh          # Pre-task startup script (one-shot initialization)
└── stop.sh           # Post-task shutdown script (clean teardown)
```

---

## 🚀 3. Usage Guide

### (0) Preflight Verification (`check.sh`)
Verify that `container`, `socktainer`, and `docker` are installed and available in `$PATH`.

```bash
./check.sh
```

---

### (A) Interactive TUI Manager (`manage.sh`)
An interactive menu interface for starting, stopping, checking status, and viewing logs. Both `manage.sh` and `start.sh` automatically perform preflight `which` checks before running.

```bash
./manage.sh
```

**Available Features**:
- 🚀 **Start All**: Starts `container system start`, launches `socktainer` daemon via `pitchfork`, and sets `docker context use socktainer`.
- 🛑 **Stop All**: Stops the `socktainer` daemon via `pitchfork` and shuts down Apple Container services via `container system stop`.
- 🔄 **Restart All**: Full restart cycle for all services.
- 📊 **Show Detailed Status & Docker Info**: Shows Apple Container API status, `pitchfork` daemon status, and `docker version`.
- 📋 **View Socktainer Logs**: Displays recent log output from the `socktainer` daemon.
- 🍏 / 🔌 **Individual Start/Stop**: Fine-grained submenus to control Apple Container or Socktainer independently.

---

### (B) Pre-Execution Startup Script (`start.sh`)
Run this script once before working with Docker containers.

```bash
./start.sh
```
- Checks if the Apple Container API server is running (`container system status --format json`), starting it if necessary.
- Starts `socktainer` via `pitchfork start socktainer` and waits until the socket and DNS proxy are fully ready (`Server started on`).
- Automatically sets the active Docker context to `socktainer`.

---

### (C) Post-Execution Shutdown Script (`stop.sh`)
Run this script after finishing Docker tasks to cleanly shut down services and release system resources.

```bash
./stop.sh
```
- Gracefully stops the `socktainer` daemon via `pitchfork stop socktainer`.
- Stops Apple Container VM and API server services via `container system stop`.

---

## ⚙️ 4. `pitchfork.toml` Configuration Details

`socktainer` is configured in `pitchfork.toml` as follows:

```toml
[daemons.socktainer]
run = "/opt/socktainer/bin/socktainer"
ready_output = "Server started on"
```

By matching `ready_output = "Server started on"`, `pitchfork start socktainer` guarantees that `socktainer` is fully initialized and listening before returning control to the script, preventing timing issues when executing subsequent Docker commands.
