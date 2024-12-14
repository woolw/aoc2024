package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"

read_file_by_lines_in_whole :: proc(filepath: string) -> ([dynamic]string, bool) {
	data, ok := os.read_entire_file(filepath, context.allocator)
	result: [dynamic]string
	if !ok {
		fmt.println("couldn't read file")
		return result, false
	}
	defer delete(data, context.allocator)

	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		if len(strings.trim(line, " ")) < 1 {continue}
		append(&result, strings.clone(strings.trim(line, " ")))
	}
	return result, len(result) > 0
}

main :: proc() {
	when ODIN_DEBUG {
		context.logger = log.create_console_logger()

		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			} else {
				fmt.eprint("=== all allocations freed ===\n")
			}

			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			} else {
				fmt.eprint("=== no incorrect frees ===\n")
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	lines, ok := read_file_by_lines_in_whole("input")
	if !ok {return}
	defer {
		for line in lines {
			delete(line)
		}
		delete(lines)
	}

	sw := time.Stopwatch{}
	time.stopwatch_reset(&sw)
	time.stopwatch_start(&sw)
	part1(&lines)
	time.stopwatch_stop(&sw)
	fmt.printfln("Part 1 took %d", sw._accumulation)
	time.stopwatch_reset(&sw)
	time.stopwatch_start(&sw)
	part2(&lines)
	time.stopwatch_stop(&sw)
	fmt.printfln("Part 2 took %d", sw._accumulation)
}

Vec2 :: struct {
	x, y: int,
}

SECONDS :: 100
GRID :: Vec2 {
	x = 101,
	y = 103,
}

part1 :: proc(lines: ^[dynamic]string) {
	tl, tr, bl, br := 0, 0, 0, 0
	for line in lines {
		splits := strings.split(line, " ")
		defer delete(splits)

		coords := strings.split(splits[0][2:], ",")
		defer delete(coords)
		pos := Vec2 {
			x = strconv.atoi(coords[0]),
			y = strconv.atoi(coords[1]),
		}

		vels := strings.split(splits[1][2:], ",")
		defer delete(vels)
		vel := Vec2 {
			x = strconv.atoi(vels[0]),
			y = strconv.atoi(vels[1]),
		}
		x := (SECONDS * vel.x + pos.x) % GRID.x
		y := (SECONDS * vel.y + pos.y) % GRID.y

		x100 := x < 0 ? GRID.x + x : x
		y100 := y < 0 ? GRID.y + y : y


		vert := int((GRID.x / 2))
		horz := int((GRID.y / 2))
		if x100 == vert || y100 == horz {continue}

		if x100 < vert {
			if y100 < horz {
				tl += 1
			} else {
				bl += 1
			}
		} else {
			if y100 < horz {
				tr += 1
			} else {
				br += 1
			}
		}
	}

	p1 := tl * tr * bl * br

	fmt.printfln("Part One: %d", p1)
}

Bot :: struct {
	pos, vel: Vec2,
}

part2 :: proc(lines: ^[dynamic]string) {
	bots := make([dynamic]Bot)
	defer delete(bots)
	for line in lines {
		splits := strings.split(line, " ")
		defer delete(splits)

		coords := strings.split(splits[0][2:], ",")
		defer delete(coords)
		pos := Vec2 {
			x = strconv.atoi(coords[0]),
			y = strconv.atoi(coords[1]),
		}

		vels := strings.split(splits[1][2:], ",")
		defer delete(vels)
		vel := Vec2 {
			x = strconv.atoi(vels[0]),
			y = strconv.atoi(vels[1]),
		}

		append(&bots, Bot{pos, vel})
	}
	p2 := 0

	for gi := 1; gi <= GRID.x * GRID.y; gi += 1 {
		x_mean, y_mean := 0, 0
		for bot in bots {
			x := (gi * bot.vel.x + bot.pos.x) % GRID.x
			y := (gi * bot.vel.y + bot.pos.y) % GRID.y

			x_mean += x < 0 ? GRID.x + x : x
			y_mean += y < 0 ? GRID.y + y : y
		}
		x_mean = x_mean / len(bots)
		y_mean = y_mean / len(bots)

		x_sq_diff, y_sq_diff := 0, 0
		for bot in bots {
			x := (gi * bot.vel.x + bot.pos.x) % GRID.x
			y := (gi * bot.vel.y + bot.pos.y) % GRID.y

			x = x < 0 ? GRID.x + x : x
			y = y < 0 ? GRID.y + y : y

			x_sq_diff += (x - x_mean) * (x - x_mean)
			y_sq_diff += (y - y_mean) * (y - y_mean)
		}
		x_devi := math.sqrt(f64(x_sq_diff / len(bots)))
		y_devi := math.sqrt(f64(y_sq_diff / len(bots)))
		if x_devi < 25 && y_devi < 25 {
			fmt.println(gi, x_devi, y_devi)

			p2 = p2 == 0 ? gi : min(p2, gi)
		}
	}

	fmt.printfln("Part Two: %d", p2)
}
