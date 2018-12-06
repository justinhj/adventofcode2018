package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"strings"
)

func check(e error) {
	if e != nil {
		panic(e)
	}
}

func reactsWith(a uint8, b uint8) bool {

	//	fmt.Printf("Compare %c with %c\n", a, b)

	if a > b {
		return a-b == 32
	} else {
		return b-a == 32
	}

}

func processReactions(inputStr string) (string, bool) {

	var b strings.Builder
	var l = len(inputStr)

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

	//fmt.Printf("return output %s changed %t\n", b.String(), changed)

	return b.String(), changed
}

func processUntilDone(input string) string {
	output, changed := processReactions(input)

	for changed == true {
		fmt.Print(".")
		output, changed = processReactions(output)
		//	fmt.Printf("Output %s Changed %t\n", output, changed)
	}

	return output
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

}
