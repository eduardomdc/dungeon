package game
import box "vendor:box3d"
import "core:c"

PLAYER_CAPSULE_HEIGHT :: 1
PLAYER_CAPSULE_RADIUS :: 0.5

create_player :: proc (world : ^WorldState) -> PlayerID {
	free_id : PlayerID
	for player, idx in world.game_state.players {
		if player.id == 0 { free_id = player_id(idx); break }
	}
	if free_id == 0 do return 0 // no free slot, max players reached
	
	player := Player{free_id, {5,5,2}}
	world.game_state.players[player_idx(free_id)] = player

	//add_player_physics(world, free_id)

	return free_id
}

move_player :: proc (world : ^WorldState, player_id : PlayerID, input : PlayerInput) {
	PLAYER_SPEED :: 10
	player := &world.game_state.players[player_idx(player_id)]
	trans_xy := PLAYER_SPEED*f32(input.msg.duration_msec)/1000 * input.msg.input_dir
	translation : Vec3 = {trans_xy.x, trans_xy.y, 0}
	filter := box.DefaultQueryFilter()
	mover := box.Capsule{{0,0,0}, {0,0,PLAYER_CAPSULE_HEIGHT}, PLAYER_CAPSULE_RADIUS}
	moved := box.World_CastMover(world.physics_world.id, player.position, mover, translation, filter, {}, nil)
	player.position += moved*translation
	mover.center1 += moved*translation
	mover.center2 += moved*translation

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
	velocity := box.ClipVector(translation, raw_data(plane_ctx.planes[:]), c.int(plane_ctx.count))
	player.position += result.delta
}

/*
add_player_physics :: proc (world : ^WorldState, player_id : PlayerID) {
	b3d.Body_CollideMover
	player := world.game_state.players[player_idx(player_id)]
	player_physics : PlayerPhysics
	body_def := b3d.DefaultBodyDef()
    body_def.type = .dynamicBody
    body_def.position = player.position

    body_id := b3d.CreateBody(world.physics_world.id, body_def)

    box_h := b3d.MakeBoxHull(0.3, 0.3, 0.9)
    shape_def := b3d.DefaultShapeDef()
    shape_def.density = 1.0

    _ = b3d.CreateHullShape(body_id, shape_def, &box_h.base)

    return body_id
}
*/
