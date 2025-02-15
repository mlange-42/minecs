from collections import Dict
from .types import Component, Id, MAX_COMPONENTS


struct Registry:
    var _lookup: Dict[Id, ID]

    fn __init__(out self):
        self._lookup = Dict[Id, ID]()

    fn get_id[T: Component](mut self) raises -> ID:
        if T.ID in self._lookup:
            return self._lookup.get(T.ID).value()

        if len(self._lookup) >= MAX_COMPONENTS:
            raise Error(
                String("Ran out of the capacity of {} components").format(
                    MAX_COMPONENTS
                )
            )
        var id = len(self._lookup)

        self._lookup[T.ID] = id
        return id
