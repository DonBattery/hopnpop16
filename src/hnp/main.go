package main

import (
	"fmt"
	"os"

	"github.com/alexflint/go-arg"

	"hnp/handler"
	"hnp/model"
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
a tiny game server framework for PICO-8 with WebSockets, Lua and magic

`

func main() {
	var args model.CLI = model.CLI{VERSION: VERSION, BUILD: BUILD}

	p, err := arg.NewParser(arg.Config{
		Program: "hnp",
	}, &args)

	if err != nil {
		panic(fmt.Sprintf("failed to set up CLI: %s", err))
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

	if args.Ver || args.Version != nil {
		fmt.Println(args.VersionInfo())
		os.Exit(0)
	}

	switch {
	case args.Init != nil:
		handler.HandleInit(*args.Init)
	case args.Config != nil:
		handler.HandleConfig(*args.Config)
	case args.Proto != nil:
		handler.HandleProto(*args.Proto)
	case args.Server != nil:
		handler.HandleServer(*args.Server)
	default:
		fmt.Printf("%v", banner)
		p.WriteHelp(os.Stdout)
	}
}
