# ID is the component identifier.
alias ID = UInt8


trait Component:
    alias ID: Id


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
