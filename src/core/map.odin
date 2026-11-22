package core

import "vendor:box3d"

MAX_TILES :: 1000
GameMap :: struct {
	tiles : [MAX_TILES]Tile,
	tile_count : u16,
}

Tile :: struct {
	position : TilePos,
	type : TileType,
}

TileType :: enum u8 {
	None,
	StoneBricks,
	BasicBlock,
}

// this will only be used by future map editor basically
add_tile :: proc (game_map : ^GameMap, tile : Tile) {
	game_map.tiles[game_map.tile_count] = tile // later check if there's a tile already
	game_map.tile_count += 1
}

generate_tile_colliders :: proc (game_map  : ^GameMap, p_world : ^PhysicsWorld) {
	for i in 0..<game_map.tile_count {
		tile := game_map.tiles[i]
		if tile.type == .None do continue
		box_h := box3d.MakeBoxHull(0.5, 0.5, 0.5)
		body := box3d.DefaultBodyDef()
		body.position = tile_center(tile.position)
		body_id := box3d.CreateBody(p_world.world_id, body)
		shape := box3d.DefaultShapeDef()
		shape_id := box3d.CreateHullShape(body_id, shape, &box_h.base)
	}
}
