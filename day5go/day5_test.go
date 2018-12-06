package main

import "testing"
import "fmt"

func TestOneChar(t *testing.T) {

	fmt.Printf("test1\n")

	input := "a"
	output := processUntilDone(input)
	if output != "a" {
		t.Errorf("Got: %s, want: %s.", output, "a")
	}
}

func TestButLast(t *testing.T) {
	fmt.Printf("test2\n")
	input := "aAbBcCzZAaBbCcx"
	output := processUntilDone(input)
	if output != "x" {
		t.Errorf("Got: %s, want: %s.", output, "a")
	}
}

func TestButFirst(t *testing.T) {
	fmt.Printf("test3\n")
	input := "xaAbBcCzZAaBbCc"
	output := processUntilDone(input)
	if output != "x" {
		t.Errorf("Got: %s, want: %s.", output, "x")
	}
}

func TestSample(t *testing.T) {
	fmt.Printf("test4\n")
	input := "dabAcCaCBAcCcaDA"
	output := processUntilDone(input)
	expect := "dabCBAcaDA"
	if output != expect {
		t.Errorf("Got: %s, want: %s.", output, expect)
	}
}

func TestCascade(t *testing.T) {
	fmt.Printf("test5\n")
	input := "ZyXwVuTsRqPoNmLkJiHgFEdcBAabCDefGhIjKlMnOpQrStUvWxYz"
	output := processUntilDone(input)
	expect := ""
	if output != expect {
		t.Errorf("Got: %s, want: %s.", output, expect)
	}
}

func TestXCascade(t *testing.T) {
	fmt.Printf("test6\n")
	input := "XZyXwVuTsRqPoNmLkJiHgFEdcBAabCDefGhIjKlMnOpQrStUvWxYz"
	output := processUntilDone(input)
	expect := "X"
	if output != expect {
		t.Errorf("Got: %s, want: %s.", output, expect)
	}
}

func TestCascadeX(t *testing.T) {
	fmt.Printf("test7\n")
	input := "ZyXwVuTsRqPoNmLkJiHgFEdcBAabCDefGhIjKlMnOpQrStUvWxYzX"
	output := processUntilDone(input)
	expect := "X"
	if output != expect {
		t.Errorf("Got: %s, want: %s.", output, expect)
	}
}

func TestEnd(t *testing.T) {
	fmt.Printf("test8\n")
	input := "ababababababaACca"
	output := processUntilDone(input)
	expect := "ababababababa"
	if output != expect {
		t.Errorf("Got: %s, want: %s.", output, expect)
	}
}

func TestBegin(t *testing.T) {
	fmt.Printf("test9\n")
	input := "ACcaababababababa"
	output := processUntilDone(input)
	expect := "ababababababa"
	if output != expect {
		t.Errorf("Got: %s, want: %s.", output, expect)
	}
}
