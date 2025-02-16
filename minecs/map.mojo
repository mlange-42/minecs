from .entity import Entity
from .storage import ComponentStorage, Storages
from .types import Component, ID
from .world import World


struct Map[world_origin: MutableOrigin, T: Component]:
    var _world: Pointer[World, world_origin]
    var _id: ID

    fn __init__(
        out self,
        world: Pointer[World, world_origin],
    ) raises:
        self._world = world
        self._id = self._world[].component_id[T]()

    fn get(
        self,
        entity: Entity,
    ) raises -> Pointer[T, __origin_of(self._world[])]:
        storage = self._world[]._storages.get_storage[T](self._id)
        return storage[].get_ptr[__origin_of(self._world[])](
            self._world[]._get_entity_index(entity)
        )

    fn has(
        self,
        entity: Entity,
    ) raises -> Bool:
        storage = self._world[]._storages.get_storage[T](self._id)
        return storage[].has_archetype(
            self._world[]._get_entity_index(entity).archetype
        )
