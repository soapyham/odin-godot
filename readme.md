# Godot Toolkit for Odin

> [!WARNING]
> **This toolkit is a Work In Progress!**
>
> If you are using parts of it, beware of sudden major changes to the API, structure, and features.

This branch generates bindings from the Godot 4.5 API pinned in the `godot-cpp` submodule.

## GDExtension Bindings

The low-level C interface is in [`gdext/`](gdext/). The generated [`godot/`](godot/) package provides Odin wrappers, and [`libgd/`](libgd/) provides extension initialization and class registration helpers.

## Generating Complete Bindings

Clone & generate bindings
```sh
git clone --branch api-fix --recurse-submodules -j8 https://github.com/soapyham/odin-godot
cd odin-godot
make bindings
```

Bindings for enums, classes, utility functions, singletons, and native structs are generated in `godot/`.

> [!NOTE]
> `make bindings` expects odin on path, all submodules updated, and odin-godot (this repo) is the working directory.

Alternatively, you may build and run `bindgen` yourself:
```sh
# temple is the templating engine used by bindgen, temple_cli is temple's preprocessor.
odin build temple/cli/ -o:speed -out:bin/temple_cli.exe

# temple_cli will recursively search all odin files in the specified directory for
# usages of `compiled` and `compiled_inline`, then it will generate Odin code with
# the built templates in templates.odin, in the specified directory. in this case,
# its searching in the bindgen directory, and outputs to bindgen/templates.odin, with
# the `bindgen` package name.
./bin/temple_cli.exe bindgen bindgen bindgen

# bindgen is the tool which uses the temple templates to generate the entire
# GDExtension binding
odin build bindgen/ -o:speed -out:bin/bindgen.exe

# bindgen requires a path to a json file which describes the GDExtension API.
# One is available in godot-cpp.
./bin/bindgen.exe godot-cpp/gdextension/extension_api.json
```

## Creating a GDExtension

Export an entry point whose name matches `entry_symbol` in your `.gdextension` file. In the [integration test project](examples/tests/), [`main.odin`](examples/tests/src/main.odin) exports `tests_library_init`. The `libgd.initialize_extension` helper runs the registration callback when Godot initializes the scene level.

```odin
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
```

[`lifecycle_probe.odin`](examples/tests/src/lifecycle_probe.odin) registers a `Node2D` subclass. The `gd:"Node2D"` tag declares the Godot base class, `gd:"export"` exposes `value` as a property, and the vtable's `ready` callback runs when the node is ready. The scene supplies a child named `Message`, and the callback updates that child and emits the registered signal.

```odin
package test

import "godot:godot"
import "godot:libgd/classdb"

Lifecycle_Probe :: struct {
    base:  godot.Node2d `gd:"Node2D"`,
    value: i64 `gd:"export"`,
}

lifecycle_probe_register :: proc() {
    classdb.register_class(
        Lifecycle_Probe,
        classdb.Class_VTable(Lifecycle_Probe) {
            ready = proc(self: ^Lifecycle_Probe) {
                label: godot.Label = godot.node_get_node(self.base, "Message")
                godot.node_set_name(label, godot.sn("Updated"))
                godot.label_set_text(label, cstring("ready"))
                classdb.emit_signal_2(self, "ready_value", self.value, string("ready"))
            },
        },
    )
    classdb.bind_signal(Lifecycle_Probe, "ready_value", struct { value: i64, message: godot.String })
}
```

For a full game example, run `make game-extension` from the repository root before opening [the Godot project](examples/game/project.godot). The built extension registers the `Player` class used by the scene.

## Headless extension tests

On Linux x86-64, build and run the integration test project from the repository root:

```sh
make test-extension
godot --headless --path examples/tests --editor --import
timeout 15s godot --headless --path examples/tests res://tests.tscn
```

The scene exits after the vector, exported property, lifecycle, and signal assertions pass.

## Godin

Godin is an experimental preprocessor in [`godin/`](godin/). To explore its syntax, build it with `./build_godin.sh` and run `godin help`.
