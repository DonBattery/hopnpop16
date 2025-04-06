package main

import (
	"fmt"
	"os"

	"github.com/alexflint/go-arg"

	"server/log"
)

const VERSION = "v0.0.1"

const BUILD = "dev"

const banner = `
   ▓▓▒▒  ▒▒▓▓
   ▓▓▒▒  ▒▒▓▓
   ▓▓▓▓▓▓▓▓▓▓                         _
 ▓▓▓▓  ▓▓▓▓  ▓▓  _____ _____ _____   | |_____    _____ _____ _____    ___   ___
 ▓▓▓▓▓▓▓▓▓▓▓▓▓▓ |  |  |     |  _  |  |_|   | |  |  _  |     |  _  |  |_  | |  _|
     ▓▓▓▓▓▓     |     |  |  |   __|    | | | |  |   __|  |  |   __|   _| |_| . |
     ▓▓▓▓▓▓     |__|__|_____|__|       |_|___|  |__|  |_____|__|     |_____|___|
     ▓▓  ▓▓

`

type CLI struct {
	Version bool `arg:"--version,-v" help:"Print version and exit"`

	ConfigFile string `arg:"-c,--config-file" help:"Path to configuration file"`

	Proto *ProtoCmd `arg:"subcommand:proto"`

	Server *ServerCmd `arg:"subcommand:server"`

	Admin *AdminCmd `arg:"subcommand:admin"`
}

type CommonConfig struct {
	DebugMode  bool   `arg:"--debug,-d" help:"Enable debug mode"`
	ConfigFile string `arg:"-c,--config-file" help:"Path to configuration file"`
}

type ProtoCmd struct {
	Validate *ValidateProtoCmd `arg:"subcommand:validate" help:"Validate a protocol YAML file"`
	Gen      *GenProtoCmd      `arg:"subcommand:gen" help:"Generate protocol JS from YAML file"`

	CommonConfig
}

type ValidateProtoCmd struct {
	ProtoFile string `arg:"positional" help:"Path to protocol YAML file to validate" default:"protocol.yml"`

	CommonConfig
}

type GenProtoCmd struct {
	ProtoFile string `arg:"positional" help:"Path to protocol YAML file to generate" default:"protocol.yml"`
	OutFile   string `arg:"--out-file,-o"  help:"Path to output JS file" default:"protocol.js"`

	CommonConfig
}

type ServerCmd struct {
	Port           int    `arg:"--port" env:"HOPNPOP16_PORT" default:"8080" help:"Port to listen on"`
	MaxRooms       int    `arg:"--max-rooms" env:"HOPNPOP16_MAX_ROOMS" default:"8" help:"Maximum number of rooms"`
	MaxConnPerRoom int    `arg:"--max-conn-per-room" env:"HOPNPOP16_MAX_CONN_PER_ROOM" default:"16" help:"Maximum connections per room"`
	MapsFile       string `arg:"--maps-file" env:"HOPNPOP16_MAPS_FILE" default:"maps.yml" help:"Path to maps YAML file"`
	LogLevel       string `arg:"--log-level" env:"HOPNPOP16_LOG_LEVEL" default:"info" help:"Logging level (debug, info, warn, error)"`

	CommonConfig
}

type AdminCmd struct {
	ServerURL string `arg:"--server-url, -u" env:"HOPNPOP16_SERVER_URL" default:"http://localhost:8080/admin" help:"Admin endpoint base URL"`
	Action    string `arg:"positional" help:"Action to perform (e.g. list-rooms, shutdown)"`

	CommonConfig
}

func (CLI) Description() string {
	return fmt.Sprintf("HOP 'N POP 16 Game Server Ver: %s Build: %s\n", VERSION, BUILD)
}

func (CLI) Epilogue() string {
	return "for details visit: https://github.com/DonBattery/hopnpop16"
}

func (CLI) VersionInfo() string {
	return fmt.Sprintf("HOP 'N POP 16 Game Server Ver: %s Build: %s", VERSION, BUILD)
}

func main() {
	var args CLI

	p, err := arg.NewParser(arg.Config{
		Program: "hopnpop16",
	}, &args)

	if err != nil {
		panic(fmt.Sprintf("error setting up argument parser: %s", err))
	}

	err = p.Parse(os.Args[1:])
	switch {
	case err == arg.ErrHelp:
		p.WriteHelp(os.Stdout)
		os.Exit(0)
	case err != nil:
		fmt.Println("Error:", err)
		p.WriteUsage(os.Stdout)
		os.Exit(1)
	}

	if args.Version {
		fmt.Println(args.VersionInfo())
		os.Exit(0)
	}

	switch {
	case args.Proto != nil:
		handleProto(args.Proto)
	case args.Server != nil:
		handleServer(args.Server)
	case args.Admin != nil:
		handleAdmin(args.Admin)
	default:
		fmt.Printf("%v", banner)
		p.WriteHelp(os.Stdout)
	}
}

// --- Handlers ---

func handleProto(cmd *ProtoCmd) {
	if cmd.Validate != nil {
		fmt.Println("Validating protocol file:", cmd.Validate)
		// TODO: load + validate protocol YAML
	} else if cmd.Gen != nil {
		fmt.Println("Generating JS from protocol file:", cmd.Gen)
		// TODO: parse YAML + generate JS
	}
}

func handleServer(cmd *ServerCmd) {
	log.Init(cmd.LogLevel)
	logger := log.Sugar()

	logger.Infow("starting server",
		"port", cmd.Port,
		"max_rooms", cmd.MaxRooms,
		"maps", cmd.MapsFile,
	)
	// TODO: load config, init protocol, launch HTTP + WS
}

func handleAdmin(cmd *AdminCmd) {
	fmt.Println("Calling admin action:", cmd.Action)
	fmt.Println("Server URL:", cmd.ServerURL)
	// TODO: HTTP client to call server's admin API
}
