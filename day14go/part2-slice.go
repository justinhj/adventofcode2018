package main

import "fmt"

func iterate(recipes []int, elf1 int, elf2 int) ([]int, int, int) {
	sum := recipes[elf1] + recipes[elf2]

	if sum >= 10 {
		recipes = append(recipes, 1)
		recipes = append(recipes, sum-10)
	} else {
		recipes = append(recipes, sum)
	}

	var l = len(recipes)

	elf1 = (elf1 + recipes[elf1] + 1) % l
	elf2 = (elf2 + recipes[elf2] + 1) % l

	return recipes, elf1, elf2
}

func check_solution(recipes []int, seq []int, offset int) bool {
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

	var recipes = []int{3, 7}

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
			target := []int{6, 3, 5, 0, 4, 1}
			found := check_solution(recipes, target, 0) || check_solution(recipes, target, 1)
			if found {
				fmt.Printf("Found at len = %d\n", len(recipes))
				break
			}

		}
	}
}
