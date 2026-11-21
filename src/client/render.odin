package client
import rl "vendor:raylib"
import "../core"

@rodata
PLAYER_COLORS : [core.MAX_PLAYERS]rl.Color = {rl.RED, rl.BLUE, rl.GREEN, rl.YELLOW, rl.WHITE, rl.BROWN}

render :: proc (client : Client) {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	rl.DrawFPS(2, 2)
	rl.BeginMode3D(client.camera)
		for player in client.world_state.game_state.players {
			if player.id == 0 do continue
			rl.DrawSphere(player.position, 0.5, PLAYER_COLORS[core.player_idx(player.id)])
		}
		render_map(client)
	rl.EndMode3D()
	rl.EndDrawing()
}

tile_center :: proc (map_pos : [3]core.MapVec) -> rl.Vector3 {
	return {f32(map_pos.x)+0.5, f32(map_pos.y)+0.5, f32(map_pos.z)+0.5}
}

render_map :: proc (client : Client) {
	render_tiles(client)
}

render_tiles :: proc (client : Client) {
	for i:u16=0; i< client.world_state.game_map.tile_count; i+=1 {
		tile := client.world_state.game_map.tiles[i]
		draw_tile(client, tile.position, tile.type)
	}
	draw_tile :: proc (client : Client, pos : core.TilePos, tile : core.TileType) {
		wpos := tile_center(pos)
		transform := rl.MatrixTranslate(wpos.x, wpos.y, wpos.z)
		rl.DrawMesh(client.assets.cube_mesh, client.assets.tile_materials[tile], transform)
	}
}
