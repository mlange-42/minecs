from .types import Component, ID


trait Storage:
    fn get_type(self) -> ID:
        ...


@value
struct ComponentStorage[T: Component](Storage):
    fn get_type(self) -> ID:
        return T.ID.id()


struct ArchetypeStorage:
    pass
