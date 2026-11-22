package game
import b3d "vendor:box3d"

Vec :: f32
Vec2 :: [2]Vec
Vec3 :: [3]Vec
vec3_to_f64 :: proc (v : Vec3) -> [3]f64 {return {f64(v.x),f64(v.y),f64(v.z)}}
MAX_PLAYERS :: 6

MapVec :: u8
TilePos :: [3]MapVec // 256 max map dimension big enough?
tile_center :: proc (map_pos : [3]MapVec) -> Vec3 {
	return {Vec(map_pos.x)+0.5, Vec(map_pos.y)+0.5, Vec(map_pos.z)+0.5}
}
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
	id : b3d.WorldId,
	player_phiscs : [MAX_PLAYERS]PlayerPhysics,
}

PlayerPhysics :: struct {
	id : PlayerID,
	body_id : b3d.BodyId,
}

WorldState :: struct {
	game_state : GameState,
	game_map : GameMap,
	physics_world : PhysicsWorld,
}
