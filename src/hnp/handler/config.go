package handler

import (
	"fmt"
	"hnp/model"
)

func HandleConfig(cmd model.ConfigCmd) {
	fmt.Println("Config command called")

	if cmd.Validate != nil {
		HandleValidateConfig(*cmd.Validate)
	}

	if cmd.Create != nil {
		HandleCreateConfig(*cmd.Create)
	}
}

func HandleValidateConfig(cmd model.ValidateConfigCmd) {
	fmt.Println("Validating configuration files at root: ", cmd.Root)

	// TODO: validate config files
}

func HandleCreateConfig(cmd model.CreateConfigCmd) {
	fmt.Println("Creating default configuration files at root: ", cmd.Root)

	// TODO: create default config files
}
