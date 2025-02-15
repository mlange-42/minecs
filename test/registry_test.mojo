from testing import *
from minecs.registry import Registry
from components import Position, Velocity


fn test_registry() raises:
    var r = Registry()

    posID = r.get_id[Position]()
    velID = r.get_id[Velocity]()

    assert_equal(posID, 0)
    assert_equal(velID, 1)

    velID = r.get_id[Velocity]()
    assert_equal(velID, 1)
