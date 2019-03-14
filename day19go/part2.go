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
	ipCur     int
	ipReg     int
	registers [6]int
}

type Instruction struct {
	opCode string
	a      int
	b      int
	c      int
}

type Operation struct {
	Execute func(d Device, i Instruction) Device
}

func parseInput(lines []string) (int, []Instruction) {

	ipRegex := regexp.MustCompile(`#ip (\d+)`)
	match := ipRegex.FindStringSubmatch(lines[0])

	if match == nil {
		return 0, []Instruction{}
	}

	ip, _ := strconv.Atoi(match[1])

	l := len(lines)

	ins := []Instruction{}

	instructionRegex := regexp.MustCompile(`([a-z]{4}) (\d+) (\d+) (\d+)`)

	line := 1
	for line < l {

		match = instructionRegex.FindStringSubmatch(lines[line])

		if match == nil {
			return 0, []Instruction{}
		}

		opCode := match[1]
		a, e1 := strconv.Atoi(match[2])
		b, e2 := strconv.Atoi(match[3])
		c, e3 := strconv.Atoi(match[4])

		if e1 != nil || e2 != nil || e3 != nil {
			return 0, []Instruction{}
		}

		ins = append(ins, Instruction{opCode, a, b, c})

		line += 1
	}

	return ip, ins
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

	ops := map[string]Operation{
		"addr": Operation{
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				b := d.registers[i.b]
				d.registers[i.c] = a + b
				return d
			},
		},
		"addi": Operation{
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				d.registers[i.c] = a + i.b
				return d
			},
		},
		"mulr": Operation{
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				b := d.registers[i.b]
				d.registers[i.c] = a * b
				return d
			},
		},
		"muli": Operation{
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				d.registers[i.c] = a * i.b
				return d
			},
		},
		"banr": Operation{
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				b := d.registers[i.b]
				d.registers[i.c] = a & b
				return d
			},
		},
		"bani": Operation{
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				d.registers[i.c] = a & i.b
				return d
			},
		},
		"borr": Operation{
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				b := d.registers[i.b]
				d.registers[i.c] = a | b
				return d
			},
		},
		"bori": Operation{
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				d.registers[i.c] = a | i.b
				return d
			},
		},
		"setr": Operation{
			Execute: func(d Device, i Instruction) Device {
				a := d.registers[i.a]
				d.registers[i.c] = a
				return d
			},
		},
		"seti": Operation{
			Execute: func(d Device, i Instruction) Device {
				d.registers[i.c] = i.a
				return d
			},
		},
		"gtir": Operation{
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
		"gtri": Operation{
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
		"gtrr": Operation{
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
		"eqir": Operation{
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
		"eqri": Operation{
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
		"eqrr": Operation{
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
		ip, instructions := parseInput(lines)
		fmt.Printf("ip = %d\n", ip)

		for _, ins := range instructions {
			fmt.Printf("%s %d %d %d\n", ins.opCode, ins.a, ins.b, ins.c)
		}

		device := Device{ipCur: 0, ipReg: ip, registers: [6]int{1, 0, 0, 0, 0, 0}}
		fmt.Printf("Initial %v\n", device)

		ipCur := 0

		numInstructions := len(instructions)

		// Debugger controls

		breakpoints := make(map[int]bool, false)
		running := false

		fmt.Printf("Commands:\n")
		fmt.Printf("---------\n")
		fmt.Printf("run - Run until any key press\n")
		fmt.Printf("break enable [n] - Add a breakpoint when instruction pointer is n\n")
		fmt.Printf("break disable [n] - Remove any breakpoint when instruction pointer is n\n")
		fmt.Printf("step - Step instruction\n")

		// Main loop

		iterations := 0
		for {

			if ipCur < 0 || ipCur >= numInstructions || iterations > 100000000 {
				fmt.Printf("Halted with reg 0 = %d after %d iterations\n", device.registers[0], iterations)
				break
			}

			instruction := instructions[ipCur]
			// Set the ip reg to current ip
			device.registers[ip] = ipCur

			// Show prompt
			is_breakpoint := breakpoints[ipCur]
			if !running || is_breakpoint {
				fmt.Printf("> ")

			}

			fmt.Printf("ip=%010d [%010d %010d %010d %010d %010d %010d] %v ", ipCur,
				device.registers[0],
				device.registers[1],
				device.registers[2],
				device.registers[3],
				device.registers[4],
				device.registers[5],
				instruction)

			op := ops[instruction.opCode]

			device = op.Execute(device, instruction)

			// Update ip from reg
			ipCur = device.registers[ip]

			fmt.Printf("%010d %010d %010d %010d %010d %010d\n", device.registers[0],
				device.registers[1],
				device.registers[2],
				device.registers[3],
				device.registers[4],
				device.registers[5])

			// And increment
			ipCur += 1

			iterations += 1
		}
	}
}
