package main

import "core:encoding/ansi"
import "core:fmt"
import "core:log"
import "core:math"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
import "core:unicode/utf8"

read_file_by_lines_in_whole :: proc(filepath: string) -> ([]string, []string, bool) {
	data, ok := os.read_entire_file(filepath, context.allocator)
	stripes: [dynamic]string
	towels: [dynamic]string
	if !ok {
		fmt.println("couldn't read file")
		return stripes[:], towels[:], false
	}
	defer delete(data, context.allocator)

	stripe_row := true
	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		if len(strings.trim(line, " ")) < 1 {continue}
		if stripe_row {
			s_combi, err := strings.split(line, ", ")
			if err != nil {
				log.panic(err)
			}
			defer delete(s_combi)
			for s in s_combi {
				append(&stripes, strings.clone(strings.trim(s, " ")))
			}

			stripe_row = false
			continue
		}

		append(&towels, strings.clone(strings.trim(line, " ")))
	}
	return stripes[:], towels[:], len(towels) > 0 && len(stripes) > 0
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

	stripes, towels, ok := read_file_by_lines_in_whole("input")
	if !ok {return}
	defer {
		for stripe in stripes {
			delete(stripe)
		}
		delete(stripes)

		for towel in towels {
			delete(towel)
		}
		delete(towels)
	}

	part1(&stripes, &towels)
	part2(&stripes, &towels)
}

find :: proc(stripes: ^[]string, towel: string, seen: ^map[string]int) -> int {
	if (towel in seen) {
		return seen[towel]
	}

	ans := 0
	if len(towel) == 0 {
		ans = 1
		seen[towel] = ans
		return ans
	}
	for s in stripes {
		if strings.starts_with(towel, s) {
			ans += find(stripes, towel[len(s):], seen)
		}
	}
	seen[towel] = ans
	return ans
}

part1 :: proc(stripes: ^[]string, towels: ^[]string) {
	p1 := 0
	seen := make(map[string]int)
	defer delete(seen)

	sw := time.Stopwatch{}
	time.stopwatch_reset(&sw)
	time.stopwatch_start(&sw)

	tow: for t in towels {
		ans := find(stripes, t, &seen)
		if ans == 0 {
			when ODIN_DEBUG {
				fmt.println("The following Towel was found invalid: ", t)
				fmt.println("With the stripes: ", stripes)
			}

			continue
		}

		p1 += 1
	}

	time.stopwatch_stop(&sw)
	fmt.printfln("Part 1 took %d", sw._accumulation)

	fmt.println("Part One: ", p1)
}

part2 :: proc(stripes: ^[]string, towels: ^[]string) {
	p2 := 0
	seen := make(map[string]int)
	defer delete(seen)

	sw := time.Stopwatch{}
	time.stopwatch_reset(&sw)
	time.stopwatch_start(&sw)

	tow: for t in towels {
		ans := find(stripes, t, &seen)
		if ans == 0 {
			when ODIN_DEBUG {
				fmt.println("The following Towel was found invalid: ", t)
				fmt.println("With the stripes: ", stripes)
			}

			continue
		}

		p2 += ans
	}

	time.stopwatch_stop(&sw)
	fmt.printfln("Part 2 took %d", sw._accumulation)

	fmt.println("Part Two: ", p2)
}
