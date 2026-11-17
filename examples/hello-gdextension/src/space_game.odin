package example

import "godot:godot"
import "godot:libgd/classdb"
import "godot:gdext"

Vec2 :: distinct [2]f32

Action_Callback :: struct {
    cb: proc(g: ^Space_Game),
    t:  enum {
        Pressed,
        Down,
        Released,
    },
}

Space_Game :: struct {
    base:       godot.Node3d `gd:"Node3D"`,
    hud:        Hud,
    lives:      u8,
    state:      enum {
        Editor,
        Game,
        Closing,
    },
    state_test: godot.String,
    player:     struct {
        pos: Vec2,
    },
    label:      godot.Label,
    camera:     godot.Camera3d,
    input_maps: map[godot.Key]Action_Callback,
}

@(private = "file")
set_state :: proc "contextless" (self: ^Space_Game, state: godot.String) {
    self.state_test = state
    godot.label_set_text(self.label, state)
}
@(private = "file")
get_state :: proc "contextless" (self: ^Space_Game) -> godot.String {
    return self.state_test
}

@(private = "file")
restart :: proc "contextless" (self: ^Space_Game) {
}

@(private = "file")
register_input_map :: proc(self: ^Space_Game) {
    context = gdext.godot_context()
    self.input_maps[.Escape] = Action_Callback {
        cb = proc(g: ^Space_Game) {
            g.state = .Closing
        },
        t = .Released,
    }
}

space_game_register :: proc() {
    classdb.register_class(
        Space_Game,
        classdb.Class_VTable(Space_Game) {
            init = proc(self: ^Space_Game) {
            },
            deinit = proc(self: ^Space_Game) {
            },
            ready = proc(self: ^Space_Game) {
                if godot.engine_is_editor_hint(godot.singleton_engine()) {
                    self.state = .Editor
                } else {
                    self.state = .Game
                }

                self.label = godot.node_get_node(self.base, "HUD/Main/Label")
                self.camera = godot.node_get_node(self.base, "Camera3D")

                godot.node3d_set_position(self.camera, {0, 2, 1})
                godot.node3d_set_rotation_degrees(self.camera, {-45, 0, 0})

                #partial switch self.state {
                case .Game:
                    register_input_map(self)
                    godot.node_set_physics_process(self.base, true)
                    godot.node_set_process_unhandled_input(self.base, true)
                }

            },
            unhandled_input = proc(self: ^Space_Game, e: godot.Input_Event) {
	            if bool(godot.input_event_is_action_released(e, "escape", true)) {
	            	//self.state = .Closing
	            }
            },
            physics_process = proc(self: ^Space_Game, delta: f64) {
                input := godot.singleton_input()
                #partial switch self.state {
                case .Game:
                    self.player.pos += {5, 5}

                    for action_key, action_callback in self.input_maps {
                        triggered := false
                        switch action_callback.t {
                        case .Pressed:
                            triggered = bool(godot.input_is_physical_key_pressed(input, action_key))
                        case .Down:
                            triggered = bool(godot.input_is_physical_key_pressed_down(input, action_key))
                        case .Released:
                            triggered = bool(godot.input_is_physical_key_released(input, action_key))
                        }
                        if triggered {
                            action_callback.cb(self)
                        }
                    }

                case .Closing:
                    tree := godot.node_get_tree(self.base)
                    godot.scene_tree_quit(tree, 0)
                }

                //                 neg_x := cstring("move_left")
                //                 pos_x := cstring("move_right")
                //                 neg_y := cstring("move_up")
                //                 pos_y := cstring("move_down")
                //
                //                 sn_move_left := godot.new_string_name(neg_x, true)
                //                 if !bool(godot.input_map_has_action(godot.singleton_input_map(), sn_move_left)) {
                //                     neg_x = "ui_left"
                //                     pos_x = "ui_right"
                //                     neg_y = "ui_up"
                //                     pos_y = "ui_down"
                //                 }

                //input_dir := libgd.get_input_vector(neg_x, pos_x, neg_y, pos_y, true)
                //pos := godot.node2d_get_position(self.base)
                //pos += input_dir * godot.Real(self.speed * delta)
                //godot.node2d_set_position(self.base, pos)
            },
        },
    )
    //classdb.bind_field(Space_Game, "label", offset_of(Space_Game, label), class_name = "Label",  f64)
    // classdb.bind_field(
    //     Player,
    //     "speed",
    //     offset_of(Player, speed),
    //     f64,
    //     hint = .Range,
    //     hint_string = "0.0,1000.0,1.0,or_greater",
    // )
    // classdb.bind_signal(Player, "time_passed", "time_passed", f64)
    //classdb.bind_field(Space_Game, "lives", offset_of(Space_Game, lives), u8)
    //classdb.bind_property(Space_Game, "state_test", get_state, set_state)
    classdb.bind_void_method(Space_Game, "restart", restart)
}
