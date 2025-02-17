import benchmark

from components import Position, Velocity
import minecs as mx


fn benchmark_map_get() raises:
    n = 100000
    world = mx.World()

    pos_map = world.map[Position]()
    vel_map = world.map[Velocity]()

    for _ in range(n):
        e = world.add_entity()
        pos_map.add(e)
        vel_map.add(e)

    query = world.query[Position, Velocity]()

    fn func(e: mx.Entity) capturing:
        try:
            pos = pos_map.get(e)
            vel = vel_map.get(e)
            pos[].x += vel[].x
            pos[].y += vel[].y
        except:
            pass

    fn bench() capturing:
        query.each[func]()

    var report = benchmark.run[bench]()
    print("benchmark_map_get")
    report.print(benchmark.Unit.ns)


fn run_all() raises:
    benchmark_map_get()
