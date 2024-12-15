package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"
import "core:unicode/utf8"

read_file_by_lines_in_whole :: proc(filepath: string) -> ([]string, []rune, bool) {
	data, ok := os.read_entire_file(filepath, context.allocator)
	result: [dynamic]string
	mov := make([dynamic]rune)
	if !ok {
		fmt.println("couldn't read file")
		return result[:], mov[:], false
	}
	defer delete(data, context.allocator)

	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		if len(strings.trim(line, " ")) < 1 {continue}
		if strings.contains_any(line, "<>^v") {
			for ch in line {
				append(&mov, ch)
			}
			continue
		}
		append(&result, strings.clone(strings.trim(line, " ")))
	}
	return result[:], mov[:], len(result) > 0
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

	lines, mov, ok := read_file_by_lines_in_whole("input")
	w_map := make([][]rune, len(lines))
	for &row, y in w_map {
		row = make([]rune, len(lines[0]))
		for &ch, x in row {
			ch = rune(lines[y][x])
		}
	}
	if !ok {return}
	defer {
		for m in w_map {
			delete(m)
		}
		for l in lines {
			delete(l)
		}
		delete(mov)
		delete(lines)
		delete(w_map)
	}

	sw := time.Stopwatch{}
	time.stopwatch_reset(&sw)
	time.stopwatch_start(&sw)
	part1(&w_map, &mov)
	time.stopwatch_stop(&sw)
	fmt.printfln("Part 1 took %d", sw._accumulation)
	time.stopwatch_reset(&sw)

	r_map := make([][]rune, len(w_map))
	defer {
		for &row in r_map {
			delete(row)
		}
		delete(r_map)
	}
	for &row, y in r_map {
		row = make([]rune, len(w_map[0]) * 2)

		for ch, x in lines[y] {
			nx := x * 2
			switch ch {
			case 'O':
				row[nx] = '['
				row[nx + 1] = ']'
			case '@':
				row[nx] = '@'
				row[nx + 1] = '.'
			case:
				row[nx] = ch
				row[nx + 1] = ch
			}
		}
	}

	time.stopwatch_start(&sw)
	part2(&r_map, &mov)
	time.stopwatch_stop(&sw)
	fmt.printfln("Part 2 took %d", sw._accumulation)
}

part1 :: proc(w_map: ^[][]rune, mov: ^[]rune) {
	p1 := 0

	buffs := make([dynamic]rune)
	defer delete(buffs)
	rx, ry := 0, 0
	for line, y in w_map do for ch, x in line {
		if ch != '@' {continue}

		rx = x
		ry = y
		break
	}
	movement: for m in mov {
		clear(&buffs)
		append(&buffs, '.', '@')
		switch m {
		case '^':
			for i := ry - 1; i >= 0; i -= 1 {
				switch w_map[i][rx] {
				case 'O':
					append(&buffs, 'O')
				case '.':
					for buff, j in buffs {
						w_map[ry - j][rx] = buff
					}
					ry -= 1
					fallthrough
				case:
					continue movement
				}
			}
		case '>':
			for i := rx + 1; i < len(w_map[0]); i += 1 {
				switch w_map[ry][i] {
				case 'O':
					append(&buffs, 'O')
				case '.':
					for buff, j in buffs {
						w_map[ry][rx + j] = buff
					}
					rx += 1
					fallthrough
				case:
					continue movement
				}
			}
		case 'v':
			for i := ry + 1; i < len(w_map); i += 1 {
				switch w_map[i][rx] {
				case 'O':
					append(&buffs, 'O')
				case '.':
					for buff, j in buffs {
						w_map[ry + j][rx] = buff
					}
					ry += 1
					fallthrough
				case:
					continue movement
				}
			}
		case '<':
			for i := rx - 1; i >= 0; i -= 1 {
				switch w_map[ry][i] {
				case 'O':
					append(&buffs, 'O')
				case '.':
					for buff, j in buffs {
						w_map[ry][rx - j] = buff
					}
					rx -= 1
					fallthrough
				case:
					continue movement
				}
			}
		}
	}

	for line, y in w_map do for ch, x in line {
		if ch != 'O' {continue}

		p1 += 100 * y + x
	}

	fmt.printfln("Part One: %d", p1)
}

can_move :: proc(
	buffs: []rune,
	r_map: ^[][]rune,
	x, y: int,
	up: bool,
	seen: ^map[int]int,
) -> bool {
	seen[x] = up ? y - (len(buffs) - 1) : y + (len(buffs) - 1)

	n_buffs := make([dynamic]rune)
	defer delete(n_buffs)

	buff_check: for buff, j in buffs {
		clear(&n_buffs)
		switch buff {
		case '[':
			if sy, k := seen[x + 1]; !k || up && sy > (y - j) || !up && sy < (y + j) {
				if up {
					for i := y - j; i >= 0; i -= 1 {
						switch r_map[i][x + 1] {
						case '[':
							fallthrough
						case ']':
							append(&n_buffs, r_map[i][x + 1])
						case '.':
							if !can_move(n_buffs[:], r_map, x + 1, y - j, up, seen) {return false}
							continue buff_check
						case '#':
							return false
						}
					}
					continue buff_check
				}
				for i := y + j; i < len(r_map); i += 1 {
					switch r_map[i][x + 1] {
					case '[':
						fallthrough
					case ']':
						append(&n_buffs, r_map[i][x + 1])
					case '.':
						if !can_move(n_buffs[:], r_map, x + 1, y + j, up, seen) {return false}
						continue buff_check
					case '#':
						return false
					}
				}
			}
		case ']':
			if sy, k := seen[x - 1]; !k || up && sy > (y - j) || !up && sy < (y + j) {
				if up {
					for i := y - j; i >= 0; i -= 1 {
						switch r_map[i][x - 1] {
						case '[':
							fallthrough
						case ']':
							append(&n_buffs, r_map[i][x - 1])
						case '.':
							if !can_move(n_buffs[:], r_map, x - 1, y - j, up, seen) {return false}
							continue buff_check
						case '#':
							return false
						}
					}
					continue buff_check
				}
				for i := y + j; i < len(r_map); i += 1 {
					switch r_map[i][x - 1] {
					case '[':
						fallthrough
					case ']':
						append(&n_buffs, r_map[i][x - 1])
					case '.':
						if !can_move(n_buffs[:], r_map, x - 1, y + j, up, seen) {return false}
						continue buff_check
					case '#':
						return false
					}
				}
			}
		case '#':
			return false
		case:
			continue
		}
	}

	return true
}

do_move :: proc(buffs: []rune, r_map: ^[][]rune, x, y: int, up: bool, seen: ^map[int]int) {
	seen[x] = up ? y - (len(buffs) - 1) : y + (len(buffs) - 1)

	when ODIN_DEBUG do fmt.println(buffs, seen)

	r_map[y][x] = '.'
	for buff, j in buffs {
		o_y := up ? y - (j + 1) : y + (j + 1)

		buff_switch: switch buff {
		case '[':
			if sy, k := seen[x + 1]; !k || up && sy > (y - j) || !up && sy < (y + j) {
				n_buffs := make([dynamic]rune)
				defer delete(n_buffs)
				if up {
					for i := y - j; i >= 0; i -= 1 {
						switch r_map[i][x + 1] {
						case '[':
							fallthrough
						case ']':
							append(&n_buffs, r_map[i][x + 1])
						case '.':
							do_move(n_buffs[:], r_map, x + 1, y - j, up, seen)
							break buff_switch
						case '#':
							log.panic("how did you get here?")
						}
					}
				} else {
					for i := y + j; i < len(r_map); i += 1 {
						switch r_map[i][x + 1] {
						case '[':
							fallthrough
						case ']':
							append(&n_buffs, r_map[i][x + 1])
						case '.':
							do_move(n_buffs[:], r_map, x + 1, y + j, up, seen)
							break buff_switch
						case '#':
							log.panic("how did you get here?")
						}
					}
				}
			}
		case ']':
			if sy, k := seen[x - 1]; !k || up && sy > (y - j) || !up && sy < (y + j) {
				n_buffs := make([dynamic]rune)
				defer delete(n_buffs)
				if up {
					for i := y - j; i >= 0; i -= 1 {
						switch r_map[i][x - 1] {
						case '[':
							fallthrough
						case ']':
							append(&n_buffs, r_map[i][x - 1])
						case '.':
							do_move(n_buffs[:], r_map, x - 1, y - j, up, seen)
							break buff_switch
						case '#':
							log.panic("how did you get here?")
						}
					}
				} else {
					for i := y + j; i < len(r_map); i += 1 {
						switch r_map[i][x - 1] {
						case '[':
							fallthrough
						case ']':
							append(&n_buffs, r_map[i][x - 1])
						case '.':
							do_move(n_buffs[:], r_map, x - 1, y + j, up, seen)
							break buff_switch
						case '#':
							log.panic("how did you get here?")
						}
					}
				}
			}
		}

		r_map[o_y][x] = buff
	}
}

part2 :: proc(r_map: ^[][]rune, mov: ^[]rune) {
	p2 := 0

	buffs := make([dynamic]rune)
	defer delete(buffs)

	seen_x := make(map[int]int)
	defer delete(seen_x)

	rx, ry := 0, 0
	for line, y in r_map do for ch, x in line {
		if ch != '@' {continue}

		rx = x
		ry = y
		break
	}

	movement: for m in mov {
		clear(&seen_x)
		clear(&buffs)
		append(&buffs, '@')

		when ODIN_DEBUG {
			buf: [256]byte
			fmt.println("Press enter to continue")
			_, err := os.read(os.stdin, buf[:])
			if err != nil {
				fmt.eprintln("Error reading: ", err)
				return
			}

			fmt.println()
			fmt.println(m)
			fmt.println()
			for line in r_map do fmt.println(line)
		}

		switch m {
		case '^':
			for i := ry - 1; i >= 0; i -= 1 {
				switch r_map[i][rx] {
				case '[':
					fallthrough
				case ']':
					append(&buffs, r_map[i][rx])
				case '.':
					if can_move(buffs[:], r_map, rx, ry, true, &seen_x) {
						clear(&seen_x)
						do_move(buffs[:], r_map, rx, ry, true, &seen_x)
						ry -= 1
					}
					fallthrough
				case:
					continue movement
				}
			}
		case '>':
			for i := rx + 1; i < len(r_map[0]); i += 1 {
				switch r_map[ry][i] {
				case '[':
					fallthrough
				case ']':
					append(&buffs, r_map[ry][i])
				case '.':
					for buff, j in buffs {
						if j == 0 {
							r_map[ry][rx] = '.'
						}
						r_map[ry][rx + j + 1] = buff
					}
					rx += 1
					fallthrough
				case:
					continue movement
				}
			}
		case 'v':
			for i := ry + 1; i >= 0; i += 1 {
				switch r_map[i][rx] {
				case '[':
					fallthrough
				case ']':
					append(&buffs, r_map[i][rx])
				case '.':
					if can_move(buffs[:], r_map, rx, ry, false, &seen_x) {
						clear(&seen_x)
						do_move(buffs[:], r_map, rx, ry, false, &seen_x)
						ry += 1
					}
					fallthrough
				case:
					continue movement
				}
			}
		case '<':
			for i := rx - 1; i >= 0; i -= 1 {
				switch r_map[ry][i] {
				case '[':
					fallthrough
				case ']':
					append(&buffs, r_map[ry][i])
				case '.':
					for buff, j in buffs {
						if j == 0 {
							r_map[ry][rx] = '.'
						}
						r_map[ry][rx - (j + 1)] = buff
					}
					rx -= 1
					fallthrough
				case:
					continue movement
				}
			}
		}
	}

	for line, y in r_map {
		when ODIN_DEBUG do fmt.println(line)
		for ch, x in line {
			if ch != '[' {continue}

			p2 += 100 * y + x
		}
	}

	fmt.printfln("Part Two: %d", p2)
}
