from collections import InlineArray
from sys.intrinsics import _type_is_eq

from .entity import Entity
from .mask import Mask
from .types import ID
from .util import _contains_type


struct EntityAccess:
    pass


struct Query[world_origin: MutableOrigin, *Ts: Component]:
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

    fn each(self, func: fn (entity: Entity)):
        for arch_idx in range(len(self._world[]._archetypes)):
            arch = self._world[]._archetypes[arch_idx]
            if not arch.mask().contains(self._mask):
                continue

            for e in arch._entities:
                func(e[])

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
