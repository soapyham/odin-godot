package libgd_classdb

import "base:intrinsics"
import "base:runtime"
import "godot:gdext"
import "godot:godot"

bind_signal_struct :: proc($T: typeid, signal_name: string, $Args_Struct: typeid, class_name := "") {
    #assert(intrinsics.type_is_struct(Args_Struct), "Args_Struct must be a struct")
    ti := runtime.type_info_base(type_info_of(Args_Struct))
    s_info := ti.variant.(runtime.Type_Info_Struct)

    names := s_info.names[:s_info.field_count]
    types := s_info.types[:s_info.field_count]

    args := make([]Signal_Arg_Def, len(names), allocator = context.temp_allocator)
    for name, i in names {
        v_type, _ := type_info_to_variant_type(types[i])
        args[i] = Signal_Arg_Def{
            name = name,
            type = v_type,
        }
    }

    bind_signal_typed(T, signal_name, args, class_name)
}

Signal_Arg_Def :: struct {
    name: string,
    type: gdext.Variant_Type,
}

@(private = "file")
emit_signal_name: godot.String_Name

@(private = "file")
emit_signal_method: gdext.MethodBindPtr

@(private = "file")
emit_signal_initialized := false

init_emit_signal :: proc "contextless" () {
    if emit_signal_initialized do return
    emit_signal_name = godot.new_string_name_cstring("emit_signal", true)
    emit_signal_method = gdext.classdb_get_method_bind(godot.object_name_ref(), &emit_signal_name, 4047867050)
    emit_signal_initialized = true
}

bind_signal_internal :: proc(class_str_name: ^godot.String_Name, signal_name: string, args: []Signal_Arg_Def) {
    sig_str_name := get_or_create_string_name(signal_name)
    if len(args) == 0 {
        gdext.classdb_register_extension_class_signal(gdext.library, class_str_name, sig_str_name, nil, 0)
        return
    }

    args_info := make([]gdext.PropertyInfo, len(args), context.temp_allocator)
    for arg, idx in args {
        arg_name := get_or_create_string_name(arg.name)
        args_info[idx] = simple_property_info(arg.type, arg_name)
    }

    gdext.classdb_register_extension_class_signal(
        gdext.library,
        class_str_name,
        sig_str_name,
        raw_data(args_info),
        cast(i64)len(args),
    )
}

bind_signal_typed :: proc($T: typeid, signal_name: string, args: []Signal_Arg_Def = {}, class_name := "") {
    class_str_name: ^godot.String_Name
    if class_name != "" {
        class_str_name = get_or_create_string_name(class_name)
    } else {
        class_str_name = get_class_name(T)
    }
    bind_signal_internal(class_str_name, signal_name, args)
}

bind_signal_typed_single_arg :: proc(
    $T: typeid,
    signal_name: string,
    arg_name: string,
    arg_type: gdext.Variant_Type,
    class_name := "",
) {
    args := [1]Signal_Arg_Def{{name = arg_name, type = arg_type}}
    bind_signal_typed(T, signal_name, args[:], class_name)
}

bind_signal_typed_single_arg_type :: proc(
    $T: typeid,
    signal_name: string,
    arg_name: string,
    $Arg_Type: typeid,
    class_name := "",
) {
    args := [1]Signal_Arg_Def{{name = arg_name, type = godot.variant_type(Arg_Type)}}
    bind_signal_typed(T, signal_name, args[:], class_name)
}

bind_signal_string :: proc(class_name: string, signal_name: string, args: []Signal_Arg_Def = {}) {
    class_str_name := get_or_create_string_name(class_name)
    bind_signal_internal(class_str_name, signal_name, args)
}

bind_signal_string_single_arg :: proc(
    class_name: string,
    signal_name: string,
    arg_name: string,
    arg_type: gdext.Variant_Type,
) {
    args := [1]Signal_Arg_Def{{name = arg_name, type = arg_type}}
    bind_signal_string(class_name, signal_name, args[:])
}

bind_signal_string_single_arg_type :: proc(
    class_name: string,
    signal_name: string,
    arg_name: string,
    $Arg_Type: typeid,
) {
    args := [1]Signal_Arg_Def{{name = arg_name, type = godot.variant_type(Arg_Type)}}
    bind_signal_string(class_name, signal_name, args[:])
}

get_target_object_ptr :: proc(target: $T) -> gdext.ObjectPtr {
    when intrinsics.type_is_pointer(T) {
        when intrinsics.type_is_struct(intrinsics.type_elem_type(T)) {
            offset := find_base_field_offset(intrinsics.type_elem_type(T))
            if offset >= 0 {
                return (cast(^gdext.ObjectPtr)(uintptr(target) + uintptr(offset)))^
            }
        }
        return cast(gdext.ObjectPtr)target
    } else {
        return cast(gdext.ObjectPtr)target
    }
}

to_variant :: proc(val: $T) -> godot.Variant {
    when T == godot.Variant {
        return val
    } else when T == string {
        s := godot.new_string_odin(val)
        defer godot.free_string(s)
        return godot.variant_from(&s)
    } else when T == cstring {
        s := godot.new_string_cstring(val)
        defer godot.free_string(s)
        return godot.variant_from(&s)
    } else when T == int {
        i := godot.Int(val)
        return godot.variant_from(&i)
    } else when T == f32 {
        f := godot.Float(val)
        return godot.variant_from(&f)
    } else {
        v := val
        return godot.variant_from(&v)
    }
}

emit_signal_raw :: proc(obj: gdext.ObjectPtr, signal_name: string, args: []godot.Variant) {
    if obj == nil do return
    init_emit_signal()

    sig_name := godot.new_string_name_odin(signal_name)
    defer godot.free_string_name(sig_name)
    sig_name_var := godot.variant_from(&sig_name)
    defer gdext.variant_destroy(&sig_name_var)

    total_args := len(args) + 1
    inline_args: [4]gdext.VariantPtr
    var_ptrs := inline_args[:]
    if total_args > len(inline_args) {
        var_ptrs = make([]gdext.VariantPtr, total_args)
    }
    defer if total_args > len(inline_args) do delete(var_ptrs)
    var_ptrs[0] = &sig_name_var
    for i in 0 ..< len(args) {
        var_ptrs[i + 1] = &args[i]
    }

    ret := godot.Variant{}
    gdext.object_method_bind_call(emit_signal_method, obj, raw_data(var_ptrs), cast(i64)total_args, &ret, nil)
    gdext.variant_destroy(&ret)
}

emit_signal_0 :: proc(target: $T, signal_name: string) {
    obj := get_target_object_ptr(target)
    emit_signal_raw(obj, signal_name, nil)
}

emit_signal_1 :: proc(target: $T, signal_name: string, arg1: $A) {
    obj := get_target_object_ptr(target)
    v1 := to_variant(arg1)
    when A != godot.Variant {
        defer gdext.variant_destroy(&v1)
    }
    args := [1]godot.Variant{v1}
    emit_signal_raw(obj, signal_name, args[:])
}

emit_signal_2 :: proc(target: $T, signal_name: string, arg1: $A, arg2: $B) {
    obj := get_target_object_ptr(target)
    v1 := to_variant(arg1)
    when A != godot.Variant {
        defer gdext.variant_destroy(&v1)
    }
    v2 := to_variant(arg2)
    when B != godot.Variant {
        defer gdext.variant_destroy(&v2)
    }
    args := [2]godot.Variant{v1, v2}
    emit_signal_raw(obj, signal_name, args[:])
}

emit_signal_3 :: proc(target: $T, signal_name: string, arg1: $A, arg2: $B, arg3: $C) {
    obj := get_target_object_ptr(target)
    v1 := to_variant(arg1)
    when A != godot.Variant {
        defer gdext.variant_destroy(&v1)
    }
    v2 := to_variant(arg2)
    when B != godot.Variant {
        defer gdext.variant_destroy(&v2)
    }
    v3 := to_variant(arg3)
    when C != godot.Variant {
        defer gdext.variant_destroy(&v3)
    }
    args := [3]godot.Variant{v1, v2, v3}
    emit_signal_raw(obj, signal_name, args[:])
}

emit_signal_varargs :: proc(target: $T, signal_name: string, args: ..godot.Variant) {
    obj := get_target_object_ptr(target)
    emit_signal_raw(obj, signal_name, args)
}

emit_signal :: proc {
    emit_signal_0,
    emit_signal_1,
    emit_signal_2,
    emit_signal_3,
    emit_signal_varargs,
}
