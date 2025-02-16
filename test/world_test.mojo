from testing import *

from minecs import World, ID
from minecs.mask import Mask


fn test_world_add_entity() raises:
    world = World()

    assert_equal(len(world._entities), 1)

    _ = world.add_entity()
    e = world.add_entity()
    assert_equal(len(world._entities), 3)
    assert_equal(e.id(), 2)
    assert_equal(e.gen(), 0)


fn test_world_exchange_mask() raises:
    world = World()

    mask = Mask(0, 1, 2)

    world._exchange_on_mask(mask, List[ID](), List[ID]())
    assert_equal(mask, Mask(0, 1, 2))

    world._exchange_on_mask(mask, List[ID](3), List[ID]())
    assert_equal(mask, Mask(0, 1, 2, 3))

    world._exchange_on_mask(mask, List[ID](), List[ID](0, 1, 2))
    assert_equal(mask, Mask(3))
