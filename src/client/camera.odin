package client

import rl "vendor:raylib"
import "core:math"
import "../game"

CAMERA_ORBIT_RADIUS :: 12.0
CAMERA_ORBIT_HEIGHT :: 12.0
CAMERA_ROTATION_SPEED :: 1.8

CameraRig :: struct {
	camera: rl.Camera3D,
	yaw: f32,
}

camera_init :: proc (rig: ^CameraRig) {
	rig.yaw = f32(math.PI / 4)
	rig.camera = rl.Camera3D{
		position = {0, 0, 0},
		target = {0, 0, 0},
		up = {0, 0, 1},
		fovy = 45,
		projection = .PERSPECTIVE,
	}
}

camera_update :: proc (rig: ^CameraRig, target: game.Vec3, dt: f32) {
	if rl.IsKeyDown(.Q) do rig.yaw -= CAMERA_ROTATION_SPEED * dt
	if rl.IsKeyDown(.E) do rig.yaw += CAMERA_ROTATION_SPEED * dt

	rig.camera.target = target
	rig.camera.position = target + {
		math.cos(rig.yaw) * CAMERA_ORBIT_RADIUS,
		math.sin(rig.yaw) * CAMERA_ORBIT_RADIUS,
		CAMERA_ORBIT_HEIGHT,
	}
}
