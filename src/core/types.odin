package core
import b3d "vendor:box3d"

Vec :: f32
Vec2 :: [2]Vec
Vec3 :: [3]Vec
MAX_PLAYERS :: 6

MapVec :: u8
TilePos :: [3]MapVec // 256 max map dimension big enough?
PlayerID :: u8
player_idx :: #force_inline proc (id : PlayerID) -> int {return int(id)-1}
player_id :: #force_inline proc (idx : int) -> PlayerID {return PlayerID(idx)+1}

GameState :: struct {
	players : [MAX_PLAYERS]Player,
}

Player :: struct {
	id : PlayerID,
	position : Vec3,
}

PhysicsWorld :: struct {
	world_id : b3d.WorldId,
}

WorldState :: struct {
	game_state : GameState,
	game_map : GameMap,
	physics_world : PhysicsWorld,
}
