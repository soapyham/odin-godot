package godot

import gd "godot:gdext"
import "base:runtime"
import "core:mem"
import "core:strings"
import "core:sync"

@(private)
EmptyString := String{}

@(private)
EmptyStringName := String_Name{}

string_empty :: proc "contextless" () -> String {
    return EmptyString
}

string_name_empty :: proc "contextless" () -> String_Name {
    return EmptyStringName
}

string_empty_ref :: proc "contextless" () -> ^String {
    return &EmptyString
}

string_name_empty_ref :: proc "contextless" () -> ^String_Name {
    return &EmptyStringName
}

/*
Clones a UTF8 Odin string into a Godot String

Inputs:
- from: The string to be cloned

Returns:
- res: A cloned Godot String
*/
new_string_odin :: proc "contextless" (from: string) -> (ret: String) {
    ret = String{}

    // N.B. we're transmuting the odin string into a cstring regardless of if it has a terminating null
    // byte or not. `string_new_with_utf8_chars_and_len2` takes a length, so we don't depend on the
    // terminating null byte.
    as_cstring := cast(cstring)(transmute(mem.Raw_String)from).data
    gd.string_new_with_utf8_chars_and_len2(&ret, as_cstring, cast(i64)len(from))
    return
}

/*
Clones a UTF8 cstring into a Godot String

Inputs:
- from: The cstring to be cloned. Must be null-terminated.

Returns:
- res: A cloned Godot String
*/
new_string_cstring :: proc "contextless" (from: cstring) -> (ret: String) {
    ret = String{}
    gd.string_new_with_utf8_chars(&ret, from)
    return
}

/*
Clones a UTF8 Odin string into a Godot String_Name

Inputs:
- from: The string to be cloned

Returns:
- res: A cloned Godot String_Name
*/
new_string_name_odin :: proc "contextless" (from: string) -> (ret: String_Name) {
    ret = String_Name{}

    // N.B. we're transmuting the odin string into a cstring regardless of if it has a terminating null
    // byte or not. `string_new_with_utf8_chars_and_len2` takes a length, so we don't depend on the
    // terminating null byte.
    as_cstring := cast(cstring)(transmute(mem.Raw_String)from).data
    gd.string_name_new_with_utf8_chars_and_len(&ret, as_cstring, cast(i64)len(from))
    return
}

/*
Clones a UTF8 cstring into a Godot String_Name

Inputs:
- from: The cstring to be cloned. Must be null-terminated.

Returns:
- res: A cloned Godot String_Name
*/
new_string_name_cstring :: proc "contextless" (from: cstring, static: bool) -> (ret: String_Name) {
    ret = String_Name{}
    gd.string_name_new_with_utf8_chars(&ret, from)
    return
}


@(private)
EmptyNodePath := Node_Path{}

node_path_empty :: proc "contextless" () -> Node_Path {
    return EmptyNodePath
}

node_path_empty_ref :: proc "contextless" () -> ^Node_Path {
    return &EmptyNodePath
}

String_Name_Arg :: union {
    String_Name,
    string,
    cstring,
}

Node_Path_Arg :: union {
    Node_Path,
    string,
    cstring,
}

String_Arg :: union {
    String,
    string,
    cstring,
}

@(private = "file")
string_cache_mutex: sync.Mutex

@(private = "file")
sn_cache: map[string]^String_Name

@(private = "file")
np_cache: map[string]^Node_Path

@(private = "file")
str_cache: map[string]^String

/*
Borrows a cached String_Name reference for an Odin string.
The reference stays valid until cleanup_string_caches. Use for a fixed set of strings.
*/
sn_ref :: proc "contextless" (s: string) -> ^String_Name {
    context = runtime.Context{allocator = gd.godot_allocator()}
    sync.mutex_lock(&string_cache_mutex)
    defer sync.mutex_unlock(&string_cache_mutex)
    if val, ok := sn_cache[s]; ok {
        return val
    }
    key := strings.clone(s, context.allocator)
    val := new(String_Name)
    val^ = new_string_name_odin(key)
    sn_cache[key] = val
    return val
}

/*
Borrows a cached String_Name for an Odin string. Use for a fixed set of strings.
*/
sn :: proc "contextless" (s: string) -> String_Name {
    return sn_ref(s)^
}

/*
Borrows a cached Node_Path reference for an Odin string.
The reference stays valid until cleanup_string_caches. Use for a fixed set of strings.
*/
np_ref :: proc "contextless" (s: string) -> ^Node_Path {
    context = runtime.Context{allocator = gd.godot_allocator()}
    sync.mutex_lock(&string_cache_mutex)
    defer sync.mutex_unlock(&string_cache_mutex)
    if val, ok := np_cache[s]; ok {
        return val
    }
    key := strings.clone(s, context.allocator)
    val := new(Node_Path)
    val^ = new_node_path_odin(key)
    np_cache[key] = val
    return val
}

/*
Borrows a cached Node_Path for an Odin string. Use for a fixed set of strings.
*/
np :: proc "contextless" (s: string) -> Node_Path {
    return np_ref(s)^
}

/*
Borrows a cached String reference for an Odin string.
The reference stays valid until cleanup_string_caches. Use for a fixed set of strings.
*/
str_ref :: proc "contextless" (s: string) -> ^String {
    context = runtime.Context{allocator = gd.godot_allocator()}
    sync.mutex_lock(&string_cache_mutex)
    defer sync.mutex_unlock(&string_cache_mutex)
    if val, ok := str_cache[s]; ok {
        return val
    }
    key := strings.clone(s, context.allocator)
    val := new(String)
    val^ = new_string_odin(key)
    str_cache[key] = val
    return val
}

/*
Borrows a cached String for an Odin string. Use for a fixed set of strings.
*/
str :: proc "contextless" (s: string) -> String {
    return str_ref(s)^
}

to_string_name_ref :: proc "contextless" (arg: ^String_Name_Arg) -> ^String_Name {
    if arg == nil do return string_name_empty_ref()
    switch &v in arg^ {
    case String_Name:
        return &v
    case string:
        return sn_ref(v)
    case cstring:
        return sn_ref(string(v))
    }
    return string_name_empty_ref()
}

to_node_path_ref :: proc "contextless" (arg: ^Node_Path_Arg) -> ^Node_Path {
    if arg == nil do return node_path_empty_ref()
    switch &v in arg^ {
    case Node_Path:
        return &v
    case string:
        return np_ref(v)
    case cstring:
        return np_ref(string(v))
    }
    return node_path_empty_ref()
}

to_string_ref :: proc "contextless" (arg: ^String_Arg) -> ^String {
    if arg == nil do return string_empty_ref()
    switch &v in arg^ {
    case String:
        return &v
    case string:
        return str_ref(v)
    case cstring:
        return str_ref(string(v))
    }
    return string_empty_ref()
}

// Call during shutdown, after all uses of borrowed cache values have ended.
cleanup_string_caches :: proc "contextless" () {
    context = runtime.Context{allocator = gd.godot_allocator()}
    sync.mutex_lock(&string_cache_mutex)
    defer sync.mutex_unlock(&string_cache_mutex)
    for key, val in sn_cache {
        free_string_name(val^)
        free(val)
        delete(key)
    }
    for key, val in np_cache {
        free_node_path(val^)
        free(val)
        delete(key)
    }
    for key, val in str_cache {
        free_string(val^)
        free(val)
        delete(key)
    }
    delete(sn_cache)
    sn_cache = nil
    delete(np_cache)
    np_cache = nil
    delete(str_cache)
    str_cache = nil
}

new_node_path_odin :: proc "contextless" (from: string) -> Node_Path {
    s := new_string_odin(from)
    defer free_string(s)
    return new_node_path_string(s)
}

new_node_path_cstring :: proc "contextless" (from: cstring) -> Node_Path {
    s := new_string_cstring(from)
    defer free_string(s)
    return new_node_path_string(s)
}

@(private)
borrow_or_convert_string_name :: proc "contextless" (arg: String_Name_Arg) -> (value: String_Name, owned: bool) {
    switch val in arg {
    case String_Name:
        return val, false
    case string:
        return new_string_name_odin(val), true
    case cstring:
        return new_string_name_odin(string(val)), true
    }
    return string_name_empty(), false
}

@(private)
borrow_or_convert_node_path :: proc "contextless" (arg: Node_Path_Arg) -> (value: Node_Path, owned: bool) {
    switch val in arg {
    case Node_Path:
        return val, false
    case string:
        return new_node_path_odin(val), true
    case cstring:
        return new_node_path_odin(string(val)), true
    }
    return node_path_empty(), false
}

@(private)
borrow_or_convert_string :: proc "contextless" (arg: String_Arg) -> (value: String, owned: bool) {
    switch val in arg {
    case String:
        return val, false
    case string:
        return new_string_odin(val), true
    case cstring:
        return new_string_odin(string(val)), true
    }
    return string_empty(), false
}
