package game
import box "vendor:box3d"
import "core:c"
import "core:math/linalg"

PLAYER_CAPSULE_HEIGHT :: 1
PLAYER_CAPSULE_RADIUS :: 0.5

create_player :: proc (world : ^WorldState) -> PlayerID {
	free_id : PlayerID
	for player, idx in world.game_state.players {
		if player.id == 0 { free_id = player_id(idx); break }
	}
	if free_id == 0 do return 0 // no free slot, max players reached
	
	player := Player{free_id, {5,5,4}}
	world.game_state.players[player_idx(free_id)] = player
	world.physics_world.player_physics[player_idx(free_id)] = PlayerPhysics{free_id, {0,0,0}}

	return free_id
}

player_input_accelerate :: proc (world : ^WorldState, input : PlayerInput) {
	player_physics := &world.physics_world.player_physics[player_idx(input.player_id)]
	PLAYER_ACC :: 10000
	inputxy := PLAYER_ACC*f32(input.msg.duration_msec)/1000 * input.msg.input_dir
	input_dir : Vec3 = {inputxy.x, inputxy.y, 0}
	player_physics.velocity += input_dir
}

player_calculate_movement :: proc (player : ^PlayerPhysics, dt : f32) -> (translation : Vec3) {	
	//player.velocity = apply_gravity(player.velocity, dt)
	player.velocity = apply_friction(player.velocity, dt)
	player.velocity = max_velocity(player.velocity)
	
	return player.velocity * dt

	max_velocity :: proc (velocity : Vec3) -> Vec3 {
		MAX_SPEED :: 10
		speed := linalg.length(velocity.xy)
		if speed == 0 do return velocity
		if speed > MAX_SPEED {
			xy := linalg.normalize(velocity.xy) * MAX_SPEED
			return {xy.x, xy.y, velocity.z}
		}
		return velocity
	}

	apply_friction :: proc (velocity : Vec3, dt : f32) -> Vec3 {
		FRICTION :: 100
		horizontal : Vec2 = {velocity.x, velocity.y}
		speed := linalg.length(horizontal)
		if speed == 0 do return velocity
		new_speed := max(0, speed - dt * FRICTION)
		horizontal = horizontal * (new_speed/speed)
		return {horizontal.x, horizontal.y, velocity.z}
	}

	apply_gravity :: proc (velocity : Vec3, dt : f32) -> Vec3 {
		GRAVITY :: -9.8
		return velocity + {0,0,1} * GRAVITY * dt
	}
}

move_and_slide :: proc (world : ^WorldState, player_id : PlayerID, translation : Vec3) {
	player := &world.game_state.players[player_idx(player_id)]
	filter := box.DefaultQueryFilter()
	mover := box.Capsule{{0,0,0}, {0,0,PLAYER_CAPSULE_HEIGHT}, PLAYER_CAPSULE_RADIUS}
	moved := box.World_CastMover(world.physics_world.id, player.position, mover, translation, filter, {}, nil)
	player.position += moved*translation

	//Solve contact planes, from box3d mover example
	MAX_PLANES :: 16
	PlaneCtx :: struct {
		planes: [MAX_PLANES]box.CollisionPlane,
		count:  int,
	}
	plane_callback :: proc "c" (shape_id: box.ShapeId, planes: [^]box.PlaneResult, plane_count: c.int, ctx: rawptr) -> bool {
		pctx := (^PlaneCtx)(ctx)
		for i in 0 ..< int(plane_count) {
			if pctx.count >= MAX_PLANES do break
			pctx.planes[pctx.count] = box.CollisionPlane{plane=planes[i].plane, pushLimit=10000, push=1, clipVelocity = true}
			pctx.count += 1
		}
		return true
	}
	plane_ctx: PlaneCtx
	box.World_CollideMover(world.physics_world.id, player.position, mover, filter, plane_callback, &plane_ctx)
	result := box.SolvePlanes({}, raw_data(plane_ctx.planes[:]), c.int(plane_ctx.count))
	player.position += result.delta

	// Clip the persistent velocity, not this frame's displacement. Otherwise the
	// next update keeps trying to move into the wall and repeatedly pushes against it.
	physics := &world.physics_world.player_physics[player_idx(player_id)]
	physics.velocity = box.ClipVector(physics.velocity, raw_data(plane_ctx.planes[:]), c.int(plane_ctx.count))
}
