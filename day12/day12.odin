package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
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

Region :: struct {
	type:               rune,
	area, peri_or_side: int,
}

Vec2 :: struct {
	x, y: int,
}

lookup :: proc(lines: ^[dynamic]string, x, y: int, r: ^Region, field_map: ^map[Vec2]struct {}) {
	field_map[Vec2{x = x, y = y}] = {}
	r.area += 1

	if x > 0 {
		nx, ny := x - 1, y
		if rune(lines[ny][nx]) == r.type {
			if (Vec2{x = nx, y = ny} not_in field_map) {
				lookup(lines, nx, ny, r, field_map)
			}
		} else {
			r.peri_or_side += 1
		}
	} else {
		r.peri_or_side += 1
	}
	if y > 0 {
		nx, ny := x, y - 1
		if rune(lines[ny][nx]) == r.type {
			if (Vec2{x = nx, y = ny} not_in field_map) {
				lookup(lines, nx, ny, r, field_map)
			}
		} else {
			r.peri_or_side += 1
		}
	} else {
		r.peri_or_side += 1
	}
	if x < len(lines[y]) - 1 {
		nx, ny := x + 1, y
		if rune(lines[ny][nx]) == r.type {
			if (Vec2{x = nx, y = ny} not_in field_map) {
				lookup(lines, nx, ny, r, field_map)
			}
		} else {
			r.peri_or_side += 1
		}
	} else {
		r.peri_or_side += 1
	}
	if y < len(lines) - 1 {
		nx, ny := x, y + 1
		if rune(lines[ny][nx]) == r.type {
			if (Vec2{x = nx, y = ny} not_in field_map) {
				lookup(lines, nx, ny, r, field_map)
			}
		} else {
			r.peri_or_side += 1
		}
	} else {
		r.peri_or_side += 1
	}
}

part1 :: proc(lines: ^[dynamic]string) {
	field_map := make(map[Vec2]struct {})
	defer delete(field_map)

	p1 := 0

	for row, y in lines {
		for ch, x in row {
			if (Vec2{x = x, y = y} in field_map) {
				continue
			}

			r := new(Region)
			r.type = ch
			lookup(lines, x, y, r, &field_map)
			//fmt.println(r)

			p1 += (r.area * r.peri_or_side)
			free(r)
		}
	}
	fmt.printfln("Part One: %d", p1)
}

part2 :: proc(lines: ^[dynamic]string) {

}