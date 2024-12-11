package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:mem"
import "core:os"
import "core:strings"
import "core:time"

get_first_line :: proc(filepath: string) -> (string, bool) {
	data, ok := os.read_entire_file(filepath, context.allocator)
	if !ok {
		fmt.println("couldn't read file")
		return "", false
	}
	defer delete(data, context.allocator)

	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		if len(strings.trim(line, " ")) < 1 {continue}
		return strings.clone(strings.trim(line, " ")), true
	}
	return "", false
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

	line, ok := get_first_line("input")
	if !ok {return}
	defer {
		delete(line)
	}

	a_map := make(map[int]int)
	defer {
		delete(a_map)
	}
	id := 0
	m_pos := -1
	for ch, i in line {
		if i % 2 == 1 {continue}

		count := int(ch - '0')
		a_map[id] = count
		m_pos += count
		id += 1
	}

	sw := time.Stopwatch{}
	time.stopwatch_reset(&sw)
	time.stopwatch_start(&sw)
	part1(&a_map, &line, &id, m_pos)
	time.stopwatch_stop(&sw)
	fmt.printfln("Part 1 took %d", sw._accumulation)
	time.stopwatch_reset(&sw)

	id = 0
	m_pos = -1
	lis := make([dynamic]int)
	defer delete(lis)
	for ch, i in line {
		count := int(ch - '0')
		m_pos += count
		if i % 2 == 1 {
			for ii := 0; ii < count; ii += 1 {
				append(&lis, -1)
			}
			continue
		}

		for ii := 0; ii < count; ii += 1 {
			append(&lis, id)
		}
		a_map[id] = count
		id += 1
	}

	time.stopwatch_start(&sw)
	part2(&a_map, &line, id, m_pos, &lis)
	time.stopwatch_stop(&sw)
	fmt.printfln("Part 2 took %d", sw._accumulation)
}

part1 :: proc(a_map: ^map[int]int, line: ^string, m_id: ^int, m_pos: int) {
	p1: u128 = 0
	pos := 0
	m_idx := 0
	total: for ch, i in line^ {
		if pos > m_pos {continue}
		if i % 2 == 1 {
			f_0 := false
			spaces: for space := int(ch - '0'); space > 0; {
				a := a_map[m_id^]
				if a <= 0 {
					m_id^ -= 1
					f_0 = !f_0
					if !f_0 {break total}
					continue
				}
				f_0 = false
				for idx := 0; idx < a; idx += 1 {
					if space == 0 {break spaces}
					//fmt.printfln("id %d at %d", m_id^, pos)
					p1 += u128(pos * m_id^)
					pos += 1
					space -= 1
					a_map[m_id^] = a_map[m_id^] - 1
				}
			}

			continue
		}

		a := a_map[m_idx]
		if a <= 0 {
			break total
		}
		for idx := 0; idx < a; idx += 1 {
			//fmt.printfln("id %d at %d", m_idx, pos)
			p1 += u128(pos * m_idx)
			pos += 1
			a_map[m_idx] = a_map[m_idx] - 1
		}
		m_idx += 1
	}

	fmt.printfln("Part One: %d", p1)
}

kvp :: struct {
	id:  int,
	cap: int,
}

get_cap :: proc(lis: ^[dynamic]int, i: int) -> int {
	res := 0
	id: int
	set := true
	for ii := i; ii < len(lis); ii += 1 {
		if set {
			id = lis[ii]
			set = false
		}

		if id != lis[ii] {
			break
		}
		res += 1
	}
	return res
}

part2 :: proc(a_map: ^map[int]int, line: ^string, m_id: int, m_pos: int, lis: ^[dynamic]int) {
	for i := m_id; i >= 0; i -= 1 {
		capa := a_map[i]
		if capa <= 0 {continue}

		clear := false
		for idx := 0; idx < len(lis^); idx += 1 {
			id := lis[idx]
			if id == i {
				if !clear {
					break
				}
				lis[idx] = -1
			}

			if c := get_cap(lis, idx); c < capa || id >= 0 || clear {
				idx += c - 1
				continue
			}

			for ii := 0; ii < capa; ii += 1 {
				lis[ii + idx] = i
			}
			idx += capa - 1
			clear = true
		}
	}


	p1: u128 = 0

	for id, idx in lis {
		if id == -1 {
			// fmt.print('.')
			continue
		}
		// fmt.print(id)

		p1 += u128(id * idx)
	}

	fmt.printfln("Part Two: %d", p1)
}
