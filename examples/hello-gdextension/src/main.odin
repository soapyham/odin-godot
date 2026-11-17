package example

import "godot:gdext"
import "godot:libgd"

// see gdext.InitializationFunction
@(export)
example_library_init :: proc "c" (
    get_proc_address: gdext.ExtensionInterfaceGetProcAddress,
    library: gdext.ExtensionClassLibraryPtr,
    initialization: ^gdext.Initialization,
) -> bool {
    return libgd.initialize_extension(get_proc_address, library, initialization, register_example_classes)
}

register_example_classes :: proc() {
    space_game_register()
    farm_game_register()
}
