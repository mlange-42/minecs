from testing import *
import minecs as mx
from minecs.storage import ArchetypeStorage, ComponentStorage, Storages
from minecs.registry import Registry
from minecs.entity import EntityIndex
from minecs.mask import Mask
from components import Position, Velocity


fn test_storage() raises:
    var s = ComponentStorage[Position](11)
    assert_equal(s.get_type(), 11)


fn test_storages() raises:
    var r = Registry()
    var s = Storages()

    posId = r.get_id[Position]()
    velId = r.get_id[Velocity]()

    s.add[Position](posId)
    s.add[Position](velId)

    posStorage = s.get[Position](posId)
    velStorage = s.get[Velocity](velId)
    assert_equal(posStorage[]._component, posId)
    assert_equal(velStorage[]._component, velId)

    arch1Idx = posStorage[].add_archetype(Mask(posId, velId))
    arch1 = posStorage[].get_archetype(arch1Idx)
    _ = arch1[].add(Position(1, 2))

    arch2Idx = posStorage[].add_archetype(Mask(posId, velId))
    arch2 = posStorage[].get_archetype(arch2Idx)
    for i in range(1024):
        _ = arch2[].add(Position(i * 2, i * 2 + 1))
    assert_equal(len(arch2[]._data), 1024)

    _ = velStorage[].add_archetype(Mask(posId, velId))

    posStorage = s.get[Position](posId)
    assert_equal(len(posStorage[]._archetypes), 2)
    assert_equal(len(velStorage[]._archetypes), 1)

    arch2 = posStorage[].get_archetype(arch2Idx)
    assert_equal(len(arch2[]._data), 1024)
    assert_equal(arch2[]._data[0].x, 0)
    assert_equal(arch2[]._data[0].y, 1)
    assert_equal(arch2[]._data[100].x, 200)
    assert_equal(arch2[]._data[100].y, 201)

    pos = posStorage[].get_ptr(EntityIndex(arch2Idx, 100))
    assert_equal(pos[].x, 200)
    assert_equal(pos[].y, 201)


fn test_storage_add_remove() raises:
    var r = Registry()
    var storages = Storages()

    posId = r.get_id[Position]()
    storages.add[Position](posId)

    s = storages.get[Position](posId)
    arch_idx = s[].add_archetype(Mask(posId))

    for i in range(8):
        _ = s[].get_archetype(arch_idx)[].add(Position(i, i + 1))

    assert_equal(len(s[].get_archetype(arch_idx)[]), 8)

    swapped = s[].remove(EntityIndex(arch_idx, 7))
    assert_false(swapped)
    assert_equal(len(s[].get_archetype(arch_idx)[]), 7)

    swapped = s[].remove(EntityIndex(arch_idx, 0))
    assert_true(swapped)
    assert_equal(len(s[].get_archetype(arch_idx)[]), 6)

    pos = s[].get_ptr(EntityIndex(arch_idx, 0))
    assert_equal(pos[].x, 6)
