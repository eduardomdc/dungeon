package client
import rl "vendor:raylib"
import "core:math/linalg"
import steam "../../ext/steamworks"
import "core:c"
import "../game"
import "core:fmt"
import "core:time"

RES : [2]c.int : {1280, 720}
FPS :: 120

Client :: struct {
	world_state : game.WorldState,
	last_server_tick: u32,
	assets : Assets,
	player_id : game.PlayerID,
	steam_id : steam.CSteamID,
	camera : rl.Camera3D,
	server_connection : steam.HSteamNetConnection,
	connected_to_server : bool,
	last_frame_time : time.Time,
	dt : time.Duration,
}

C : ^Client

main :: proc () {
	C = new(Client); defer free(C)
	start_steamworks(C)
	rl.InitWindow(RES.x, RES.y, "Dungeon")
	rl.SetTargetFPS(FPS)
	load_assets(C)
	init_camera(C)
	game.game_init(&C.world_state)
	C.last_frame_time = time.now()
	for ; !rl.WindowShouldClose() ; {
		now := time.now()
		C.dt = time.diff(C.last_frame_time, now)
		C.last_frame_time = now
		steam_callbacks(C)
		poll_msgs(C)
		input := input(C)
		inputs : []game.PlayerInput = {input}
		// simulate
		game.state_update(&C.world_state, inputs, f32(time.duration_seconds(C.dt)))
		render(C^)
		if C.player_id != 0 do C.camera.target = C.world_state.game_state.players[game.player_idx(C.player_id)].position
	}
	steam.Shutdown()
}

init_camera :: proc (client : ^Client) {
	client.camera = rl.Camera3D{
		position = {10, 10, 10},
		target = {0, 0, 0},
		up = {0, 0, 1},
		fovy = 45,
		projection = .PERSPECTIVE,
	}
}

input :: proc (client : ^Client) -> game.PlayerInput {
	dir := get_directional_input()
	
	input_msg : game.MsgPlayerInput
	input_msg.input_dir = dir
	if rl.IsKeyDown(.SPACE) do input_msg.buttons += {.JUMP}
	if input_msg == {} do return {}
	
	frame_dt := u16(time.duration_milliseconds(client.dt))
	input_msg.duration_msec = frame_dt
	send_msg(client, input_msg)
	pi := game.PlayerInput{ client.player_id, input_msg }
	return pi
}

get_directional_input :: proc () -> (dir : game.Vec2){
	if rl.IsKeyDown(.W)	do dir += game.Vec2{0,1}
	if rl.IsKeyDown(.S) do dir += game.Vec2{0,-1}
	if rl.IsKeyDown(.A) do dir += game.Vec2{-1,0}
	if rl.IsKeyDown(.D) do dir += game.Vec2{1,0}
	if dir != {} do dir = linalg.normalize(dir)
	return
}

send_msg :: proc (client : ^Client, msg : game.Msg) {
	if !client.connected_to_server do return
	serialized, err := game.serialize_msg(msg, context.allocator); defer delete(serialized)
	if err != nil do panic(fmt.tprint("Msg serialization error :", err))
	steam.NetworkingSockets_SendMessageToConnection(steam.NetworkingSockets_SteamAPI(), client.server_connection, raw_data(serialized), u32(len(serialized)), steam.nSteamNetworkingSend_Unreliable, nil)
}

poll_msgs :: proc (client : ^Client) {
	if !client.connected_to_server do return
	MAX_MSGS :: 64
	messages : [MAX_MSGS]^steam.SteamNetworkingMessage
	received_count := steam.NetworkingSockets_ReceiveMessagesOnConnection(steam.NetworkingSockets_SteamAPI(), client.server_connection, &messages[0], MAX_MSGS)
	for i in 0..<received_count {
		message := messages[i]
		defer steam.NetworkingMessage_t_Release(message)
		data_ptr := cast([^]u8)message^.pData
        data := data_ptr[:message^.cbSize]
		msg, err := game.deserialize_msg(data, context.temp_allocator)
		if err != nil {fmt.println("Failed to deserialize msg"); continue}
		handle_msg(client, msg)
	}
}

handle_msg :: proc (client : ^Client, msg : game.Msg) {
	switch m in msg {
	case game.MsgPlayerInput:
	case game.MsgGameState:
		if m.tick > client.last_server_tick {
			client.last_server_tick = m.tick
			client.world_state.game_state = m.state
		} else do fmt.println("Received out of order msg tick", m.tick, "vs server", client.last_server_tick)
	case game.MsgPlayerJoined:
	case game.MsgClientHandshake:
		client.player_id = m.player_id
	}
}
