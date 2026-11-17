package game

import "godot:libgd"
import "godot:gdext"

@(export)
game_init :: proc "c" (
    get_proc_address: gdext.ExtensionInterfaceGetProcAddress,
    library: gdext.ExtensionClassLibraryPtr,
    initialization: ^gdext.Initialization,
) -> bool {
    return libgd.initialize_extension(get_proc_address, library, initialization, player_class_register)
}
