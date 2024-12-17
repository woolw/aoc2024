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

read_file_by_lines_in_whole :: proc(filepath: string) -> ([3]int, []int, bool) {
	data, ok := os.read_entire_file(filepath, context.allocator)
	result: [3]int
	mov: [dynamic]int
	if !ok {
		fmt.println("couldn't read file")
		return result, mov[:], false
	}
	defer delete(data, context.allocator)

	it := string(data)
	instructions := false
	for line in strings.split_lines_iterator(&it) {
		if len(strings.trim(line, " ")) < 1 {
			instructions = true
			continue
		}
		if instructions {
			inst, err := strings.split(line, " ")
			if err != nil {
				log.panic(err)
			}
			defer delete(inst)
			ch, err2 := strings.split(inst[1], ",")
			if err2 != nil {
				log.panic(err2)
			}
			defer delete(ch)

			for nums in ch {
				append(&mov, strconv.atoi(nums))
			}
			continue
		}

		reg, err3 := strings.split(line, " ")
		if err3 != nil {
			log.panic(err3)
		}
		defer delete(reg)
		if strings.contains(reg[1], "A") {
			result[0] = strconv.atoi(reg[2])
		} else if strings.contains(reg[1], "B") {
			result[1] = strconv.atoi(reg[2])
		} else if strings.contains(reg[1], "C") {
			result[2] = strconv.atoi(reg[2])
		}
	}
	return result, mov[:], true
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

	regs, instrs, ok := read_file_by_lines_in_whole("input")
	if !ok {return}

	init_A := regs[0]
	init_B := regs[1]
	init_C := regs[2]

	sw := time.Stopwatch{}
	time.stopwatch_reset(&sw)
	time.stopwatch_start(&sw)
	part1(&regs, &instrs)
	time.stopwatch_stop(&sw)
	fmt.printfln("Part 1 took %d", sw._accumulation)
	time.stopwatch_reset(&sw)

	regs[0] = init_A
	regs[1] = init_B
	regs[2] = init_C

	time.stopwatch_start(&sw)
	part2(&regs, &instrs)
	time.stopwatch_stop(&sw)
	fmt.printfln("Part 2 took %d", sw._accumulation)
}

get_operant :: proc(regs: ^[3]int, operant_num: int) -> (int, bool) {
	switch operant_num {
	case 0:
		return 0, true
	case 1:
		return 1, true
	case 2:
		return 2, true
	case 3:
		return 3, true
	case 4:
		return regs[0], true
	case 5:
		return regs[1], true
	case 6:
		return regs[2], true
	case:
		return 0, false
	}
}

part1 :: proc(regs: ^[3]int, instrs: ^[]int) {
	print_buff := make([dynamic]int)
	defer delete(print_buff)
	for i := 0; i < len(instrs); i += 2 {
		literal_operant := instrs[i + 1]
		combo_operant, valid := get_operant(regs, instrs[i + 1])
		if !valid {
			log.panic("program invalid")
		}

		switch instrs[i] {
		case 0:
			regs[0] = regs[0] >> uint(combo_operant)
		case 1:
			regs[1] = regs[1] ~ int(literal_operant)
		case 2:
			regs[1] = combo_operant %% 8
		case 3:
			if regs[0] != 0 {
				i = literal_operant - 2
			}
		case 4:
			regs[1] = regs[1] ~ regs[2]
		case 5:
			append(&print_buff, combo_operant %% 8)
		case 6:
			regs[1] = regs[0] >> uint(combo_operant)
		case 7:
			regs[2] = regs[0] >> uint(combo_operant)
		}
	}

	if len(print_buff) > 0 {
		fmt.println("Part One: ")

		for buf, i in print_buff {
			if i > 0 {
				fmt.print(",")
			}
			fmt.print(buf)
		}
		fmt.println()
	}
}

run_to_print :: proc(a: int, instrs: ^[]int) -> int {
	regs: [3]int = {a, 0, 0}

	i: int
	for i := 0; i < len(instrs); i += 2 {
		literal_operant := instrs[i + 1]
		combo_operant, valid := get_operant(&regs, literal_operant)
		if !valid {
			log.panic("program invalid")
		}

		switch instrs[i] {
		case 0:
			regs[0] = regs[0] >> uint(combo_operant)
		case 1:
			regs[1] = regs[1] ~ literal_operant
		case 2:
			regs[1] = combo_operant %% 8
		case 3:
			if regs[0] != 0 {
				i = literal_operant - 2
			}
		case 4:
			regs[1] = regs[1] ~ regs[2]
		case 5:
			return combo_operant %% 8
		case 6:
			regs[1] = regs[0] >> uint(combo_operant)
		case 7:
			regs[2] = regs[0] >> uint(combo_operant)
		}
	}
	return -1
}

iter_to_a :: proc(a: int, instrs: ^[]int, instrs_left: int) -> int {
	for i in 0 ..< 8 {
		new_a := (a << 3) | i
		if run_to_print(new_a, instrs) == instrs[instrs_left] {
			if instrs_left == 0 {
				return new_a
			} else {
				f := iter_to_a(new_a, instrs, instrs_left - 1)
				if f != -1 {
					return f
				}
			}
		}
	}
	return -1
}

part2 :: proc(regs: ^[3]int, instrs: ^[]int) {
	regs[0] = -1
	for i in 0 ..< 8 {
		regs[0] = iter_to_a(i, instrs, len(instrs) - 1)
		if regs[0] != -1 {
			fmt.println("Part Two: ", regs[0])
			return
		}
	}
	fmt.println("couldn't solve part 2")
}
