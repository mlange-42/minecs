from bit import pop_count, bit_not
from collections import InlineList, InlineArray

from .types import ID


@register_passable
struct Mask(Stringable, KeyElement):
    """Mask is a 256 bit bitmask."""

    alias total_bits = 256
    alias total_bytes = Self.total_bits // 8

    var _bytes: SIMD[DType.uint8, Self.total_bytes]

    @always_inline
    fn __init__(mut self, *bits: ID):
        """Initializes the mask with the bits at the given indices set to True.
        """
        self._bytes = SIMD[DType.uint8, Self.total_bytes]()
        for bit in bits:
            self.set[True](bit)

    @always_inline
    fn __init__(mut self, *, bytes: SIMD[DType.uint8, Self.total_bytes]):
        """Initializes the mask with the given bytes."""
        self._bytes = bytes

    fn __copyinit__(mut self, other: Self):
        """Initializes the mask with the other mask."""
        self._bytes = other._bytes

    @always_inline
    fn __hash__(self) -> UInt:
        """Hashes the mask."""
        return hash(self._bytes)

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        """Compares two masks for equality."""
        return (self._bytes == other._bytes).reduce_and()

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        """Compares two masks for inequality."""
        return not self.__eq__(other)

    @always_inline
    fn matches(self, bits: Self) -> Bool:
        """Matches the mask as filter against another mask."""
        return bits.contains(self)

    @always_inline
    fn get(self, bit: ID) -> Bool:
        """Reports whether the bit at the given index is set.

        Returns False for bit >= Self.total_bits.
        """
        var idx: ID = bit // 8
        var offset: ID = bit - (8 * idx)
        mask = 1 << offset
        return (self._bytes[index(idx)] & mask) == mask

    @always_inline
    fn set(mut self, bit: ID, value: Bool):
        """Sets the state of bit at the given index."""
        if value:
            self.set[True](bit)
        else:
            self.set[False](bit)

    @always_inline
    fn set[value: Bool](mut self, bit: ID):
        """Sets the state of bit at the given index."""
        var idx: ID = bit // 8
        var offset: ID = bit - (8 * idx)

        @parameter
        if value:
            self._bytes[index(idx)] |= 1 << offset
        else:
            self._bytes[index(idx)] &= ~(1 << offset)

    @always_inline
    fn flip(mut self, bit: ID):
        """Flips the state of bit at the given index."""
        var idx: ID = bit // 8
        var offset: ID = bit - (8 * idx)
        self._bytes[index(idx)] ^= 1 << offset

    @always_inline
    fn invert(self) -> Mask:
        """Returns the inversion of this mask."""
        return Mask(bytes=bit_not(self._bytes))

    @always_inline
    fn is_zero(self) -> Bool:
        """Returns whether no bits are set in the mask."""
        return not self._bytes.reduce_or()

    @always_inline
    fn reset(mut self):
        """Resets the mask setting all bits to False."""
        self._bytes = 0

    @always_inline
    fn contains(self, other: Self) -> Bool:
        """Reports if the other mask is a subset of this mask."""
        return ((self._bytes & other._bytes) == other._bytes).reduce_and()

    @always_inline
    fn contains_any(self, other: Self) -> Bool:
        """Reports if any bit of the other mask is in this mask."""
        return ((self._bytes & other._bytes) != 0).reduce_or()

    @always_inline
    fn total_bits_set(self) -> Int:
        """Returns how many bits are set in this mask."""
        return self._bytes.reduce_bit_count()

    fn __str__(self) -> String:
        """Implements String(...)."""
        var result: String = "["
        for i in range(len(self._bytes) * 8):
            if self.get(i):
                result += "1"
            else:
                result += "0"
        result += "]"
        return result

    @always_inline
    fn __repr__(self) -> String:
        """Representation string of the Mask."""
        return "BitMask(" + String(self._bytes) + ")"
