package main

import "testing"
import "fmt"

// Test for opcode finding...

func TestOneChar(t *testing.T) {

	// 9 could 1 2 3
	// 10 could be 1 2
	// 11 could be 3

	// 9:1 10:2 11:3
	// 9:2 10:1 11:3
	// 9:3 10:1 11:

	c1 := map[int]bool{1: true, 2: true, 3: true}
	c2 := map[int]bool{1: true, 2: true}
	c3 := map[int]bool{3: true}

	cs := make(map[int]CandidateSet)
	cs[9] = c1
	cs[10] = c2
	cs[11] = c3

	opCodes := getOpCodes(cs)

	fmt.Printf("%v\n", opCodes)

	//	func getOpCodes(cs map[int]CandidateSet) map[int]int {

	//	c1 := map[int]bool{0: true, 1: true}
	//	c2 := map[int]bool{1: true, 2:true}
	//	c3 := map[int]bool{1: true, 2:true}

	// input := "a"
	// output := processUntilDone(input)
	// if output != "a" {
	// 	t.Errorf("Got: %s, want: %s.", output, "a")
	// }
}
