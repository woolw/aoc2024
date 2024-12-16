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

	maze := make(map[Vec2]rune)
	defer {
		for l in lines {
			delete(l)
		}
		delete(lines)
		delete(maze)
	}
	for row, y in lines do for col, x in row {
		maze[{x, y}] = col
	}


	sw := time.Stopwatch{}
	time.stopwatch_reset(&sw)
	time.stopwatch_start(&sw)
	score := part1(maze, &lines)
	time.stopwatch_stop(&sw)
	fmt.printfln("Part 1 took %d", sw._accumulation)
	time.stopwatch_reset(&sw)


	time.stopwatch_start(&sw)
	part2(maze, &lines, score)
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

Reindeer :: struct {
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

part1 :: proc(maze: map[Vec2]rune, lines: ^[]string) -> int {
	p1 := 0

	origin := Reindeer {
		ori = .East,
	}
	when ODIN_DEBUG do for line in lines {
		append(&origin.own_map, strings.clone(line))
	}

	e_count := make(map[Direction]struct {})
	defer delete(e_count)
	for pos, ru in maze {
		if ru == 'S' {
			origin.pos = pos
		}
		if ru == 'E' {
			for dir in Direction {
				if ru, ok := maze[pos + Direction_Vectors[dir]]; ok && ru == '.' {
					switch dir {
					case .North:
						e_count[.South] = {}
					case .East:
						e_count[.West] = {}
					case .South:
						e_count[.North] = {}
					case .West:
						e_count[.East] = {}
					}
				}
			}
		}
	}


	q := [dynamic]Reindeer{origin}
	seen := make(map[Vec2]struct {})
	defer {
		delete(seen)
		delete(q)
	}

	when ODIN_DEBUG {
		fmt.println("initial maze: ", maze)
		fmt.println("initial e_count", e_count)
		fmt.println("initial q", q)

		buf: [1]byte
		fmt.println("Press enter to continue")
		_, err := os.read(os.stdin, buf[:])
		if err != nil {
			fmt.eprintln("Error reading: ", err)
			return 0
		}
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

		when ODIN_DEBUG {
			fmt.println("current q", cur.pos, cur.ori, cur.score)
		}

		if ru := maze[cur.pos]; ru == 'E' {
			if _, k := e_count[cur.ori]; !k {continue}
			p1 = p1 == 0 ? cur.score : min(p1, cur.score)
			delete_key(&e_count, cur.ori)

			when ODIN_DEBUG {
				fmt.println("current p1", p1)
				fmt.println("current score", cur.score)
				fmt.println("current e_count", e_count)
				pretty_print_map(&cur.own_map)

				buf: [1]byte
				fmt.println("Press enter to continue")
				_, err := os.read(os.stdin, buf[:])
				if err != nil {
					fmt.eprintln("Error reading: ", err)
					return 0
				}
			}

			if len(e_count) == 0 {
				break game
			}

			continue
		}
		seen[cur.pos] = {}

		for dir in Direction {
			s := 1
			dir_diff := math.abs(int(dir) - int(cur.ori))
			if dir_diff == 1 || dir_diff == 3 {
				s += 1_000
			} else if dir_diff == 2 {
				continue
			}

			new_dir := Reindeer {
				pos = cur.pos + Direction_Vectors[dir],
				ori = dir,
			}

			if ru, ok := maze[new_dir.pos]; !ok || ru == '#' {
				seen[new_dir.pos] = {}
				continue
			}

			if _, ok := seen[new_dir.pos]; ok {
				continue
			}

			new_dir.score = cur.score + s

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

			if s == 1 {
				inject_at(&q, 0, new_dir)
			} else {
				append(&q, new_dir)
			}
		}

		when ODIN_DEBUG {
			fmt.println(len(q))
		}
	}

	fmt.printfln("Part One: %d", p1)
	return p1
}

Reindeer2 :: struct {
	pos:     Vec2,
	ori:     Direction,
	score:   int,
	own_map: [dynamic]string,
	seen:    map[Vec2]struct {},
}

part2 :: proc(maze: map[Vec2]rune, lines: ^[]string, score: int) {
	origin := Reindeer2 {
		ori = .East,
	}
	when ODIN_DEBUG do for line in lines {
		append(&origin.own_map, strings.clone(line))
	}

	seen := make(map[Vec2]struct {})
	defer delete(seen)
	all_seen := make(map[Vec2]struct {})
	defer delete(all_seen)
	for pos, ru in maze {
		if ru == 'S' {
			origin.pos = pos
			all_seen[pos] = {}
			break
		}
	}

	q := [dynamic]Reindeer2{origin}
	defer {
		delete(q)
	}

	when ODIN_DEBUG {
		fmt.println("initial maze: ", maze)
		fmt.println("initial q", q)

		buf: [1]byte
		fmt.println("Press enter to continue")
		_, err := os.read(os.stdin, buf[:])
		if err != nil {
			fmt.eprintln("Error reading: ", err)
			return
		}
	}
	first_look := true

	game: for len(q) > 0 {
		cur := pop_front(&q)
		when ODIN_DEBUG do defer {
			for line in cur.own_map {
				delete(line)
			}
			delete(cur.own_map)
		}
		defer delete(cur.seen)

		if cur.pos in seen && (first_look || cur.pos not_in all_seen && len(all_seen) > 1) {
			continue
		}
		seen[cur.pos] = {}

		when ODIN_DEBUG {
			fmt.println("current q", cur.pos, cur.ori, cur.score)
		}

		if ru := maze[cur.pos]; ru == 'E' {
			if cur.score != score {continue}

			if first_look {
				for cq in q {
					when ODIN_DEBUG {
						for line in cq.own_map {
							delete(line)
						}
						delete(cq.own_map)
					}
					delete(cq.seen)
				}
				clear(&q)
				when ODIN_DEBUG {
					origin.own_map = make([dynamic]string)
					for line in lines {
						append(&origin.own_map, strings.clone(line))
					}
				}
				append(&q, origin)
				first_look = false
				for s in seen {
					delete_key(&seen, s)
				}
			}
			for cs in cur.seen {
				all_seen[cs] = {}
			}

			when ODIN_DEBUG {
				fmt.println("current seen len", len(all_seen))
				pretty_print_map(&cur.own_map)

				buf: [1]byte
				fmt.println("Press enter to continue")
				_, err := os.read(os.stdin, buf[:])
				if err != nil {
					fmt.eprintln("Error reading: ", err)
					return
				}
			}

			continue
		}

		for dir in Direction {
			s := 1
			dir_diff := math.abs(int(dir) - int(cur.ori))
			if dir_diff == 1 || dir_diff == 3 {
				s += 1_000
			} else if dir_diff == 2 {
				continue
			}

			new_dir := Reindeer2 {
				pos = cur.pos + Direction_Vectors[dir],
				ori = dir,
			}

			if ru, ok := maze[new_dir.pos]; !ok || ru == '#' || new_dir.pos in cur.seen {
				continue
			}

			if new_dir.pos in seen &&
			   (first_look || new_dir.pos not_in all_seen && len(all_seen) > 1) {
				continue
			}

			new_dir.score = cur.score + s
			if new_dir.score > score {continue}

			new_dir.seen = make(map[Vec2]struct {})
			for cm in cur.seen {
				new_dir.seen[cm] = {}
			}
			new_dir.seen[new_dir.pos] = {}

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

			if s == 1 {
				inject_at(&q, 0, new_dir)
			} else {
				append(&q, new_dir)
			}
		}

		when ODIN_DEBUG {
			fmt.println(len(q))
		}
	}
	p2 := len(all_seen)

	fmt.printfln("Part Two: %d", p2)
}
