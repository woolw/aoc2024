package main

import (
	"fmt"
	"log"
	"math"
	"os"
	"sort"
	"strconv"
	"strings"
)

func main() {
	content, err := os.ReadFile("input")
	if err != nil {
		log.Fatal(err)
	}
	lines := strings.Split(string(content), "\n")

	var lefts []int
	var rights []int
	for _, line := range lines {
		splits := strings.Split(line, " ")
		left, err := strconv.Atoi(splits[0])
		if err != nil {
			panic(err)
		}
		lefts = append(lefts, left)
		right, err := strconv.Atoi(splits[len(splits)-1])
		if err != nil {
			panic(err)
		}
		rights = append(rights, right)
	}

	sort.Ints(lefts)
	sort.Ints(rights)

	part1(lefts, rights)
	part2(lefts, rights)
}

func part1(lefts, rights []int) {
	sum := 0
	for idx, left := range lefts {
		sum += int(math.Abs(float64(left - rights[idx])))
	}

	fmt.Println("Part 1 : ", sum)
}

func part2(lefts, rights []int) {
	score := 0
	for _, left := range lefts {
		count := 0
		for _, right := range rights {
			if left == right {
				count += 1
			}
		}
		score += (left * count)
	}

	fmt.Println("Part 2 : ", score)
}
