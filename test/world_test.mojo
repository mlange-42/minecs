from testing import *

from minecs import World


fn test_world_add_entity() raises:
    world = World()

    assert_equal(len(world._entities), 1)

    _ = world.add_entity()
    e = world.add_entity()
    assert_equal(len(world._entities), 3)
    assert_equal(e.id(), 2)
    assert_equal(e.gen(), 0)
