// -*- mode: Go; compile-command:"go build part1.go"; gdb-many-windows:t; -*-
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

// Parse candidates which look like this:
// Before: [1, 3, 1, 3]
// 14 0 3 0
// After:  [0, 3, 1, 3]

// Implement operations as things that take a Device state and implement that instruction
// That could be defined as an interface
// then you have an array of the implementations
// These can then be applied to each of the candidates

// Returns a slice of evidence and the remaining lines
func parseEvidence(lines []string, start int) ([]Evidence, int) {

	ev := []Evidence{}

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

func countCandidates(ev Evidence, ops []Operation) int {
	count := 0
	for _, op := range ops {
		result := op.Execute(ev.before, ev.instruction)
		if result == ev.after {
			count += 1
		}
	}
	return count
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

	if error == nil {
		evidence, _ := parseEvidence(lines, 0)

		answer := 0
		for _, ev := range evidence {
			count := countCandidates(ev, ops)
			fmt.Printf("%d\n", count)
			if count >= 3 {
				answer += 1
			}
		}

		fmt.Printf("Answer %d\n", answer)
	} else {
		fmt.Printf("Error %v\n", error)
	}

}
