package game

PLAYER_CAPSULE_HEIGHT :: 2
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
