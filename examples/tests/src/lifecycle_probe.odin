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
