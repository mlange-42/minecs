from .archetype import Archetype
from .entity import Entity, EntityIndex
from .mask import Mask
from .pool import EntityPool
from .registry import Registry
from .storage import Storages
from .types import ArchetypeID


struct World:
    var _registry: Registry
    var _storages: Storages
    var _archetypes: List[Archetype]

    var _entity_pool: EntityPool
    var _entities: List[EntityIndex, hint_trivial_type=True]

    fn __init__(out self):
        self._registry = Registry()
        self._storages = Storages()
        self._archetypes = List[Archetype]()
        self._archetypes.append(Archetype(ArchetypeID(0), List[ID](), Mask()))

        self._entity_pool = EntityPool()
        self._entities = List[EntityIndex, hint_trivial_type=True](
            EntityIndex(0, 0)
        )

    fn add_entity(mut self) -> Entity:
        return self._create_entity(0)

    @always_inline
    fn is_alive(self, entity: Entity) -> Bool:
        return self._entity_pool.is_alive(entity)

    fn _create_entity(mut self, arch: ArchetypeID) -> Entity:
        entity = self._entity_pool.get()

        idx = self._archetypes[arch].add(entity)
        len = len(self._entities)
        if entity.id() == len:
            self._entities.append(EntityIndex(arch, idx))
        else:
            self._entities[entity.id()] = EntityIndex(arch, idx)
        return entity

    @always_inline
    fn _get_entity_index(self, entity: Entity) raises -> EntityIndex:
        if not self.is_alive(entity):
            raise Error("can't get component of a dead entity")
        return self._entities[entity.id()]
