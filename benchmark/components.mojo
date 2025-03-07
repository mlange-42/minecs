import minecs as mx


@value
@register_passable("trivial")
struct Position(mx.Component):
    alias ID = mx.Id("minecs/test/Position")

    var x: Float64
    var y: Float64

    fn __init__(out self):
        self.x = 0
        self.y = 0


@value
@register_passable("trivial")
struct Velocity(mx.Component):
    alias ID = mx.Id("minecs/test/Velocity")

    var x: Float64
    var y: Float64

    fn __init__(out self):
        self.x = 0
        self.y = 0
