package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"

read_file_first_line :: proc(filepath: string) -> (string, bool) {
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

	line, ok := read_file_first_line("input")
	if !ok {return}

	s_nums, err := strings.split(line, " ")
	if err != nil {
		log.panic(err)
	}

	nums := make([dynamic]u64)
	//defer delete(nums)
	for s in s_nums {
		append(&nums, u64(strconv.atoi(s)))
	}
	delete(s_nums)
	delete(line)


	sw := time.Stopwatch{}
	time.stopwatch_reset(&sw)
	time.stopwatch_start(&sw)
	part1(&nums)
	time.stopwatch_stop(&sw)
	fmt.printfln("Part 1 took %d", sw._accumulation)
	time.stopwatch_reset(&sw)
	time.stopwatch_start(&sw)
	part2(&nums)
	time.stopwatch_stop(&sw)
	fmt.printfln("Part 2 took %d", sw._accumulation)
}

part1 :: proc(nums: ^[dynamic]u64, depth: u8 = 1) {
	n_nums := make([dynamic]u64)

	for num in nums {
		if num == 0 {
			append(&n_nums, 1)
		} else if dig := u64(math.log10(f64(num)) + 1); dig % 2 == 0 {
			l := u64(f64(num) * math.pow(10, -f64(dig / 2)))
			append(&n_nums, l)
			r := num - u64(f64(l) * math.pow(10, f64((dig / 2))))
			append(&n_nums, r)
		} else {
			append(&n_nums, num * 2024)
		}
	}
	if depth > 1 {
		delete(nums^)
	}

	if depth < 25 {
		part1(&n_nums, depth + 1)
	} else {
		fmt.printfln("Part One : %d", len(n_nums))
		delete(n_nums)
	}
}

part2 :: proc(nums: ^[dynamic]u64, depth: u8 = 0) {
	c_nums := make(map[u64]u64)
	defer delete(c_nums)

	p2 := u64(len(nums^))
	for n in nums {
		c_nums[n] += 1
	}
	delete(nums^)

	for _ in depth ..< 75 {
		n_nums := make(map[u64]u64)
		defer delete(n_nums)

		for k, v in c_nums {
			if k == 0 {
				n_nums[1] += v
			} else if dig := u64(math.log10(f64(k)) + 1); dig % 2 == 0 {

				nk := u64(f64(k) * math.pow(10, -f64(dig / 2)))
				n_nums[nk] += v
				nk = k - u64(f64(nk) * math.pow(10, f64((dig / 2))))
				n_nums[nk] += v

				p2 += v
			} else {
				nk := k * 2024
				n_nums[nk] += v
			}
		}
		delete(c_nums)
		c_nums = make(map[u64]u64)

		for k, v in n_nums {
			c_nums[k] = v
		}
	}

	fmt.printfln("Part Two : %d", p2)
}
