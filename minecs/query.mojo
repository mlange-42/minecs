from collections import InlineArray, Optional
from sys.intrinsics import _type_is_eq

from .archetype import Archetype
from .entity import Entity
from .mask import Mask
from .storage import Storages, ComponentStorage
from .types import ID
from .util import _contains_type


trait Iterator:
    fn get[T: Component](ref self) raises -> Pointer[T, __origin_of(self)]:
        ...


struct Query[world_origin: MutableOrigin, *Ts: Component]:
    alias Iterator = QueryIterator[_, _, *Ts]
    alias component_count = len(VariadicList(Ts))

    var _world: Pointer[World, world_origin]
    var _mask: Mask
    var _ids: List[ID]  # TODO: use inline array?

    fn __init__(out self, world: Pointer[World, world_origin]) raises:
        self._world = world
        self._ids = List[ID]()

        @parameter
        for i in range(len(VariadicList(Ts))):
            self._ids.append(self._world[].component_id[Ts[i]]())

        self._mask = Mask(self._ids)

    @always_inline
    fn __iter__(
        self,
        out iterator: Self.Iterator[
            archetype_origin = __origin_of(self._world[]._archetypes[0]),
            storages_origin = __origin_of(self._world[]._storages),
        ],
    ) raises:
        iterator = Self.Iterator(
            # self._world,
            Pointer.address_of(self._world[]._archetypes),
            Pointer.address_of(self._world[]._storages),
            self._mask,
            self._ids,
        )


struct QueryIterator[
    archetype_mutability: Bool, //,
    # world_origin: MutableOrigin,
    archetype_origin: Origin[archetype_mutability],
    storages_origin: MutableOrigin,
    *Ts: Component,
](Iterator):
    alias component_count = len(VariadicList(Ts))

    # var _world: Pointer[World, world_origin]
    var _mask: Mask
    var _ids: List[ID]  # TODO: use inline array?

    var _storages: Pointer[Storages, storages_origin]
    var _archetypes: Pointer[List[Archetype], archetype_origin]
    var _archetype: Pointer[Archetype, archetype_origin]
    var _index: Int
    var _last_index: Int

    fn __init__(
        out self,
        # world: Pointer[World, world_origin],
        archetypes: Pointer[List[Archetype], archetype_origin],
        storages: Pointer[Storages, storages_origin],
        mask: Mask,
        ids: List[ID],
    ) raises:
        # self._world = world
        self._mask = mask
        self._ids = ids

        self._storages = storages
        self._archetypes = archetypes
        self._archetype = Pointer.address_of(self._archetypes[][0])
        self._index = -1
        self._last_index = -1

        _ = self._next_archetype()

    @always_inline
    fn next(mut self) -> Bool:
        if self._index < self._last_index:
            self._index += 1
            return True
        return self._next_archetype()

    @always_inline
    fn get_entity(self, out entity: Entity):
        entity = self._archetype[]._entities[self._index]

    @always_inline
    fn get[T: Component](ref self) raises -> Pointer[T, __origin_of(self)]:
        storage = self._storages[].get_storage[T](self.get_id[T]())
        return Pointer[T, __origin_of(self)].address_of(
            storage[].get_unsafe(self._archetype[]._id, self._index)[]
        )

    @always_inline
    fn _next_archetype(mut self) -> Bool:
        max_arch_index = len(self._archetypes[]) - 1
        while self._archetype[]._id < max_arch_index:
            self._archetype = Pointer.address_of(
                self._archetypes[][self._archetype[]._id + 1]
            )
            if self._archetype[].mask().contains(self._mask):
                self._index = -1
                self._last_index = len(self._archetype[]) - 1
                return True
        return False

    @always_inline
    fn __len__(self) -> Int:
        var size = 0
        for arch_idx in range(len(self._archetypes[])):
            arch = Pointer.address_of(self._archetypes[][arch_idx])
            if not arch[].mask().contains(self._mask):
                continue
            size += len(arch[])
        return size

    @always_inline
    fn get_id[T: Component](self) -> ID:
        @parameter
        for i in range(len(VariadicList(Ts))):

            @parameter
            if _type_is_eq[T, Ts[i]]():
                return self._ids[i]

        # This constraint will fail if the component type is not in the list.
        constrained[
            _contains_type[T, *Ts](),
            "The used component is not in the component parameter list.",
        ]()
        return -1  # This is unreachable.


struct Query2[world_origin: MutableOrigin, A: Component, B: Component]:
    alias Iterator = QueryIterator2[_, _, A, B]

    var _world: Pointer[World, world_origin]
    var _mask: Mask
    var _ids: List[ID]

    fn __init__(out self, world: Pointer[World, world_origin]) raises:
        self._world = world
        self._ids = List[ID](
            self._world[].component_id[A](), self._world[].component_id[B]()
        )
        self._mask = Mask(self._ids)

    @always_inline
    fn __iter__(
        self,
        out iterator: Self.Iterator[
            archetype_origin = __origin_of(self._world[]._archetypes[0]),
            storages_origin = __origin_of(self._world[]._storages),
        ],
    ) raises:
        iterator = Self.Iterator(
            _QueryIterator(
                Pointer.address_of(self._world[]._archetypes),
                Pointer.address_of(self._world[]._storages),
                self._mask,
                self._ids,
            )
        )


@value
struct _QueryIterator[
    archetype_mutability: Bool,
    archetype_origin: Origin[archetype_mutability],
    storages_origin: MutableOrigin,
]:
    var _mask: Mask
    var _storages: Pointer[Storages, storages_origin]
    var _archetypes: Pointer[List[Archetype], archetype_origin]
    var _archetype: Pointer[Archetype, archetype_origin]
    var _index: Int
    var _last_index: Int
    var _ids: List[ID]

    fn __init__(
        out self,
        archetypes: Pointer[List[Archetype], archetype_origin],
        storages: Pointer[Storages, storages_origin],
        mask: Mask,
        ids: List[ID],
    ) raises:
        self._mask = mask

        self._storages = storages
        self._archetypes = archetypes
        self._archetype = Pointer.address_of(self._archetypes[][0])
        self._index = -1
        self._last_index = -1

        self._ids = ids
        _ = self._next_archetype()

    @always_inline
    fn next(mut self) -> Bool:
        if self._index < self._last_index:
            self._index += 1
            return True
        return self._next_archetype()

    @always_inline
    fn get_entity(self, out entity: Entity):
        entity = self._archetype[]._entities[self._index]

    @always_inline
    fn _next_archetype(mut self) -> Bool:
        max_arch_index = len(self._archetypes[]) - 1
        while self._archetype[]._id < max_arch_index:
            self._archetype = Pointer.address_of(
                self._archetypes[][self._archetype[]._id + 1]
            )
            if self._archetype[].mask().contains(self._mask):
                self._index = -1
                self._last_index = len(self._archetype[]) - 1
                return True
        return False

    @always_inline
    fn __len__(self) -> Int:
        var size = 0
        for arch_idx in range(len(self._archetypes[])):
            arch = Pointer.address_of(self._archetypes[][arch_idx])
            if not arch[].mask().contains(self._mask):
                continue
            size += len(arch[])
        return size


struct QueryIterator2[
    archetype_mutability: Bool, //,
    archetype_origin: Origin[archetype_mutability],
    storages_origin: MutableOrigin,
    A: Component,
    B: Component,
]:
    var _inner: _QueryIterator[
        archetype_mutability, archetype_origin, storages_origin
    ]
    var _storage_a: Pointer[ComponentStorage[A], storages_origin]
    var _storage_b: Pointer[ComponentStorage[B], storages_origin]

    fn __init__(
        out self,
        inner: _QueryIterator[
            archetype_mutability, archetype_origin, storages_origin
        ],
    ) raises:
        self._inner = inner

        self._storage_a = self._inner._storages[].get_storage[A](
            self._inner._ids[0]
        )
        self._storage_b = self._inner._storages[].get_storage[B](
            self._inner._ids[1]
        )

    @always_inline
    fn next(mut self) -> Bool:
        return self._inner.next()

    @always_inline
    fn get_entity(self, out entity: Entity):
        return self._inner.get_entity()

    @always_inline
    fn get_a(ref self) raises -> Pointer[A, __origin_of(self)]:
        return Pointer[A, __origin_of(self)].address_of(
            self._storage_a[].get_unsafe(
                self._inner._archetype[]._id, self._inner._index
            )[]
        )

    @always_inline
    fn get_b(ref self) raises -> Pointer[B, __origin_of(self)]:
        return Pointer[B, __origin_of(self)].address_of(
            self._storage_b[].get_unsafe(
                self._inner._archetype[]._id, self._inner._index
            )[]
        )
