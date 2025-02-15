from testing import *
import minecs as mx
from minecs.storage import ComponentStorage
from components import Position


fn test_storage() raises:
    var s = ComponentStorage[Position](11)
    assert_equal(s.get_type(), 11)
