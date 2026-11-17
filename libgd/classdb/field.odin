package libgd_classdb

import "base:intrinsics"
import "base:runtime"
import "core:fmt"
import "core:reflect"
import "core:strings"
import "godot:gdext"
import "godot:godot"

Generic_Field_Data :: struct {
    offset:       uintptr,
    size:         int,
    variant_type: gdext.Variant_Type,
}

@(private)
generic_field_pool: [dynamic]^Generic_Field_Data

generic_getter_ptrcall :: proc "c" (
    data: rawptr,
    instance: gdext.ExtensionClassInstancePtr,
    args: [^]gdext.TypePtr,
    ret: gdext.TypePtr,
) {
    field_data := cast(^Generic_Field_Data)data
    val_ptr := cast(rawptr)(uintptr(instance) + field_data.offset)
    runtime.mem_copy(ret, val_ptr, field_data.size)
}

generic_getter_call :: proc "c" (
    data: rawptr,
    instance: gdext.ExtensionClassInstancePtr,
    args: [^]gdext.VariantPtr,
    arg_count: i64,
    ret: gdext.VariantPtr,
    error: ^gdext.CallError,
) {
    if !expect_args(args, arg_count, error) {
        return
    }
    field_data := cast(^Generic_Field_Data)data
    val_ptr := cast(rawptr)(uintptr(instance) + field_data.offset)
    from_type_constructor := gdext.get_variant_from_type_constructor(field_data.variant_type)
    from_type_constructor(ret, val_ptr)
}

generic_setter_ptrcall :: proc "c" (
    data: rawptr,
    instance: gdext.ExtensionClassInstancePtr,
    args: [^]gdext.TypePtr,
    ret: gdext.TypePtr,
) {
    field_data := cast(^Generic_Field_Data)data
    val_ptr := cast(rawptr)(uintptr(instance) + field_data.offset)
    runtime.mem_copy(val_ptr, args[0], field_data.size)
}

generic_setter_call :: proc "c" (
    data: rawptr,
    instance: gdext.ExtensionClassInstancePtr,
    args: [^]gdext.VariantPtr,
    arg_count: i64,
    ret: gdext.VariantPtr,
    error: ^gdext.CallError,
) {
    field_data := cast(^Generic_Field_Data)data
    if !expect_args(args, arg_count, error, field_data.variant_type) {
        return
    }
    val_ptr := cast(rawptr)(uintptr(instance) + field_data.offset)
    to_type_constructor := gdext.get_variant_to_type_constructor(field_data.variant_type)
    to_type_constructor(val_ptr, args[0])
}

type_info_to_variant_type :: proc(ti: ^runtime.Type_Info) -> (gdext.Variant_Type, bool) {
    if ti == nil do return .Nil, false

    actual := ti
    for {
        if named, ok := actual.variant.(runtime.Type_Info_Named); ok {
            actual = named.base
        } else {
            break
        }
    }

    #partial switch v in actual.variant {
    case runtime.Type_Info_Boolean:
        return .Bool, true
    case runtime.Type_Info_Integer:
        return .Int, true
    case runtime.Type_Info_Float:
        return .Float, true
    case runtime.Type_Info_String:
        return .String, true
    case runtime.Type_Info_Array:
        elem_is_float := false
        elem_is_int := false
        elem := v.elem
        for {
            if named, ok := elem.variant.(runtime.Type_Info_Named); ok {
                elem = named.base
            } else {
                break
            }
        }
        if _, ok := elem.variant.(runtime.Type_Info_Float); ok do elem_is_float = true
        if _, ok := elem.variant.(runtime.Type_Info_Integer); ok do elem_is_int = true

        if elem_is_float {
            switch v.count {
            case 2: return .Vector2, true
            case 3: return .Vector3, true
            case 4: return .Vector4, true
            }
        } else if elem_is_int {
            switch v.count {
            case 2: return .Vector2i, true
            case 3: return .Vector3i, true
            case 4: return .Vector4i, true
            }
        }
    case runtime.Type_Info_Struct:
        if named, ok := ti.variant.(runtime.Type_Info_Named); ok {
            switch named.name {
            case "Color": return .Color, true
            case "Rect2": return .Rect2, true
            case "Rect2i": return .Rect2i, true
            case "Transform2d", "Transform2D": return .Transform2d, true
            case "Transform3d", "Transform3D": return .Transform3d, true
            case "Plane": return .Plane, true
            case "Quaternion": return .Quaternion, true
            case "Aabb", "AABB": return .Aabb, true
            case "Basis": return .Basis, true
            case "Projection": return .Projection, true
            case "String_Name", "StringName": return .String_Name, true
            case "Node_Path", "NodePath": return .Node_Path, true
            case "Rid", "RID": return .Rid, true
            case "Callable": return .Callable, true
            case "Signal": return .Signal, true
            case "Dictionary": return .Dictionary, true
            case "Array": return .Array, true
            }
        }
    }

    return .Nil, false
}

Property_Hint_Range :: struct {
    min:        f64,
    max:        f64,
    step:       f64,
    or_greater: bool,
    or_less:    bool,
}

format_hint_range :: proc(h: Property_Hint_Range, allocator := context.temp_allocator) -> string {
    sb := strings.builder_make(allocator)
    fmt.sbprintf(&sb, "%v,%v", h.min, h.max)
    if h.step != 0.0 {
        fmt.sbprintf(&sb, ",%v", h.step)
    }
    if h.or_greater {
        fmt.sbprint(&sb, ",or_greater")
    }
    if h.or_less {
        fmt.sbprint(&sb, ",or_less")
    }
    return strings.to_string(sb)
}

get_field_calls :: proc "contextless" (
    $T: typeid,
    $Value: typeid,
) -> (
    getter_ptrcall: gdext.ExtensionClassMethodPtrCall,
    getter_call: gdext.ExtensionClassMethodCall,
    setter_ptrcall: gdext.ExtensionClassMethodPtrCall,
    setter_call: gdext.ExtensionClassMethodCall,
) {
    getter_ptrcall = proc "c" (
        data: rawptr,
        instance: gdext.ExtensionClassInstancePtr,
        args: [^]gdext.TypePtr,
        ret: gdext.TypePtr,
    ) {
        offset := uintptr(data)
        val_ptr := cast(^Value)(uintptr(instance) + offset)
        (cast(^Value)ret)^ = val_ptr^
    }

    getter_call = proc "c" (
        data: rawptr,
        instance: gdext.ExtensionClassInstancePtr,
        args: [^]gdext.VariantPtr,
        arg_count: i64,
        ret: gdext.VariantPtr,
        error: ^gdext.CallError,
    ) {
        if !expect_args(args, arg_count, error) {
            return
        }
        context = gdext.godot_context()
        offset := uintptr(data)
        val_ptr := cast(^Value)(uintptr(instance) + offset)
        godot.variant_into_ptr(val_ptr, cast(^godot.Variant)ret)
    }

    setter_ptrcall = proc "c" (
        data: rawptr,
        instance: gdext.ExtensionClassInstancePtr,
        args: [^]gdext.TypePtr,
        ret: gdext.TypePtr,
    ) {
        offset := uintptr(data)
        val_ptr := cast(^Value)(uintptr(instance) + offset)
        val_ptr^ = (cast(^Value)args[0])^
    }

    setter_call = proc "c" (
        data: rawptr,
        instance: gdext.ExtensionClassInstancePtr,
        args: [^]gdext.VariantPtr,
        arg_count: i64,
        ret: gdext.VariantPtr,
        error: ^gdext.CallError,
    ) {
        if !expect_args(args, arg_count, error, godot.variant_type(Value)) {
            return
        }
        context = gdext.godot_context()
        offset := uintptr(data)
        val_ptr := cast(^Value)(uintptr(instance) + offset)
        val_ptr^ = godot.variant_to(cast(^godot.Variant)args[0], Value)
    }

    return
}

bind_field :: proc {
    bind_field_full,
    bind_field_with_type,
    bind_field_name_only,
    bind_field_range,
}

bind_field_full :: proc(
    $T: typeid,
    name: string,
    offset: uintptr,
    $Value: typeid,
    getter_name := "",
    setter_name := "",
    class_name := "",
    hint := godot.Property_Hint.None,
    hint_string := "",
    usage: u32 = 6,
) {
    class_str_name: ^godot.String_Name
    if class_name != "" {
        class_str_name = get_or_create_string_name(class_name)
    } else {
        class_str_name = get_class_name(T)
    }

    prop_name := get_or_create_string_name(name)
    g_name_str := getter_name if getter_name != "" else fmt.tprintf("get_%s", name)
    s_name_str := setter_name if setter_name != "" else fmt.tprintf("set_%s", name)
    g_name := get_or_create_string_name(g_name_str)
    s_name := get_or_create_string_name(s_name_str)

    getter_ptrcall, getter_call, setter_ptrcall, setter_call := get_field_calls(T, Value)

    return_info := simple_property_info(godot.variant_type(Value), godot.string_name_empty_ref())
    getter_info := gdext.ExtensionClassMethodInfo {
        name                   = g_name,
        method_user_data       = rawptr(offset),
        call_func              = getter_call,
        ptr_call_func          = getter_ptrcall,
        method_flags           = 0,
        has_return_value       = true,
        return_value_info      = &return_info,
        return_value_metadata  = .None,
        argument_count         = 0,
        default_argument_count = 0,
    }
    gdext.classdb_register_extension_class_method(gdext.library, class_str_name, &getter_info)

    arg_info := simple_property_info(godot.variant_type(Value), prop_name)
    arg_meta := gdext.ExtensionClassMethodArgumentMetadata.None
    setter_info := gdext.ExtensionClassMethodInfo {
        name                   = s_name,
        method_user_data       = rawptr(offset),
        call_func              = setter_call,
        ptr_call_func          = setter_ptrcall,
        method_flags           = 0,
        has_return_value       = false,
        return_value_info      = nil,
        return_value_metadata  = .None,
        argument_count         = 1,
        arguments_info         = &arg_info,
        arguments_metadata     = &arg_meta,
        default_argument_count = 0,
    }
    gdext.classdb_register_extension_class_method(gdext.library, class_str_name, &setter_info)

    hint_str: godot.String
    hint_str_ptr: ^godot.String = nil
    if hint_string != "" {
        hint_str = godot.new_string_odin(hint_string)
        hint_str_ptr = &hint_str
    }
    defer if hint_string != "" {
        godot.free_string(hint_str)
    }

    prop_info := simple_property_info(godot.variant_type(Value), prop_name, u32(hint), hint_str_ptr, usage)
    gdext.classdb_register_extension_class_property(gdext.library, class_str_name, &prop_info, s_name, g_name)
}

bind_field_generic :: proc(
    $T: typeid,
    name: string,
    offset: uintptr,
    size: int,
    v_type: gdext.Variant_Type,
    hint := godot.Property_Hint.None,
    hint_string := "",
    usage: u32 = 6,
    class_name := "",
    getter_name := "",
    setter_name := "",
) {
    class_str_name: ^godot.String_Name
    if class_name != "" {
        class_str_name = get_or_create_string_name(class_name)
    } else {
        class_str_name = get_class_name(T)
    }

    prop_name := get_or_create_string_name(name)
    g_name_str := getter_name if getter_name != "" else fmt.tprintf("get_%s", name)
    s_name_str := setter_name if setter_name != "" else fmt.tprintf("set_%s", name)
    g_name := get_or_create_string_name(g_name_str)
    s_name := get_or_create_string_name(s_name_str)

    f_data := new(Generic_Field_Data)
    f_data.offset = offset
    f_data.size = size
    f_data.variant_type = v_type
    append(&generic_field_pool, f_data)

    return_info := simple_property_info(v_type, godot.string_name_empty_ref())
    getter_info := gdext.ExtensionClassMethodInfo {
        name                   = g_name,
        method_user_data       = f_data,
        call_func              = generic_getter_call,
        ptr_call_func          = generic_getter_ptrcall,
        method_flags           = 0,
        has_return_value       = true,
        return_value_info      = &return_info,
        return_value_metadata  = .None,
        argument_count         = 0,
        default_argument_count = 0,
    }
    gdext.classdb_register_extension_class_method(gdext.library, class_str_name, &getter_info)

    arg_info := simple_property_info(v_type, prop_name)
    arg_meta := gdext.ExtensionClassMethodArgumentMetadata.None
    setter_info := gdext.ExtensionClassMethodInfo {
        name                   = s_name,
        method_user_data       = f_data,
        call_func              = generic_setter_call,
        ptr_call_func          = generic_setter_ptrcall,
        method_flags           = 0,
        has_return_value       = false,
        return_value_info      = nil,
        return_value_metadata  = .None,
        argument_count         = 1,
        arguments_info         = &arg_info,
        arguments_metadata     = &arg_meta,
        default_argument_count = 0,
    }
    gdext.classdb_register_extension_class_method(gdext.library, class_str_name, &setter_info)

    hint_str: godot.String
    hint_str_ptr: ^godot.String = nil
    if hint_string != "" {
        hint_str = godot.new_string_odin(hint_string)
        hint_str_ptr = &hint_str
    }
    defer if hint_string != "" {
        godot.free_string(hint_str)
    }

    prop_info := simple_property_info(v_type, prop_name, u32(hint), hint_str_ptr, usage)
    gdext.classdb_register_extension_class_property(gdext.library, class_str_name, &prop_info, s_name, g_name)
}

@(private = "file")
_struct_field_by_name :: proc(T: typeid, name: string) -> reflect.Struct_Field {
    return reflect.struct_field_by_name(T, name)
}

bind_field_name_only :: proc(
    $T: typeid,
    name: string,
    hint := godot.Property_Hint.None,
    hint_string := "",
    usage: u32 = 6,
) -> bool {
    #assert(intrinsics.type_is_struct(T), "T must be a struct")
    field := _struct_field_by_name(T, name)
    if field.name == "" {
        return false
    }

    v_type, ok := type_info_to_variant_type(field.type)
    if !ok {
        return false
    }

    bind_field_generic(T, name, field.offset, field.type.size, v_type, hint, hint_string, usage)
    return true
}

bind_field_with_type :: proc(
    $T: typeid,
    name: string,
    $Value: typeid,
    hint := godot.Property_Hint.None,
    hint_string := "",
    usage: u32 = 6,
) {
    #assert(intrinsics.type_is_struct(T), "T must be a struct")
    field := reflect.struct_field_by_name(T, name)
    offset := field.offset if field.name != "" else 0
    bind_field_full(T, name, offset, Value, "", "", "", hint, hint_string, usage)
}

bind_field_range :: proc(
    $T: typeid,
    name: string,
    range: Property_Hint_Range,
    usage: u32 = 6,
) -> bool {
    hint_str := format_hint_range(range)
    return bind_field_name_only(T, name, .Range, hint_str, usage)
}

bind_fields :: proc($T: typeid) {
    #assert(intrinsics.type_is_struct(T), "T must be a struct")
    ti := runtime.type_info_base(type_info_of(T))
    s_info := ti.variant.(runtime.Type_Info_Struct)

    names := s_info.names[:s_info.field_count]
    offsets := s_info.offsets[:s_info.field_count]
    tags := s_info.tags[:s_info.field_count]
    types := s_info.types[:s_info.field_count]

    for name, i in names {
        if name == "base" || name == "object" do continue
        tag := string(tags[i])
        if tag == "" do continue

        tag_val, has_gd := reflect.struct_tag_lookup(reflect.Struct_Tag(tag), "gd")
        if !has_gd do continue

        hint := godot.Property_Hint.None
        hint_str := ""

        if strings.contains(tag_val, "range:") {
            hint = .Range
            idx := strings.index(tag_val, "range:")
            range_part := tag_val[idx + 6:]
            if end_idx := strings.index(range_part, ","); end_idx >= 0 {
                range_part = range_part[:end_idx]
            }
            context = gdext.godot_context()
            r_str := strings.clone(range_part, context.temp_allocator)
            r_str, _ = strings.replace_all(r_str, "..", ",", context.temp_allocator)
            r_str, _ = strings.replace_all(r_str, ":", ",", context.temp_allocator)
            hint_str = r_str
        }

        f_type := types[i]
        v_type, ok := type_info_to_variant_type(f_type)
        if !ok do continue

        bind_field_generic(T, name, uintptr(offsets[i]), f_type.size, v_type, hint, hint_str, 6)
    }
}

bind_property_type :: proc(
    $T: typeid,
    name: string,
    getter: proc "contextless" (self: ^$Self) -> $Value,
    setter: proc "contextless" (self: ^Self, value: Value),
    getter_name := "",
    setter_name := "",
    class_name := "",
    hint := godot.Property_Hint.None,
    hint_string := "",
    usage: u32 = 6,
) {
    class_str_name: ^godot.String_Name
    if class_name != "" {
        class_str_name = get_or_create_string_name(class_name)
    } else {
        class_str_name = get_class_name(T)
    }

    prop_name := get_or_create_string_name(name)
    g_name_str := getter_name if getter_name != "" else fmt.tprintf("get_%s", name)
    s_name_str := setter_name if setter_name != "" else fmt.tprintf("set_%s", name)
    g_name := get_or_create_string_name(g_name_str)
    s_name := get_or_create_string_name(s_name_str)

    hint_str: godot.String
    hint_str_ptr: ^godot.String = nil
    if hint_string != "" {
        hint_str = godot.new_string_odin(hint_string)
        hint_str_ptr = &hint_str
    }
    defer if hint_string != "" {
        godot.free_string(hint_str)
    }

    bind_property_and_methods_gdstringname(class_str_name, prop_name, g_name, s_name, getter, setter, u32(hint), hint_str_ptr, usage)
}

bind_property_string :: proc(
    class_name: string,
    name: string,
    getter: proc "contextless" (self: ^$Self) -> $Value,
    setter: proc "contextless" (self: ^Self, value: Value),
    getter_name := "",
    setter_name := "",
    hint := godot.Property_Hint.None,
    hint_string := "",
    usage: u32 = 6,
) {
    class_str_name := get_or_create_string_name(class_name)
    prop_name := get_or_create_string_name(name)
    g_name_str := getter_name if getter_name != "" else fmt.tprintf("get_%s", name)
    s_name_str := setter_name if setter_name != "" else fmt.tprintf("set_%s", name)
    g_name := get_or_create_string_name(g_name_str)
    s_name := get_or_create_string_name(s_name_str)

    hint_str: godot.String
    hint_str_ptr: ^godot.String = nil
    if hint_string != "" {
        hint_str = godot.new_string_odin(hint_string)
        hint_str_ptr = &hint_str
    }
    defer if hint_string != "" {
        godot.free_string(hint_str)
    }

    bind_property_and_methods_gdstringname(class_str_name, prop_name, g_name, s_name, getter, setter, u32(hint), hint_str_ptr, usage)
}
