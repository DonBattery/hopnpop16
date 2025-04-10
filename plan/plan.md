# 🎩 Multiplayer Pico-8 Game Server Architecture

## 🎮 Game Description

An **online multiplayer platformer** where players control characters in a **256×256 pixel world**, jumping on each other's heads in a style reminiscent of *Jump 'n Bump* and *Mario*. The client is built in **Pico-8** and runs in the browser. The server is written in **Golang**, and supports **up to 16 players per room** in real-time.

---

## 🏗️ Architectural Design

### 🔹 Pico-8 Client (Browser)

- Exported via Pico-8 as HTML/JS and hosted on GitHub Pages.
- Connects to the game server via **WebSocket** (through GPIO pins).
- Sends **1–2 bytes** per frame representing the controller input.
- Receives **up to 126 bytes** per frame from the server.
- No local simulation — all state comes from the server.

### 🌐 Web Player (Hosting)

- Hosted on **GitHub Pages** under a custom GoDaddy domain.
- Displays a teaser banner and connects players to the game.
- Supports both:
  - **Manual server selection** (in early stage)
  - **Automatic matchmaking** (planned, via a routing service)
- Thin JS layer negotiates protocol with the server and relays GPIO data.

### 🧠 Game Server (Golang)

- Written in Go using:
  - [`gin-gonic/gin`](https://github.com/gin-gonic/gin) – HTTP + routing
  - [`go.uber.org/zap`](https://github.com/uber-go/zap) – structured logging
  - [`gorilla/websocket`](https://github.com/gorilla/websocket) – WebSocket communication
  - [`alexflint/go-arg`](https://github.com/alexflint/go-arg) – command-line parsing
- Maintains rooms, player connections, and full game simulation.
- Handles 60 FPS game loop and input processing.
- Outputs structured logs for Docker, terminal, or CloudWatch.
- Can be deployed:
  - Locally
  - As a standalone EC2 service
  - Or via **Nomad** for clustered deployment

### 🛠️ Admin Interface

- Optional embedded UI served via `/admin`
- Built using JS and HTML Canvas
- Allows spectating rooms live in browser (uses same sprite sheet as the game!)
- Can be disabled via config
- Future: centralized dashboard for multi-server deployments

---

## ⚙️ Game Server Design

### 📁 Folder Structure (as of first commit)

```plaintext
/docs/                     ← GitHub Pages + teaser landing page
/src/client/               ← Pico-8 project (.p8 files)
/src/server/               ← Go server application
  ├— api/                 ← Gin-based HTTP + WS router
  ├— config/              ← Config loading from CLI, env, or file
  ├— hub/                 ← Hub that manages active rooms
  ├— log/                 ← Zap logging wrapper
  ├— model/               ← Core game structs (player, room, world, etc.)
  ├— static/              ← Admin interface assets (HTML/JS/CSS)
  └— main.go              ← CLI entrypoint (uses go-arg)
```

### 📆 Game Server Modules

| Package     | Role |
|-------------|------|
| `main.go`   | CLI tool with subcommands (`proto`, `server`, `admin`) |
| `api`       | Starts Gin server, handles WebSocket and HTTP routes |
| `config`    | Loads config from defaults, file, env, CLI (via go-arg) |
| `hub`       | Manages and allocates rooms |
| `log`       | Thin wrapper around `zap.Logger` with dev/prod modes |
| `model`     | All domain structs: Player, Room, World, Event, etc. |
| `static`    | Admin interface (Canvas-based room viewer) |

---

## 🔌 Protocol System: **Binmark** (binary protocol markup)

The game protocol is defined in a versioned YAML format called **Binmark**. It supports a full lifecycle of parsing, validation, code generation, and runtime use.

### Features

- ✏️ **Single source of truth** for protocol layout
- 🌐 Used by both **Go server** and **JS/Pico-8 clients**
- ⚛️ YAML defines:
  - `version`
  - `input` layout (1–2 bytes from client)
  - `output` layout (126 bytes from server)
  - `sections` and `bitfields`
- ⚖️ Validated for alignment, overflow, and repeat structures

### Extensible Toolchain

The Go server is also a **protocol toolchain**:

| Mode         | Output |
|--------------|--------|
| `server`     | Initializes runtime middleware from YAML |
| `proto gen`  | Generates `.p8` file for Pico-8 projects |
|              | Generates `.js` + `.css` files for web frontend |
|              | Patches or inlines JS/CSS into `index.html` |

### Future-Proof Design

- Multiple protocol versions can coexist
- Pluggable renderers for future languages or formats
- Site ↔ Pico initial protocol distinct from game runtime protocol
- Enables debug panels, version negotiation, and hot-swapping

---

## ⚙️ CLI Design

### 📆 Subcommands

| Command       | Description |
|---------------|-------------|
| `proto`       | Protocol tooling CLI (with `validate`, `gen`) |
| `server`      | Runs the actual game server (WS + HTTP) |
| `admin`       | CLI client to interact with running server (e.g. shutdown) |

### 🔧 Config Precedence

1. **Command-line flags** (highest priority)
2. **Environment variables** (prefixed with `HOPNPOP16_`)
3. **Config file**:
   - `./hopnpop16_config.yml`
   - `~/.hopnpop16/hopnpop16_config.yml`
   - From `--config-file` or `HOPNPOP16_CONFIG_FILE_PATH`
4. **Defaults** (e.g. port `8080`, rooms `8`)

### 🛠️ Logging

- Built using `zap`
- Supports `--log-level` (debug, info, warn, error)
- Dev mode: pretty output
- Prod mode: JSON for Docker / CloudWatch

---

## 🚀 CI/CD

- GitHub Actions workflows:
  - `ci.yml` → Runs on **any branch**
  - `cd.yml` → Runs on **`master` only**
- CI will:
  - Checkout, install Go, build server, run tests
- CD will:
  - Build production binary with `ldflags` (version/hash)
  - Upload as an artifact (release targets TBD)

---

## Next Steps

- Flesh out protocol YAML schema and Go loader
- Implement WebSocket broadcast loop
- Build admin `/spectate/:room_id` view
- Test with 16+ clients in browser
- Auto-generate `protocol.js` from YAML
- Deploy to EC2 or Nomad for alpha tests

---

This plan is just the beginning — welcome to **HOP 'N POP 16**! 🐰
