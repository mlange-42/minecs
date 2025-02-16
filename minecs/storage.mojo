from sys.info import sizeof
from collections import List
from memory import memcpy, UnsafePointer
from .archetype import Archetype
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

    alias add_archetype_func = fn (mask: Mask) escaping -> UInt
    alias copy_func = fn (
        index: EntityIndex, target: ArchetypeID
    ) escaping -> UInt32
    alias extend_func = fn (archetype: ArchetypeID) escaping -> UInt32
    alias remove_func = fn (index: EntityIndex) escaping -> Bool

    var _data: UnsafePointer[UInt8]
    var _length: UInt8

    var _has_archetype_funcs: List[Self.add_archetype_func]
    var _copy_funcs: List[Self.copy_func]
    var _extend_funcs: List[Self.extend_func]
    var _remove_funcs: List[Self.remove_func]

    fn __init__(out self):
        self._data = UnsafePointer[UInt8].alloc(
            TOTAL_MASK_BITS * Self.storage_size
        )
        self._has_archetype_funcs = List[Self.add_archetype_func]()
        self._copy_funcs = List[Self.copy_func]()
        self._extend_funcs = List[Self.extend_func]()
        self._remove_funcs = List[Self.remove_func]()
        self._length = 0

    fn add_component[
        T: Component
    ](mut self, id: ID, archetypes: List[Archetype]) raises:
        if id != self._length:
            raise Error("storages can be extended only sequentially")

        var s = ComponentStorage[T](id, archetypes)
        memcpy(
            self._get_storage_ptr(id),
            UnsafePointer.address_of(s).bitcast[UInt8](),
            index(Self.storage_size),
        )
        ptr = self.get_storage[T](id)

        fn add_archetype(mask: Mask) escaping -> UInt:
            return ptr[].add_archetype(mask)

        fn copy(index: EntityIndex, target: ArchetypeID) escaping -> UInt32:
            return ptr[].copy(index, target)

        fn extend(archetype: ArchetypeID) escaping -> UInt32:
            return ptr[].extend(archetype)

        fn remove(index: EntityIndex) escaping -> Bool:
            return ptr[].remove(index)

        self._has_archetype_funcs.append(add_archetype)
        self._copy_funcs.append(copy)
        self._extend_funcs.append(extend)
        self._remove_funcs.append(remove)

        self._length += 1

    fn add_archetype(mut self, mask: Mask):
        for i in range(self._length):
            _ = self._has_archetype_funcs[i](mask)

    fn copy(
        mut self, id: ID, index: EntityIndex, target: ArchetypeID
    ) -> UInt32:
        return self._copy_funcs[id](index, target)

    fn extend(mut self, id: ID, archetype: ArchetypeID) -> UInt32:
        return self._extend_funcs[id](archetype)

    fn remove(mut self, id: ID, index: EntityIndex) -> Bool:
        return self._remove_funcs[id](index)

    @always_inline
    fn get_storage[
        T: Component
    ](ref self, id: ID) raises -> Pointer[
        ComponentStorage[T], __origin_of(self)
    ]:
        return Pointer[ComponentStorage[T], __origin_of(self)].address_of(
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

    fn __init__(out self, comp: ID, archetypes: List[Archetype]):
        self._component = comp
        self._archetypes = List[ArchetypeStorage[T]]()

        i = 0
        for arch in archetypes:
            self._archetypes.append(ArchetypeStorage[T]())
            if arch[].mask().get(comp):
                self._archetypes[i].activate()
            i += 1

    fn __init__(out self, comp: ID):
        self._component = comp
        self._archetypes = List[ArchetypeStorage[T]]()

    @always_inline
    fn get_type(self) -> ID:
        return self._component

    @always_inline
    fn get_archetype(
        ref self, idx: UInt
    ) -> Pointer[ArchetypeStorage[T], __origin_of(self._archetypes)]:
        return Pointer.address_of(self._archetypes[idx])

    @always_inline
    fn get_ptr[
        origin: MutableOrigin
    ](ref self, index: EntityIndex) -> Pointer[T, origin]:
        ptr = self._archetypes[index.archetype].get_unsafe(index.index)
        return Pointer[T, origin].address_of(ptr[])

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
        idx = self._archetypes[archetype].add(T())
        print(
            "extend",
            self._component,
            archetype,
            len(self._archetypes[archetype]),
        )
        return idx

    @always_inline
    fn remove(mut self, index: EntityIndex) -> Bool:
        return self._archetypes[index.archetype].remove(index.index)

    @always_inline
    fn copy(mut self, index: EntityIndex, target: ArchetypeID) -> UInt32:
        print(
            "copy ",
            self._component,
            index.archetype,
            index.index,
            len(self._archetypes[index.archetype]),
        )
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
    fn get_ptr(ref self, index: UInt32) -> Pointer[T, __origin_of(self._data)]:
        return Pointer.address_of(self._data[index])

    @always_inline
    fn get_unsafe(ref self, index: UInt32) -> UnsafePointer[T]:
        return UnsafePointer.address_of(self._data[index])

    @always_inline
    fn get(ref self, index: UInt32) -> ref [self._data] T:
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
