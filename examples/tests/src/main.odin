package test

import "godot:gdext"
import "godot:libgd"

// see gdext.InitializationFunction
@(export)
tests_library_init :: proc "c" (
    get_proc_address: gdext.ExtensionInterfaceGetProcAddress,
    library: gdext.ExtensionClassLibraryPtr,
    initialization: ^gdext.Initialization,
) -> bool {
    return libgd.initialize_extension(get_proc_address, library, initialization, register_test_classes)
}

register_test_classes :: proc() {
    test_class_register()
    lifecycle_probe_register()
}
