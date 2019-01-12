package main

import (
	"bufio"
	"fmt"
	"os"
	"regexp"
	"strconv"
)

type Device struct {
	registers [4]int
}

type Instruction struct {
	opCode int
	a      int
	b      int
	c      int
}

// Represents a state change we can use
// to determine what the opcode does
type Evidence struct {
	before      Device
	after       Device
	instruction Instruction
}

// Parse candidates which look like this:
// Before: [1, 3, 1, 3]
// 14 0 3 0
// After:  [0, 3, 1, 3]

// Implement operations as things that take a Device state and implement that instruction
// That could be defined as an interface
// then you have an array of the implementations
// These can then be applied to each of the candidates

// Returns a slice of evidence and the remaining lines
func parseEvidence(lines []string) ([]Evidence, []string) {

	ev := make([]Evidence, 10)

	for {
		var before = `Before: \[(\d), (\d), (\d), (\d)\]`
		var instruction = `(\d)+ (\d) (\d) (\d)`
		var after = `After:  \[(\d+), (\d), (\d), (\d)\]`

		r1 := regexp.MustCompile(before)
		r2 := regexp.MustCompile(instruction)
		r3 := regexp.MustCompile(after)

		matchBefore := r1.FindStringSubmatch(lines[0])
		matchInstruction := r2.FindStringSubmatch(lines[1])
		matchAfter := r3.FindStringSubmatch(lines[2])

		reg1, e1 := strconv.Atoi(matchBefore[1])
		reg2, e2 := strconv.Atoi(matchBefore[2])
		reg3, e3 := strconv.Atoi(matchBefore[3])
		reg4, e4 := strconv.Atoi(matchBefore[4])

		if !(e1 != nil && e2 != nil && e3 != nil && e4 != nil) {
			lines = lines[1:]
			break
		}

		beforeDevice := Device{registers: [...]int{reg1, reg2, reg3, reg4}}

		reg1, e1 = strconv.Atoi(matchAfter[1])
		reg2, e2 = strconv.Atoi(matchAfter[2])
		reg3, e3 = strconv.Atoi(matchAfter[3])
		reg4, e4 = strconv.Atoi(matchAfter[4])

		if !(e1 != nil && e2 != nil && e3 != nil && e4 != nil) {
			lines = lines[1:]
			break
		}

		afterDevice := Device{registers: [...]int{reg1, reg2, reg3, reg4}}

		op, e1 := strconv.Atoi(matchInstruction[1])
		a, e2 := strconv.Atoi(matchInstruction[2])
		b, e3 := strconv.Atoi(matchInstruction[3])
		c, e4 := strconv.Atoi(matchInstruction[4])

		if !(e1 != nil && e2 != nil && e3 != nil && e4 != nil) {
			lines = lines[1:]
			break
		}

		thisInstruction := Instruction{op, a, b, c}

		ev = append(ev, Evidence{beforeDevice, afterDevice, thisInstruction})

		fmt.Printf("%v\n", ev)

		lines = lines[4:]
	}

	return ev, lines
}

func readLines(path string) ([]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var lines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}
	return lines, scanner.Err()
}

func main() {

	filename := "input.txt"
	if len(os.Args) > 1 {
		filename = os.Args[1]
	}

	lines, error := readLines(filename)

	if error == nil {
		evidence, _ := parseEvidence(lines)

		fmt.Printf("Sucess %v\n", evidence)
	} else {
		fmt.Printf("Error %v\n", error)
	}

}
