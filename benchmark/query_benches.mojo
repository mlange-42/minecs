import benchmark

from components import Position, Velocity
import minecs as mx


fn benchmark_query() raises:
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
        try:
            iter = query.__iter__()
            while iter.next():
                var pos = iter.get[Position]()
                var vel = iter.get[Velocity]()
                pos[].x += vel[].x
                pos[].y += vel[].y
        except:
            pass

    var report = benchmark.run[bench]()
    print("benchmark_query")
    report.print(benchmark.Unit.ns)


fn benchmark_query2() raises:
    n = 100000
    world = mx.World()

    pos_map = world.map[Position]()
    vel_map = world.map[Velocity]()

    for _ in range(n):
        var e = world.add_entity()
        pos_map.add(e)
        vel_map.add(e)

    query = world.query_n[Position, Velocity]()

    fn bench() capturing:
        try:
            iter = query.__iter__()
            while iter.next():
                var pos = iter.get_a()
                var vel = iter.get_b()
                pos[].x += vel[].x
                pos[].y += vel[].y
        except:
            pass

    var report = benchmark.run[bench]()
    print("benchmark_query_n")
    report.print(benchmark.Unit.ns)


fn run_all() raises:
    benchmark_query()
    benchmark_query2()
