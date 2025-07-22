# Godot Deepseek 代码补全插件


## 环境
Godot 4.4 环境

## 获得项目
``` bash
# 克隆项目
git clone https://github.com/925236118/godot_deepseek_completions.git

# 获取最新
git pull
```

## 使用方法
- 克隆本项目后，可以直接使用godot打开作为示例项目，或将addon中的插件复制到自己项目下的addon文件夹下
- 在代码编辑器中，使用快捷键`ctrl + I`，即可唤醒补全插件，插件会自动获取上文并发起请求
- 代码生成后，点击插入可以将代码插入到光标位置

## Deepseek API key
- 目前项目中带有一个可使用的key，**不定期失效**
- 如果需要替换自己的deepseek api key，则可以打开`res://addons/deepseek_completions/deepseek_chat.tscn`文件，在检查器中填写自己的key并重新加载插件。
- 后续可能会在设置页面中修改本字段

## Prompt
- 项目中内置了提示词，如需替换则可以打开`res://addons/deepseek_completions/deepseek_chat.tscn`文件，在检查器中填写Prompt。并重启插件。

## 作者
[陌上竹](https://925236118.github.io/)
