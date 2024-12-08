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

Vec2 :: struct {
	x, y: i8,
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

	a_map := make(map[rune][dynamic]Vec2)
	defer {
		for _, e in a_map {
			delete(e)
		}
		delete(a_map)
	}
	for line, y in lines {
		for ch, x in line {
			if ch == '.' {continue}

			if _, ok := a_map[ch]; !ok {
				a_map[ch] = make([dynamic]Vec2)
			}
			append(&a_map[ch], Vec2{x = i8(x), y = i8(y)})
		}
	}

	sw := time.Stopwatch{}
	time.stopwatch_reset(&sw)
	time.stopwatch_start(&sw)
	part1(a_map, i8(len(lines[0]) - 1), i8(len(lines) - 1))
	time.stopwatch_stop(&sw)
	fmt.printfln("Part 1 took %d", sw._accumulation)
	time.stopwatch_reset(&sw)
	time.stopwatch_start(&sw)
	part2(a_map, i8(len(lines[0]) - 1), i8(len(lines) - 1))
	time.stopwatch_stop(&sw)
	fmt.printfln("Part 2 took %d", sw._accumulation)
}

part1 :: proc(a_map: map[rune][dynamic]Vec2, mx, my: i8) {
	p1 := 0
	s_set := make(map[Vec2]bool)
	defer delete(s_set)
	for _, c_vec in a_map {
		if len(c_vec) == 1 {continue}

		for vec in c_vec {
			comp := vec
			for i_vec in c_vec {
				if comp == i_vec {continue}

				nx, ny := comp.x - i_vec.x, comp.y - i_vec.y
				v_case := Vec2 {
					x = comp.x + nx,
					y = comp.y + ny,
				}
				if _, ok := s_set[v_case];
				   ok || v_case.x < 0 || v_case.x > mx || v_case.y < 0 || v_case.y > my {continue}
				s_set[v_case] = true
				p1 += 1
			}
		}
	}

	fmt.printfln("Part One: %d", p1)
}

part2 :: proc(a_map: map[rune][dynamic]Vec2, mx, my: i8) {
	p2 := 0
	s_set := make(map[Vec2]bool)
	defer delete(s_set)
	for _, c_vec in a_map {
		if len(c_vec) == 1 {continue}

		for vec in c_vec {
			comp := vec
			if _, ok := s_set[comp]; !ok {
				s_set[comp] = true
				p2 += 1
			}
			for i_vec in c_vec {
				if comp == i_vec {continue}
				nx, ny := comp.x - i_vec.x, comp.y - i_vec.y
				v_case := comp
				freq_step: for {
					v_case = Vec2 {
						x = v_case.x + nx,
						y = v_case.y + ny,
					}
					if _, ok := s_set[v_case]; ok {continue freq_step}
					if v_case.x < 0 ||
					   v_case.x > mx ||
					   v_case.y < 0 ||
					   v_case.y > my {break freq_step}
					s_set[v_case] = true
					p2 += 1
				}
			}
		}
	}

	fmt.printfln("Part Two: %d", p2)
}
