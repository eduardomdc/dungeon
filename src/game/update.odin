package game
import box "vendor:box3d"

// game_state_update :: proc (game_state, player_inputs) -> events
// then send game state to all connections unreliably
// send game events reliably, game events are damage, item pickup, door closed, player started to attack etc...
// events need unique ids so clients dont replicate duplicated events ?
// actually lets test client ignores events that are related to their character (start attack) but doesnt ignore or tries to
// predict authorative events (player takes damage, other player starts attack)
state_update :: proc (state : ^WorldState, player_inputs : []PlayerInput) {
	BALL_SPEED :: 20
	for input in player_inputs {
		if input.player_id == 0 do continue
		player := &state.game_state.players[player_idx(input.player_id)]
		trans_xy := BALL_SPEED*f32(input.msg.duration_msec)/1000 * input.msg.input_dir
		translation : Vec3 = {trans_xy.x, trans_xy.y, 0}
		filter := box.DefaultQueryFilter()
		mover := box.Capsule{{0,0,0}, {0,0,PLAYER_CAPSULE_HEIGHT}, PLAYER_CAPSULE_RADIUS}
		moved := box.World_CastMover(state.physics_world.id, player.position, mover, translation, filter, {}, nil)
		player.position += moved*translation
	}
}

// testing map init
game_init :: proc (state : ^WorldState) {
	pworld := box.DefaultWorldDef()
	state.physics_world.id = box.CreateWorld(pworld)

	gm := &state.game_map
	for x:MapVec = 0; x < 20; x+=1 {
		for y:MapVec = 0; y < 20; y+=1 {
			tile := Tile{{x,y,0}, .BasicBlock}
			add_tile(gm, tile)
		}
	}
	for z:MapVec = 1; z <= 2; z+=1 {
		for x:MapVec = 0; x < 20; x+=1 {
			add_tile(gm, Tile{{x,0,z}, .StoneBricks})
			add_tile(gm, Tile{{x,19,z}, .StoneBricks})
		}
		for y:MapVec = 1; y < 19; y+=1 {
			add_tile(gm, Tile{{0,y,z}, .StoneBricks})
			add_tile(gm, Tile{{19,y,z}, .StoneBricks})
		}
	}
	generate_tile_colliders(&state.game_map, &state.physics_world)
}
