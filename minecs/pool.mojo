from .types import EntityID
from .entity import Entity
from .constants import MAX_UINT32


struct EntityPool(Movable, Copyable):
    """EntityPool is an implementation using implicit linked lists.

    Implements https:#skypjack.github.io/2019-05-06-ecs-baf-part-3/
    """

    var _entities: List[Entity]
    var _next: EntityID
    var _available: Int

    @always_inline
    fn __init__(mut self):
        self._entities = List[Entity]()
        self._entities.append(Entity(0, MAX_UINT32))
        self._next = 0
        self._available = 0

    fn __copyinit__(out self, other: Self):
        self._entities = other._entities
        self._next = other._next
        self._available = other._available

    fn __moveinit__(out self, owned other: Self):
        self._entities = other._entities^
        self._next = other._next
        self._available = other._available

    fn get(mut self) -> Entity:
        """Returns a fresh or recycled entity."""
        if self._available == 0:
            return self._get_new()

        curr = self._next
        self._entities[self._next]._id, self._next = (
            self._next,
            self._entities[self._next].id(),
        )
        self._available -= 1
        return self._entities[curr]

    @always_inline
    fn _get_new(mut self, out entity: Entity):
        """Allocates and returns a new entity. For internal use."""
        entity = Entity(EntityID(len(self._entities)))
        self._entities.append(entity)

    fn recycle(mut self, enitity: Entity) raises:
        """Hands an entity back for recycling."""
        if enitity.id() == 0:
            raise Error("Can't recycle reserved zero entity")

        self._entities[enitity.id()]._gen += 1
        self._next, self._entities[enitity.id()]._id = (
            enitity.id(),
            self._next,
        )
        self._available += 1

    @always_inline
    fn reset(mut self):
        """Recycles all entities. Does NOT free the reserved memory."""
        self._entities.resize(1)
        self._next = 0
        self._available = 0

    @always_inline
    fn is_alive(self, entity: Entity) -> Bool:
        """Returns whether an entity is still alive, based on the entity's generations.
        """
        return entity._gen == self._entities[entity.id()]._gen

    @always_inline
    fn __len__(self) -> Int:
        """Returns the current number of used entities."""
        return len(self._entities) - 1 - self._available

    @always_inline
    fn capacity(self) -> Int:
        """Returns the current capacity (used and recycled entities)."""
        return len(self._entities) - 1

    @always_inline
    fn available(self) -> Int:
        """Returns the current number of available/recycled entities."""
        return self._available
