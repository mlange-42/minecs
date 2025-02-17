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

    fn func(e: Entity) capturing:
        print(String(e))

    query.each[func]()
