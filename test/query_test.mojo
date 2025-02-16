from minecs import World
from minecs.query import Query

from components import Position, Velocity


fn test_query() raises:
    world = World()

    pos_map = world.map[Position]()
    vel_map = world.map[Velocity]()

    for _ in range(100):
        e = world.add_entity()
        pos_map.add(e)
        vel_map.add(e)

    query = world.query[Position, Velocity]()
