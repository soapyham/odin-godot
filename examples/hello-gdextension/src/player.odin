package example

import "godot:godot"
import "godot:libgd"
import "godot:libgd/classdb"


Player :: struct {
    base:        godot.Sprite2d `gd:"Sprite2D"`,
    amplitude:   f64 `gd:"export"`,
    speed:       f64 `gd:"export,range:0.0..1000.0:1.0:or_greater"`,
    time_emit:   f64,
    time_passed: f64,
}

set_player_speed :: proc "contextless" (self: ^Player, speed: f64) {
    self.speed = speed
}

get_player_speed :: proc "contextless" (self: ^Player) -> f64 {
    return self.speed
}

player_class_register :: proc() {
    classdb.register_class(
        Player,
        classdb.Class_VTable(Player) {
            init = proc(self: ^Player) {
                self.amplitude = 1.0
                self.speed = 5000.0
                self.time_passed = 0.0
                self.time_emit = 5.0
            },
            ready = proc(self: ^Player) {
                if godot.engine_is_editor_hint(godot.singleton_engine()) {
                    return
                }
                godot.node_set_physics_process(self.base, true)
            },
            physics_process = proc(self: ^Player, delta: f64) {
                if godot.engine_is_editor_hint(godot.singleton_engine()) {
                    return
                }

                neg_x := "move_left"
                pos_x := "move_right"
                neg_y := "move_up"
                pos_y := "move_down"

                if !bool(godot.input_map_has_action(godot.singleton_input_map(), neg_x)) {
                    neg_x = "ui_left"
                    pos_x = "ui_right"
                    neg_y = "ui_up"
                    pos_y = "ui_down"
                }

                input_dir := libgd.get_input_vector(neg_x, pos_x, neg_y, pos_y)
                pos := godot.node2d_get_position(self.base)
                pos += input_dir * godot.Real(self.speed * delta)
                godot.node2d_set_position(self.base, pos)
            },
        },
    )
    classdb.bind_signal(Player, "time_passed", struct { time_passed: f64 })
}
