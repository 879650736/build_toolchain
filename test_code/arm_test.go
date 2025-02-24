package main

import (
	"fmt"
	"runtime"
)

func main() {
	fmt.Println("=== Cross Compilation Test ===")
	fmt.Printf("CPU Architecture: %s\n", runtime.GOARCH)
	fmt.Printf("Operating System: %s\n", runtime.GOOS)
	
	// 测试ARM指令集特性
	var a, b uint32 = 0x12345678, 0x87654321
	fmt.Printf("ARM SWP operation test: 0x%x\n", a^b)
	
	// 测试硬件浮点运算（如果配置了hard-float）
	f1, f2 := 3.1415926, 2.7182818
	fmt.Printf("Floating point test: %.4f\n", f1*f2)
}
