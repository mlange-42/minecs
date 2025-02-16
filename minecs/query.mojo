from collections import InlineArray

from .types import ID


struct Query[world_origin: MutableOrigin, *Ts: Component]:
    alias component_count = len(VariadicList(Ts))

    var _world: Pointer[World, world_origin]
    var _ids: List[ID]  # TODO: use inline array

    fn __init__(out self, world: Pointer[World, world_origin]) raises:
        self._world = world
        self._ids = List[ID]()

        @parameter
        for i in range(len(VariadicList(Ts))):
            self._ids.append(self._world[].component_id[Ts[i]]())
