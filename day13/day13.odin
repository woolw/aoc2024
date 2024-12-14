package main

import "core:fmt"
import "core:log"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:text/regex"
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

part1 :: proc(lines: ^[dynamic]string) {
	p1 := 0

	pat, err := regex.create(`.*?X.(\d+).*?Y.(\d+)`)
	if err != nil {
		log.panic(err)
	}
	defer {
		delete(pat.program)
		for c in pat.class_data {
			delete(c.ranges)
		}
		delete(pat.class_data)
	}

	game: for idx := 0; idx < len(lines); idx += 3 {
		a_cap, a_ok := regex.match_and_allocate_capture(pat, lines[idx + 0])
		if !a_ok {
			log.panic("a_cap failed")
		}
		defer {
			delete(a_cap.groups)
			delete(a_cap.pos)
		}

		a := Vec2 {
			x = strconv.atoi(a_cap.groups[1]),
			y = strconv.atoi(a_cap.groups[2]),
		}

		b_cap, b_ok := regex.match_and_allocate_capture(pat, lines[idx + 1])
		if !b_ok {
			log.panic("b_cap failed")
		}
		defer {
			delete(b_cap.groups)
			delete(b_cap.pos)
		}

		b := Vec2 {
			x = strconv.atoi(b_cap.groups[1]),
			y = strconv.atoi(b_cap.groups[2]),
		}

		p_cap, p_ok := regex.match_and_allocate_capture(pat, lines[idx + 2])
		if !p_ok {
			log.panic("p_cap failed")
		}
		defer {
			delete(p_cap.groups)
			delete(p_cap.pos)
		}

		prize := Vec2 {
			x = strconv.atoi(p_cap.groups[1]),
			y = strconv.atoi(p_cap.groups[2]),
		}

		cheapest := 0
		for a_count in 0 ..= 100 {
			for b_count in 0 ..= 100 {
				x := prize.x - (a_count * a.x) - (b_count * b.x)
				y := prize.y - (a_count * a.y) - (b_count * b.y)

				coins := a_count * 3 + b_count
				if x == 0 && y == 0 && (cheapest == 0 || coins < cheapest) {
					cheapest = coins
				}
			}
		}

		if cheapest > 0 {
			p1 += cheapest
		}
	}

	fmt.printfln("Part One: %d", p1)
}

part2 :: proc(lines: ^[dynamic]string) {
	p2 := 0

	pat, err := regex.create(`.*?X.(\d+).*?Y.(\d+)`)
	if err != nil {
		log.panic(err)
	}
	defer {
		delete(pat.program)
		for c in pat.class_data {
			delete(c.ranges)
		}
		delete(pat.class_data)
	}

	game: for idx := 0; idx < len(lines); idx += 3 {
		a_cap, a_ok := regex.match_and_allocate_capture(pat, lines[idx + 0])
		if !a_ok {
			log.panic("a_cap failed")
		}
		defer {
			delete(a_cap.groups)
			delete(a_cap.pos)
		}

		a := Vec2 {
			x = strconv.atoi(a_cap.groups[1]),
			y = strconv.atoi(a_cap.groups[2]),
		}

		b_cap, b_ok := regex.match_and_allocate_capture(pat, lines[idx + 1])
		if !b_ok {
			log.panic("b_cap failed")
		}
		defer {
			delete(b_cap.groups)
			delete(b_cap.pos)
		}

		b := Vec2 {
			x = strconv.atoi(b_cap.groups[1]),
			y = strconv.atoi(b_cap.groups[2]),
		}

		p_cap, p_ok := regex.match_and_allocate_capture(pat, lines[idx + 2])
		if !p_ok {
			log.panic("p_cap failed")
		}
		defer {
			delete(p_cap.groups)
			delete(p_cap.pos)
		}

		prize := Vec2 {
			x = strconv.atoi(p_cap.groups[1]) + 10_000_000_000_000,
			y = strconv.atoi(p_cap.groups[2]) + 10_000_000_000_000,
		}

		// https://en.wikipedia.org/wiki/Cramer%27s_rule
		// no - I never would've found this without help
		det := a.x * b.y - b.x * a.y
		if det == 0 {continue}

		x := prize.x * b.y - b.x * prize.y
		if x % det != 0 {continue}

		y := a.x * prize.y - prize.x * a.y
		if y % det != 0 {continue}

		p2 += (x * 3 + y) / det
	}

	fmt.printfln("Part Two: %d", p2)
}
