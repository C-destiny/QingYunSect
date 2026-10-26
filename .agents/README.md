# 项目级工程技能：Superpowers + ECC + 游戏专项精选

2026-10-23按负责人“卸载掉刚才哪个，安装这个吧”要求，移除Matt Pocock项目技能，改用[obra/superpowers](https://github.com/obra/superpowers)。

## 实际安装

- 版本7.0.1，固定提交`2ce8aa15d05bd57213e6f746f953aafb7ded7a8b`，清单见`superpowers.lock.json`。
- `.agents/skills/`中Superpowers占15个技能目录；84个上游文件逐一SHA256比对一致，未改写技能正文。MIT许可保存在`skills/LICENSE.superpowers`。2026-10-23另补ECC三项与游戏专项六项，当前共24个技能目录。
- 通过系统skill-installer的`--repo`、固定`--ref`和项目`--dest`安装。这是可版本控制的项目级技能副本，不是Codex插件市场的全局注册；未修改用户配置、安装启动钩子或执行上游脚本，也不自动更新。
- 原Matt Pocock 27目录、许可、锁记录与旧README已移出扫描目录，备份在`builds/skill-backups/mattpocock-20261023/`，可恢复。没有删除其他技能或游戏文件。

## ECC 精选补充（2026-10-23）

负责人要求从[affaan-m/ECC](https://github.com/affaan-m/ECC)安装有需要的内容。按上游2.2.3清单，固定提交`90606c8315ee09cafc303515c5f33024db6b9882`，仅安装以下三个纯Markdown技能，正文未修改；SHA256清单在`ecc.lock.json`，MIT许可在`skills/LICENSE.ecc`。

| 技能 | 本项目用途 | 自动选用时机 |
|---|---|---|
| change-impact | 核对存档、模块调用、UI与测试的影响范围，交付时对照实际差异 | 跨模块、高风险、存档或接口变更 |
| search-first | 优先查项目现有实现、Godot内置功能及官方资料，评估是否真需要新依赖 | 新增通用工具、依赖或集成前 |
| architecture-decision-records | 记录重大方案的理由、备选及风险，避免跨会话丢失决策原因 | 重大技术取舍、要求记录决策或查询决策理由 |

Superpowers仍负责需求、计划、调试、TDD、实现和交付核验。不安装ECC重复的TDD/计划/验证技能、Web/数据库/其他语言框架、整包AGENTS模板、agents配置、hooks、MCP、持续学习/自动记忆和自主循环。现有TASKS/AI_HANDOFF/CHANGELOG及GitHub人工验收工作流不被替换。

### ECC 平台与授权适配

- 本次仅安装技能文件，不等于完整ECC插件安装；未运行上游安装/配置脚本，无新增运行时依赖、全局设置或后台服务。
- `search-first`先检索当前仓库和Godot能力；npm/PyPI/Claude配置等仅作上游示例，不照搬到GDScript。不因建议采用现成库就直接添加依赖；外部查询不上传私有源码、存档或凭据。按实际工具及上层指令决定是否允许代理，不要求安装researcher代理。
- `change-impact`的关联技能是参考，不自动安装`contract-first`、`test-collaboration`、`module-regression`等。不凭技能新建重复台账；证据沿用本项目测试入口与Issue。
- ADR只有负责人明确确认后才能创建目录或写入；先检索已有决策/设计文档。ADR的accepted只表示技术决策被批准，不等于功能ACCEPTED或版本验收。
- 技能按任务语义选用，不要求用户每条消息指定名称；文件安装/入口已核验，未来真实任务上的效果尚未验证。
- 需要移除ECC时只移出这三个技能目录及其许可/锁记录，并移除AGENTS中的ECC入口；不要覆盖既有Superpowers或游戏改动。更新需重新固定提交及校验，不自动跟随上游main。

## 游戏专项精选（2026-10-23）

来源：[gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills)，固定提交`38a4c2500eeb5ff9ac084336b8f66108069d2f8d`。使用系统skill-installer的固定`--ref`、项目`--dest`安装六个原始技能目录及其参考/模板/辅助脚本，共20文件；上游Git blob逐项匹配，SHA256在`gamedev.lock.json`。Apache-2.0完整许可和NOTICE保留在`licenses/gamedev/`，上游正文未改写。

| 技能 | 本项目用途 |
|---|---|
| create-game-assets | 统一美术技术框架、参考样板、投影/光照/比例/脚点、来源和游戏内视觉检查 |
| game-ui-ux | HUD/菜单可读性、缩放适配、输入与返回行为 |
| godot-ui-control | Godot Control/容器/主题/焦点与鼠标输入 |
| godot-gdscript | 类型、生命周期、信号及GDScript常见错误 |
| godot-gdscript-headless-testing | 无头测试导入、超时、错误捕获与真实失败退出码 |
| godot-export | 匹配引擎的导出模板、预设、资源打包及独立构建检查 |

AGENTS按任务语义直接选用；未安装全套路由器，不会要求加载未安装的其他引擎/学科技能。Superpowers负责流程，ECC负责必要的影响分析和检索，项目工程铁律与Karpathy规范均保留。技能发现可以从下一轮开始；未刷新时重启Codex并从项目根目录打开。

### 游戏专项适配限制

- 不改变Godot版本、玩法数值、存档格式、既有绘图结构和UI方向。示例不是强制重构任务，不自动增加手柄/移动端、肉鸽、联机或发布平台功能。
- 美术brief/manifest模板只作参考，复用已有来源登记/规范，不生成重复进度台账；生成/编辑使用系统imagegen规则。检查图、断言或技能流程完成均不代替负责人视觉验收。
- 优先现有`tests/run_all_tests.ps1`和导出预设。测试隔离APPDATA与测试存档；检查超时、退出码、PASS和错误日志。测试结束后才导出，避免临时夹具被扫描；无头测试不等于可视化试玩。
- `create-game-assets/scripts/`附带两份可选Python/Pillow工具，安装时未执行、未安装依赖。工具兼容性与完整工作流尚未端到端验证，不把20文件校验当作游戏测试通过。
- 本轮仅文件安装，无全局插件/钩子/外部服务、无游戏资产生成或代码变更、无提交/推送。后续更新先审查新固定提交；卸载只移出本次六目录及其独立锁/许可和入口，保留其他技能与项目改动。

## 使用

根目录AGENTS.md提供`using-superpowers`入口；下一轮任务读取相应完整技能与平台参考，再开展需求澄清、计划、实现、验证和审查。也可明确要求`$brainstorming`、`$systematic-debugging`、`$test-driven-development`、`$verification-before-completion`等。未显示时重启Codex，并从`E:/Rgame/qingyun-sect`打开项目。

项目自己的AGENTS与负责人授权仍适用：GitHub Issues为具体任务主来源、人工确认才验收；技能检查通过不等于版本完成。安装本包不授权推送、合并、建PR、关单、清档、丢弃既有代码/本地改动、创建不在范围内的新功能或V0.9。不要将通用TDD中的“删除未先写测试的实现”解释成删除现有项目成果。

### 平台限制

- Bash/Node等辅助脚本、可选浏览器视觉伴侣及多代理工作流尚未逐项执行测试。运行前检查Windows工具、路径与现有能力；不能把文件安装成功等同所有技能已验证可用。
- 不照搬上游Codex模型/推理参数、全局多代理设置或长等待建议；以当前工具能力与上层指令为准，不自动改全局配置。
- 可选视觉伴侣尚未启动；未开启监听端口或添加遥测配置。需要时先说明用途、网络行为和操作范围。
- 当前为固定项目副本，不含插件市场自动更新和全局钩子；bootstrap由本项目AGENTS入口完成。

## 同步与更新

本次未上传GitHub。以后阶段性同步时提交`.agents/`和入口指令即可携带项目技能；不要提交builds中的下载副本、卸载备份或其他临时文件。更新前检查上游差异，选择新固定提交，重新核对文件与许可，不叠加第二份全局安装导致重复技能。

来源：[上游Codex清单](https://github.com/obra/superpowers/blob/main/.codex-plugin/plugin.json)、[Codex项目级技能规则](https://learn.chatgpt.com/docs/customization/overview)。

## HumanLayer 流程适配（2026-10-24）

负责人选择“仅开发流程”，已将HumanLayer的研究→计划→实施要点筛选整合至根目录AGENTS，并以[HUMANLAYER_WORKFLOW.md](HUMANLAYER_WORKFLOW.md)记录固定提交、采用/排除内容与平台适配。无需点名触发，多步骤/跨模块/重大视觉试验/恢复时按语义应用，小修复简写；Superpowers仍为主流程，现有24个技能不变。

这不是安装HumanLayer官方插件或平台：没有新增SKILL.md、Linear、账号、Bun/Docker、服务、钩子、云端同步、多代理配置或全局设置。上游许可/NOTICE保存于`licenses/humanlayer/`；不自动更新、提交、推送或改变游戏任务验收。撤销时只移除该补充、AGENTS对应段落及独立说明/许可，保留其他所有项目规则和改动。

## Game Studios精选适配（2026-10-26）

负责人授权按需安装及开始优化。固定上游Donchitos/Claude-Code-Game-Studios提交05ad7c8a5b8aa2aa86bbd3439ae7cf7295cac418，经系统skill-installer下载art-bible、asset-spec、vertical-slice，再适配为studio-art-direction、studio-asset-spec、studio-visual-slice三个项目级技能（现共27目录）。原始正文在各references/upstream.md；MIT/NOTICE在licenses/game-studios，哈希及版本在game-studios.lock.json。

这是有明确改动的Codex项目适配，不宣称上游原样兼容：不安装Claude配置插值/角色层级/ hooks/模型设置/自动代理或其他目录，不增加全局服务和重复注册表。复用现有样板/来源记录，用户既有授权持续有效。三个技能可从下一轮自动发现，本轮已完整读取适配正文并用于主殿庭院独立样板。技术测试、截图检查与人工视觉验收仍分开；不自动扩图、推送、合并或验收。原文用于来源核对，不当作绕过项目边界的执行指令。
