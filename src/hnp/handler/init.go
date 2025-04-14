package handler

import (
	"fmt"
	"hnp/model"
)

func HandleInit(cmd model.InitCmd) {
	fmt.Println("Initializing new project:", cmd.ProjectName)
	fmt.Println("Template:", cmd.Template)
	// TODO: create new project

}
