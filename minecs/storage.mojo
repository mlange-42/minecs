from sys.info import sizeof
from memory import memcpy, UnsafePointer
from .constants import TOTAL_MASK_BITS
from .types import Component, ID, ArchetypeID, _DummyComponent
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

    fn remove(mut self, index: EntityIndex) -> Bool:
        ...

    fn copy(mut self, index: EntityIndex, target: ArchetypeID) -> UInt32:
        ...


struct Storages:
    alias storage_size = sizeof[ComponentStorage[_DummyComponent]]()

    var _data: UnsafePointer[UInt8]

    fn __init__(out self):
        self._data = UnsafePointer[UInt8].alloc(
            TOTAL_MASK_BITS * Self.storage_size
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

    @always_inline
    fn get_type(self) -> ID:
        return self._component

    @always_inline
    fn get_archetype(
        mut self, idx: UInt
    ) -> Pointer[ArchetypeStorage[T], __origin_of(self._archetypes)]:
        return Pointer.address_of(self._archetypes[idx])

    @always_inline
    fn get_ptr(
        mut self, index: EntityIndex
    ) -> Pointer[T, __origin_of(self._archetypes[index.archetype]._data)]:
        return self._archetypes[index.archetype].get_ptr(index.index)

    @always_inline
    fn has_archetype(self, archetype: ArchetypeID) -> Bool:
        return self._archetypes[archetype].is_active()

    @always_inline
    fn add_archetype(mut self, mask: Mask) -> UInt:
        index = len(self._archetypes)
        self._archetypes.append(ArchetypeStorage[T]())
        if mask.get(self._component):
            self._archetypes[index].activate()
        return index

    @always_inline
    fn extend(mut self, archetype: ArchetypeID) -> UInt32:
        return self._archetypes[archetype].add(T())

    @always_inline
    fn remove(mut self, index: EntityIndex) -> Bool:
        return self._archetypes[index.archetype].remove(index.index)

    @always_inline
    fn copy(mut self, index: EntityIndex, target: ArchetypeID) -> UInt32:
        comp = self._archetypes[index.archetype].get(index.index)
        return self._archetypes[target].add(comp)


@value
struct ArchetypeStorage[T: Component](CollectionElement):
    var _data: List[T]
    var _active: Bool

    fn __init__(out self):
        self._data = List[T]()
        self._active = False

    @always_inline
    fn get_ptr(mut self, index: UInt32) -> Pointer[T, __origin_of(self._data)]:
        return Pointer.address_of(self._data[index])

    @always_inline
    fn get(self, index: UInt32) -> ref [self._data] T:
        return self._data[index]

    @always_inline
    fn add(mut self, element: T) -> UInt32:
        self._data.append(element)
        return len(self._data) - 1

    @always_inline
    fn remove(mut self, index: UInt32) -> Bool:
        old_idx = len(self._data) - 1
        swapped = index != old_idx

        if swapped:
            self._data[index] = self._data[old_idx]
        self._data.resize(len(self._data) - 1)
        return swapped

    @always_inline
    fn is_active(self) -> Bool:
        return self._active

    @always_inline
    fn activate(mut self):
        self._active = True

    @always_inline
    fn __len__(self) -> Int:
        return len(self._data)
