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

    fn _exchange(mut self, entity: Entity, add: List[ID], rem: List[ID]) raises:
        if not self.is_alive(entity):
            raise Error("can't exchange components on a dead entity")
        if len(add) == 0 and len(rem) == 0:
            return

        index = self._entities[entity.id()]
        old_arch = Pointer.address_of(self._archetypes[index.archetype])

        mask = old_arch[].mask()
        self._exchange_on_mask(mask, add, rem)

        old_ids = old_arch[].components()

        arch_idx = self._find_or_create_archetype(mask)
        new_index = self._archetypes[arch_idx].add(entity)

        # TODO continue

    fn _find_or_create_archetype(mut self, read mask: Mask) -> ArchetypeID:
        # TODO: use archetype graph
        index = -1
        for i in range(len(self._archetypes)):
            if self._archetypes[i].mask() == mask:
                index = i
                break

        if index < 0:
            index = Int(self._create_archetype(mask))
        return ArchetypeID(index)

    fn _create_archetype(mut self, read mask: Mask) -> ArchetypeID:
        comps = mask.get_bits(self._registry)
        index = len(self._archetypes)
        self._archetypes.append(Archetype(index, comps, mask))
        self._storages.add_archetype(mask)
        return index

    fn _exchange_on_mask(
        self, mut mask: Mask, add: List[ID], rem: List[ID]
    ) raises:
        for comp in rem:
            if not mask.get(comp[]):
                raise Error(
                    "entity does not have a component of type ID {}, can't"
                    " remove".format(comp[])
                )
            mask.set(comp[], False)

        for comp in add:
            if mask.get(comp[]):
                raise Error(
                    "entity already has component of type %v, can't add".format(
                        comp[]
                    )
                )
            mask.set(comp[], True)
