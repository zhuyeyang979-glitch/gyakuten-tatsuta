# 逆转辰田

Godot 4.6.2 制作的文字冒险辩论类游戏雏形。

当前版本聚焦“逆转裁判式”的交叉辩论循环：调查获得证物、追问陈述、选择证物指证矛盾、错误指证扣除信誉、正确信息推进剧情。

## 当前内容

- 第一回：主义主义与月末辩论
- 角色：辰田昇、未明子、AR精灵、意识形态课老师
- 证物：意识形态学讲义、辩论赛规则卡、历史影像片段、未明子的论点板书
- 核心主题：结果能否为手段辩护

## 运行

用 Godot 4.6.2 打开项目目录：

```powershell
E:\gyakuten-tatsuta
```

或用本机已安装的 Godot 控制台版本运行：

```powershell
& 'E:\New project\tools\godot-4.6.2\Godot_v4.6.2-stable_win64_console.exe' --path 'E:\gyakuten-tatsuta'
```

## 校验

```powershell
& 'E:\New project\tools\godot-4.6.2\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'E:\gyakuten-tatsuta' -s 'res://tests/validate_game_data.gd'
& 'E:\New project\tools\godot-4.6.2\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'E:\gyakuten-tatsuta' -s 'res://tests/smoke_main_scene.gd'
& 'E:\New project\tools\godot-4.6.2\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'E:\gyakuten-tatsuta' -s 'res://tests/simulate_game_flow.gd'
```

## 后续方向

- 增加保存/读档
- 扩展更多月末辩论章节
- 加入原创角色立绘、背景、音效
- 把剧情数据拆分为多案件文件
