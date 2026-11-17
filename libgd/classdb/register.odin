package libgd_classdb

import "base:intrinsics"
import "base:runtime"
import "core:reflect"
import "core:strings"
import "godot:gdext"
import "godot:godot"

Class_VTable :: struct($T: typeid) {
    init:            proc(self: ^T),
    deinit:          proc(self: ^T),
    ready:           proc(self: ^T),
    process:         proc(self: ^T, delta: f64),
    physics_process: proc(self: ^T, delta: f64),
    input:           proc(self: ^T, event: godot.Input_Event),
    unhandled_input: proc(self: ^T, event: godot.Input_Event),
    enter_tree:      proc(self: ^T),
    exit_tree:       proc(self: ^T),
    notification:    proc(self: ^T, what: i32),
    to_string:       proc(self: ^T) -> godot.String,
}

Class_VTable_Contextless :: struct($T: typeid) {
    init:            proc "contextless" (self: ^T),
    deinit:          proc "contextless" (self: ^T),
    ready:           proc "contextless" (self: ^T),
    process:         proc "contextless" (self: ^T, delta: f64),
    physics_process: proc "contextless" (self: ^T, delta: f64),
    input:           proc "contextless" (self: ^T, event: godot.Input_Event),
    unhandled_input: proc "contextless" (self: ^T, event: godot.Input_Event),
    enter_tree:      proc "contextless" (self: ^T),
    exit_tree:       proc "contextless" (self: ^T),
    notification:    proc "contextless" (self: ^T, what: i32),
    to_string:       proc "contextless" (self: ^T) -> godot.String,
}

Virtual_Method_Id :: enum {
    Ready,
    Enter_Tree,
    Exit_Tree,
    Process,
    Physics_Process,
    Input,
    Unhandled_Input,
    Notification,
    To_String,
}

Virtual_Call_Data :: struct {
    meta:      rawptr,
    method_id: Virtual_Method_Id,
}

Class_Metadata :: struct($T: typeid) {
    class_name:        godot.String_Name,
    base_class_name:   godot.String_Name,
    binding_callbacks: gdext.InstanceBindingCallbacks,
    base_field_offset: int,
    vtable:            Class_VTable(T),
    call_data:         [Virtual_Method_Id]Virtual_Call_Data,
}

Class_Metadata_Contextless :: struct($T: typeid) {
    class_name:        godot.String_Name,
    base_class_name:   godot.String_Name,
    binding_callbacks: gdext.InstanceBindingCallbacks,
    base_field_offset: int,
    vtable:            Class_VTable_Contextless(T),
    call_data:         [Virtual_Method_Id]Virtual_Call_Data,
}

Virtual_Names :: struct {
    ready:           godot.String_Name,
    enter_tree:      godot.String_Name,
    exit_tree:       godot.String_Name,
    process:         godot.String_Name,
    physics_process: godot.String_Name,
    input:           godot.String_Name,
    unhandled_input: godot.String_Name,
    notification:    godot.String_Name,
    to_string:       godot.String_Name,
    initialized:     bool,
}

@(private)
virtual_names: Virtual_Names

@(private)
class_name_map: map[typeid]godot.String_Name

@(private)
string_name_cache: map[string]godot.String_Name

@(private)
registered_classes: [dynamic]godot.String_Name

init_virtual_names :: proc "contextless" () {
    if virtual_names.initialized do return
    virtual_names.ready = godot.new_string_name_cstring("_ready", true)
    virtual_names.enter_tree = godot.new_string_name_cstring("_enter_tree", true)
    virtual_names.exit_tree = godot.new_string_name_cstring("_exit_tree", true)
    virtual_names.process = godot.new_string_name_cstring("_process", true)
    virtual_names.physics_process = godot.new_string_name_cstring("_physics_process", true)
    virtual_names.input = godot.new_string_name_cstring("_input", true)
    virtual_names.unhandled_input = godot.new_string_name_cstring("_unhandled_input", true)
    virtual_names.notification = godot.new_string_name_cstring("_notification", true)
    virtual_names.to_string = godot.new_string_name_cstring("_to_string", true)
    virtual_names.initialized = true
}

get_or_create_string_name :: proc(str: string) -> ^godot.String_Name {
    if sn, ok := &string_name_cache[str]; ok {
        return sn
    }
    key := strings.clone(str)
    string_name_cache[key] = godot.new_string_name_odin(key)
    return &string_name_cache[key]
}

get_class_name :: proc(T: typeid) -> ^godot.String_Name {
    if name, ok := &class_name_map[T]; ok {
        return name
    }
    if named, ok := type_info_of(T).variant.(runtime.Type_Info_Named); ok {
        class_name_map[T] = godot.new_string_name_odin(named.name)
        return &class_name_map[T]
    }
    return nil
}

find_base_field_offset :: proc($T: typeid) -> int {
    #assert(intrinsics.type_is_struct(T), "T must be a struct")
    if field := reflect.struct_field_by_name(T, "base"); field.name != "" {
        return int(field.offset)
    }
    if field := reflect.struct_field_by_name(T, "object"); field.name != "" {
        return int(field.offset)
    }
    return -1
}

find_base_class_name :: proc($T: typeid) -> string {
    #assert(intrinsics.type_is_struct(T), "T must be a struct")
    if field := reflect.struct_field_by_name(T, "base"); field.name != "" {
        if tag_val, ok := reflect.struct_tag_lookup(field.tag, "gd"); ok {
            return tag_val
        }
        if tag_val, ok := reflect.struct_tag_lookup(field.tag, "extends"); ok {
            return tag_val
        }
    }
    if field := reflect.struct_field_by_name(T, "object"); field.name != "" {
        if tag_val, ok := reflect.struct_tag_lookup(field.tag, "gd"); ok {
            return tag_val
        }
        if tag_val, ok := reflect.struct_tag_lookup(field.tag, "extends"); ok {
            return tag_val
        }
    }
    return ""
}

register_class :: proc {
    register_class_vtable,
    register_class_vtable_contextless,
    register_class_simple,
    register_class_vtable_auto,
    register_class_vtable_contextless_auto,
    register_class_simple_auto,
}

register_class_simple_auto :: proc($T: typeid, class_name := "") {
    inherits := find_base_class_name(T)
    if inherits == "" {
        inherits = "Node"
    }
    register_class_vtable(T, inherits, Class_VTable(T){}, class_name)
    bind_fields(T)
}

register_class_vtable_auto :: proc($T: typeid, vtable: Class_VTable(T), class_name := "") {
    inherits := find_base_class_name(T)
    if inherits == "" {
        inherits = "Node"
    }
    register_class_vtable(T, inherits, vtable, class_name)
    bind_fields(T)
}

register_class_vtable_contextless_auto :: proc($T: typeid, vtable: Class_VTable_Contextless(T), class_name := "") {
    inherits := find_base_class_name(T)
    if inherits == "" {
        inherits = "Node"
    }
    register_class_vtable_contextless(T, inherits, vtable, class_name)
    bind_fields(T)
}

register_class_simple :: proc($T: typeid, inherits: string, class_name := "") {
    register_class_vtable(T, inherits, Class_VTable(T){}, class_name)
}

register_class_vtable :: proc($T: typeid, inherits: string, vtable: Class_VTable(T), class_name := "") {
    #assert(intrinsics.type_is_struct(T), "T must be a struct")

    c_name := class_name
    if c_name == "" {
        if named, ok := type_info_of(T).variant.(runtime.Type_Info_Named); ok {
            c_name = named.name
        }
    }

    meta := new(Class_Metadata(T))
    meta.class_name = godot.new_string_name_odin(c_name)
    meta.base_class_name = godot.new_string_name_odin(inherits)
    meta.base_field_offset = find_base_field_offset(T)
    meta.vtable = vtable

    class_name_map[typeid_of(T)] = meta.class_name

    for id in Virtual_Method_Id {
        meta.call_data[id] = Virtual_Call_Data {
            meta      = meta,
            method_id = id,
        }
    }

    create_instance :: proc "c" (class_user_data: rawptr) -> gdext.ObjectPtr {
        context = gdext.godot_context()
        meta := cast(^Class_Metadata(T))class_user_data

        base_obj := gdext.classdb_construct_object(&meta.base_class_name)
        if base_obj == nil {
            return nil
        }

        instance := new(T)
        if meta.base_field_offset >= 0 {
            base_ptr := cast(^gdext.ObjectPtr)(uintptr(instance) + uintptr(meta.base_field_offset))
            base_ptr^ = base_obj
        }

        gdext.object_set_instance(base_obj, &meta.class_name, instance)
        gdext.object_set_instance_binding(base_obj, gdext.library, instance, &meta.binding_callbacks)

        if meta.vtable.init != nil {
            meta.vtable.init(instance)
        }

        return base_obj
    }

    free_instance :: proc "c" (class_user_data: rawptr, instance: gdext.ExtensionClassInstancePtr) {
        if instance == nil do return
        context = gdext.godot_context()
        meta := cast(^Class_Metadata(T))class_user_data
        self := cast(^T)instance

        if meta.vtable.deinit != nil {
            meta.vtable.deinit(self)
        }

        free(self)
    }

    get_virtual_call_data :: proc "c" (class_user_data: rawptr, name: gdext.StringNamePtr) -> rawptr {
        meta := cast(^Class_Metadata(T))class_user_data
        name_ptr := cast(^godot.String_Name)name

        init_virtual_names()

        if meta.vtable.process != nil && godot.string_name_equal(name_ptr^, virtual_names.process) {
            return &meta.call_data[.Process]
        }
        if meta.vtable.ready != nil && godot.string_name_equal(name_ptr^, virtual_names.ready) {
            return &meta.call_data[.Ready]
        }
        if meta.vtable.physics_process != nil && godot.string_name_equal(name_ptr^, virtual_names.physics_process) {
            return &meta.call_data[.Physics_Process]
        }
        if meta.vtable.input != nil && godot.string_name_equal(name_ptr^, virtual_names.input) {
            return &meta.call_data[.Input]
        }
        if meta.vtable.unhandled_input != nil && godot.string_name_equal(name_ptr^, virtual_names.unhandled_input) {
            return &meta.call_data[.Unhandled_Input]
        }
        if meta.vtable.enter_tree != nil && godot.string_name_equal(name_ptr^, virtual_names.enter_tree) {
            return &meta.call_data[.Enter_Tree]
        }
        if meta.vtable.exit_tree != nil && godot.string_name_equal(name_ptr^, virtual_names.exit_tree) {
            return &meta.call_data[.Exit_Tree]
        }
        if meta.vtable.notification != nil && godot.string_name_equal(name_ptr^, virtual_names.notification) {
            return &meta.call_data[.Notification]
        }
        if meta.vtable.to_string != nil && godot.string_name_equal(name_ptr^, virtual_names.to_string) {
            return &meta.call_data[.To_String]
        }

        return nil
    }

    call_virtual_with_data :: proc "c" (
        instance: gdext.ExtensionClassInstancePtr,
        name: gdext.StringNamePtr,
        virtual_call_user_data: rawptr,
        args: [^]gdext.TypePtr,
        ret: gdext.TypePtr,
    ) {
        if virtual_call_user_data == nil do return
        context = gdext.godot_context()

        cd := cast(^Virtual_Call_Data)virtual_call_user_data
        meta := cast(^Class_Metadata(T))cd.meta
        self := cast(^T)instance

        switch cd.method_id {
        case .Process:
            delta := (cast(^f64)args[0])^
            meta.vtable.process(self, delta)
        case .Physics_Process:
            delta := (cast(^f64)args[0])^
            meta.vtable.physics_process(self, delta)
        case .Ready:
            meta.vtable.ready(self)
        case .Input:
            event := (cast(^godot.Input_Event)args[0])^
            meta.vtable.input(self, event)
        case .Unhandled_Input:
            event := (cast(^godot.Input_Event)args[0])^
            meta.vtable.unhandled_input(self, event)
        case .Enter_Tree:
            meta.vtable.enter_tree(self)
        case .Exit_Tree:
            meta.vtable.exit_tree(self)
        case .Notification:
            what := (cast(^i32)args[0])^
            meta.vtable.notification(self, what)
        case .To_String:
            str := meta.vtable.to_string(self)
            (cast(^godot.String)ret)^ = str
        }
    }

    class_info := gdext.ExtensionClassCreationInfo2 {
        is_virtual                  = false,
        is_abstract                 = false,
        is_exposed                  = true,
        create_instance_func        = create_instance,
        free_instance_func          = free_instance,
        get_virtual_call_data_func  = get_virtual_call_data,
        call_virtual_with_data_func = call_virtual_with_data,
        class_userdata              = meta,
    }

    gdext.classdb_register_extension_class2(gdext.library, &meta.class_name, &meta.base_class_name, &class_info)
    append(&registered_classes, meta.class_name)
}

register_class_vtable_contextless :: proc(
    $T: typeid,
    inherits: string,
    vtable: Class_VTable_Contextless(T),
    class_name := "",
) {
    #assert(intrinsics.type_is_struct(T), "T must be a struct")

    c_name := class_name
    if c_name == "" {
        if named, ok := type_info_of(T).variant.(runtime.Type_Info_Named); ok {
            c_name = named.name
        }
    }

    meta := new(Class_Metadata_Contextless(T))
    meta.class_name = godot.new_string_name_odin(c_name)
    meta.base_class_name = godot.new_string_name_odin(inherits)
    meta.base_field_offset = find_base_field_offset(T)
    meta.vtable = vtable

    class_name_map[typeid_of(T)] = meta.class_name

    for id in Virtual_Method_Id {
        meta.call_data[id] = Virtual_Call_Data {
            meta      = meta,
            method_id = id,
        }
    }

    create_instance :: proc "c" (class_user_data: rawptr) -> gdext.ObjectPtr {
        context = gdext.godot_context()
        meta := cast(^Class_Metadata_Contextless(T))class_user_data

        base_obj := gdext.classdb_construct_object(&meta.base_class_name)
        if base_obj == nil {
            return nil
        }

        instance := new(T)
        if meta.base_field_offset >= 0 {
            base_ptr := cast(^gdext.ObjectPtr)(uintptr(instance) + uintptr(meta.base_field_offset))
            base_ptr^ = base_obj
        }

        gdext.object_set_instance(base_obj, &meta.class_name, instance)
        gdext.object_set_instance_binding(base_obj, gdext.library, instance, &meta.binding_callbacks)

        if meta.vtable.init != nil {
            meta.vtable.init(instance)
        }

        return base_obj
    }

    free_instance :: proc "c" (class_user_data: rawptr, instance: gdext.ExtensionClassInstancePtr) {
        if instance == nil do return
        context = gdext.godot_context()
        meta := cast(^Class_Metadata_Contextless(T))class_user_data
        self := cast(^T)instance

        if meta.vtable.deinit != nil {
            meta.vtable.deinit(self)
        }

        free(self)
    }

    get_virtual_call_data :: proc "c" (class_user_data: rawptr, name: gdext.StringNamePtr) -> rawptr {
        meta := cast(^Class_Metadata_Contextless(T))class_user_data
        name_ptr := cast(^godot.String_Name)name

        init_virtual_names()

        if meta.vtable.process != nil && godot.string_name_equal(name_ptr^, virtual_names.process) {
            return &meta.call_data[.Process]
        }
        if meta.vtable.ready != nil && godot.string_name_equal(name_ptr^, virtual_names.ready) {
            return &meta.call_data[.Ready]
        }
        if meta.vtable.physics_process != nil && godot.string_name_equal(name_ptr^, virtual_names.physics_process) {
            return &meta.call_data[.Physics_Process]
        }
        if meta.vtable.input != nil && godot.string_name_equal(name_ptr^, virtual_names.input) {
            return &meta.call_data[.Input]
        }
        if meta.vtable.unhandled_input != nil && godot.string_name_equal(name_ptr^, virtual_names.unhandled_input) {
            return &meta.call_data[.Unhandled_Input]
        }
        if meta.vtable.enter_tree != nil && godot.string_name_equal(name_ptr^, virtual_names.enter_tree) {
            return &meta.call_data[.Enter_Tree]
        }
        if meta.vtable.exit_tree != nil && godot.string_name_equal(name_ptr^, virtual_names.exit_tree) {
            return &meta.call_data[.Exit_Tree]
        }
        if meta.vtable.notification != nil && godot.string_name_equal(name_ptr^, virtual_names.notification) {
            return &meta.call_data[.Notification]
        }
        if meta.vtable.to_string != nil && godot.string_name_equal(name_ptr^, virtual_names.to_string) {
            return &meta.call_data[.To_String]
        }

        return nil
    }

    call_virtual_with_data :: proc "c" (
        instance: gdext.ExtensionClassInstancePtr,
        name: gdext.StringNamePtr,
        virtual_call_user_data: rawptr,
        args: [^]gdext.TypePtr,
        ret: gdext.TypePtr,
    ) {
        if virtual_call_user_data == nil do return
        context = gdext.godot_context()

        cd := cast(^Virtual_Call_Data)virtual_call_user_data
        meta := cast(^Class_Metadata_Contextless(T))cd.meta
        self := cast(^T)instance

        switch cd.method_id {
        case .Process:
            delta := (cast(^f64)args[0])^
            meta.vtable.process(self, delta)
        case .Physics_Process:
            delta := (cast(^f64)args[0])^
            meta.vtable.physics_process(self, delta)
        case .Ready:
            meta.vtable.ready(self)
        case .Input:
            event := (cast(^godot.Input_Event)args[0])^
            meta.vtable.input(self, event)
        case .Unhandled_Input:
            event := (cast(^godot.Input_Event)args[0])^
            meta.vtable.unhandled_input(self, event)
        case .Enter_Tree:
            meta.vtable.enter_tree(self)
        case .Exit_Tree:
            meta.vtable.exit_tree(self)
        case .Notification:
            what := (cast(^i32)args[0])^
            meta.vtable.notification(self, what)
        case .To_String:
            str := meta.vtable.to_string(self)
            (cast(^godot.String)ret)^ = str
        }
    }

    class_info := gdext.ExtensionClassCreationInfo2 {
        is_virtual                  = false,
        is_abstract                 = false,
        is_exposed                  = true,
        create_instance_func        = create_instance,
        free_instance_func          = free_instance,
        get_virtual_call_data_func  = get_virtual_call_data,
        call_virtual_with_data_func = call_virtual_with_data,
        class_userdata              = meta,
    }

    gdext.classdb_register_extension_class2(gdext.library, &meta.class_name, &meta.base_class_name, &class_info)
    append(&registered_classes, meta.class_name)
}

unregister_class :: proc {
    unregister_class_type,
    unregister_class_string,
    unregister_class_gdstringname,
}

unregister_class_gdstringname :: proc(class_name: ^godot.String_Name) {
    gdext.classdb_unregister_extension_class(gdext.library, cast(gdext.StringNamePtr)class_name)
    for i := len(registered_classes) - 1; i >= 0; i -= 1 {
        if godot.string_name_equal(registered_classes[i], class_name^) {
            ordered_remove(&registered_classes, i)
            break
        }
    }
}

unregister_class_string :: proc(class_name: string) {
    if sn, ok := &string_name_cache[class_name]; ok {
        unregister_class_gdstringname(sn)
        return
    }
    sn := godot.new_string_name_odin(class_name)
    defer godot.free_string_name(sn)
    unregister_class_gdstringname(&sn)
}

unregister_class_type :: proc($T: typeid, class_name := "") {
    if class_name != "" {
        unregister_class_string(class_name)
        return
    }
    if sn := get_class_name(T); sn != nil {
        unregister_class_gdstringname(sn)
    }
}

unregister_all_classes :: proc() {
    #reverse for &name in registered_classes {
        gdext.classdb_unregister_extension_class(gdext.library, cast(gdext.StringNamePtr)&name)
    }
    clear(&registered_classes)
}
