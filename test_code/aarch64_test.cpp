#include <iostream>
#include <vector>
using namespace std;

// 简单的类示例
class Calculator {
public:
    int multiply(int a, int b) {
        return a * b;
    }
};

int main() {
    // 基本输出测试
    cout << "C++ Test Program" << endl;

    // 类方法测试
    Calculator calc;
    cout << "Product of 4 * 6 = " << calc.multiply(4, 6) << endl;

    // 容器测试
    vector<string> languages = {"C++", "Python", "Java"};
    cout << "Languages: ";
    for (const auto& lang : languages) {
        cout << lang << " ";
    }
    cout << endl;

    // 现代C++特性测试（C++11及以上）
    auto result = [](int a, int b) { return a - b; };
    cout << "10 - 7 = " << result(10, 7) << endl;

    return 0;
}
