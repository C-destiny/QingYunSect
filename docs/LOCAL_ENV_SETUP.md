# 本机开发环境配置说明

## 2026-10-22 双机通用Windows测试入口

以下旧章节记录单位电脑环境；E盘开发机仍使用`E:/Rgame/qingyun-sect`与`E:/Rgame/tools/godot-4.7.2/`。优先在仓库根目录通过PowerShell运行：

```powershell
.\tests\run_all_tests.ps1
# 自定义安装路径：
.\tests\run_all_tests.ps1 -Godot 'D:\Tools\Godot_v4.7.2-stable_win64_console.exe'
# 包含30分钟真实运行项：
.\tests\run_all_tests.ps1 -All
```

脚本自动识别仓库父目录下的tools或`C:/Tools/`引擎，也接受`GODOT_EXE`环境变量。日志写入被忽略的`builds/local-validation/`独立时间戳目录；测试隔离APPDATA/TEMP/TMP，普通单项超时60秒，真实长稳项2100秒。60项快速测试已在E盘开发机验证通过。失败返回1，成功返回0。旧Bash脚本保留了单位电脑绝对路径，不能直接用于E盘开发机。

配置日期：2026-10-19。本文件记录本机（家勋台式机）实际可用的环境与验证证据，供换机或重建时对照。

## 环境要求（来自项目文档）

依据 `README.md`「开发环境」与 `AGENTS.md`「验证和交付」：

| 项目 | 要求 |
|---|---|
| 引擎 | Godot 4.7.2 Standard（Windows x86_64） |
| 脚本 | GDScript |
| 渲染器 | GL Compatibility |
| 设计分辨率 | 1920×1080（窗口 1280×720） |
| 导出目标 | Windows Desktop x86_64，embed_pck=true，排除 tests/* |

不需要 .NET/Mono 版（C# 未使用），不需要 Android/iOS/Web 模板。

## 已安装组件

| 组件 | 路径 | 说明 |
|---|---|---|
| 引擎（图形版） | `C:\Tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe` | 日常编辑与运行 |
| 引擎（控制台版） | `C:\Tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe` | **跑测试必须用这个**，带日志输出 |
| 导出模板 | `C:\Users\72736\AppData\Roaming\Godot\export_templates\4.7.2.stable\` | 35 个模板，含 Windows x86_64 debug/release |

引擎版本实测：`4.7.2.stable.official.ed1daf0bf`，与 `docs/V0.3_ENGINEERING_AUDIT.md` 记录的原始开发机版本**完全一致**（同一构建号 ed1daf0bf）。

下载来源为 GitHub 官方 release，引擎包 SHA256已校验：
`731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953`（与官方 SHA512-SUMS 一致）。

## 路径迁移说明

原开发环境在 `E:\Rgame\`，本机**没有E 盘**，故重新安装：

| 原路径（E 盘） | 本机路径（C 盘） |
|---|---|
| `E:\Rgame\tools\godot-4.7.2\` | `C:\Tools\godot-4.7.2\` |
| `E:\Rgame\qingyun-sect\` | `C:\Users\72736\Documents\GitHub\QingYunSect\` |

`docs/V0.3_ENGINEERING_AUDIT.md` 中记录的绝对路径命令已失效，改用本文件下方相对路径写法。

## 常用命令

### 导入项目（首次或改动配置后）
```bash
"/c/Tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "C:/Users/72736/Documents/GitHub/QingYunSect" --import
```

### 跑全量回归测试
```bash
cd "C:/Users/72736/Documents/GitHub/QingYunSect" && bash tests/run_all_tests.sh
```
默认档跳过 `test_real_time_stability`（需真实运行 30 分钟）。要跑完整版：
```bash
bash tests/run_all_tests.sh --all
```
脚本对每个 `tests/test_*.gd` 做三重校验（退出码 0、日志含 PASS、无 SCRIPT ERROR/Parse Error/Assertion failed/CRASH），只满足退出码 0 不算通过 —— 这是 `AGENTS.md` 的明确要求。日志输出到 `tests/_logs/`。

注意：`test_real_time_stability` 内部设定`DURATION_SECONDS = 30 * 60`，靠 `create_timer` 真实等待30 分钟，中途只打印 `HEARTBEAT:` 每分钟一次，结束时才输出 `PASS:`。给它的时间窗口不足会导致无 PASS 文本而被判FAIL，这是超时不是失败。

单个测试：
```bash
"/c/Tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe" --headless \
  --path "C:/Users/72736/Documents/GitHub/QingYunSect" \
  --log-file "<项目>/tests/<名字>.log" --quit-after 200000 \
  -s res://tests/test_battle_system.gd
```
`--quit-after` 是帧数不是秒数。普通测试 3000 帧足够；长时测试需200000 帧以上。

### 导出 Windows 候选版
```bash
"/c/Tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe" --headless \
  --path "C:/Users/72736/Documents/GitHub/QingYunSect" \
  --export-release "Windows Desktop" "builds/QingYunSect-v0.4-rc-win64.exe"
```

### 可视化运行
双击 `C:\Tools\godot-4.7.2\Godot_v4.7.2-stable_win64.exe`，在项目管理器中导入
`C:\Users\72736\Documents\GitHub\QingYunSect\project.godot`，F5 运行。

## 注意事项

1. **测试必须用 console 版 exe**。非 console 版不带日志输出，无法做 AGENTS.md 要求的错误校验。
2. **测试会写 `user://` 存档**。项目测试已做隔离（用独立路径），但不要用发布包跑测试。
3. **不要提交 `.godot/` 和 `builds/`**，`.gitignore` 已覆盖。
4. **升级引擎前先备份**。Godot 升级可能改写 `project.godot` 格式和 `.uid` 文件；AGENTS.md 第10 条禁止擅自更改引擎主版本。
5. 导出模板体积约 1.2GB，若C 盘紧张可只保留 windows 相关的 12 个文件。
6. **强杀进程会产生误导性报错**。用 `timeout` 强杀 Godot 进程会刷出一堆
   `ERROR: BUG: Unreferenced static string to 0: ...` / `at: unref (core/string/string_name.cpp)` 清理噪音，
   这不是运行错误。验证干净退出请用 `--quit-after <帧数>` 让引擎自行退出。

## 本次配置验证结果（2026-10-19）

| 验证项 | 结果 |
|---|---|
| 引擎 `--version` | `4.7.2.stable.official.ed1daf0bf`，与原开发机一致 |
| 引擎包 SHA256 | 与官方 SHA512-SUMS 一致 |
| 项目导入 `--headless --import` | 退出码 0，无SCRIPT ERROR / Parse Error |
| 回归测试（22 项） | 21 PASS / 1 超时，详见下方说明 |
| Windows 导出（debug） | 成功，103MB 可执行文件 |
| 导出包独立运行 | 启动成功，`青云宗 V0.4 验收候选：自动战斗完善版启动成功`，OpenGL 3.3 / RTX 2060 |
| 导出包干净退出 | `--quit-after` 退出码 0，无错误 |
| 图形渲染 | 正常，Compatibility 渲染器按预期工作 |

关于 `test_real_time_stability`：该项设计为真实运行 30 分钟（`DURATION_SECONDS := 30 * 60`），
结束时才输出 `PASS:`。首次用默认档跑时被时间窗口截断，判为 FAIL，属于超时而非测试失败。
脚本已改为默认跳过、`--all` 参数下留足时间窗口执行。

## 换机重装清单

1. 下载 `Godot_v4.7.2-stable_win64.exe.zip`，解压到任意 tools 目录
2. 下载 `Godot_v4.7.2-stable_export_templates.tpz`，解压后把 `templates/` 内容放到 `%APPDATA%\Godot\export_templates\4.7.2.stable\`
3. 校验引擎 SHA256 = `731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953`
4. 跑一次 `--headless --import` 生成 `.godot` 缓存
5. 跑 `bash tests/run_all_tests.sh` 确认全绿
