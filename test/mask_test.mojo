from testing import *

from minecs import ID
from minecs.mask import Mask
from minecs.registry import Registry
from components import Position, Velocity


fn test_mask_get_bits() raises:
    r = Registry()
    _ = r.get_id[Position]()
    velID = r.get_id[Velocity]()[0]

    m = Mask(velID)
    comps = m.get_bits(r)

    assert_equal(comps, List[ID](velID))
