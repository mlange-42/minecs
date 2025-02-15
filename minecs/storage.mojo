from .types import Component, ID


trait Storage:
    fn get_type(self) -> ID:
        ...


struct ComponentStorage[T: Component](Storage):
    var _component: ID
    var _archetypes: List[ArchetypeStorage[T]]

    fn __init__(out self, comp: ID):
        self._component = comp
        self._archetypes = List[ArchetypeStorage[T]]()

    fn get_type(self) -> ID:
        return self._component


@value
struct ArchetypeStorage[T: Component](CollectionElement):
    var _data: List[T]
