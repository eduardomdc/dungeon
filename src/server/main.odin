package server
import steam "../../ext/steamworks"
import "core:time"
import game "../game"

S : ^Server
SERVER_TICK_RATE :: 20 // Hz
SERVER_TICK_PERIOD : time.Duration : time.Second/SERVER_TICK_RATE // ms

Server :: struct {
	world_state : game.WorldState,
	connections : map[steam.HSteamNetConnection]ClientConnection,
	network_tick : time.Time,
	tick: game.Seq,
	poll_group : steam.HSteamNetPollGroup,
	listen_socket: steam.HSteamListenSocket
}

main :: proc () {
	S = new(Server); defer free(S)

	start_steamworks(S)
	network_init(S)
	game.game_init(&S.world_state)

	for ; true ; {
		steam_callbacks(S)
		network_tick(S)
		free_all(context.temp_allocator)
		time.sleep(SERVER_TICK_PERIOD-time.since(S.network_tick))
	}

	steam.Shutdown()
}
