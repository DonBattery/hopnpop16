package handler

import (
	"fmt"
	"hnp/model"
)

func HandleProto(cmd model.ProtoCmd) {
	if cmd.Validate != nil {
		HandleValidateProto(*cmd.Validate)
	} else if cmd.Gen != nil {
		HandleGenProto(*cmd.Gen)
	}
}

func HandleValidateProto(cmd model.ValidateProtoCmd) {

	fmt.Println("Validating protocol file:", cmd.ProtoFile)
	// TODO: load + validate protocol YAML
}

func HandleGenProto(cmd model.GenProtoCmd) {

	fmt.Println("Generating JS from protocol file:", cmd.ProtoFile)
	// TODO: parse YAML + generate JS
}
