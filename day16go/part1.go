package main

import "fmt"

type Device struct {
	registers [4]int
}

type Instruction struct {
	opCode int
	a      int
	b      int
	c      int
}

// Parse candidates which look like this:
// Before: [1, 3, 1, 3]
// 14 0 3 0
// After:  [0, 3, 1, 3]

// Implement operations as things that take a Device state and implement that instruction
// That could be defined as an interface
// then you have an array of the implementations
// These can then be applied to each of the candidates

func main() {

	fmt.Printf("Goob moooging\n")

}
