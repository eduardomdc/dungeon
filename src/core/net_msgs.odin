package core

MsgHeaderSize :: u8

MsgType :: enum MsgHeaderSize {
	None,
	MsgMoveActor,
	MsgGameState,
}

Msg :: union {
	MsgMoveActor,
	MsgGameState,
}

MsgMoveActor :: struct {
	input_dir : Vec2,
}

MsgGameState :: struct {
	state : GameState,
}
