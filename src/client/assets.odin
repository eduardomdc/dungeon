package client
import "../core"
import rl "vendor:raylib"
import "core:reflect"
import "core:fmt"

Assets :: struct {
	tile_textures : [core.TileType]rl.Texture,
	tile_materials : [core.TileType]rl.Material,
	cube_mesh : rl.Mesh,
}

load_assets :: proc (client : ^Client) {
	for tile in core.TileType {
		if tile == .None do continue
		path := fmt.ctprintf("assets/tile-textures/%s.png", reflect.enum_string(tile))
		client.assets.tile_textures[tile] = rl.LoadTexture(path)
	}
	for tile in core.TileType {
		mat := rl.LoadMaterialDefault()
		mat.maps[rl.MaterialMapIndex.ALBEDO].texture = client.assets.tile_textures[tile]
		client.assets.tile_materials[tile] = mat
	}

	client.assets.cube_mesh = rl.GenMeshCube(1.0, 1.0, 1.0)
}
