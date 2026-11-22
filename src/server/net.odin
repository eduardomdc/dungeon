package server
import steam "../../ext/steamworks"
import "core:time"
import game "../game"
import "core:fmt"

ClientConnection :: struct {
	steam_id : steam.CSteamID,
	player_id : game.PlayerID,
}

network_init :: proc (server : ^Server) {
	server.network_tick = time.now()
}

network_tick :: proc (server : ^Server) {
	since_last_tick := time.since(server.network_tick)
	if since_last_tick < SERVER_TICK_PERIOD do return
	server.network_tick = time.now()
	MAX_MSGS :: 256
	messages: [MAX_MSGS]^steam.SteamNetworkingMessage
	msg_count := steam.NetworkingSockets_ReceiveMessagesOnPollGroup(steam.NetworkingSockets_SteamAPI(), server.poll_group, &messages[0], MAX_MSGS)
	for i in 0..<msg_count {
		message := messages[i]
		defer steam.NetworkingMessage_t_Release(message)
		data_ptr := cast([^]u8)message^.pData
        data := data_ptr[:message^.cbSize]
		msg, err := game.deserialize_msg(data, context.temp_allocator)
		if err != nil {fmt.println("Failed to deserialize msg"); continue}
		handle_msg(server, msg, message.conn)
	} // need to do it again if count == MAX_MSGS
	
	broadcast_msg(server, game.MsgGameState{server.world_state.game_state})
}

handle_msg :: proc (server : ^Server, msg : game.Msg, steam_connection : steam.HSteamNetConnection) {
	inputs := make([dynamic]game.PlayerInput, context.temp_allocator)
	client := server.connections[steam_connection]
	switch m in msg {
	case game.MsgPlayerInput:
		append(&inputs, game.PlayerInput{client.player_id, m})
	case game.MsgGameState, game.MsgPlayerJoined, game.MsgClientHandshake:
	}
	game.state_update(&server.world_state, inputs[:])
}

broadcast_msg :: proc (server : ^Server, msg : game.Msg) {
	msg_bytes, _ := game.serialize_msg(msg, context.temp_allocator)
	for connection in server.connections {
		steam.NetworkingSockets_SendMessageToConnection(steam.NetworkingSockets_SteamAPI(), connection, raw_data(msg_bytes), u32(len(msg_bytes)), steam.nSteamNetworkingSend_Unreliable, nil)
	}
}

send_reliable_msg :: proc (server : ^Server, msg : game.Msg, connection : steam.HSteamNetConnection) {
	msg_bytes, _ := game.serialize_msg(msg, context.temp_allocator)
	steam.NetworkingSockets_SendMessageToConnection(steam.NetworkingSockets_SteamAPI(), connection, raw_data(msg_bytes), u32(len(msg_bytes)), steam.nSteamNetworkingSend_Reliable, nil)
}

broadcast_reliable_msg :: proc (server : ^Server, msg : game.Msg) {
	msg_bytes, _ := game.serialize_msg(msg, context.temp_allocator)
	for connection in server.connections {
		steam.NetworkingSockets_SendMessageToConnection(steam.NetworkingSockets_SteamAPI(), connection, raw_data(msg_bytes), u32(len(msg_bytes)), steam.nSteamNetworkingSend_Reliable, nil)
	}
}
