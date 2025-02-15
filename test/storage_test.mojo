from testing import *
import minecs as mx
from minecs.storage import ArchetypeStorage, ComponentStorage, Storages
from minecs.registry import Registry
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

    arch1Idx = posStorage[].add_archetype()
    arch = posStorage[].get_archetype(arch1Idx)
    arch.add(Position(1, 2))

    posStorage = s.get[Position](posId)
    velStorage = s.get[Velocity](velId)
    assert_equal(len(posStorage[]._archetypes), 2)
    assert_equal(len(velStorage[]._archetypes), 1)
