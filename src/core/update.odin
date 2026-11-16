package core

GameState_move_actor :: proc (game_state : ^GameState, dir : Vec2) {
	game_state.player_pos.xy += dir
}
