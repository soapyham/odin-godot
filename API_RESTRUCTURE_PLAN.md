# Odin–Godot API restructuring plan

Make the first extension easy to build and give authors one predictable way to initialize an extension, register a class, and call Godot. Keep Godot names recognizable so users can move between the Godot reference and Odin source.

The first milestone is a Node2D that registers at scene initialization, exports a property, receives a lifecycle callback, and emits a signal consumed by GDScript. A new user should be able to build and run it from a clean checkout with the documented Odin and Godot versions.

## Scope

`godot-cpp/` is an upstream Git submodule. Use `gdextension/extension_api.json` from the revision recorded by the parent repository as the baseline. The parent currently records `e83fd09`, while the working submodule is at `507ed9d` and the local `.gitmodules` changes the branch hint from `4.5` to `master`.

Aim to ship the first milestone entirely in the handwritten authoring layer, build tooling, examples, and docs. Use the existing low-level `gdext` interface and generated `godot` bindings as they are. If a concrete binding limitation blocks the milestone, document the missing capability and check whether `libgd` can handle it first. If a generated binding change is necessary, make the smallest change in the generator or templates and regenerate from the same pinned input.

## Starting point

- The current hello example initializes `gdext`, restores the Odin context in engine callbacks, initializes generated bindings, and unregisters classes itself. Its player source illustrates tagged fields, a class vtable, separate signal registration, and calls such as `godot.node2d_get_position`.
- Generated engine and builtin bindings share the `godot` package with handwritten code such as `Strings.odin`. `libgd/classdb` already implements registration, reflection-based property binding, and signals. Godin provides another approach to generating registration boilerplate.
- The README describes `gdextension` and generated `core`, `editor`, and `variant` packages. The current generator writes into `godot/`, the examples import `godot:gdext`, and the hello extension declares a 4.5 compatibility minimum while the README says 4.4. The Makefile targets Windows for examples and the hello shell script builds for Linux.

## Returning to the recorded submodule revision

Test the original pin in a separate checkout before switching the active submodule. Current source or generated bindings may depend on the newer API input, so returning to the original pin may break generation, compilation, or runtime loading. Capture the current baseline, then regenerate in the isolated checkout using the original pin and run the same build and headless checks. Classify any failures by stage and identify the API differences that caused them. Prefer adapting handwritten code, build configuration, or examples to the original pin. If the original pin still blocks the milestone, record the exact incompatibility and decide explicitly whether to adjust the bindings or change the dependency pin.

## Implementation order

1. **Establish a reproducible baseline.** Record the Odin version and the Godot API input from the pinned submodule for the first supported configuration. Verify the actual Godot version and precision against the generator input, extension descriptor, and engine used to load the library. Add a top-level build entry point that generates bindings and builds the minimal extension for the host with the correct filename and collection flag. Repair stale package paths in the build checks. Record which platforms and versions have been exercised.

2. **Centralize extension startup and shutdown.** Add a small entry helper in `libgd` that configures initialization and deinitialization, installs the Odin context before invoking user callbacks, and initializes the generated bindings at the appropriate level. The project keeps an exported Odin procedure matching its `.gdextension` entry symbol and delegates its body to the helper. Reuse the existing ClassDB teardown and verify that registered classes and cached Godot values are released in an order that keeps the engine interface valid. Keep editor-level initialization available where needed.

3. **Make extension classes declarative.** Build on `libgd/classdb` with one documented registration path that associates an Odin struct with its Godot base, lifecycle callbacks, exported fields, and signals. Prototype it on the minimal Node2D and the player source. Validate metadata before mutating ClassDB wherever possible, and surface errors with the class and field or signal name. Keep explicit binding procedures available for custom property behavior and advanced callbacks. Revisit Godin after the handwritten API is stable so it can generate calls to that same registration path.

4. **Improve everyday engine calls.** Keep the generated `godot` package as the engine API and use `libgd` for handwritten conveniences such as the existing input helper. Start with strings, node lookup and casts, singleton calls, and common conversions used by the examples. Keep generated procedure naming systematic and document how Godot class and method names map to Odin. Use short before-and-after examples to decide whether any wrapper earns a public name. Document allocation, borrowing, destruction, and allocator requirements for helpers that cross the Godot boundary.

5. **Clarify generation and migration.** Treat `gdext` as the low-level interface, `godot` as the engine bindings, and `libgd` as the authoring layer. Keep these import paths during the first migration. Verify repeatable generation with the existing generator and pinned API input. If stale generated files need cleanup, limit it to files the generator owns. Update the README around the minimal extension, use the game example to exercise more advanced features, and document replacements and compatibility aliases where call sites change.

## Completion checks

- A clean checkout can generate bindings, build the minimal shared library, and load it in headless Godot using the documented workflow.
- A headless test extends `examples/tests` to check class instantiation from GDScript, property round-tripping, lifecycle execution, signal payload delivery, and clean shutdown. Existing vector tests still pass.
- The minimal example uses one startup helper and one registration path. The game example still builds and exercises the documented escape hatches as needed.
- Running the generator twice with the pinned input produces identical output. Verify that the first milestone runs with the existing bindings and the pinned submodule revision. Record any binding exception and the specific failure that required it.
- The README names the current packages and records the engine versions, platforms, and precision configurations actually verified. A migration guide covers startup, registration, and any changed imports or calls.

## Initial implementation results

- On Linux with Odin `dev-2026-11`, the existing generator produced bindings from `e83fd09` (Godot 4.5 stable API) in an isolated copy. Two runs produced matching checksums. Generating over the newer output initially failed at type-check time because files for newer classes were still present. Clean generated outputs when changing API inputs.
- The hello example now delegates scene initialization and class teardown to `libgd.initialize_extension`. It built against the isolated 4.5-generated bindings and ran `space_game.tscn` headlessly on Godot `4.8.beta2.official.cafc17a19`. The editor import reported socket and icon errors in this environment. The scene run exited successfully without engine errors in its log. A Godot 4.5 runtime still needs verification.
- `make check` now uses the `gdext/` path. The older game example initially blocked this check with imports of the removed `core` and `variant` packages.
- The existing headless test project now covers the Node2D class, exported integer property, ready callback, and signal payload alongside the vector tests. It passed on Linux with the 4.5-generated bindings and the Godot 4.8 beta 2 runtime. Both test classes use the shared registration path and unregister at shutdown.
- The game example now uses the shared extension lifecycle and ClassDB callbacks. `make check` passes, and a Linux headless run confirmed the Player scene loads, retains its serialized movement settings, exposes its signals, and runs physics on Godot 4.8 beta 2.
