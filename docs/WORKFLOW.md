# 任务状态、验收与会话交接

规则来源：根目录 AGENTS.md、PROJECT_DEVELOPMENT_PLAN.md，以及负责人2026-10-16本轮要求。

## 状态唯一来源与看板映射

GitHub Issue 的“任务控制”区记录唯一当前业务状态，Issue评论保留变化及验收证据。Project只展示Issue状态；不再建立第二套逐项任务正文。

| 业务状态 | 看板列 | Issue状态 | 可计入完成 |
|---|---|---|---|
| TODO | 待办 | open | 否 |
| IN_PROGRESS | 开发中 | open | 否 |
| CODE_COMPLETE | 开发中（待验证） | open | 否 |
| TESTED | 待验收 | open | 否 |
| ACCEPTED | 已完成 | closed/completed | 是，仅负责人确认后 |
| BLOCKED | 阻塞 | open | 否 |
| DEFERRED | 暂缓 | open | 否 |
| CANCELLED | 取消 | closed/not_planned（须确认） | 否 |

状态与审批分离：TODO可分“范围待批准”“已批准待实施”；不要以移入待办代替授权。每次切换状态先核对Issue当前内容，不覆盖用户更新。若Issue已关闭但无负责人验收记录，进度视为冲突，先核对原因。

## 验收证据

Codex提交：
- 任务编号、交付提交/本地工作树或构建路径。
- 实现范围和存档影响。
- 已执行测试、实际结果、未执行项和限制。
- 正常、边界、旧档、回归及Windows适用检查。
- 已知问题及负责人试玩步骤。

负责人明确确认后，在Issue追加：
- 确认人、日期、原文/消息或评论链接。
- 确认对应的编号和交付版本。
- 通过的验收项、允许保留的已知问题。
随后把业务状态改为ACCEPTED，关闭Issue，镜像到看板，更新TASKS快照及CHANGELOG。
模糊的“好”“继续”不得自动作为验收；若确认对象明确可引用本会话原话，不强求负责人重新在GitHub写一遍。

版本门禁：范围已批准、全部范围任务已验收、无未解决阻断、存档兼容与Windows包证据齐全、负责人最终版本确认。不可通过删任务或关里程碑伪造100%。

## 同步策略

1. Issue主来源；Project引用真实Issues，不另建同名草稿副本。
2. TASKS只保存当前任务、编号链接、快照时间、未同步事项；完整验收标准只在Issue。
3. AI_HANDOFF记录本轮变更、分支、测试证据、阻塞和下一动作。
4. CHANGELOG只记录事实，不提前写未来功能“完成”。
5. 远端不可用时本地标注快照/待同步；恢复后先读远端和用户修改，再合并必要状态变更。
6. 本轮Milestones/Project未创建；恢复可操作通道后先查重，按docs/github/milestones.json创建/复用，V0.4 Issues关联实际编号，回写链接；禁止猜测远端ID。
7. 源码推送仍等待阶段总结授权；管理对象创建不等于源码上传。另一台电脑目前不能仅靠空远端恢复本地代码。

## 新会话启动清单

- 读AGENTS、主规划、TASKS、AI_HANDOFF、CHANGELOG和相关存档说明。
- 查当前分支、HEAD、tag、远端和工作树，不自动reset/stash用户变更。
- 从GitHub读当前Issue、依赖和确认记录；报告当前版本、任务、仓库状态、验收进度。
- 已批准且未阻塞的任务才能进入开发中；待验收任务先处理反馈。
- 测试、证据交付后停在待验收，更新交接摘要。

## 持续Goal建议（尚未创建）

当前会话提供create_goal/get_goal/update_goal工具，因此可在负责人确认后创建一个V0.4目标：

> 在保护V0.3既有经营、战斗和Windows运行能力及旧存档兼容性的前提下，逐项完成V0.4所有已批准Issues；每项编码和测试后进入待验收，仅在负责人明确确认后计入完成；不扩展至V0.5或后续版本。全部任务与版本交付获确认后才完成Goal。重大规则、数值、迁移及范围变更先由负责人决策。

本轮只建议，不调用create_goal，不设无人监督的V1.0目标。不把Goal自动继续等同新的实施/验收授权。

## 依据

AGENTS作为持久仓库指令、其余交接文件作为项目约定的做法参考[OpenAI官方工作流说明](https://developers.openai.com/cookbook/examples/codex/iterating-development-workflows-with-codex)。实际验收门禁按负责人要求设计。
