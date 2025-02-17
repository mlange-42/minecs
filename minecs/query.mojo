from collections import InlineArray
from sys.intrinsics import _type_is_eq

from .archetype import Archetype
from .entity import Entity
from .mask import Mask
from .storage import Storages
from .types import ID
from .util import _contains_type


struct EntityAccess:
    pass


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
    ):
        iterator = Self.Iterator(
            # self._world,
            Pointer.address_of(self._world[]._archetypes),
            Pointer.address_of(self._world[]._storages),
            self._mask,
            self._ids,
        )

    fn each[func: fn (entity: Entity) capturing](self):
        for arch_idx in range(len(self._world[]._archetypes)):
            arch = Pointer.address_of(self._world[]._archetypes[arch_idx])
            if not arch[].mask().contains(self._mask):
                continue

            for e in arch[]._entities:
                func(e[])


@value
struct QueryIterator[
    archetype_mutability: Bool, //,
    # world_origin: MutableOrigin,
    archetype_origin: Origin[archetype_mutability],
    storages_origin: MutableOrigin,
    *Ts: Component,
]:
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
    ):
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
    fn __iter__(owned self, out iterator: Self):
        iterator = self^

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
    fn get[T: Component](self) raises -> Pointer[T, Self.storages_origin]:
        storage = self._storages[].get_storage[T](self.get_id[T]())
        return storage[].get_ptr[Self.storages_origin](
            self._archetype[]._id, self._index
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
