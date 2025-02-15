alias ID = UInt8
alias EntityID = UInt32
alias ArchetypeID = UInt16


trait Component(CollectionElement, Defaultable):
    alias ID: Id


@value
@register_passable("trivial")
struct _DummyComponent(Component):
    alias ID = Id("minecs/types/_DummyComponent")


@register_passable("trivial")
struct Id(KeyElement):
    var _id: UInt

    fn id(self) -> UInt:
        return self._id

    fn __init__(out self, name: String):
        self._id = name.__hash__()

    fn __eq__(self, other: Self) -> Bool:
        return self._id == other._id

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    fn __hash__(self) -> UInt:
        return self._id
