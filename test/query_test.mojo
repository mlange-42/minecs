from minecs import World, Entity
from minecs.query import Query

from components import Position, Velocity


fn test_query() raises:
    world = World()

    pos_map = world.map[Position]()
    vel_map = world.map[Velocity]()

    for _ in range(10):
        e = world.add_entity()
        pos_map.add(e)

    for _ in range(10):
        e = world.add_entity()
        pos_map.add(e)
        vel_map.add(e)

    query = world.query[Velocity]()
    iter = query.__iter__()
    while iter.next():
        print(String(iter.get_entity()))
