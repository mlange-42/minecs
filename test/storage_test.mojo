from testing import *
import minecs as mx
from minecs.storage import ComponentStorage


struct Position(mx.Component):
    alias ID = mx.Id("minecs/test/Position")


fn test_query_length() raises:
    var s = ComponentStorage[Position]()
