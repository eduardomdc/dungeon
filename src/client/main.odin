package client
import rl "vendor:raylib"
import "core:math/linalg"
import steam "../../ext/steamworks"
import "core:c"
import "../core"
import "core:fmt"

RES : [2]c.int : {1280, 720}
FPS :: 60

Client :: struct {
	game_state : core.GameState,
	camera : rl.Camera3D,
	server_connection : steam.HSteamNetConnection,
	connected_to_server : bool,
}

C : ^Client

main :: proc () {
	C = new(Client); defer free(C)
	start_steamworks(C)
	rl.InitWindow(RES.x, RES.y, "Dungeon")
	rl.SetTargetFPS(60)
	init_camera(C)
	for ; !rl.WindowShouldClose() ; {
		steam_callbacks(C)
		render(C^)
		input(C)
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

render :: proc (client : Client) {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	rl.DrawFPS(2, 2)
	rl.BeginMode3D(client.camera)
		rl.DrawSphere(client.game_state.player_pos, 1, rl.BLUE)
	rl.EndMode3D()
	rl.EndDrawing()
}

input :: proc (client : ^Client) {
	dir := get_directional_input()
	if dir != {} do send_msg(client, core.MsgMoveActor{dir})
}

get_directional_input :: proc () -> (dir : core.Vec2){
	if rl.IsKeyDown(.W)	do dir += core.Vec2{0,1}
	if rl.IsKeyDown(.S) do dir += core.Vec2{0,-1}
	if rl.IsKeyDown(.A) do dir += core.Vec2{-1,0}
	if rl.IsKeyDown(.D) do dir += core.Vec2{1,0}
	dir = linalg.normalize(dir)
	return
}

send_msg :: proc (client : ^Client, msg : core.Msg) {
	if !client.connected_to_server do return
	serialized, err := core.serialize_msg(msg, context.allocator); defer delete(serialized)
	if err != nil do panic(fmt.tprint("Msg serialization error :", err))
	steam.NetworkingSockets_SendMessageToConnection(steam.NetworkingSockets_SteamAPI(), client.server_connection, raw_data(serialized), u32(len(serialized)), steam.nSteamNetworkingSend_Unreliable, nil)
}
