from sys.intrinsics import _type_is_eq

from .types import Component


@always_inline
fn _contains_type[T: Component, *Ts: Component]() -> Bool:
    @parameter
    for i in range(len(VariadicList(Ts))):

        @parameter
        if _type_is_eq[T, Ts[i]]():
            return True
    return False
