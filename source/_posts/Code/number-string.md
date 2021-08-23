---
title: 'c++: 数字和字符串的转换'
katex: true
typora-copy-images-to: ..\..\img\
date: 2021-08-22 16:42:46
updated: 2021-08-22 16:42:46
tags: 
	- c++
	- string
categories: Code
---



<!-- more -->

---

用户在键盘中输入数字时，数字以字符串的形式输入，在C++中通过流运算符`>>`来读取，在存储到变量前，运算符会根据需要对字符串进行类型转换。同样在输出时由流运算符`<<`执行，将不同类型的变量转化为字符串的形式进行输出。

下面介绍两种数字与字符串之间的转换方法：

- 字符串流对象
- to_string()
- stoX()



## 字符串流对象

c++中的`ostringstream`和`istringstream`，可以用来对内存中的值执行数字和字符串之间的转换。

`ostringstream`类是`ostream`的子类，和`cout`一样使用`<<`将数字转化为字符串，和`cout`不同的是，`ostringstream`将数据写入字符串对象中，而不是屏幕或文件中。

`istringstream`类是从`istream`派生出来的，内部包含一个字符串对象作为为输入流，使用`>>`从输入流中读取，并转化为对应的数字。

| 成员函数                | 描述                                               |
| ----------------------- | -------------------------------------------------- |
| istringstream(string s) | `istringstream`的构造函数                          |
| ostringstream(string s) | `ostringstream`的构造函数                          |
| string str()            | 返回`ostringstream`和`istringstream`中的字符串对象 |
| void str(string &s)     | 设置`ostringstream`和`istringstream`中的字符串对象 |

```cpp
#include <iostream>
#include <string>
#include <sstream>
using namespace std;

int main() {

  string str = "sanzo 100 80";
  istringstream istr(str);
  ostringstream ostr;


  string name;
  int score1, score2, avg_score;

  // read from istr
  istr >> name >> score1 >> score2;
  ostr << name << " " << score1 << " " << score2 << endl;

  // compute avg_score and write to ostr;
  avg_score = (score1 + score2) / 2;
  ostr << name << " has average score " << avg_score << endl;

  // switch to hexadeximal output on ostr
  ostr << hex;
  ostr << name << " has average score " << avg_score << endl;

  // extract the string from ostr
  cout << ostr.str();

  return 0;
}

/*
sanzo 100 80
sanzo has average score 90
sanzo has average score 5a
*/
```



## to_string

C++提供`string to_string(T value)`函数，将T类型转化为字符串格式，只支持10进制数字。

```cpp
int a = 10;
float b = 10.1;
double c = 10.2;

cout << to_string(a) << endl; // 10
cout << to_string(b) << endl; // 10.100000
cout << to_string(c) << endl; // 10.200000
```



## stoX

字符串到数字的转换可以通过`stoX()`函数执行，支持int、long、float、double。

```cpp
int stoi(const string& str, size_t* pos = 0, int base = 10)
long stol(const string& str, size_t* pos = 0, int base = 10)
long long stoll(const string& str, size_t* pos = 0, int base = 10)
float stof(const string& str, size_t* pos = 0)
double stod(const string& str, size_t* pos = 0)
```

其中`str`为需要转换的字符串，`pos`保存`str`无法转化的第一个字符索引，`base`指定转化的进制。

```cpp
#include <iostream>
#include <string>
using namespace std;

int main() {

  string str = "-3.1415s";
  size_t pos;

  int i = stoi(str, &pos);
  cout << i << " " << pos << endl; // -3 2

  double d = stod(str, &pos);
  cout << d << " " << pos << endl; // -3.1415 7

  str = "1001b";
  i = stoi(str, &pos, 2);
  cout << i << " " << pos << endl; // 9 4

  return 0;
}
```





<!-- Q.E.D. -->

