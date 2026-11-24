package game
import box "vendor:box3d"

// game_state_update :: proc (game_state, player_inputs) -> events
// then send game state to all connections unreliably
// send game events reliably, game events are damage, item pickup, door closed, player started to attack etc...
// events need unique ids so clients dont replicate duplicated events ?
// actually lets test client ignores events that are related to their character (start attack) but doesnt ignore or tries to
// predict authorative events (player takes damage, other player starts attack)
state_update :: proc (state : ^WorldState, player_inputs : []PlayerInput, dt : f32) {
	for input in player_inputs {
		if input.player_id == 0 do continue
		player_input_accelerate(state, input)
	}
	for &player in state.game_state.players {
		if player.id == 0 do continue
		translation := player_calculate_movement(&state.physics_world.player_physics[player_idx(player.id)], dt)
		move_and_slide(state, player.id, translation)
	}
}

// testing map init
game_init :: proc (state : ^WorldState) {
	pworld := box.DefaultWorldDef()
	state.physics_world.id = box.CreateWorld(pworld)

	gm := &state.game_map
	for x:MapVec = 0; x < 20; x+=1 {
		for y:MapVec = 0; y < 20; y+=1 {
			tile := Tile{{x,y,0}, .StoneBricks}
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
