package main

import "fmt"
import "strconv"

func iterate(recipes string, elf1 int, elf2 int) (string, int, int) {
	var sum byte = recipes[elf1] - '0' + recipes[elf2] - '0'

	//	recipes = strings.Join([]string{recipes, strconv.Itoa(int(sum))}, "")
	recipes += strconv.Itoa(int(sum))

	var l = len(recipes)

	elf1 = (elf1 + int(recipes[elf1]-'0') + 1) % l
	elf2 = (elf2 + int(recipes[elf2]-'0') + 1) % l

	return recipes, elf1, elf2
}

func check_solution(recipes string, seq string, offset int) bool {
	i := len(recipes) - 1 - offset
	s := len(seq) - 1

	for s >= 0 {
		if recipes[i] == seq[s] {
			i -= 1
			s -= 1
		} else {
			return false
		}
	}

	return true
}

func main() {
	var elf1 = 0
	var elf2 = 1

	var recipes = "37"

	recipes, elf1, elf2 = iterate(recipes, elf1, elf2)

	for {
		recipes, elf1, elf2 = iterate(recipes, elf1, elf2)

		l := len(recipes)

		if l%100000 == 0 {
			fmt.Print(".")
		}

		if l < 10 {
			continue
		} else {
			target := "635041"
			found := check_solution(recipes, target, 0) || check_solution(recipes, target, 1)
			if found {
				fmt.Printf("Found at len = %d\n", len(recipes))
				break
			}

		}
	}
}
