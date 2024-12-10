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

Vec2 :: struct {
	x, y: int,
}

lookup :: proc(lines: ^[dynamic]string, c_ele, x, y: int, s_set: ^map[Vec2]bool) -> int {
	c9 := 0

	if x > 0 {
		nx, ny := x - 1, y
		if int(lines[ny][nx] - '0') == c_ele {
			if k := s_set[Vec2{x = nx, y = ny}]; !k && c_ele == 9 {
				s_set[Vec2{x = nx, y = ny}] = true
				c9 += 1
			} else {
				c9 += lookup(lines, c_ele + 1, nx, ny, s_set)
			}
		}
	}
	if y > 0 {
		nx, ny := x, y - 1
		if int(lines[ny][nx] - '0') == c_ele {
			if k := s_set[Vec2{x = nx, y = ny}]; !k && c_ele == 9 {
				s_set[Vec2{x = nx, y = ny}] = true
				c9 += 1
			} else {
				c9 += lookup(lines, c_ele + 1, nx, ny, s_set)
			}
		}
	}
	if x < len(lines[y]) - 1 {
		nx, ny := x + 1, y
		if int(lines[ny][nx] - '0') == c_ele {
			if k := s_set[Vec2{x = nx, y = ny}]; !k && c_ele == 9 {
				s_set[Vec2{x = nx, y = ny}] = true
				c9 += 1
			} else {
				c9 += lookup(lines, c_ele + 1, nx, ny, s_set)
			}
		}
	}
	if y < len(lines) - 1 {
		nx, ny := x, y + 1
		if int(lines[ny][nx] - '0') == c_ele {
			if k := s_set[Vec2{x = nx, y = ny}]; !k && c_ele == 9 {
				s_set[Vec2{x = nx, y = ny}] = true
				c9 += 1
			} else {
				c9 += lookup(lines, c_ele + 1, nx, ny, s_set)
			}
		}
	}

	return c9
}

part1 :: proc(lines: ^[dynamic]string) {
	p1 := 0

	for y := 0; y < len(lines); y += 1 {
		for x := 0; x < len(lines[y]); x += 1 {
			if lines[y][x] == '0' {
				s_set := make(map[Vec2]bool)
				defer delete(s_set)

				p1 += lookup(lines, 1, x, y, &s_set)
			}
		}
	}

	fmt.printfln("Part One: %d", p1)
}

lookup2 :: proc(lines: ^[dynamic]string, c_ele, x, y: int) -> int {
	c9 := 0

	if x > 0 {
		nx, ny := x - 1, y
		if int(lines[ny][nx] - '0') == c_ele {
			if c_ele == 9 {
				c9 += 1
			} else {
				c9 += lookup2(lines, c_ele + 1, nx, ny)
			}
		}
	}
	if y > 0 {
		nx, ny := x, y - 1
		if int(lines[ny][nx] - '0') == c_ele {
			if c_ele == 9 {
				c9 += 1
			} else {
				c9 += lookup2(lines, c_ele + 1, nx, ny)
			}
		}
	}
	if x < len(lines[y]) - 1 {
		nx, ny := x + 1, y
		if int(lines[ny][nx] - '0') == c_ele {
			if c_ele == 9 {
				c9 += 1
			} else {
				c9 += lookup2(lines, c_ele + 1, nx, ny)
			}
		}
	}
	if y < len(lines) - 1 {
		nx, ny := x, y + 1
		if int(lines[ny][nx] - '0') == c_ele {
			if c_ele == 9 {
				c9 += 1
			} else {
				c9 += lookup2(lines, c_ele + 1, nx, ny)
			}
		}
	}

	return c9
}

part2 :: proc(lines: ^[dynamic]string) {
	p2 := 0

	for y := 0; y < len(lines); y += 1 {
		for x := 0; x < len(lines[y]); x += 1 {
			if lines[y][x] == '0' {
				p2 += lookup2(lines, 1, x, y)
			}
		}
	}

	fmt.printfln("Part Two: %d", p2)
}
