// -*- mode: Go; compile-command:"go build part2.go" -*-
package main

import (
	"bufio"
	"fmt"
	"os"
	"regexp"
	"sort"
	"strconv"
)

type Device struct {
	registers [4]int
}

type CandidateSet map[int]bool

type Instruction struct {
	opCode int
	a      int
	b      int
	c      int
}

type Operation struct {
	opCode  int
	name    string
	Execute func(d Device, i Instruction) Device
}

// Evidence presents a state change we can use
// to determine what the opcode does
type Evidence struct {
	before      Device
	after       Device
	instruction Instruction
}

func parseInstructions(lines []string, startLine int) []Instruction {

	instruction := `(\d+) (\d) (\d) (\d)`
	r1 := regexp.MustCompile(instruction)

	var instructions []Instruction

	for l := startLine; l < len(lines); l++ {
		matchInstruction := r1.FindStringSubmatch(lines[l])

		if matchInstruction == nil {
			continue
		}

		op, e1 := strconv.Atoi(matchInstruction[1])
		a, e2 := strconv.Atoi(matchInstruction[2])
		b, e3 := strconv.Atoi(matchInstruction[3])
		c, e4 := strconv.Atoi(matchInstruction[4])

		if e1 == nil && e2 == nil && e3 == nil && e4 == nil {
			thisInstruction := Instruction{op, a, b, c}
			instructions = append(instructions, thisInstruction)
		}
	}

	return instructions
}

// Returns a slice of evidence and the remaining lines
func parseEvidence(lines []string) ([]Evidence, int) {

	ev := []Evidence{}

	start := 0

	for {
		if lines[start] == "" || start+2 > len(lines) {
			return ev, start
		}

		var before = `Before: \[(\d), (\d), (\d), (\d)\]`
		var instruction = `(\d+) (\d) (\d) (\d)`
		var after = `After:  \[(\d+), (\d), (\d), (\d)\]`

		r1 := regexp.MustCompile(before)
		r2 := regexp.MustCompile(instruction)
		r3 := regexp.MustCompile(after)

		matchBefore := r1.FindStringSubmatch(lines[start])
		matchInstruction := r2.FindStringSubmatch(lines[start+1])
		matchAfter := r3.FindStringSubmatch(lines[start+2])

		if matchBefore == nil || matchInstruction == nil || matchAfter == nil {
			return ev, start
		}

		reg1, e1 := strconv.Atoi(matchBefore[1])
		reg2, e2 := strconv.Atoi(matchBefore[2])
		reg3, e3 := strconv.Atoi(matchBefore[3])
		reg4, e4 := strconv.Atoi(matchBefore[4])

		if e1 != nil || e2 != nil || e3 != nil || e4 != nil {
			return ev, start
		}

		beforeDevice := Device{registers: [...]int{reg1, reg2, reg3, reg4}}

		reg1, e1 = strconv.Atoi(matchAfter[1])
		reg2, e2 = strconv.Atoi(matchAfter[2])
		reg3, e3 = strconv.Atoi(matchAfter[3])
		reg4, e4 = strconv.Atoi(matchAfter[4])

		if e1 != nil || e2 != nil || e3 != nil || e4 != nil {
			return ev, start
		}

		afterDevice := Device{registers: [...]int{reg1, reg2, reg3, reg4}}

		op, e1 := strconv.Atoi(matchInstruction[1])
		a, e2 := strconv.Atoi(matchInstruction[2])
		b, e3 := strconv.Atoi(matchInstruction[3])
		c, e4 := strconv.Atoi(matchInstruction[4])

		if e1 != nil || e2 != nil || e3 != nil || e4 != nil {
			return ev, start
		}

		thisInstruction := Instruction{op, a, b, c}

		ev = append(ev, Evidence{beforeDevice, afterDevice, thisInstruction})

		start += 4
	}
	return ev, start
}

// Get the candidates that match this evidence
func getCandidates(ev Evidence, ops []Operation) []int {
	var candidates []int

	//	fmt.Printf("Ins %d a %d b %d c %d\nbefore %v\nafter %v\n", ev.instruction.opCode, ev.instruction.a, ev.instruction.b, ev.instruction.c, ev.before, ev.after)

	for index, op := range ops {

		result := op.Execute(ev.before, ev.instruction)

		//		fmt.Printf("op id %d name %s result %v\n", index, op.name, result)

		if result == ev.after {
			candidates = append(candidates, index)
		}
	}

	return candidates
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

func checkMappingWithEvidence(mapping map[int]int, evidence []Evidence, ops []Operation) bool {

	for _, ev := range evidence {
		op := ev.instruction.opCode
		op = mapping[op]

		after := ops[op].Execute(ev.before, ev.instruction)

		if after != ev.after {
			return false
		}
	}

	return true
}

func showOpCandidates(opCandidates map[int]CandidateSet) {
	fmt.Printf("Op candidates %v\n\n", opCandidates)

	keys := make([]int, len(opCandidates))

	i := 0
	for k, _ := range opCandidates {
		keys[i] = k
		i += 1
	}
	sort.Ints(keys)

	for k := range keys {
		fmt.Printf("op %d : ", k)
		for k, _ := range opCandidates[k] {
			fmt.Printf("%d ", k)
		}
		fmt.Printf("\n")
	}
}

func replaceKnown(opCandidates map[int]CandidateSet, known map[int]int) {

	// known is a map of fake opcode to real opcode
	// here we want to know which real opcodes are known and
	// remove them from candidate sets
	// first we need the reverse map of known

	reverseKnown := make(map[int]int)

	for k, v := range known {
		reverseKnown[v] = k
	}

	for op, candidates := range opCandidates {
		newC := make(CandidateSet)
		for candidate, _ := range candidates {
			_, found := reverseKnown[candidate]
			if !found {
				newC[candidate] = true
			}
		}
		opCandidates[op] = newC
	}
}

func allKnown(opCandidates map[int]CandidateSet) bool {
	for _, candidates := range opCandidates {
		if len(candidates) > 0 {
			return false
		}
	}
	return true
}

func findUnknown(opCandidates map[int]CandidateSet, known map[int]int) {
	for op, v := range opCandidates {
		if len(v) == 1 {
			for k := range v {
				known[op] = k
			}
		}
	}
}

func main() {

	filename := "input.txt"
	if len(os.Args) > 1 {
		filename = os.Args[1]
	}

	ops := []Operation{
		Operation{opCode: -1,
			name: "addr",
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				b := d.registers[i.b]
				d.registers[i.c] = a + b
				return d
			},
		},
		Operation{opCode: -1,
			name: "addi",
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				d.registers[i.c] = a + i.b
				return d
			},
		},
		Operation{opCode: -1,
			name: "mulr",
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				b := d.registers[i.b]
				d.registers[i.c] = a * b
				return d
			},
		},
		Operation{opCode: -1,
			name: "muli",
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				d.registers[i.c] = a * i.b
				return d
			},
		},
		Operation{opCode: -1,
			name: "banr",
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				b := d.registers[i.b]
				d.registers[i.c] = a & b
				return d
			},
		},
		Operation{opCode: -1,
			name: "bani",
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				d.registers[i.c] = a & i.b
				return d
			},
		},
		Operation{opCode: -1,
			name: "borr",
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				b := d.registers[i.b]
				d.registers[i.c] = a | b
				return d
			},
		},
		Operation{opCode: -1,
			name: "bori",
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				d.registers[i.c] = a | i.b
				return d
			},
		},
		Operation{opCode: -1,
			name: "setr",
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				d.registers[i.c] = a
				return d
			},
		},
		Operation{opCode: -1,
			name: "seti",
			Execute: func(d Device, i Instruction) Device {
				d.registers[i.c] = i.a
				return d
			},
		},
		Operation{opCode: -1,
			name: "gtir",
			Execute: func(d Device, i Instruction) Device {
				b := d.registers[i.b]
				if i.a > b {
					d.registers[i.c] = 1
				} else {
					d.registers[i.c] = 0
				}
				return d
			},
		},
		Operation{opCode: -1,
			name: "gtri",
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				if a > i.b {
					d.registers[i.c] = 1
				} else {
					d.registers[i.c] = 0
				}
				return d
			},
		},
		Operation{opCode: -1,
			name: "gtrr",
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				b := d.registers[i.b]
				if a > b {
					d.registers[i.c] = 1
				} else {
					d.registers[i.c] = 0
				}
				return d
			},
		},
		Operation{opCode: -1,
			name: "eqir",
			Execute: func(d Device, i Instruction) Device {
				b := d.registers[i.b]
				if i.a == b {
					d.registers[i.c] = 1
				} else {
					d.registers[i.c] = 0
				}
				return d
			},
		},
		Operation{opCode: -1,
			name: "eqri",
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				if a == i.b {
					d.registers[i.c] = 1
				} else {
					d.registers[i.c] = 0
				}
				return d
			},
		},
		Operation{opCode: -1,
			name: "eqrr",
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				b := d.registers[i.b]
				if a == b {
					d.registers[i.c] = 1
				} else {
					d.registers[i.c] = 0
				}
				return d
			},
		},
	}

	lines, error := readLines(filename)

	// For part 2 create a map (really we want a set but we can use a map
	// as a set for our purposes)

	opCandidates := make(map[int]CandidateSet)

	if error == nil {
		evidence, next_line := parseEvidence(lines)

		// fmt.Printf("evidence %v\n", evidence)

		instructions := parseInstructions(lines, next_line)

		instructions = instructions // TODO remove later

		for _, ev := range evidence {
			// Find all candidate ops for each evidence, returned as a list
			// of candidate codes for those ops
			candidates := getCandidates(ev, ops)

			//			fmt.Printf("candidates for ev %d %v\n", i, candidates)

			// We'll maintain a map of the remapped opcodes and the
			// actual opcodes they represent (indexes into the opcodes array)
			for _, candidate := range candidates {
				m, found := opCandidates[ev.instruction.opCode]

				if !found {
					opCandidates[ev.instruction.opCode] = make(map[int]bool)
					m = opCandidates[ev.instruction.opCode]
				}
				m[candidate] = true
			}
		}

		known := make(map[int]int, 20)

		for !allKnown(opCandidates) {
			//			showOpCandidates(opCandidates)

			findUnknown(opCandidates, known)

			//			fmt.Printf("known %v\n", known)

			replaceKnown(opCandidates, known)
		}
		fmt.Printf("known %v\n", known)

		state := Device{registers: [...]int{0, 0, 0, 0}}

		for _, instruction := range instructions {
			op := instruction.opCode
			op = known[op]
			state = ops[op].Execute(state, instruction)
		}

		fmt.Printf("State %v\n", state)

	} else {
		fmt.Printf("Error %v\n", error)
	}

}
