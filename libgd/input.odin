package libgd

import "godot:godot"

get_input_vector :: proc {
    get_input_vector_strings,
    get_input_vector_cstring_legacy,
}

get_input_vector_strings :: proc "contextless" (
    negative_x := "ui_left",
    positive_x := "ui_right",
    negative_y := "ui_up",
    positive_y := "ui_down",
) -> godot.Vector2 {
    return godot.input_get_vector(
        godot.singleton_input(),
        godot.sn(negative_x),
        godot.sn(positive_x),
        godot.sn(negative_y),
        godot.sn(positive_y),
        -1.0,
    )
}

get_input_vector_cstring_legacy :: proc "contextless" (
    negative_x: cstring,
    positive_x: cstring,
    negative_y: cstring,
    positive_y: cstring,
    static: bool,
) -> godot.Vector2 {
    return godot.input_get_vector(
        godot.singleton_input(),
        godot.sn(string(negative_x)),
        godot.sn(string(positive_x)),
        godot.sn(string(negative_y)),
        godot.sn(string(positive_y)),
        -1.0,
    )
}

is_physical_key_pressed :: proc {
    is_physical_key_pressed_input,
    is_physical_key_pressed_auto,
}

is_physical_key_pressed_down :: proc {
    is_physical_key_pressed_down_input,
    is_physical_key_pressed_down_auto,
}

is_physical_key_released :: proc {
    is_physical_key_released_input,
    is_physical_key_released_auto,
}

is_physical_key_pressed_input :: proc "contextless" (input: godot.Input, key: godot.Key) -> bool {
    return bool(godot.input_is_physical_key_pressed(input, key))
}

is_physical_key_pressed_auto :: proc "contextless" (key: godot.Key) -> bool {
    return bool(godot.input_is_physical_key_pressed(godot.singleton_input(), key))
}

is_physical_key_pressed_down_input :: proc "contextless" (input: godot.Input, key: godot.Key) -> bool {
    return bool(godot.input_is_physical_key_pressed_down(input, key))
}

is_physical_key_pressed_down_auto :: proc "contextless" (key: godot.Key) -> bool {
    return bool(godot.input_is_physical_key_pressed_down(godot.singleton_input(), key))
}

is_physical_key_released_input :: proc "contextless" (input: godot.Input, key: godot.Key) -> bool {
    return bool(godot.input_is_physical_key_released(input, key))
}

is_physical_key_released_auto :: proc "contextless" (key: godot.Key) -> bool {
    return bool(godot.input_is_physical_key_released(godot.singleton_input(), key))
}

input_is_physical_key_pressed :: is_physical_key_pressed
input_is_physical_key_pressed_down :: is_physical_key_pressed_down
input_is_physical_key_released :: is_physical_key_released

is_key_pressed :: proc {
    is_key_pressed_input,
    is_key_pressed_auto,
}

is_key_pressed_down :: proc {
    is_key_pressed_down_input,
    is_key_pressed_down_auto,
}

is_key_released :: proc {
    is_key_released_input,
    is_key_released_auto,
}

is_key_pressed_input :: proc "contextless" (input: godot.Input, key: godot.Key) -> bool {
    return bool(godot.input_is_key_pressed(input, key))
}

is_key_pressed_auto :: proc "contextless" (key: godot.Key) -> bool {
    return bool(godot.input_is_key_pressed(godot.singleton_input(), key))
}

is_key_pressed_down_input :: proc "contextless" (input: godot.Input, key: godot.Key) -> bool {
    return bool(godot.input_is_key_pressed_down(input, key))
}

is_key_pressed_down_auto :: proc "contextless" (key: godot.Key) -> bool {
    return bool(godot.input_is_key_pressed_down(godot.singleton_input(), key))
}

is_key_released_input :: proc "contextless" (input: godot.Input, key: godot.Key) -> bool {
    return bool(godot.input_is_key_released(input, key))
}

is_key_released_auto :: proc "contextless" (key: godot.Key) -> bool {
    return bool(godot.input_is_key_released(godot.singleton_input(), key))
}

input_is_key_pressed :: is_key_pressed
input_is_key_pressed_down :: is_key_pressed_down
input_is_key_released :: is_key_released

is_action_pressed :: proc "contextless" (action: godot.String_Name_Arg, exact_match := false) -> bool {
    return bool(godot.input_is_action_pressed(godot.singleton_input(), action, godot.Bool(exact_match)))
}

is_action_just_pressed :: proc "contextless" (action: godot.String_Name_Arg, exact_match := false) -> bool {
    return bool(godot.input_is_action_just_pressed(godot.singleton_input(), action, godot.Bool(exact_match)))
}

is_action_just_released :: proc "contextless" (action: godot.String_Name_Arg, exact_match := false) -> bool {
    return bool(godot.input_is_action_just_released(godot.singleton_input(), action, godot.Bool(exact_match)))
}

/*
    Copyright 2025 Dresses Digital

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
