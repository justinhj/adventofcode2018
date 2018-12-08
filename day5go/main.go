package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"strings"
	//	"sync"
)

func check(e error) {
	if e != nil {
		panic(e)
	}

}

func reactsWith(a uint8, b uint8) bool {

	//fmt.Printf("Compare %c with %c\n", a, b)

	if a > b {
		return a-b == 32
	} else {
		return b-a == 32
	}

}

const MinSizeForProcess int = 1000

type result struct {
	output  string
	changed bool
}

func processReactions(inputStr string, response chan result) result {

	l := len(inputStr)

	if l > MinSizeForProcess {

		left := make(chan result)
		right := make(chan result)

		go processReactions(inputStr[0:l/2], left)
		go processReactions(inputStr[l/2:l], right)

		var leftResult result = result{"", false}
		var rightResult result = result{"", false}

	Out:
		for {
			select {
			case l := <-left:
				//fmt.Printf("received output on chan %v %s\n", left, l.output)
				leftResult = l
				if len(rightResult.output) > 0 {
					break Out
				}
			case r := <-right:
				//fmt.Printf("received output on chan %v %s\n", right, r.output)
				rightResult = r
				if len(leftResult.output) > 0 {
					break Out
				}
			}
		}

		res := result{leftResult.output + rightResult.output, leftResult.changed || rightResult.changed}

		if response != nil {
			response <- res
			close(response)
		}

		return res

	} else {

		var b strings.Builder

		skip := false
		changed := false

		for i := 0; i < l; i++ {

			if skip == false {
				//fmt.Printf("i %d l %d\n", i, l)
				if i <= (l - 2) {
					// if there's no reaction write the char to the output string
					if !reactsWith(inputStr[i], inputStr[i+1]) {
						b.WriteByte(inputStr[i])
						//fmt.Printf("Output %s\n", b.String())
					} else {
						//fmt.Printf("Skipping %c %c because they react\n", inputStr[i], inputStr[i+1])
						// when there is a reaction skip this char and the next one
						skip = true
						changed = true
					}
				} else {
					b.WriteByte(inputStr[i])
				}
			} else {
				skip = false
			}

		}

		if response != nil {
			//fmt.Printf("Chan %v send output %d changed %t\n", response, len(b.String()), changed)
			response <- result{b.String(), changed}
			close(response)
		}

		//fmt.Printf("return output. changed %t\n", changed)
		return result{b.String(), changed}
	}
}

func processUntilDone(input string) string {
	res := processReactions(input, nil)

	//fmt.Printf("Output %s Changed %t\n", res.output, res.changed)

	for res.changed == true {
		fmt.Print(".")
		res = processReactions(res.output, nil)
		//	fmt.Printf("Output %s Changed %t\n", output, changed)
	}

	return res.output
}

func main() {

	if len(os.Args) < 2 {
		fmt.Println("Please provide an input file")
		os.Exit(1)
	}

	filename := os.Args[1]

	fmt.Printf("Reading %s\n", filename)

	dat, err := ioutil.ReadFile(filename)
	check(err)

	input := strings.TrimSpace(string(dat))

	//fmt.Printf("Input %s %d\n\n", input, len(input))
	fmt.Printf("Input length %d\n", len(input))

	output := processUntilDone(input)

	fmt.Printf("\nOutput length %d\n", len(output))

	// Part 2... remove each letter and find the shortest polymer

	for remove := 'A'; remove <= 'Z'; remove++ {

		noLower := strings.Replace(input, string(remove), "", -1)

		noUpper := strings.Replace(noLower, string(remove+32), "", -1)

		out := processUntilDone(noUpper)

		fmt.Printf("\nOutput length without letter %c is %d\n", remove, len(out))
	}

}
