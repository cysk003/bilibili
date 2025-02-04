### Bash 命令行编辑(emacs 模式)
#### 默认：set -o emacs
#### set -o vi 切换为 vi 模式
#### 配置文件：~/.inputrc
#### Shell 操作
 - Ctr-c: 退出当前命令
 - Ctr-z: 当前进程放后台, fg %1, 可以放到前台, jobs 可以查看任务
 - Ctr-d：退出 Shell，相当于敲 exit
#### 控制屏显
 - Ctr-l: 清屏
 - Ctr-s: 暂停屏幕输出
 - Ctr-q: 继续屏幕输出
#### 移动
 - Ctr-a: 移动到行首
 - Ctr-e: 移动到行尾
 - Ctr-f: 前进一个字符 
 - Ctr-b: 后退一个字符
 - Alt-f: 前进一个单词
 - Alt-b: 后退一个单词
 - Ctrl-xx: 行首到当前光标之间切换
#### 历史搜索
 - Ctr-p: 上一条命令历史
 - Ctr-n: 下一条命令历史
 - Alt-<: 命令历史的第一行
 - Alt->: 命令历史的最后一行
 - Ctr-r: 向前搜索
 - Ctr-s: 向前搜索
 - Ctr-0: 运行搜索结果的命令, Ctr-g: 离开搜索界面，不自行命令
 - !!: 重复上次命令
 - !n: 重复命令历史里的第 n 个命令
 - !n:m: 重复命令历史的 n:m 个命令
 - !n:$: 重复第n 个命令到最后一个
 - !n:p: 显示第n 个命令到最后
 - !string 显示 string 开头的命令
 - !:q: 引用上次命令
 - !$: 上个命令的最后一个参数 
 - !*: 上个命令的所有参数
 - \^abc\^def: 运行上个命令，把 abc 替换为 def
#### 自动补全
 - Tab: 补全
 - Esc-Tab: 从上一条命令补全
 - Alt-?: 列出可选的补全
 - Alt-/: 尝试文件名补全
 - Alt-~: 尝试用户名补全
 - Alt-$: 尝试变量名补全
 - Alt-@: 尝试主机名补全
 - Alt-!: 尝试命令补全
 - Ctr-x /:	列出可补全的文件名
 - Ctr-x ~: 列出可补全的用户名替换
 - Ctr-x $: 列出可补全的变量名替换
 - Ctr-x @: 列出可补全的主机名替换
 - Ctr-x !: 列出可补全的命令替换
#### 编辑
 - Ctr-d 或者 Del: 删除当前光标的字符
 - Ctr-q 或者 Ctr-v: 引用式插入
 - Alt-Ctr-i: 插入 tab 键，等于提示命令 
 - Ctr-t: 交换字母位置
 - Alt-t: 交换单词位置
 - Alt-u: 整个单词都大写
 - Alt-l: 整个单词都小写
 - Alt-c: 大写单词首字母
 - Ctr-k: 删除到行尾,送到剪贴板
 - Ctr-u: 从行首删除到当前位置,送到剪贴板
 - Alt-d: 删除当前光标的单词
 - Alt-Del 或者 Esc-Ctr-h: 向前删除一个单词
 - Ctr-w: 剪切光标前的单词
 - Alt-\: 删除当前光标上的空格
 - Ctr-y: 粘贴文本
 - Alt-y: 粘贴文本
 - Ctr-h: 删除光标前的字符(回退键)
 - Alt-d: 向后删除一个单词
 - Esc-t: 交换光标前两个单词的位置
 - Ctr-_ 或者 Ctr-x Ctr-u: Undo 上次交换(Terminal 下是缩小字体，无法使用)
 - Alt-r: 取消修改(rollback)
 - Ctr-e: 切换为 emacs 模式
 - Alt-Ctr-j: 切换为 vi 模式

##### Ref: [Cheetsheets](books/readline-emacs-editing-mode-cheat-sheet.pdf)
