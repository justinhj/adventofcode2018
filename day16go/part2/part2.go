// -*- mode: Go; compile-command:"go build part2.go" -*-
package main

import (
	"bufio"
	"fmt"
	"os"
	"regexp"
	"strconv"
	"strings"
	"reflect"
)

// For set bullshit
func addSolution(newSolution map[int]int, currentSolutions []map[int]int) []map[int]int {

	for thing := range currentSolutions {
		if reflect.DeepEqual(thing, newSolution) {
			return currentSolutions
		}
	}

	return append(currentSolutions, newSolution)
}

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

// Evidence presents a state change we can use
// to determine what the opcode does
type Evidence struct {
	before      Device
	after       Device
	instruction Instruction
}

func parseInstructions(lines []string, startLine int) []Instruction {

	instruction := `(\d)+ (\d) (\d) (\d)`
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

func getOpCodesHelper(cs map[int]CandidateSet, used map[int]int, solutions []map[int]int, depth int) []map[int]int {

	indent := strings.Repeat("  ", depth)

	fmt.Printf("%slen %d used %v solutions %d\n", indent, len(cs), used, len(solutions))

	if len(cs) == 0 {
		fmt.Printf("gen %v\n", used)
		return addSolution(used, solutions)
	}

	keys := make([]int, 0, len(cs))
	for k := range cs {
		keys = append(keys, k)
	}

	for _, k := range keys {

		fmt.Printf("%sk %v\n", indent, k)

		//	fmt.Printf("k %v cs %v\n", k, cs[k])
		candidates := cs[k]

		fmt.Printf("%sshall loop over %v\n", indent,   cs[k])

		for candidate, _ := range candidates {

			//fmt.Printf("candidate %v\n", candidate)

			_, found := used[candidate]

			if found {
				continue
			}

			// Make a copy of the used map to pass into the continued recursion
			newUsed := make(map[int]int)
			for key, value := range used {
				newUsed[key] = value
			}

			newUsed[candidate] = k

			// Copy candidate set without the current key
			newCs := make(map[int]CandidateSet)
			for key, value := range cs {
				if key == k {
					continue
				}

				// oh god this is so painful
				// copy the candidate set manually

				candSet := make(map[int]bool)
				for ck, cv := range value {
					candSet[ck] = cv
				}

				newCs[key] = candSet
			}

			solutions = getOpCodesHelper(newCs, newUsed, solutions, depth + 1)

			//fmt.Printf("%sfound %d solutions\n", indent, len(recursiveSolutions))
			//
			//solutions = append(solutions, recursiveSolutions...)
		}
	}

	return solutions
}

func getOpCodes(cs map[int]CandidateSet) []map[int]int {

	solutions := make([]map[int]int, 0)

	return getOpCodesHelper(cs, make(map[int]int), solutions, 0)
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

	// TEMP

	c1 := map[int]bool{1: true, 2: true, 3: true}
	c2 := map[int]bool{1: true, 2: true}
	c3 := map[int]bool{3: true}

	cs := make(map[int]CandidateSet)
	cs[9] = c1
	cs[10] = c2
	cs[11] = c3

	opCodes := getOpCodes(cs)

	opCodes = opCodes
	// for k, v := range opCodes {
	// 	fmt.Printf("%v %v\n", k, v)
	// }
	fmt.Printf("Found %d potential opcode mappings %v\n", len(opCodes), opCodes)
	//os.Exit(0)

	// END

	// For part 2 create a map (really we want a set but we can use a map
	// as a set for our purposes)

	opCandidates := make(map[int]CandidateSet)

	if error == nil {
		evidence, next_line := parseEvidence(lines)

		//fmt.Printf("evidence %v\n", evidence)

		instructions := parseInstructions(lines, next_line)

		instructions = instructions

		for _, ev := range evidence {
			candidates := getCandidates(ev, ops)

			for _, candidate := range candidates {
				m, found := opCandidates[ev.instruction.opCode]

				if !found {
					opCandidates[ev.instruction.opCode] = make(map[int]bool)
					m = opCandidates[ev.instruction.opCode]
				}
				m[candidate] = true
			}
		}

		fmt.Printf("op candidates%v\n", opCandidates)

		opCodeMappings := getOpCodes(opCandidates)

		fmt.Printf("Found %d potential opcode mappings %v\n", len(opCodeMappings), opCodeMappings)

		// Test each combination with the evidence and see which ones are good

		for index, mapping := range opCodeMappings {
			works := checkMappingWithEvidence(mapping, evidence, ops)
			if works == true {
				fmt.Printf("\n%v works\n", mapping)
			}
			if index%10000 == 0 {
				fmt.Print(".")
			}
		}

		//Fmt.Printf("Instructions %v\n", instructions)

		// state := Device{registers: [...]int{0, 0, 0, 0}}

		// for _, instruction := range instructions {
		// 	op := instruction.opCode
		// 	op = opCodes[op]
		// 	state = ops[op].Execute(state, instruction)
		// }

		// fmt.Printf("State %v\n", state)

	} else {
		fmt.Printf("Error %v\n", error)
	}

}
