package handler

import (
	"fmt"

	"hnp/log"
	"hnp/model"
)

func HandleServer(cmd model.ServerCmd) {
	if cmd.Run != nil {
		HandleRunServer(*cmd.Run)
	} else if cmd.Admin != nil {
		HandleAdmin(*cmd.Admin)
	}
}

func HandleRunServer(cmd model.RunServerCmd) {
	// TODO: load config, init protocol, launch HTTP + WS
	log.Init(cmd.LogLevel)
	logger := log.Sugar()

	logger.Infow("starting server",
		"port", cmd.Port,
		"max_rooms", cmd.MaxRooms,
		"max_conn_per_room", cmd.MaxConnPerRoom,
		"server_config_file", cmd.ServerConfigFile,
	)
}

func HandleAdmin(cmd model.AdminCmd) {
	fmt.Println("Calling admin action:", cmd.Action)
	fmt.Println("Server URL:", cmd.HostURL)
	fmt.Println("Server Port:", cmd.Port)
	fmt.Println("Admin header:", cmd.AdminHeader)
	fmt.Println("Admin secret:", cmd.AdminSecret)
	// TODO: HTTP client to call server's admin API
}
