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

read_file_by_lines_in_whole :: proc(filepath: string) -> ([]string, bool) {
	data, ok := os.read_entire_file(filepath, context.allocator)
	result: [dynamic]string
	if !ok {
		fmt.println("couldn't read file")
		return result[:], false
	}
	defer delete(data, context.allocator)

	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		if len(strings.trim(line, " ")) < 1 {continue}
		append(&result, strings.clone(strings.trim(line, " ")))
	}
	return result[:], len(result) > 0
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
		for l in lines {
			delete(l)
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

Direction :: enum i8 {
	North = 0,
	East  = 1,
	South = 2,
	West  = 3,
}

@(rodata)
Direction_Vectors := [Direction]Vec2 {
	.North = {0, -1},
	.East  = {+1, 0},
	.South = {0, +1},
	.West  = {-1, 0},
}

@(rodata)
Direction_Runes := [Direction]rune {
	.North = '^',
	.East  = '>',
	.South = 'v',
	.West  = '<',
}

Vec2 :: [2]int

Group :: struct {
	pos:     Vec2,
	ori:     Direction,
	score:   int,
	own_map: [dynamic]string,
}

pretty_print_map :: proc(m: ^[dynamic]string) {
	RESET :: ansi.CSI + ansi.RESET + ansi.SGR
	WALL :: ansi.CSI + ansi.FG_BRIGHT_BLACK + ansi.SGR
	REINDEER :: ansi.CSI + ansi.FG_BRIGHT_BLUE + ansi.SGR

	for row in m do for col, x in row {
		if x == 0 {
			fmt.println()
		}
		if strings.contains_any(row[x:x + 1], "<>^vSE") {
			str := strings.concatenate({REINDEER, row[x:x + 1], RESET})
			defer delete(str)
			fmt.print(str)
		} else if col == '#' {
			str := strings.concatenate({WALL, row[x:x + 1], RESET})
			defer delete(str)
			fmt.print(str)
		} else {
			fmt.print(col)
		}
	}
	fmt.println()
}

EXIT_BYTE :: Vec2{70, 70}
COR_BYTE_COUNT :: 1024

part1 :: proc(lines: ^[]string) {
	p1 := 0

	maze := make(map[Vec2]rune)
	defer delete(maze)
	for row, count in lines {
		if count >= COR_BYTE_COUNT {break}
		coords, err := strings.split(row, ",")
		if err != nil {
			fmt.eprintln(err)
		}
		defer delete(coords)

		maze[{strconv.atoi(coords[0]), strconv.atoi(coords[1])}] = '#'
	}

	origin := Group {
		ori = .East,
		pos = {0, 0},
	}

	when ODIN_DEBUG {
		row_arr := make([]rune, EXIT_BYTE.x + 1)
		defer delete(row_arr)
		for y in 0 ..= EXIT_BYTE.y {
			for x in 0 ..= EXIT_BYTE.x {
				if val, ok := maze[{x, y}]; ok {
					row_arr[x] = val
				} else {
					row_arr[x] = '.'
					maze[{x, y}] = '.'
				}
			}
			line := utf8.runes_to_string(row_arr)
			append(&origin.own_map, line)
		}
	} else {
		for y in 0 ..= EXIT_BYTE.y {
			for x in 0 ..= EXIT_BYTE.x {
				if val, ok := maze[{x, y}]; !ok {
					maze[{x, y}] = '.'
				}
			}
		}
	}

	q := [dynamic]Group{origin}
	seen := make(map[Vec2]struct {})
	defer {
		delete(seen)
		for iq in q {
			for line in iq.own_map {
				delete(line)
			}
			delete(iq.own_map)
		}
		delete(q)
	}

	when ODIN_DEBUG {
		fmt.println("initial queue", q)
		fmt.println("current score", origin.score)
		pretty_print_map(&origin.own_map)
	}

	game: for len(q) > 0 {
		cur := pop_front(&q)
		when ODIN_DEBUG do defer {
			for line in cur.own_map {
				delete(line)
			}
			delete(cur.own_map)
		}

		if _, ok := seen[cur.pos]; ok {
			continue
		}

		if cur.pos == EXIT_BYTE {
			p1 = cur.score

			when ODIN_DEBUG {
				pretty_print_map(&cur.own_map)
				for iq in q {
					for line in iq.own_map {
						delete(line)
					}
					delete(iq.own_map)
				}
			}

			break game
		}
		seen[cur.pos] = {}

		for dir in Direction {
			dir_diff := math.abs(int(dir) - int(cur.ori))
			if dir_diff == 2 {
				continue
			}

			new_dir := Group {
				pos = cur.pos + Direction_Vectors[dir],
				ori = dir,
			}

			if _, ok := seen[new_dir.pos]; ok {
				continue
			}

			if ru, ok := maze[new_dir.pos]; !ok || ru == '#' {
				seen[new_dir.pos] = {}
				continue
			}

			new_dir.score = cur.score + 1

			when ODIN_DEBUG {
				r_arr := make([dynamic]rune)
				defer {
					delete(r_arr)
				}
				for row, y in cur.own_map {
					clear(&r_arr)
					for col, x in row {
						if new_dir.pos[0] == x && new_dir.pos[1] == y {
							append(&r_arr, Direction_Runes[dir])
							continue
						}
						append(&r_arr, col)
					}
					append(&new_dir.own_map, utf8.runes_to_string(r_arr[:]))
				}
			}

			append(&q, new_dir)
		}
	}

	fmt.printfln("Part One: %d", p1)
}

part2 :: proc(lines: ^[]string) {
	p2: Vec2

	maze := make(map[Vec2]rune)
	defer delete(maze)
	for row, count in lines {
		if count >= COR_BYTE_COUNT {break}
		coords, err := strings.split(row, ",")
		if err != nil {
			fmt.eprintln(err)
		}
		defer delete(coords)

		maze[{strconv.atoi(coords[0]), strconv.atoi(coords[1])}] = '#'
	}

	q := make([dynamic]Group)
	seen := make(map[Vec2]struct {})
	defer {
		delete(seen)
		for iq in q {
			for line in iq.own_map {
				delete(line)
			}
			delete(iq.own_map)
		}
		delete(q)
	}

	game: for i in COR_BYTE_COUNT ..< len(lines) {
		clear(&q)
		clear(&seen)

		coords, err := strings.split(lines[i], ",")
		if err != nil {
			fmt.eprintln(err)
		}
		defer delete(coords)

		p2 = {strconv.atoi(coords[0]), strconv.atoi(coords[1])}
		maze[p2] = '#'


		origin := Group {
			ori = .East,
			pos = {0, 0},
		}
		when ODIN_DEBUG {
			row_arr := make([]rune, EXIT_BYTE.x + 1)
			defer delete(row_arr)
			for y in 0 ..= EXIT_BYTE.y {
				for x in 0 ..= EXIT_BYTE.x {
					if val, ok := maze[{x, y}]; ok {
						row_arr[x] = val
					} else {
						row_arr[x] = '.'
						maze[{x, y}] = '.'
					}
				}
				line := utf8.runes_to_string(row_arr)
				append(&origin.own_map, line)
			}
		} else {
			for y in 0 ..= EXIT_BYTE.y {
				for x in 0 ..= EXIT_BYTE.x {
					if val, ok := maze[{x, y}]; !ok {
						maze[{x, y}] = '.'
					}
				}
			}
		}

		append(&q, origin)

		for len(q) > 0 {
			cur := pop_front(&q)
			when ODIN_DEBUG do defer {
				for line in cur.own_map {
					delete(line)
				}
				delete(cur.own_map)
			}
			if _, ok := seen[cur.pos]; ok {
				when ODIN_DEBUG do if len(q) == 0 {
					pretty_print_map(&cur.own_map)
				}
				continue
			}

			if cur.pos == EXIT_BYTE {
				when ODIN_DEBUG {
					pretty_print_map(&cur.own_map)
					for iq in q {
						for line in iq.own_map {
							delete(line)
						}
						delete(iq.own_map)
					}
				}

				continue game
			}
			seen[cur.pos] = {}

			for dir in Direction {
				dir_diff := math.abs(int(dir) - int(cur.ori))
				if dir_diff == 2 {
					continue
				}

				new_dir := Group {
					pos = cur.pos + Direction_Vectors[dir],
					ori = dir,
				}

				if _, ok := seen[new_dir.pos]; ok {
					continue
				}

				if ru, ok := maze[new_dir.pos]; !ok || ru == '#' {
					seen[new_dir.pos] = {}
					continue
				}

				new_dir.score = cur.score + 1

				when ODIN_DEBUG {
					r_arr := make([dynamic]rune)
					defer {
						delete(r_arr)
					}
					for row, y in cur.own_map {
						clear(&r_arr)
						for col, x in row {
							if new_dir.pos[0] == x && new_dir.pos[1] == y {
								append(&r_arr, Direction_Runes[dir])
								continue
							}
							append(&r_arr, col)
						}
						append(&new_dir.own_map, utf8.runes_to_string(r_arr[:]))
					}
				}

				append(&q, new_dir)
			}

			when ODIN_DEBUG do if len(q) == 0 {
				pretty_print_map(&cur.own_map)
			}
		}

		break game
	}

	fmt.println("Part Two:", p2)
}
