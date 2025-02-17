from collections import List

from .entity import Entity
from .mask import Mask
from .types import ArchetypeID, ID


@value
struct Archetype(CollectionElement):
    var _id: ArchetypeID
    var _components: List[ID]
    var _mask: Mask
    var _entities: List[Entity]

    fn __init__(
        out self, id: ArchetypeID, components: List[ID], owned mask: Mask
    ):
        self._id = id
        self._components = components
        self._mask = mask^
        self._entities = List[Entity]()

    @always_inline
    fn mask(self) -> ref [self._mask] Mask:
        return self._mask

    @always_inline
    fn components(self) -> ref [self._components] List[ID]:
        return self._components

    fn add(mut self, entity: Entity) -> UInt32:
        self._entities.append(entity)
        return len(self._entities) - 1

    fn remove(mut self, index: UInt32) -> Bool:
        old_idx = len(self._entities) - 1
        swapped = index != old_idx

        if swapped:
            self._entities[index] = self._entities[old_idx]

        self._entities.resize(len(self._entities) - 1)
        return swapped
