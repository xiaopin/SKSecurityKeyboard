# SKSecurityKeyboard

iOS 安全键盘

## 特性

- 支持多种数字键盘类型(纯数字、带小数点、身份证、随机等)
- 完美支持长按删除功能
- 支持按键音效果

## 用法

- 将 `SKSecurityKeyboard` 文件夹拖入项目
- 设置 UITextField/UITextView 的 `enabledSecurityKeyboard` 属性为 `YES` 即可

## 演示 & 效果图

![GIF](./Screenshot/demo.gif)

![](./Screenshot/number.png)

![](./Screenshot/digit-random.png)

![](./Screenshot/idcard.png)

## TODO

- 横竖屏适配待完善
- 按键的底部阴影效果(使其看起来更加像系统键盘)
- 删除按钮的特殊音效

## 关于按键音的说明

现在按键音功能已经采用 [`UIInputViewAudioFeedback`](https://developer.apple.com/library/archive/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/InputViews/InputViews.html) 协议方案替换原来的 [`AudioServicesPlaySystemSound`](http://iphonedevwiki.net/index.php/AudioServices) 方案。

前者能够完美兼顾系统的设置，需要满足：

- 打开 `系统设置 -- 声音与触感 -- 按键音` 选项
- 关闭静音模式

才能有声音输出，而 AudioServicesPlaySystemSound 方案不受系统设置的影响，既然是键盘，那还是和系统保持一致吧 :)

> 开启/关闭 按键音功能后，需要重启应用才能更新效果。

## License

基于MIT License进行开源，详细内容请参阅 `LICENSE` 文件。