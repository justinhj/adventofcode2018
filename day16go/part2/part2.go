// -*- mode: Go; compile-command:"go build part2.go" -*-
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

// type Op interface {
// 	Execute(d Device, i Instruction) Device
// }

// Represents a state change we can use
// to determine what the opcode does
type Evidence struct {
	before      Device
	after       Device
	instruction Instruction
}

func parseInstructions(lines []string, start_line int) []Instruction {

	instruction := `(\d)+ (\d) (\d) (\d)`
	r1 := regexp.MustCompile(instruction)

	var instructions []Instruction

	for l := start_line; l < len(lines); l++ {
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
		if lines[start] == "" {
			return ev, start
		}

		var before = `Before: \[(\d), (\d), (\d), (\d)\]`
		var instruction = `(\d)+ (\d) (\d) (\d)`
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
	for index, op := range ops {
		result := op.Execute(ev.before, ev.instruction)
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

func getOpCodesHelper(first int, cs map[int]CandidateSet, used map[int]int) map[int]int {

	if len(used) == len(cs) {
		return used // the solution!
	} else if first == len(cs) {
		return nil // failed
	}

	var candidates map[int]bool
	candidates = cs[first]

	for candidate, _ := range candidates {

		_, found := used[candidate]

		if found {
			continue
		}

		newUsed := make(map[int]int)
		for key, value := range used {
			newUsed[key] = value
		}

		newUsed[candidate] = first

		result := getOpCodesHelper(first+1, cs, newUsed)

		if result != nil {
			return result
		}
	}

	return nil
}

func getOpCodes(cs map[int]CandidateSet) map[int]int {

	// // sigh: we need to make the keys for the map
	// keys := make([]int, 0, len(cs))
	// for k := range cs {
	// 	keys = append(keys, k)
	// }

	return getOpCodesHelper(0, cs, make(map[int]int))
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

	//	perms := permutations([]int{0, 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12})

	//fmt.Printf("Number of perms is %d\n", len(perms))

	// For part 2 create a map (really we want a set but we can use a map
	// as a set for our purposes)

	opCandidates := make(map[int]CandidateSet)

	if error == nil {
		evidence, next_line := parseEvidence(lines)

		instructions := parseInstructions(lines, next_line)

		for _, ev := range evidence {
			candidates := getCandidates(ev, ops)

			for _, candidate := range candidates {
				m, found := opCandidates[ev.instruction.opCode]

				if found {
					m[candidate] = true
				} else {
					opCandidates[ev.instruction.opCode] = make(map[int]bool)
				}
			}
		}

		fmt.Printf("%v\n", opCandidates)

		opCodes := getOpCodes(opCandidates)

		fmt.Printf("Result %v\n", opCodes)

		// Now we have our opcodes run the code

		//fmt.Printf("Instructions %v\n", instructions)

		state := Device{registers: [...]int{0, 0, 0, 0}}

		for _, instruction := range instructions {
			op := instruction.opCode
			op = opCodes[op]
			state = ops[op].Execute(state, instruction)
		}

		fmt.Printf("State %v\n", state)

	} else {
		fmt.Printf("Error %v\n", error)
	}

}
