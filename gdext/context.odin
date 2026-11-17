package gdextension

import "base:intrinsics"
import "base:runtime"
import "core:c"
import "core:mem"

godot_aligned_alloc :: proc(size, alignment: int, zero: bool) -> (rawptr, mem.Allocator_Error) {
    if size == 0 do return nil, nil

    align := max(alignment, align_of(rawptr))
    total_size := size + align + size_of(rawptr)

    raw := mem_alloc(cast(c.size_t)total_size)
    if raw == nil {
        return nil, .Out_Of_Memory
    }

    if zero {
        intrinsics.mem_zero(raw, total_size)
    }

    aligned := (uintptr(raw) + size_of(rawptr) + uintptr(align) - 1) & ~uintptr(align - 1)
    (cast(^rawptr)(aligned - size_of(rawptr)))^ = raw

    return rawptr(aligned), nil
}

godot_aligned_free :: proc(ptr: rawptr) {
    if ptr == nil do return
    raw := (cast(^rawptr)(uintptr(ptr) - size_of(rawptr)))^
    mem_free(raw)
}

godot_allocator_proc :: proc(
    allocator_data: rawptr,
    mode: mem.Allocator_Mode,
    size, alignment: int,
    old_memory: rawptr,
    old_size: int,
    loc := #caller_location,
) -> (
    []byte,
    mem.Allocator_Error,
) {
    switch mode {
    case .Alloc:
        ptr, err := godot_aligned_alloc(size, alignment, true)
        if err != nil do return nil, err
        return mem.byte_slice(ptr, size), nil

    case .Alloc_Non_Zeroed:
        ptr, err := godot_aligned_alloc(size, alignment, false)
        if err != nil do return nil, err
        return mem.byte_slice(ptr, size), nil

    case .Free:
        godot_aligned_free(old_memory)
        return nil, nil

    case .Free_All:
        return nil, .Mode_Not_Implemented

    case .Resize, .Resize_Non_Zeroed:
        if old_memory == nil {
            ptr, err := godot_aligned_alloc(size, alignment, mode == .Resize)
            if err != nil do return nil, err
            return mem.byte_slice(ptr, size), nil
        }
        if size == 0 {
            godot_aligned_free(old_memory)
            return nil, nil
        }

        new_ptr, err := godot_aligned_alloc(size, alignment, mode == .Resize)
        if err != nil do return nil, err

        copy_size := min(old_size, size)
        if copy_size > 0 {
            intrinsics.mem_copy(new_ptr, old_memory, copy_size)
        }

        godot_aligned_free(old_memory)
        return mem.byte_slice(new_ptr, size), nil

    case .Query_Features:
        set := (^mem.Allocator_Mode_Set)(old_memory)
        if set != nil {
            set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Resize, .Query_Features}
        }
        return nil, nil

    case .Query_Info:
        return nil, .Mode_Not_Implemented
    }

    return nil, nil
}

godot_allocator :: #force_inline proc "contextless" () -> (a: runtime.Allocator) {
    return runtime.Allocator{procedure = godot_allocator_proc}
}

@(private)
temp_arena: runtime.Arena

godot_context :: #force_inline proc "contextless" () -> (c: runtime.Context) {
    alloc := runtime.Allocator{procedure = godot_allocator_proc}
    if temp_arena.backing_allocator.procedure == nil {
        temp_arena.backing_allocator = alloc
    }
    c.allocator = alloc
    c.temp_allocator = runtime.Allocator{procedure = runtime.arena_allocator_proc, data = &temp_arena}
    return
}
