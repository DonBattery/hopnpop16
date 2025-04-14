package log

import (
	"go.uber.org/zap"
)

var logger *zap.Logger

// Init sets up the global logger. Pass "dev" or "prod".
func Init(mode string) {
	var err error
	switch mode {
	case "dev":
		logger, err = zap.NewDevelopment()
	case "prod":
		logger, err = zap.NewProduction()
	default:
		logger, err = zap.NewDevelopment()
	}

	if err != nil {
		panic("failed to initialize logger: " + err.Error())
	}
}

// Logger returns the base zap.Logger instance
func Logger() *zap.Logger {
	if logger == nil {
		Init("dev") // fallback
	}
	return logger
}

// Sugar returns the sugared logger for convenience
func Sugar() *zap.SugaredLogger {
	return Logger().Sugar()
}
