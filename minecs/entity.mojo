from bit import bit_reverse

from .types import EntityID, ArchetypeID


@register_passable("trivial")
struct Entity(EqualityComparable, Stringable, Hashable):
    var _id: EntityID
    """Entity ID"""
    var _gen: UInt32
    """Entity generation"""

    @doc_private
    @always_inline
    fn __init__(mut self, id: EntityID = 0, gen: UInt32 = 0):
        self._id = id
        self._gen = gen

    @always_inline
    fn __eq__(self, other: Entity) -> Bool:
        """
        Compares two entities for equality.

        Args:
            other: The other entity to compare to.
        """
        return self._id == other._id and self._gen == other._gen

    @always_inline
    fn __ne__(self, other: Entity) -> Bool:
        """
        Compares two entities for inequality.

        Args:
            other: The other entity to compare to.
        """
        return not (self == other)

    @always_inline
    fn __bool__(self) -> Bool:
        """
        Returns whether this entity is not the zero entity.
        """
        return self._id != 0

    @always_inline
    fn __str__(self) -> String:
        """
        Returns a string representation of the entity.
        """
        return "Entity(" + String(self._id) + ", " + String(self._gen) + ")"

    @always_inline
    fn __hash__(self, out output: UInt):
        """Returns a unique hash of the entity."""
        output = Int(self._id)
        output |= bit_reverse(Int(self._gen))

    @always_inline
    fn id(self) -> EntityID:
        """Returns the entity's ID."""
        return self._id

    @always_inline
    fn gen(self) -> UInt32:
        """Returns the entity's generation."""
        return self._gen

    @always_inline
    fn is_zero(self) -> Bool:
        """Returns whether this entity is the reserved zero entity."""
        return self._id == 0


@value
@register_passable("trivial")
struct EntityIndex:
    """Indicates where an entity's components are currently stored."""

    var archetype: ArchetypeID
    var index: UInt32
