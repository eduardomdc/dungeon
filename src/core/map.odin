package core

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
}

// this will only be used by future map editor basically
add_tile :: proc (game_map : ^GameMap, tile : Tile) {
	game_map.tiles[game_map.tile_count] = tile // later check if there's a tile already
	game_map.tile_count += 1
}
