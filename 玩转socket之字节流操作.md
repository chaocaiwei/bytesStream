#### 玩转socket之字节流操作--拼包、拆包
我们开发中用得最多的HTTP协议及超文本传输协议，是一种基于TCP/IP的文本传输协议。基本很少碰到字节流操作。

但是我过我们要用socket，实现一套基本TCP/IP协议的自定义协议，那么，对于字节流的操作，数据包的拼接、拆解，是绕不开的。

本文的所有示例代码在[这里][https://github.com/chaocaiwei/bytesStream]

##### 字节流的表示方式
###### NSData、Data
在iOS，对于字节流，大多数情况下我们要打交道的是`NSData`类型数据。在swift中它叫`Data`

###### 字节数组

在OC中它可以表示为`Byte`类型的数组

```
Byte bytes[256];
```
`Byte`等同于`UInt8`及`unsigned char`

```
typedef UInt8            Byte;
typedef unsigned char    UInt8;
```
与NSData相互转换：

```
// bytes转Data
Byte bytes[256] = {0xff,0xaa,0x33,0xe4};
NSData *data = [[NSData alloc] initWithBytes:bytes length:256];

// Data转Bytes
const Byte *nBytes = [data bytes];
// 或者
Byte byte[4] = {0};
[cdata getBytes:byte length:4];
```

swift中，没有`Byte`类型，他叫`[UInt8]`。转化为`Data`时

```
var bytes : [UInt8] = [0x22,0xef,0xee,0xb3]
let data = Data(bytes)
```
`Data`转`UInt8`时，没有像OC一样的`bytes `方法

我们也可以跟OC中类似的方法

```
var nBytes = [UInt8]()
data.copyBytes(to:&nBytes, count:4)
```
当然，最简单的方式是这样

```
let bytes = [UInt8](data)
```
如果你喜欢，也可以这样

```
let bytes : [UInt8] = data0.withUnsafeBytes({$0.map({$0})})
```

###### 十六进制字符串
我们都知道，计算机存储和传输的数据都是二进制的。而二进制不易与阅读。当我们要查看字节流进行调试时，往往会将其转化为16进制的字符串。

OC的`NSData`对象打印默认得到的是带*<*、*>*及空格的十六进制字符串。如果想让其根容易阅读些，可以在NSData的category中增添：

```
- (NSString *)hexString
{
    NSMutableString *mstr = [NSMutableString new];
    const Byte *bytes = [self bytes];
    for (int i = 0; i < self.length; i++) {
        [mstr appendFormat:@"0x%02x ",bytes[i]];
    }
    return mstr;
}
```
swift中的Data只能打印出有多少个字节。需要一个生成十六进制串的方法：

```
extension UInt8 {
    var hexString : String {
        let str = String(format:"0x%02x",self)
        return str
    }
}

extension Data {
    var bytes : [UInt8] {
        return [UInt8](self)
    }
    var hexString : String {
        var str = ""
        for byte in self.bytes {
            str += byte.hexString
            str += " "
        }
        return str
    }
}
```
##### 字节序
在进行字节流的拼接和解析之前，我们必须先了解网络传输中，一个关键的概念`字节序`

###### 什么叫字节序
当一个整数的值大于255时，必须用多个字节表示。那么就产生一个问题，这些字节是从左到右还是从右到左称为字节顺序。

###### 大端字节序Vs小端字节序
如果我们有一个16进制值0x0025，那么它包含两个字节0x00、0x25。在传输时，我们期望的是，在字节流中，先看到0x00而0x25紧随其后。
 
如果是`大端字节序`，一切将会是我们预期的。
 但是如果是`小端字节序`，我们看到的是将是0x25、0x00。

在网络传输时，TCP/IP中规定必须采用`网络字节顺`，也就是`大端字节序`。

而不同的CPU和操作系统下的`主机字节序`是不同的。

###### 我们用的是什么字节序
我们用简单代码测试一下。

```
int16_t i = 0x0025;
NSData *data = [[NSData alloc] initWithBytes:&i length:2];
NSLog(@"%@",[data hexString]);

// 输出：0x25 0x00
```
swift中

```
var value : UInt16 = 0x0025
let data = Data(bytes:&value, count:2)
print([UInt8](data))
// 输出：0x25 0x00
```

根据简单的测试。很显然，我们用的是`小端字节序`
###### 如何转换
我们的主机字节序与网络字节序是不一致。那么，在字节流的编码和解码过程中，就需要进行字节序的转化。

swift中所有整形，都有`bigEndian`属性，可以很容易进行大小端字节序之间的转化

```
let v : UInt32 = 78
let bv = v.bigEndian
```
OC中，将转化方法分为两种，主机序转大字节序、大字节序转主机序。其实只用其中之一就可以了。因为两种方法实现都是一样，都是字节序的反转。但为了代码可读性，可以在编码和解析时候区分一下，使用不同方法。

```
// 大端字节序转主机字节序（小端字节序）
uint16_t CFSwapInt16BigToHost(uint16_t arg)
uint32_t CFSwapInt32BigToHost(uint32_t arg)

// 大端字节序转主机字节序（小端字节序）
uint16_t CFSwapInt16HostToBig(uint16_t arg)
uint32_t CFSwapInt32HostToBig(uint32_t arg)
```
###### double需不需要处理
swift中只对所用整形类型提供转化方法，对于浮点型却没有。那么如果碰到浮点数，我们需要如果处理呢。

一般而言，编译器是按照IEEE标准对浮点型解释的。只要编译器是支持IEEE浮点标准的，就不需要考虑字节顺序。而目前主流编译器都是支持IEEE的。

所以浮点型不用考虑字节序问题

##### 编码方式(拼包)
编码方式即，我们根据事先约定好的格式，从低位到高位，依次拼接相应数据类型及字节长度的数据。最终形成数据包。

下面我们来看一下，针对不同的数据类型的处理方式

###### 整型
OC中拼接方式很简单，只要注意大端字节序的转化就行了。

```
// 以整形初始化
int a = -25;
int biga = CFSwapInt32HostToBig(a);
NSMutableData *data = [[NSMutableData alloc] initWithBytes:&biga length:sizeof(biga)];
    
// 整形的拼接
uint16_t b = 8;
uint16_t bigb = CFSwapInt16HostToBig(b);
[data appendBytes:&bigb length:sizeof(bigb)];

```
需要补充一点：OC中`int`固定占4个字节32位；`NSInteger`与swift中`Int`类型一样，根据不同的平台会差生差异。目前iOS都是64位系统，他们都占8个字节64位相当于`int64_t`或`Int64`。所以上述代码中`int`类型的`a`用`CFSwapInt32HostToBig()`转化

如果你喜欢byte数组，也可以。

```
uint32_t value = 0x1234;
Byte byteData[4] = {0};
byteData[0] =(Byte)((value & 0xFF000000)>>24);
byteData[1] =(Byte)((value & 0x00FF0000)>>16);
byteData[2] =(Byte)((value & 0x0000FF00)>>8);
byteData[3] =(Byte)((value & 0x000000FF));

// 输出 byteData：0x00 0x00 0x12 0x34
```

swift当中

```
var a = 3.bigEndian
var b  = UInt16(23).bigEndian
var data = Data(bytes:&a, count:a.bitWidth/8)
let bpoint = UnsafeBufferPointer(start:&b, count:1)
data.append(bpoint)
```
我们也可以转化为UIn8字节数组

```
extension FixedWidthInteger {
    var bytes : [UInt8] {
        let size = MemoryLayout<Self>.size
        if size == 1 {
            return [UInt8(self)]
        }
        var bytes = [UInt8]()
        for i in 0..<size {
            let distance = (size - 1 - i) * 8;
            let sub  = self >> distance
            let value = UInt8(sub & 0xff)
            bytes.append(value)
        }
        return bytes
    }
}
```
如此得到的字节数组本身就是大端字节序，我们可以直接这样用

```
let c : Int8 = 6
let d : UInt16 = 0x1234
var abytes = c.bytes
abytes += d.bytes
let data0 = Data(abytes)
```

###### 浮点型

浮点型的编码方式与整型相似，只是少了大字节序的转化过程。但是上述转成字节数组的方式只适用于整型，对于浮点型并不奏效。

而在swift中，转化字节数组，对于任意类型都有效的方式：

```
func toByteArray<T>(value: T) -> [UInt8] {
    var value = value
    let bytes = withUnsafeBytes(of: &value,{$0.map({$0})})
    return bytes
}
```
虽然上述方法是范型的，理论上任意类型都可以调用。但准确来说上述方法，只适用于整型与浮点型。

###### 字符串

通常我们使用和传输的字符串都是utf-8编码的。

字符串转NSData很简单。

```
NSString *str = @"temp";
NSData *datas = [str dataUsingEncoding:NSUTF8StringEncoding];
```

swift中类似的

```
var data = "buf".data(using:.utf8)
```


###### 字符串转字节数组
如果我们要使用字节数组，我们往往会将字符串转化为c字符串。因为c字符串本身就是字符数组，而每个字符正好是一个字节。

```
NSString *string = @"一个字符串";
Byte *cbytes = (Byte *)[string cStringUsingEncoding:NSUTF8StringEncoding];
```
需要注意的是，这样转化之后我们并不知道字节数组的长度，它与`NSString`的`length`截然不同。需要根据字符串末尾的`\0`标识符来确定

```
int ci = 0;
while (*(cbytes+ci) != '\0') {
    ci++;
}

NSLog(@"string.length=%lu cstring.lenth=%d",(unsigned long)string.length,ci);
// 输出：string.length=5 cstring.lenth=15
```
如果在swift中这要做：

```
var sarr  = "一个字符串".cString(using:.utf8)
```
可以直接得到`[CChar]`即`[Int8]`，并且可以直接得到数组长度。但是要注意的是，swift是强类型，离我们的`[UInt8]`还差一步。注意如果`CChar`是负数及首位上是1，直接转化成`UInt8`直接抛出异常。

但我们可以先去掉首位，等转化完成再加上

```
extension String {
    var bytes : [UInt8] {
       var bytes = self.cString(using:.utf8)?.map({ char -> UInt8 in
            if char < 0 {
                let b = char & 0b01111111
                let c = UInt8(b) | 0b10000000
                return c
            }else{
                return UInt8(char)
            }
        })
        bytes = bytes?.dropLast()
        return bytes ?? [UInt8]()
    }
}
```
需要注意的是，转成`[CChar]`之后，其末尾的`\0`	也会带上。这里我们同意把它去掉

###### 字节数组如何拼接
貌似漏了字符数组的拼接方式。下面我们来看看

先说swift，基于之前定义的扩展方法，它拼接起来很简单

```
var mbytes = [UInt8]()
mbytes += 5.bytes
mbytes += toByteArray(value:3.14)
mbytes += "a string".bytes
let mdata = Data(mbytes)
```

###### 数据包中添加字符串
需要注意的是，如果我们在二进制数据包中加入字符串，那么必须指定字符串的长度。要么在字符串之前添加指定长度的字段，要么指定字符串的固定最大长度。不然将会对数据的解析造成困扰。

##### 解码的方式（拆包）
###### 用OC实现
```
int16_t ri;
UInt8   rj;
double  rk;
[data0 getBytes:&ri range:NSMakeRange(0,2)];
int16_t rri = CFSwapInt16BigToHost(ri);
[data0 getBytes:&rj range:NSMakeRange(2,1)];
[data0 getBytes:&rk range:NSMakeRange(3,8)];
NSData *rsData = [data0 subdataWithRange:NSMakeRange(8,8)];
NSString *rs = [[NSString alloc] initWithData:rsData encoding:NSUTF8StringEncoding];
```
###### 用swift实现
基于`字节数组如何拼接`一节中的swift代码片段中的`mdata`。在swift中可以这样拆包、解析：

```
let mi : Int   =  mdata[0..<8].withUnsafeBytes {$0.pointee}
let rmi : Int = mi.bigEndian
let md : Double = mdata[8..<16].withUnsafeBytes {$0.pointee}
let ms  = String(data:mdata[16..<mdata.count], encoding:.utf8)
```

###### 碰到的坑
但是`Data`的下列方法在swift5中废弃了。

```
public func withUnsafeBytes<ResultType, ContentType>(_ body: (UnsafePointer<ContentType>) throws -> ResultType) rethrows -> ResultType
```
换成了同名但参数类型变化了的函数

```
 @inlinable public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R
```

直接影响是用旧方法时，无法联想出`pointee `属性，每次都得手敲。

那么，我们就换新方法试一下

```
let mi0 = mdata[0..<8].withUnsafeBytes {  $0.load(as:Int.self) }
let rmi0 = mi0.bigEndian
let md0 = mdata[8..<16].withUnsafeBytes {  $0.load(as: Double.self) }
let ms0 = String(data:mdata[16..<mdata.count], encoding:.utf8)
```

一切看起来都很正常。但是如果我们在要处理的数据最前面加上一个`UInt`类型。依次方法解析，在获取第二个变量时，会抛出

```
Fatal error: load from misaligned raw pointer
```
搜索一番后，在[stack overflow](https://stackoverflow.com/questions/50272004/without-debug-mode-unsafepointer-withmemoryrebound-will-gives-wrong-value/50275140#50275140)。得到的结果是除非支持[unaligned loads](https://github.com/apple/swift-evolution/blob/master/proposals/0107-unsaferawpointer.md#future-improvements-and-planned-additive-api)，不然还是用`[UInt8]`吧

> By loading individual UInt8 values instead and performing bit shifting, we can avoid such alignment issues (however if/when UnsafeMutableRawPointer supports unaligned loads, this will no longer be an issue).

然后看到这个[答案](https://stackoverflow.com/questions/55378409/swift-5-0-withunsafebytes-is-deprecated-use-withunsafebytesr)，知道原来它需要内存像C语言结构体那样的对界方式，如果你取UInt32需要按4的倍数取，如果你取Int需要按8的倍数取

然而，我们通过`subscript`得到了新的`Data`肯定是对齐的啊。

有可能通过`subscript`获取到的`Data`和原始数据共享的相同内存。那么我们创建新的对象试试：

```
let mdata1 = Data(mdata[1..<9])
let mi0 = mdata1.withUnsafeBytes {$0.load(as:UInt64.self)}
```
果然跟我们想的一样，这回跑起来一起正常。

###### 用字节数组实现
我们还是以先以swift为例

```
let bytes = [UInt8](mdata)
let ma : UInt8 = bytes[0]
let mb = bytes[1..<9].enumerated().reduce(0, { (result, arg) -> Int in
    let (offset, item) = arg
    let size = MemoryLayout<Int>.size
    let biteOffset = (size - offset - 1) * 8
    let temp =  Int(item) << biteOffset
    return result | temp
})
```
对于double类型，我们没办法进行位运算。聪明的你如果想通过Int进行位运算再转化为double，但是就是在转成`Dobule`那一步一切将前功尽弃。原因很简单，double遵循IEEE浮点标准，跟整型的编码方式不一样，在做类型转化时，所有已经排好的字节将会按新规则重新生成。

还是像当初将double转成字节数组一样

```
func byteArrayToType<T>(_ value:[UInt8]) -> T
{
    return value.withUnsafeBytes({$0.load(as:T.self)})
}
```
使用时

```
let mc : Double = byteArrayToType(bytes[9..<17].map({$0}))
```
###### 用c指针实现
如果你对C指针很熟悉的话，自然会这样做：

```
const void *bytes = [data0 bytes];
int16_t ci = *(int16_t*)(bytes);
uint8_t cj = *(uint8_t*)(bytes+2);
double  ck = *(double*)(bytes+3);
char *cstr = (char *)(bytes+11);
NSString *nstr = [NSString stringWithCString:cstr encoding:NSUTF8StringEncoding];
```

##### C结构体的传输
当我们的服务器是C/C++时，那么我们在数据传递时，有一种更为高效的方式，直接传递结构体。

为了有效传输和解析，需要保证

- 结构体的大小必须是固定的。这就意味着我们在传递字符串或者数组时，必须定义其大小
- 接受与发送端结构体定义必须一致。就是说，其一变量的顺序一致；其二结构体的字节对齐方式一致，都是自然对界（按结构体的成员中size最大的成员对齐）或者`#pragma pack (n)`申明一致

如何满足上述两个条件。我们可以很容易的完成数据包的生成及拆解。

数据包的生成：

```
struct Message msg = {};
msg.type = 1;
msg.seq  = 0x0102;
msg.timeTemp = CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970;
memcpy(msg.content,cstr,16);

void *sent = &msg;
int length = sizeof(struct Message);
NSData *cdata = [[NSData alloc] initWithBytes:&sent length:length];
```
拆解：

```
const void *rec = [cdata bytes];
struct Message nmsg = *(struct Message *)rec;
```



##### 参考资料

- [HTTP协议、文本协议与二进制协议](https://www.yuque.com/u37594/amnhaq/uvzp8n)
- [How to teach endian](https://blog.erratasec.com/2016/11/how-to-teach-endian.html#.XOjKCdMzaXR)
- [浮点数/float/double 是否需要考虑网络字节序的问题](https://blog.csdn.net/learnhard/article/details/5696167)
- [结构体传输 & TCP粘包处理](https://blog.csdn.net/rock_joker/article/details/60885270)
- [struct用法及其构建网络传输报文](https://blog.csdn.net/Watson2016/article/details/53673113)
- [How to convert a double into a byte array in swift](https://stackoverflow.com/questions/26953591/how-to-convert-a-double-into-a-byte-array-in-swift)
