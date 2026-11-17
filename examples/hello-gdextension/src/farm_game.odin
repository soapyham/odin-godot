package example

import "core:fmt"
import "godot:gdext"
import "godot:godot"
import "godot:libgd/classdb"

Rect :: distinct [4]f32

@(private = "file")
Action_Callback :: struct {
    cb: proc(g: ^Farm_Game),
    t:  enum {
        Pressed,
        Down,
        Released,
    },
}

Plot :: struct {
    rect:   Rect,
    plants: #soa[dynamic]Plant,
}

Plant :: struct {
    kind:           enum {
        Wheat,
        Corn,
    },
    growth_percent: f32,
}

Farm_Game :: struct {
    base:       godot.Node3d `gd:"Node3D"`,
    hud:        Hud,
    state:      enum {
        Editor,
        Game,
        Closing,
    },
    camera:     struct {
        r:   godot.Camera3d,
        pos: Vec2,
    },
    label:      godot.Label,
    input_maps: map[godot.Key]Action_Callback,
    plots:      #soa[dynamic]Plot,
    sim_speed:  f32, // sim speed multiplier
    tilemap: godot.Tile_Map_Layer,
}

@(private = "file")
register_input_map :: proc(self: ^Farm_Game) {
    context = gdext.godot_context()
    self.input_maps[.Escape] = Action_Callback {
        cb = proc(g: ^Farm_Game) {
            g.state = .Closing
        },
        t = .Released,
    }
}

farm_game_register :: proc() {
    classdb.register_class(
        Farm_Game,
        classdb.Class_VTable(Farm_Game) {
            init = proc(self: ^Farm_Game) {
            },
            deinit = proc(self: ^Farm_Game) {
            },
            ready = proc(self: ^Farm_Game) {
                if godot.engine_is_editor_hint(godot.singleton_engine()) {
                    self.state = .Editor
                } else {
                    self.state = .Game
                }

                #partial switch self.state {
                case .Game:
                    self.label = godot.node_get_node(self.base, "HUD/Main/Label")
                    self.camera.r = godot.node_get_node(self.base, "Camera3D")
                    //self.tilemap = godot.node_get_path(self.base, "Tilemap")

                    godot.node3d_set_position(self.camera.r, {0, 2, 1})
                    godot.node3d_set_rotation_degrees(self.camera.r, {-45, 0, 0})
                    register_input_map(self)
                    godot.node_set_physics_process(self.base, true)
                    godot.node_set_process_unhandled_input(self.base, true)

                    plot := Plot {

                    }

                    wheat_plant := Plant {
                    	.Wheat,
                     	0,
                    }

                    godot.node_add_to_group(self.base, "plants", false)

                    append_soa(&plot.plants, wheat_plant)
                    append_soa(&self.plots, plot)

                    append_soa(&self.plots, plot)

                }

            },
            unhandled_input = proc(self: ^Farm_Game, e: godot.Input_Event) {
                if bool(godot.input_event_is_action_released(e, "escape", true)) {
                    //self.state = .Closing
                }
            },
            physics_process = proc(self: ^Farm_Game, delta: f64) {
                input := godot.singleton_input()
                #partial switch self.state {
                case .Game:
                    self.camera.pos += {5, 5}

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

                    for &plot in self.plots {
                        for &p in plot.plants {
                            p.growth_percent += f32(0.1 * delta) * self.sim_speed
                        }
                    }

                    godot.label_set_text(self.label, fmt.tprintf("%v", self.plots))

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
    //classdb.bind_field(Farm_Game, "label", offset_of(Farm_Game, label), class_name = "Label",  f64)
    // classdb.bind_field(
    //     Player,
    //     "speed",
    //     offset_of(Player, speed),
    //     f64,
    //     hint = .Range,
    //     hint_string = "0.0,1000.0,1.0,or_greater",
    // )
    // classdb.bind_signal(Player, "time_passed", "time_passed", f64)
    //classdb.bind_field(Farm_Game, "lives", offset_of(Farm_Game, lives), u8)
    //classdb.bind_property(Farm_Game, "state_test", get_state, set_state)
    //classdb.bind_void_method(Farm_Game, "restart", restart)
}
