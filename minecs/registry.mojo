from collections import Dict
from .types import Component, Id


struct Registry:
    var _lookup: Dict[Id, ID]

    fn __init__(out self):
        self._lookup = Dict[Id, ID]()

    fn get_id[T: Component](mut self) -> ID:
        if T.ID in self._lookup:
            return self._lookup.get(T.ID).value()

        var id = len(self._lookup)
        self._lookup[T.ID] = id
        return id
