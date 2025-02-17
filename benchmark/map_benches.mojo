import benchmark

from components import Position, Velocity
import minecs as mx


fn benchmark_map_get() raises:
    n = 100000
    world = mx.World()

    pos_map = world.map[Position]()
    vel_map = world.map[Velocity]()

    for _ in range(n):
        var e = world.add_entity()
        pos_map.add(e)
        vel_map.add(e)

    query = world.query[Position, Velocity]()

    fn bench() capturing:
        var e = mx.Entity()
        iter = query.__iter__()
        try:
            while iter.next():
                var pos = iter.get[Position]()
                var vel = iter.get[Velocity]()
                pos[].x += vel[].x
                pos[].y += vel[].y
        except:
            pass
        benchmark.keep(e)

    var report = benchmark.run[bench]()
    print("benchmark_map_get")
    report.print(benchmark.Unit.ns)


fn run_all() raises:
    benchmark_map_get()
