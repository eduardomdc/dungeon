package server
import steam "../../ext/steamworks"

S : ^Server

Server :: struct {
	connections : map[steam.HSteamNetConnection]Connection,
}

Connection :: struct {}

main :: proc () {
	S = new(Server)
	defer free(S)

	start_steamworks()
	
	for ; true ; {
		steam_callbacks(S)
	}

	steam.Shutdown()
}
