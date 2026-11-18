package core
import b3d "vendor:box3d"

Vec :: f32
Vec2 :: [2]Vec
Vec3 :: [3]Vec

MapVec :: u8
TilePos :: [3]MapVec // 256 max map dimension big enough?

GameState :: struct {
	player_pos : Vec3,
}

PhysicsWorld :: struct {
	world_id : b3d.WorldId,
}

WorldState :: struct {
	game_state : GameState,
	game_map : GameMap,
	physics_world : PhysicsWorld,
}
