package model

import "fmt"

type CLI struct {
	VERSION string

	BUILD string

	Ver bool `arg:"--version,-v" help:"print version and exit"`

	Version *VersionCmd `arg:"subcommand:version|ver" help:"print version and exit"`

	Config *ConfigCmd `arg:"subcommand:config" help:"manage configuration"`

	Init *InitCmd `arg:"subcommand:init" help:"initialize a new game project"`

	Proto *ProtoCmd `arg:"subcommand:proto" help:"protocol toolchain"`

	Server *ServerCmd `arg:"subcommand:server" help:"manage the game server"`
}

func (c CLI) Description() string {
	return fmt.Sprintf("HOP 'N POP 16 ver: %s build: %s\n", c.VERSION, c.BUILD)
}

func (CLI) Epilogue() string {
	return "for details visit: https://github.com/DonBattery/hopnpop16"
}

func (c CLI) VersionInfo() string {
	return fmt.Sprintf("HOP 'N POP 16 ver: %s build: %s", c.VERSION, c.BUILD)
}

type VersionCmd struct{}

type CommonConfig struct {
	Root       string `arg:"--root,-r" env:"HOPNPOP16_ROOT" help:"root folder of HOP 'N POP 16 configurations, templates and logs" default:"."`
	DebugMode  bool   `arg:"--debug,-d" env:"HOPNPOP16_DEBUG_MODE" help:"enable debug mode"`
	ConfigFile string `arg:"-c,--config-file" env:"HOPNPOP16_CONFIG_FILE" help:"path to the configuration file" default:"hopnpop16_config.yml"`
}

type ConfigCmd struct {
	Create   *CreateConfigCmd   `arg:"subcommand:create" help:"create the default configuration files under the HOPNPOP16_ROOT folder"`
	Validate *ValidateConfigCmd `arg:"subcommand:validate" help:"validate configuration files"`

	CommonConfig
}

type CreateConfigCmd struct {
	CommonConfig
}

type ValidateConfigCmd struct {
	CommonConfig
}

type InitCmd struct {
	ProjectName string `arg:"required,positional" help:"name of the new project (a subfolder will be created under the current working directory)"`
	Template    string `arg:"--template,-t" env:"HOPNPOP16_TEMPLATE" help:"name of the template to use for the new project"`
	Default     bool   `arg:"--default" help:"use the default HOP 'N POP 16 template" default:"false"`

	CommonConfig
}

type ProtoCmd struct {
	Validate *ValidateProtoCmd `arg:"subcommand:validate" help:"validate a protocol YAML file"`
	Gen      *GenProtoCmd      `arg:"subcommand:gen" help:"generate JS and P8 files based on a protocol YAML file"`

	CommonConfig
}

type ValidateProtoCmd struct {
	ProtoFile string `arg:"positional" help:"path of the protocol YAML file to validate" default:"protocol.yml"`

	CommonConfig
}

type GenProtoCmd struct {
	ProtoFile      string `arg:"positional" help:"path of the protocol YAML file to generate JS and P8 files" default:"protocol.yml"`
	OutFolder      string `arg:"--out-folder,-o"  help:"path of the output folder" default:"."`
	WithDebugger   bool   `arg:"--with-debugger" help:"include GPIO debugger" default:"false"`
	Embed          bool   `arg:"--embed" help:"embed JS and CSS into the HTML file as tags" default:"false"`
	Import         bool   `arg:"--import" help:"import JS and CSS into the HTML file" default:"false"`
	Remove         bool   `arg:"--remove" help:"remove JS and CSS from the HTML file" default:"false"`
	RemoveDebugger bool   `arg:"--remove-debugger" help:"remove GPIO debugger from the HTML file" default:"false"`

	CommonConfig
}

type CommonServerConfig struct {
	HostURL     string `arg:"--host-url, -u" env:"HOPNPOP16_HOST_URL" default:"http://localhost" help:"URL of the game server"`
	Port        int    `arg:"--port" env:"HOPNPOP16_PORT" default:"57000" help:"the port where the game server listens on"`
	AdminHeader string `arg:"--admin-header" env:"HOPNPOP16_ADMIN_HEADER" default:"HOPNPOP16_ADMIN" help:"HTTP header to use for admin authentication"`
	AdminSecret string `arg:"--admin-secret" env:"HOPNPOP16_ADMIN_SECRET" default:"bloodisthickerthanwater" help:"HTTP secret to use for admin authentication"`
}

type ServerCmd struct {
	Run   *RunServerCmd `arg:"subcommand:run" help:"start the game server"`
	Admin *AdminCmd     `arg:"subcommand:admin" help:"perform admin actions against the game server"`
}

type RunServerCmd struct {
	ServerConfigFile string `arg:"--server-config-file" env:"HOPNPOP16_SERVER_CONFIG_FILE" default:"server_config.yml" help:"path to the server config YAML file"`
	MaxRooms         int    `arg:"--max-rooms" env:"HOPNPOP16_MAX_ROOMS" default:"8" help:"maximum number of rooms"`
	MaxConnPerRoom   int    `arg:"--max-conn-per-room" env:"HOPNPOP16_MAX_CONN_PER_ROOM" default:"16" help:"maximum number of connections per room"`
	LogLevel         string `arg:"--log-level" env:"HOPNPOP16_LOG_LEVEL" default:"info" help:"level of logging (debug, info, warn, error)"`
	LogFolder        string `arg:"--log-folder" env:"HOPNPOP16_LOG_FOLDER" help:"path to the logging folder (if not specified logs will be written to STDOUT)"`

	CommonConfig
	CommonServerConfig
}

type AdminCmd struct {
	Action string `arg:"positional" help:"The action to perform on the game server (e.g. list-rooms, shutdown)"`

	CommonConfig
	CommonServerConfig
}
