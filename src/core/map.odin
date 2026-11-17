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

TileType :: enum {
	StoneBricks,
}
