package server
import steam "../../ext/steamworks"
import "core:time"
import "../core"
import "core:fmt"

ClientConnection :: struct {
	steam_id : steam.CSteamID,
	player_id : core.PlayerID,
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
		msg, err := core.deserialize_msg(data, context.temp_allocator)
		if err != nil {fmt.println("Failed to deserialize msg"); continue}
		handle_msg(server, msg, message.conn)
	} // need to do it again if count == MAX_MSGS
	
	broadcast_msg(server, core.MsgGameState{server.world_state.game_state})
}

handle_msg :: proc (server : ^Server, msg : core.Msg, steam_connection : steam.HSteamNetConnection) {
	inputs := make([dynamic]core.PlayerInput, context.temp_allocator)
	client := server.connections[steam_connection]
	switch m in msg {
	case core.MsgPlayerInput:
		append(&inputs, core.PlayerInput{client.player_id, m})
	case core.MsgGameState, core.MsgPlayerJoined, core.MsgClientHandshake:
	}
	core.state_update(&server.world_state, inputs[:])
}

broadcast_msg :: proc (server : ^Server, msg : core.Msg) {
	msg_bytes, _ := core.serialize_msg(msg, context.temp_allocator)
	for connection in server.connections {
		steam.NetworkingSockets_SendMessageToConnection(steam.NetworkingSockets_SteamAPI(), connection, raw_data(msg_bytes), u32(len(msg_bytes)), steam.nSteamNetworkingSend_Unreliable, nil)
	}
}

send_reliable_msg :: proc (server : ^Server, msg : core.Msg, connection : steam.HSteamNetConnection) {
	msg_bytes, _ := core.serialize_msg(msg, context.temp_allocator)
	steam.NetworkingSockets_SendMessageToConnection(steam.NetworkingSockets_SteamAPI(), connection, raw_data(msg_bytes), u32(len(msg_bytes)), steam.nSteamNetworkingSend_Reliable, nil)
}

broadcast_reliable_msg :: proc (server : ^Server, msg : core.Msg) {
	msg_bytes, _ := core.serialize_msg(msg, context.temp_allocator)
	for connection in server.connections {
		steam.NetworkingSockets_SendMessageToConnection(steam.NetworkingSockets_SteamAPI(), connection, raw_data(msg_bytes), u32(len(msg_bytes)), steam.nSteamNetworkingSend_Reliable, nil)
	}
}

player_join :: proc (server : ^Server) -> core.PlayerID {
	free_player_id : core.PlayerID
	for player, idx in server.world_state.game_state.players {
		if player.id == 0 { free_player_id = core.player_id(idx); break }
	}
	if free_player_id == 0 do return 0 // no free slot, max players reached
	server.world_state.game_state.players[core.player_idx(free_player_id)] = core.Player{free_player_id, {}}
	return free_player_id
}
