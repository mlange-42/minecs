import minecs as mx


@value
@register_passable("trivial")
struct Position(mx.Component):
    alias ID = mx.Id("minecs/test/Position")

    var x: Float64
    var y: Float64


@value
@register_passable("trivial")
struct Velocity(mx.Component):
    alias ID = mx.Id("minecs/test/Velocity")

    var x: Float64
    var y: Float64
