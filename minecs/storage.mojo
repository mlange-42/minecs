from sys.info import sizeof
from memory import memcpy, UnsafePointer
from .types import Component, ID, MAX_COMPONENTS, _DummyComponent


trait Storage:
    fn get_type(self) -> ID:
        ...


struct Storages:
    alias storage_size = sizeof[ComponentStorage[_DummyComponent]]()

    var _data: UnsafePointer[UInt8]

    fn __init__(out self):
        self._data = UnsafePointer[UInt8].alloc(
            MAX_COMPONENTS * Self.storage_size
        )

    fn add[T: Component](mut self, id: ID):
        var s = ComponentStorage[T](id)
        memcpy(
            self._get_storage_ptr(id),
            UnsafePointer.address_of(s).bitcast[UInt8](),
            index(Self.storage_size),
        )

    @always_inline
    fn get[
        T: Component
    ](ref self, id: ID) raises -> Pointer[
        ComponentStorage[T], __origin_of(self._data)
    ]:
        return Pointer[ComponentStorage[T], __origin_of(self._data)].address_of(
            (self._data + id * Self.storage_size).bitcast[
                ComponentStorage[T]
            ]()[]
        )

    @always_inline
    fn _get_storage_ptr(self, id: ID) -> UnsafePointer[UInt8]:
        return self._data + id * Self.storage_size


struct ComponentStorage[T: Component](Storage):
    var _component: ID
    var _archetypes: List[ArchetypeStorage[T]]

    fn __init__(out self, comp: ID):
        self._component = comp
        self._archetypes = List[ArchetypeStorage[T]]()

    fn get_type(self) -> ID:
        return self._component

    fn get_archetype(
        ref self, idx: UInt
    ) -> ref [self._archetypes] ArchetypeStorage[T]:
        return self._archetypes[idx]

    fn add_archetype(mut self) -> UInt:
        idx = len(self._archetypes)
        self._archetypes.append(ArchetypeStorage[T]())
        return idx


@value
struct ArchetypeStorage[T: Component](CollectionElement):
    var _data: List[T]

    fn __init__(out self):
        self._data = List[T]()

    fn add(mut self, element: T):
        self._data.append(element)
