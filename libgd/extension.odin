package libgd

import "godot:gdext"
import "godot:godot"
import "godot:libgd/classdb"

// Initializes a scene extension from its exported GDExtension entry point.
// The registration callback runs with the Godot Odin context installed.
initialize_extension :: proc "contextless" (
    get_proc_address: gdext.ExtensionInterfaceGetProcAddress,
    library: gdext.ExtensionClassLibraryPtr,
    initialization: ^gdext.Initialization,
    $register_classes: proc(),
) -> bool {
    gdext.init(library, get_proc_address)
    initialization^ = {
        minimum_initialization_level = .Scene,
        initialize = proc "c" (user_data: rawptr, level: gdext.InitializationLevel) {
            if level == .Scene {
                context = gdext.godot_context()
                godot.init()
                register_classes()
            }
        },
        deinitialize = proc "c" (user_data: rawptr, level: gdext.InitializationLevel) {
            if level == .Scene {
                context = gdext.godot_context()
                classdb.unregister_all_classes()
                godot.cleanup_string_caches()
            }
        },
    }
    return true
}
