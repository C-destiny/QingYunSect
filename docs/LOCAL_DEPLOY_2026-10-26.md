# 2026-10-26 本机部署核验

负责人要求将另一台电脑上传的项目部署到本机。本轮仅同步、构建和验证，不开发新视觉方案，不推进验收。

## 同步基线

- 仓库：https://github.com/C-destiny/QingYunSect 。远端默认分支仍为 `docs/development-management`；当前游戏进展在 `feature/v0.8-visual-polish`。
- 本地原先为 `5e325bf`，工作区干净；获取远端后确认落后5个提交，通过仅快进同步到 `142f94a`。没有切换、重置、合并默认分支或覆盖本地改动。
- #37/#38正文与评论已读取：当前候选24，open/TESTED、待负责人验收；V0.7为最近已验收版本。主殿＋庭院独立实机样板尚未实现，本轮不开始该任务。

## 本机结果

- 引擎：`C:/Tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe`，实际版本 `4.7.2.stable.official.ed1daf0bf`；匹配的Windows x86_64模板已存在，无需安装依赖。
- 首次受限环境导入出现编辑器Safe save权限错误；在具备所需权限的环境中重新导入后退出0，最终日志无错误。未关闭安全保存功能或修改游戏配置。最终证据：`builds/local-validation/deploy26-import-final.*`。
- 原有快速测试入口运行：68项PASS、0失败、无超时，退出0，包含旧档、恢复与8小时模拟。日志：`builds/local-validation/20261026-103317/`。30分钟真实稳定性测试按默认配置跳过。
- 使用既有GPU审图脚本运行1280×720、1920×1080，共16张实际截图与1张局部对照。退出0、PASS、无错误；局部变化1625/1630个采样点，区域外采样变化0，状态前后相同。已查看1280全景与1920卡片截图；自动渲染不等于真人鼠标试玩或审美验收。证据：`builds/local-validation/deploy26-gpu.*`、`builds/v08-scene-audit/material24-*.png`。
- Windows串行导出成功，退出0、日志无错误；随后普通、付费施工演示、七院落展示、自由建造备份四个入口均以图形模式独立启动并正常退出，无错误，两个演示日志包含 `formal save not loaded`。每个入口使用独立APPDATA。日志：`builds/local-validation/deploy26-export.*`、`builds/local-validation/deploy26-smoke/`。
- 正式 `savegame.json*` 文件部署前后名称、长度及SHA256比较一致；无游戏代码、素材、配置、数值或存档格式改动。

## 打开游戏

- 普通游戏：`builds/QingYunSect-v0.8-material24-win64.exe`，正常使用本机原有存档。
- 完工全景展示：根目录 `Run-Courtyard-Preview.cmd`。
- 付费施工演示：根目录 `Run-Construction-Test.cmd`。
- 后两项为已有隔离演示，不读取正式玩家存档。本机已重建两启动器所需的EXE，无需调整启动器。

包大小：159684512字节；SHA256：`3E82F19A06F0BF2A81E713F62F90755FB07E60FECB9EE6E934C78529573664F8`。这是本机构建，不以另一电脑旧包哈希为一致性要求。

## 限制与交接

没有运行真人鼠标试玩、联机或30分钟真实稳定性测试。候选24仍有材质、透视与融合差距，本次部署不改善或验收这些问题。没有修改Issue/Project状态、推送源码、发布构建或进入V0.9；构建、缓存、日志与存档仍不入库。仅补充本机部署文档及TASKS/AI_HANDOFF/CHANGELOG摘要。
