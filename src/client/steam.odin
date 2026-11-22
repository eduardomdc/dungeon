package client
import "core:fmt"
import steam "../../ext/steamworks"
import "base:runtime"
import "core:c"
import "../game"

LOCAL_SERVER_IP :: 0x7F000001 // 127.0.0.1

start_steamworks :: proc (client : ^Client) {
	if steam.RestartAppIfNecessary(steam.uAppIdInvalid) {
        fmt.println("Launching app through steam...")
        return
    }

    err_msg: steam.SteamErrMsg
    if err := steam.InitFlat(&err_msg); err != .OK {
        fmt.printfln("steam.InitFlat failed with code '{}' and message \"{}\"", err, transmute(cstring)&err_msg[0])
        panic("Steam Init failed. Make sure Steam is running.")
    }

    steam.Client_SetWarningMessageHook(steam.Client(), steam_debug_text_hook)

    steam.ManualDispatch_Init()

    if !steam.User_BLoggedOn(steam.User()) {
        panic("User isn't logged in.")
    } else {
        fmt.println("USER IS LOGGED IN")
    }
	client.steam_id = steam.User_GetSteamID(steam.User())	

	address : steam.SteamNetworkingIPAddr
	steam.NetworkingIPAddr_Clear(&address)
	steam.NetworkingIPAddr_SetIPv4(&address, LOCAL_SERVER_IP, game.PORT)
	client.server_connection = steam.NetworkingSockets_ConnectByIPAddress(steam.NetworkingSockets_SteamAPI(), &address, 0, nil)
}

steam_debug_text_hook :: proc "c" (severity: c.int, debugText: cstring) {
    // if you're running in the debugger, only warnings (nSeverity >= 1) will be sent
    // if you add -debug_steamworksapi to the command-line, a lot of extra informational messages will also be sent
    runtime.print_string(string(debugText))

    if severity >= 1 {
        runtime.debug_trap()
    }
}

steam_callbacks :: proc (client : ^Client) {
    steam_pipe := steam.GetHSteamPipe()
    steam.ManualDispatch_RunFrame(steam_pipe)
    cb: steam.CallbackMsg

    for steam.ManualDispatch_GetNextCallback(steam_pipe, &cb) {
		#partial switch cb.iCallback {
		case .SteamNetConnectionStatusChangedCallback:
			event := transmute(^steam.SteamNetConnectionStatusChangedCallback)cb.pubParam
			#partial switch event.info.eState {
			case .Connecting:
				fmt.println("Connecting to server...")
            case .Connected:
                fmt.println("Connected to server")
				client.connected_to_server = true
            case .ClosedByPeer, .ProblemDetectedLocally:
                fmt.println("Disconnected from server")
				client.connected_to_server = false
                steam.NetworkingSockets_CloseConnection(steam.NetworkingSockets_SteamAPI(), event.hConn, 0, nil, false)
            }
		}
        steam.ManualDispatch_FreeLastCallback(steam_pipe)
    }
}

