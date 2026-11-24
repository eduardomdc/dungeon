package game
import "core:encoding/cbor"
import "core:mem"
import steam "../../ext/steamworks"

PORT :: 27015
MsgHeaderSize :: u8

MsgType :: enum MsgHeaderSize {
	None,
	MsgMoveActor,
	MsgGameState,
}

Msg :: union {
	MsgPlayerInput,
	MsgGameState,
	MsgPlayerJoined,
	MsgClientHandshake,
}

MsgPlayerInput :: struct {
	duration_msec : u16,
	input_dir: Vec2,
	looking: Vec3,
}

PlayerInput :: struct {
	player_id : PlayerID,
	msg : MsgPlayerInput,
}

MsgGameState :: struct {
	tick: u32,
	state: GameState,
}

MsgPlayerJoined :: struct {
	steam_id : steam.CSteamID,
	player_id : PlayerID,
}

MsgClientHandshake :: struct { // sent only to the connecting client so that it knows what is its' player id
	player_id : PlayerID,
}

@require_results
serialize_msg :: proc(msg: Msg, allocator : mem.Allocator) -> (data: []byte, err: cbor.Marshal_Error) {
	return cbor.marshal(msg, allocator = allocator)
}

@require_results
deserialize_msg :: proc(data: []byte, allocator : mem.Allocator) -> (msg: Msg, err: cbor.Unmarshal_Error) {
	err = cbor.unmarshal(transmute(string)data, &msg, allocator = allocator)
	return
}
