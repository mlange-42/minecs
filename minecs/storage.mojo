from sys.info import sizeof
from memory import memcpy, UnsafePointer
from .types import Component, ID, ArchetypeID, MAX_COMPONENTS, _DummyComponent
from .mask import Mask
from .entity import EntityIndex


trait Storage:
    fn get_type(self) -> ID:
        ...

    fn has_archetype(self, archetype: ArchetypeID) -> Bool:
        ...

    fn add_archetype(mut self, mask: Mask) -> UInt:
        ...

    fn extend(mut self, archetype: ArchetypeID) -> UInt32:
        ...

    """
    fn remove(mut self, index: EntityIndex) -> Bool:
        ...

    fn copy(mut self, index: EntityIndex, target: ArchetypeID) -> UInt32:
        ...
    """


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
        mut self, idx: UInt
    ) -> Pointer[ArchetypeStorage[T], __origin_of(self._archetypes)]:
        return Pointer.address_of(self._archetypes[idx])

    fn get(
        mut self, index: EntityIndex
    ) -> Pointer[T, __origin_of(self._archetypes[index.archetype]._data)]:
        return self._archetypes[index.archetype].get(index.index)

    fn has_archetype(self, archetype: ArchetypeID) -> Bool:
        return self._archetypes[archetype].is_active()

    fn add_archetype(mut self, mask: Mask) -> UInt:
        index = len(self._archetypes)
        self._archetypes.append(ArchetypeStorage[T]())
        if mask.get(self._component):
            self._archetypes[index].activate()
        return index

    fn extend(mut self, archetype: ArchetypeID) -> UInt32:
        return self._archetypes[archetype].add(T())


@value
struct ArchetypeStorage[T: Component](CollectionElement):
    var _data: List[T]
    var _active: Bool

    fn __init__(out self):
        self._data = List[T]()
        self._active = False

    fn get(mut self, index: UInt32) -> Pointer[T, __origin_of(self._data)]:
        return Pointer.address_of(self._data[index])

    fn add(mut self, element: T) -> UInt32:
        self._data.append(element)
        return len(self._data) - 1

    fn is_active(self) -> Bool:
        return self._active

    fn activate(mut self):
        self._active = True
