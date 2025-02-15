from collections import Dict
from .types import Component, Id
from .constants import TOTAL_MASK_BITS


struct Registry:
    var _lookup: Dict[Id, ID]

    fn __init__(out self):
        self._lookup = Dict[Id, ID]()

    fn get_id[T: Component](mut self) raises -> ID:
        if T.ID in self._lookup:
            return self._lookup.get(T.ID).value()

        if len(self._lookup) >= TOTAL_MASK_BITS:
            raise Error(
                String("Ran out of the capacity of {} components").format(
                    TOTAL_MASK_BITS
                )
            )
        var id = len(self._lookup)

        self._lookup[T.ID] = id
        return id
