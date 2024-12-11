package main

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
)

func main() {
	content, err := os.ReadFile("input")
	if err != nil {
		log.Fatal(err)
	}
	lines := strings.Split(string(content), "\n")

	rules := make(map[string]map[string]bool)
	p1 := 0
	p2 := 0
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if len(line) == 0 {
			continue
		}

		rule_parts := strings.Split(line, "|")
		if len(rule_parts) == 2 {
			_, ok := rules[rule_parts[0]]
			if !ok {
				rules[rule_parts[0]] = make(map[string]bool)
			}
			rules[rule_parts[0]][rule_parts[1]] = true

			continue
		}

		if !strings.Contains(line, ",") {
			page_num, err := strconv.Atoi(line)
			if err != nil {
				log.Fatal(err)
			}

			p1 += page_num
			continue
		}

		pages := make([]string, 0)
		for _, page := range strings.Split(line, ",") {
			pages = append(pages, page)
		}

		corrected_pages, valid := correct(rules, pages)
		if valid {
			val, err := strconv.Atoi(pages[len(pages)/2])
			if err != nil {
				log.Fatal(err)
			}
			p1 += val
		} else {
			val, err := strconv.Atoi(corrected_pages[len(corrected_pages)/2])
			if err != nil {
				log.Fatal(err)
			}
			p2 += val
		}
	}

	fmt.Println(p1)
	fmt.Println(p2)
}

func correct(rules map[string]map[string]bool, pages []string) ([]string, bool) {
	for idx, page := range pages {
		if idx == 0 {
			continue
		}

		p_rules, exist := rules[page]
		if !exist {
			continue
		}

		for p_idx, prev_page := range pages[0:idx] {
			_, violated := p_rules[prev_page]
			if violated {
				corrected_pages, _ := correct(rules, moveInt(pages, p_idx, len(pages)-1))
				return corrected_pages, false
			}
		}
	}

	return pages, true
}

func insertInt(array []string, value string, index int) []string {
	return append(array[:index], append([]string{value}, array[index:]...)...)
}

func removeInt(array []string, index int) []string {
	return append(array[:index], array[index+1:]...)
}

func moveInt(array []string, srcIndex int, dstIndex int) []string {
	value := array[srcIndex]
	return insertInt(removeInt(array, srcIndex), value, dstIndex)
}
