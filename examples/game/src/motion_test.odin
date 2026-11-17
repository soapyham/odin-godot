package game

import "core:math/linalg"
import "godot:godot"

PhysicsMotion :: struct {
    params:    godot.Physics_Test_Motion_Parameters3d,
    result:    godot.Physics_Test_Motion_Result3d,
    last_hit:  bool,
    rid:       godot.Rid,
    remainder: godot.Vector3,
    travel:    godot.Vector3,
    distance:  godot.Real,
    normal:    godot.Vector3,
}

new_physics_motion :: proc(rid: godot.Rid, margin: f32) -> PhysicsMotion {
    mt := PhysicsMotion {
        params   = godot.new_physics_test_motion_parameters3d(),
        result   = godot.new_physics_test_motion_result3d(),
        last_hit = false,
        rid      = rid,
    }

    godot.physics_test_motion_parameters3d_set_margin(mt.params, margin)
    return mt
}

physics_motion_test :: proc(motion: ^PhysicsMotion, from: godot.Transform3d, move: godot.Vector3) -> bool {
    godot.physics_test_motion_parameters3d_set_from(motion.params, from)
    godot.physics_test_motion_parameters3d_set_motion(motion.params, move)
    motion.last_hit = bool(godot.physics_server3d_body_test_motion(
        godot.singleton_physics_server3d(),
        motion.rid,
        motion.params,
        motion.result,
    ))

    if motion.last_hit {
        motion.remainder = godot.physics_test_motion_result3d_get_remainder(motion.result)
        motion.travel = godot.physics_test_motion_result3d_get_travel(motion.result)
        motion.distance = linalg.length(motion.travel)
        motion.normal = godot.physics_test_motion_result3d_get_collision_normal(motion.result, 0)
    }

    return motion.last_hit
}

