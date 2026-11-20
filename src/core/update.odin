package core

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
		player.position.xy += BALL_SPEED*f32(input.msg.duration_msec)/1000 * input.msg.input_dir
	}
}

// testing map init
core_init :: proc (state : ^WorldState) {
	gm := &state.game_map
	for x:MapVec = 0; x < 10; x+=1 {
		for y:MapVec = 0; y < 10; y+=1 {
			tile := Tile{{x,y,0}, .StoneBricks}
			add_tile(gm, tile)
		}
	}
}
