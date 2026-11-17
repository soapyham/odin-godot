package game

import "core:math"
import "godot:libgd"
import "godot:libgd/classdb"
import "godot:godot"

YawSpeed :: 0.022
PitchSpeed :: 0.022
MouseSpeed :: 2.0

PLAYER_CLASS_NAME :: "Player"

Player :: struct {
    object:                       godot.Character_Body3d `gd:"CharacterBody3D"`,

    // Group: Movement. Subgroup: On Ground
    ground_friction:              f64,
    ground_accel:                 f64,
    ground_max_speed:             f64,
    max_step_height:              f64,
    max_step_up_slide_iterations: i64,

    // Group: Movement. Subgroup: In Air
    gravity_up_scale:             f64,
    gravity_down_scale:           f64,
    air_friction:                 f64,
    air_accel:                    f64,
    air_max_speed:                f64,
    max_vertical_speed:           f64,

    // onready
    camera_yaw:                   godot.Node3d,
    camera:                       godot.Camera3d,

    // fields
    vertical_speed:               f64,
    horizontal_velocity:          godot.Vector3,
}

@(private = "file")
player_ready :: proc "contextless" (self: ^Player) {
    self.camera_yaw = godot.node_get_node(self.object, "CameraYaw")
    self.camera = godot.node_get_node(self.object, "CameraYaw/Camera")
}

@(private = "file")
player_input :: proc "contextless" (self: ^Player, event: godot.Input_Event) {
    if godot.input_get_mouse_mode(godot.singleton_input()) == .Mouse_Mode_Captured {
        if key_event, ok := godot.cast_class(event, godot.Input_Event_Key); ok {
            if godot.input_event_key_get_keycode(key_event) == .Escape {
                godot.input_set_mouse_mode(godot.singleton_input(), .Mouse_Mode_Visible)
            }
            return
        }

        if mouse_motion_event, ok := godot.cast_class(event, godot.Input_Event_Mouse_Motion); ok {
            player_move_camera(self, godot.input_event_mouse_motion_get_relative(mouse_motion_event))
            return
        }
    } else {
        if mouse_button_event, ok := godot.cast_class(event, godot.Input_Event_Mouse_Button); ok {
            mouse_button_index := godot.input_event_mouse_button_get_button_index(mouse_button_event)
            if mouse_button_index == .Left && godot.input_event_is_pressed(event) {
                godot.input_set_mouse_mode(godot.singleton_input(), .Mouse_Mode_Captured)
            }
            return
        }
    }
}

@(private = "file")
player_physics_process :: proc "contextless" (self: ^Player, delta: f64) {
    local_wish_dir := godot.VECTOR3_ZERO
    if godot.input_get_mouse_mode(godot.singleton_input()) == .Mouse_Mode_Captured {
        input_dir := libgd.get_input_vector("move_left", "move_right", "move_forward", "move_back")
        local_wish_dir = godot.Vector3{input_dir.x, 0, input_dir.y}
    }

    camera_yaw_basis := godot.node3d_get_basis(self.camera_yaw)
    wish_dir := godot.basis_multiply(camera_yaw_basis, local_wish_dir)

    if godot.character_body3d_is_on_floor(self.object) {
        player_move(self, delta, wish_dir, self.ground_friction, self.ground_accel, self.ground_max_speed)
    } else {
        player_move(self, delta, wish_dir, self.air_friction, self.air_accel, self.air_max_speed)
    }

    player_apply_gravity(self, delta)

    was_grounded := godot.character_body3d_is_on_floor(self.object)
    godot.character_body3d_set_velocity(
        self.object,
        godot.Vector3{self.horizontal_velocity.x, godot.Real(self.vertical_speed), self.horizontal_velocity.z},
    )

    player_sweep_stairs_up(self, delta)
    godot.character_body3d_move_and_slide(self.object)
    player_sweep_stairs_down(self, was_grounded)

    self.horizontal_velocity = godot.character_body3d_get_velocity(self.object)
    self.vertical_speed = cast(godot.Float)self.horizontal_velocity.y
    self.horizontal_velocity.y = 0
}

player_move_camera :: proc "contextless" (self: ^Player, move: godot.Vector2) {
    horizontal := move.x * YawSpeed * MouseSpeed
    vertical := move.y * PitchSpeed * MouseSpeed
    yaw_rotation := math.to_radians(-horizontal)
    pitch_rotation := math.to_radians(-vertical)

    godot.node3d_rotate_y(self.camera_yaw, f32(yaw_rotation))
    godot.node3d_rotate_x(self.camera, f32(pitch_rotation))
}

player_move :: proc "contextless" (
    self: ^Player,
    delta: godot.Float,
    wish_dir: godot.Vector3,
    friction: godot.Float,
    accel: godot.Float,
    max_speed: godot.Float,
) {
    if (wish_dir == godot.Vector3{0, 0, 0}) {
        self.horizontal_velocity = exp_decay(
            self.horizontal_velocity,
            godot.VECTOR3_ZERO,
            godot.Real(friction),
            godot.Real(delta),
        )
        if is_zero_approx(self.horizontal_velocity) {
            self.horizontal_velocity = godot.Vector3{0, 0, 0}
        }
    } else {
        self.horizontal_velocity += wish_dir * godot.Real(accel * delta)
    }

    self.horizontal_velocity = limit_length(self.horizontal_velocity, max_speed)
}

player_apply_gravity :: proc "contextless" (self: ^Player, delta: f64) {
    if self.vertical_speed > -self.max_vertical_speed {
        gravity: f64 = -10
        if self.vertical_speed > 0 || godot.character_body3d_is_on_floor(self.object) {
            gravity *= self.gravity_up_scale
        } else {
            gravity *= self.gravity_down_scale
        }

        self.vertical_speed += gravity * delta

        if self.vertical_speed < -self.max_vertical_speed {
            self.vertical_speed = -self.max_vertical_speed
        }
    }
}

player_sweep_stairs_up :: proc "contextless" (self: ^Player, delta: f64) {
    if !godot.character_body3d_is_on_floor(self.object) {
        return
    }
}

player_sweep_stairs_down :: proc "contextless" (self: ^Player, was_grounded: bool) {

}

@(private = "file")
player_init :: proc "contextless" (self: ^Player) {
    // defaults
    self.ground_friction = 20
    self.ground_accel = 100
    self.ground_max_speed = 5.0
    self.max_step_height = 0.6
    self.max_step_up_slide_iterations = 4
    self.gravity_up_scale = 1.0
    self.gravity_down_scale = 1.0
    self.air_friction = 10.0
    self.air_accel = 50.0
    self.air_max_speed = 3.0
    self.max_vertical_speed = 15.0

    self.vertical_speed = 0.0
    self.horizontal_velocity = godot.Vector3{0, 0, 0}
}

@(private = "file")
set_ground_friction :: proc "contextless" (self: ^Player, value: f64) {
    self.ground_friction = value
}

@(export)
get_ground_friction :: proc "contextless" (self: ^Player) -> f64 {
    return self.ground_friction
}

@(private = "file")
set_ground_accel :: proc "contextless" (self: ^Player, value: f64) {
    self.ground_accel = value
}

@(private = "file")
get_ground_accel :: proc "contextless" (self: ^Player) -> f64 {
    return self.ground_accel
}

@(private = "file")
set_ground_max_speed :: proc "contextless" (self: ^Player, value: f64) {
    self.ground_max_speed = value
}

@(private = "file")
get_ground_max_speed :: proc "contextless" (self: ^Player) -> f64 {
    return self.ground_max_speed
}

@(private = "file")
set_max_step_height :: proc "contextless" (self: ^Player, value: f64) {
    self.max_step_height = value
}

@(private = "file")
get_max_step_height :: proc "contextless" (self: ^Player) -> f64 {
    return self.max_step_height
}

@(private = "file")
set_max_step_up_slide_iterations :: proc "contextless" (self: ^Player, value: i64) {
    self.max_step_up_slide_iterations = value
}

@(private = "file")
get_max_step_up_slide_iterations :: proc "contextless" (self: ^Player) -> i64 {
    return self.max_step_up_slide_iterations
}

@(private = "file")
set_gravity_up_scale :: proc "contextless" (self: ^Player, value: f64) {
    self.gravity_up_scale = value
}

@(private = "file")
get_gravity_up_scale :: proc "contextless" (self: ^Player) -> f64 {
    return self.gravity_up_scale
}

@(private = "file")
set_gravity_down_scale :: proc "contextless" (self: ^Player, value: f64) {
    self.gravity_down_scale = value
}

@(private = "file")
get_gravity_down_scale :: proc "contextless" (self: ^Player) -> f64 {
    return self.gravity_down_scale
}

@(private = "file")
set_air_friction :: proc "contextless" (self: ^Player, value: f64) {
    self.air_friction = value
}

@(private = "file")
get_air_friction :: proc "contextless" (self: ^Player) -> f64 {
    return self.air_friction
}

@(private = "file")
set_air_accel :: proc "contextless" (self: ^Player, value: f64) {
    self.air_accel = value
}

@(private = "file")
get_air_accel :: proc "contextless" (self: ^Player) -> f64 {
    return self.air_accel
}

@(private = "file")
set_air_max_speed :: proc "contextless" (self: ^Player, value: f64) {
    self.air_max_speed = value
}

@(private = "file")
get_air_max_speed :: proc "contextless" (self: ^Player) -> f64 {
    return self.air_max_speed
}

@(private = "file")
set_max_vertical_speed :: proc "contextless" (self: ^Player, value: f64) {
    self.max_vertical_speed = value
}

@(private = "file")
get_max_vertical_speed :: proc "contextless" (self: ^Player) -> f64 {
    return self.max_vertical_speed
}

player_class_register :: proc() {
    classdb.register_class(
        Player,
        classdb.Class_VTable_Contextless(Player){
            init = player_init,
            ready = player_ready,
            input = player_input,
            physics_process = player_physics_process,
        },
    )

    classdb.bind_property_group(PLAYER_CLASS_NAME, "Movement", "")
    classdb.bind_property_subgroup(PLAYER_CLASS_NAME, "On Ground", "")
    classdb.bind_property_and_methods(
        PLAYER_CLASS_NAME,
        "ground_friction",
        "get_ground_friction",
        "set_ground_friction",
        get_ground_friction,
        set_ground_friction,
        static_strings = true,
    )
    classdb.bind_property_and_methods(
        PLAYER_CLASS_NAME,
        "ground_accel",
        "get_ground_accel",
        "set_ground_accel",
        get_ground_accel,
        set_ground_accel,
        static_strings = true,
    )
    classdb.bind_property_and_methods(
        PLAYER_CLASS_NAME,
        "ground_max_speed",
        "get_ground_max_speed",
        "set_ground_max_speed",
        get_ground_max_speed,
        set_ground_max_speed,
        static_strings = true,
    )
    classdb.bind_property_and_methods(
        PLAYER_CLASS_NAME,
        "max_step_height",
        "get_max_step_height",
        "set_max_step_height",
        get_max_step_height,
        set_max_step_height,
        static_strings = true,
    )
    classdb.bind_property_and_methods(
        PLAYER_CLASS_NAME,
        "max_step_up_slide_iterations",
        "get_max_step_up_slide_iterations",
        "set_max_step_up_slide_iterations",
        get_max_step_up_slide_iterations,
        set_max_step_up_slide_iterations,
        static_strings = true,
    )

    classdb.bind_property_subgroup(PLAYER_CLASS_NAME, "In Air", "")
    classdb.bind_property_and_methods(
        PLAYER_CLASS_NAME,
        "gravity_up_scale",
        "get_gravity_up_scale",
        "set_gravity_up_scale",
        get_gravity_up_scale,
        set_gravity_up_scale,
        static_strings = true,
    )
    classdb.bind_property_and_methods(
        PLAYER_CLASS_NAME,
        "gravity_down_scale",
        "get_gravity_down_scale",
        "set_gravity_down_scale",
        get_gravity_down_scale,
        set_gravity_down_scale,
        static_strings = true,
    )
    classdb.bind_property_and_methods(
        PLAYER_CLASS_NAME,
        "air_friction",
        "get_air_friction",
        "set_air_friction",
        get_air_friction,
        set_air_friction,
        static_strings = true,
    )
    classdb.bind_property_and_methods(
        PLAYER_CLASS_NAME,
        "air_accel",
        "get_air_accel",
        "set_air_accel",
        get_air_accel,
        set_air_accel,
        static_strings = true,
    )
    classdb.bind_property_and_methods(
        PLAYER_CLASS_NAME,
        "air_max_speed",
        "get_air_max_speed",
        "set_air_max_speed",
        get_air_max_speed,
        set_air_max_speed,
        static_strings = true,
    )
    classdb.bind_property_and_methods(
        PLAYER_CLASS_NAME,
        "max_vertical_speed",
        "get_max_vertical_speed",
        "set_max_vertical_speed",
        get_max_vertical_speed,
        set_max_vertical_speed,
        static_strings = true,
    )

    classdb.bind_signal(Player, "stepped_up", struct { distance: f64 })
    classdb.bind_signal(Player, "stepped_down", struct { distance: f64 })
}
