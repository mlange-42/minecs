from testing import *

from minecs import World, ID
from minecs.mask import Mask

from components import Position, Velocity


fn test_world_add_entity() raises:
    world = World()

    assert_equal(len(world._entities), 1)

    _ = world.add_entity()
    e = world.add_entity()
    assert_equal(len(world._entities), 3)
    assert_equal(e.id(), 2)
    assert_equal(e.gen(), 0)

    assert_equal(len(world._archetypes[0]._entities), 2)


fn test_world_exchange_mask() raises:
    world = World()

    mask = Mask(0, 1, 2)

    world._exchange_on_mask(mask, List[ID](), List[ID]())
    assert_equal(mask, Mask(0, 1, 2))

    world._exchange_on_mask(mask, List[ID](3), List[ID]())
    assert_equal(mask, Mask(0, 1, 2, 3))

    world._exchange_on_mask(mask, List[ID](), List[ID](0, 1, 2))
    assert_equal(mask, Mask(3))


fn test_world_exchange() raises:
    world = World()
    pos_id = world.component_id[Position]()
    vel_id = world.component_id[Velocity]()
    assert_equal(world._storages._length, 2)

    pos_map = world.get_map[Position]()
    vel_map = world.get_map[Velocity]()

    e1 = world.add_entity()
    e2 = world.add_entity()
    assert_false(pos_map.has(e1))
    assert_false(vel_map.has(e1))

    world._exchange(e1, List[ID](pos_id), List[ID]())
    world._exchange(e2, List[ID](vel_id), List[ID]())

    assert_true(pos_map.has(e1))
    assert_false(vel_map.has(e1))

    assert_false(pos_map.has(e2))
    assert_true(vel_map.has(e2))

    world._exchange(e1, List[ID](vel_id), List[ID](pos_id))
    assert_false(pos_map.has(e1))
    assert_true(vel_map.has(e1))

    vel = vel_map.get(e1)
    vel[].x = 100
    vel = vel_map.get(e1)
    assert_equal(vel[].x, 100)
