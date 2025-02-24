package main

import "fmt"

func main() {
	var a, b uint32 = 0x12345678, 0x87654321
	fmt.Printf("XOR test: 0x%x\n", a^b) // 0x95511759

	f1, f2 := 3.1415926, 2.7182818
	fmt.Printf("Floating point test: %.4f\n", f1*f2) // 8.5397
}
