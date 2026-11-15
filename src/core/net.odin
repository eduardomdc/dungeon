package core
import "core:encoding/cbor"
import "core:mem"

PORT :: 27015
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

MsgMoveActor :: struct #packed {
	input_dir: Vec2,
}

MsgGameState :: struct #packed {
	state: GameState,
}

@require_results
serialize_msg :: proc(msg: Msg, allocator : mem.Allocator) -> (data: []byte, err: cbor.Marshal_Error) {
	return cbor.marshal(msg, allocator = allocator)
}

@require_results
unserialize_msg :: proc(data: []byte, allocator : mem.Allocator) -> (msg: Msg, err: cbor.Unmarshal_Error) {
	err = cbor.unmarshal(transmute(string)data, &msg, allocator = allocator)
	return
}
