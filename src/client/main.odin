package client
import rl "vendor:raylib"
import steam "../../ext/steamworks"
import "core:c"
import "../core"

RES : [2]c.int : {1280, 720}
FPS :: 60

Client :: struct {
	game_state : core.GameState,
	camera : rl.Camera3D,
}

C : ^Client

main :: proc () {
	C = new(Client); defer free(C)
	start_steamworks()
	rl.InitWindow(RES.x, RES.y, "Dungeon")
	rl.SetTargetFPS(60)
	init_camera(C)
	for ; !rl.WindowShouldClose() ; {
		steam_callbacks()
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
	
}
