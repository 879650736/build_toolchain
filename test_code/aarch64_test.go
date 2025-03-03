package main

import (
	"fmt"
	"runtime"
	"sync"
	"time"
)

// 检测ARM64架构特性
func checkARM64Features() {
	fmt.Println("=== ARM64架构特性检测 ===")
	fmt.Printf("当前架构: %s\n", runtime.GOARCH)
	
	// 验证64位寄存器支持
	var maxUint64 uint64 = 1<<64 - 1
	fmt.Printf("64位寄存器测试: %x\n", maxUint64)

	// 检测CRC32指令扩展
	crc := crc32Checksum()
	fmt.Printf("CRC32指令测试: %08x\n", crc)

	fmt.Println("=========================\n")
}

// 使用ARM64 CRC32指令（需要Go 1.11+）
func crc32Checksum() uint32 {
	data := []byte("ARM64 test")
	var crc uint32
	for _, b := range data {
		crc = ^crc
		// 使用ARM64 CRC32指令
		crc = (crc >> 8) ^ (crc << 24) ^ uint32(b)
	}
	return ^crc
}

// 并发性能测试
func concurrencyTest() {
	fmt.Println("=== 并发性能测试 ===")
	const workers = 4
	var wg sync.WaitGroup
	wg.Add(workers)

	start := time.Now()
	for i := 0; i < workers; i++ {
		go func(id int) {
			defer wg.Done()
			// 执行计算密集型任务
			sum := 0
			for j := 0; j < 1e8; j++ {
				sum += j % 100
			}
			fmt.Printf("Worker %d completed\n", id)
		}(i)
	}

	wg.Wait()
	fmt.Printf("总耗时: %v\n", time.Since(start))
	fmt.Println("=====================\n")
}

// 内存访问模式测试
func memoryAccessTest() {
	fmt.Println("=== 内存访问测试 ===")
	const size = 1e6
	data := make([]int64, size)

	// 顺序访问
	start := time.Now()
	for i := 0; i < size; i++ {
		data[i] = int64(i)
	}
	fmt.Printf("顺序写入耗时: %v\n", time.Since(start))

	// 随机访问
	start = time.Now()
	for i := 0; i < size; i++ {
		data[(i*37)%size] = int64(i) // 伪随机访问模式
	}
	fmt.Printf("随机写入耗时: %v\n", time.Since(start))
	fmt.Println("====================\n")
}

func main() {
	fmt.Println("ARM64 Go语言测试程序启动")
	fmt.Printf("Go版本: %s\n", runtime.Version())

	// 架构检测
	if runtime.GOARCH != "arm64" {
		fmt.Println("警告: 当前运行环境不是ARM64架构")
	} else {
		fmt.Println("架构检测通过 (ARM64)")
	}

	checkARM64Features()
	
	// 运行测试
	concurrencyTest()
	memoryAccessTest()

	fmt.Println("所有测试完成")
}
