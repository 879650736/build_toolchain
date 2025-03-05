#include <stdio.h>

// 计算两个数的和
int add(int a, int b) {
    return a + b;
}

// 测试结构体
struct Point {
    int x;
    int y;
};

int main() {
    // 基本功能测试
    printf("C Test Program\n");
    printf("Sum of 3 + 5 = %d\n", add(3, 5));

    // 结构体测试
    struct Point p = {2, 8};
    printf("Point coordinates: (%d, %d)\n", p.x, p.y);

    // 数组测试
    int arr[3] = {10, 20, 30};
    printf("Array elements: %d, %d, %d\n", arr[0], arr[1], arr[2]);

    return 0;
}
