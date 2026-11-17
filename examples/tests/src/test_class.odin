package test

import "godot:gdext"
import "godot:libgd/classdb"
import "godot:godot"

Test_Class :: struct {
    object: gdext.ObjectPtr,
    vector: godot.Vector2,
}

@(private = "file")
set_vector :: proc "contextless" (self: ^Test_Class, vector: godot.Vector2) {
    self.vector = vector
}

@(private = "file")
get_vector :: proc "contextless" (self: ^Test_Class) -> godot.Vector2 {
    return self.vector
}

@(private = "file")
vector_eq :: proc "contextless" (self: ^Test_Class, other: godot.Vector2) -> bool {
    return self.vector == other
}

@(private = "file")
vector_neq :: proc "contextless" (self: ^Test_Class, other: godot.Vector2) -> bool {
    return self.vector != other
}

@(private = "file")
vector_add :: proc "contextless" (self: ^Test_Class, other: godot.Vector2) -> godot.Vector2 {
    return self.vector + other
}

@(private = "file")
vector_sub :: proc "contextless" (self: ^Test_Class, other: godot.Vector2) -> godot.Vector2 {
    return self.vector - other
}

test_class_register :: proc() {
    classdb.register_class(Test_Class, "Node", "Test")
    test_class_name := classdb.get_class_name(Test_Class)

    get_vector_name := godot.new_string_name_cstring("get_vector", true)
    set_vector_name := godot.new_string_name_cstring("set_vector", true)
    vector_name := godot.new_string_name_cstring("vector", true)
    classdb.bind_property_and_methods(
        test_class_name,
        &vector_name,
        &get_vector_name,
        &set_vector_name,
        get_vector,
        set_vector,
    )

    other_name := godot.new_string_name_cstring("other", true)
    vector_eq_name := godot.new_string_name_cstring("vector_eq", true)
    classdb.bind_returning_method(test_class_name, &vector_eq_name, vector_eq, &other_name)

    vector_neq_name := godot.new_string_name_cstring("vector_neq", true)
    classdb.bind_returning_method(test_class_name, &vector_neq_name, vector_neq, &other_name)

    vector_add_name := godot.new_string_name_cstring("vector_add", true)
    classdb.bind_returning_method(test_class_name, &vector_add_name, vector_add, &other_name)

    vector_sub_name := godot.new_string_name_cstring("vector_sub", true)
    classdb.bind_returning_method(test_class_name, &vector_sub_name, vector_sub, &other_name)
}
