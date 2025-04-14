# HOP 'N POP 16  

a tiny game server framework for [PICO-8](https://www.lexaloffle.com/pico-8.php) with WebSockets, Lua and magic  

## Why?  

The inspiration for this project came from these:  
- [benwiley4000/pico8-gpio-listener](https://github.com/benwiley4000/pico8-gpio-listener)  
- [zacharypetersen1/picario-server](https://github.com/zacharypetersen1/picario-server)  
- [JRJurman/pico-socket](https://github.com/JRJurman/pico-socket)  

However I wanted to go one step further and not just provide a game server, but a comfortable framework for PICO-8 developers to build their own online game worlds, using the beloved Lua language.  

## How?  

- [Lua](https://www.lua.org/) for both client side (PICO-8) and server side
- [PICO-8](https://www.lexaloffle.com/pico-8.php) initial web-export  
- [JavaScript](https://developer.mozilla.org/en-US/docs/Web/JavaScript) to connect the client to a server using the [GPIO pins](https://pico-8.fandom.com/wiki/GPIO) and [WebSockets](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API)  
  - [fengari-lua/fengari](https://github.com/fengari-lua/fengari) - Lua VM in the browser so we don't have to write JavaScript for server UI  
- [Golang](https://go.dev) to glue everything together in a nice, fast, small, portable runtime  
  - [`alexflint/go-arg`](https://github.com/alexflint/go-arg) – command line interface  
  - [`gin-gonic/gin`](https://github.com/gin-gonic/gin) – HTTP and routing  
  - [`gorilla/websocket`](https://github.com/gorilla/websocket) – WebSocket communication  
  - [`yuin/gopher-lua`](https://github.com/yuin/gopher-lua) - Lua VM for your game worlds  
  - [`go.uber.org/zap`](https://github.com/uber-go/zap) – structured logging  

## Seriously?  

yes