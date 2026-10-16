# 当前任务摘要

快照日期：2026-10-16。具体状态以[GitHub Issues](https://github.com/C-destiny/QingYunSect/issues)正文任务控制区及负责人确认记录为准。本文件不是第二份任务正文。

- 当前历史已完成版本：V0.3（1567995 / v0.3.0）；V0.1、V0.2、V0.3依负责人本轮明确要求归档已完成。
- 目标版本：V0.4 战斗系统完善与经营联动，状态：规划中。
- 当前任务：QYS-V04-005，V0.3存档迁移与安全恢复已编码并通过测试，等待负责人验收；GitHub里程碑/看板创建仍受工具阻塞。
- 本轮授权：负责人已明确验收QYS-V04-004并要求进行下一步开发；QYS-V04-005获准实施。
- V0.4批准范围共10项（含核验和版本交付），当前ACCEPTED为4/10；其余任务不能提前计入完成。
- V0.5～V1.0仅路线和里程碑草案，未创建细碎任务。

| 编号 / GitHub | 任务 | 优先级 | 本轮快照 |
|---|---|---|---|
| [QYS-V04-001](https://github.com/C-destiny/QingYunSect/issues/1) | V0.3工程核验与V0.4开发拆分 | P0 | 已验收（2026-10-16） |
| [QYS-V04-002](https://github.com/C-destiny/QingYunSect/issues/2) | 明确战斗公式与状态转换契约 | P0 | 已验收（2026-10-16） |
| [QYS-V04-003](https://github.com/C-destiny/QingYunSect/issues/3) | 统一队伍与岗位互斥及异常成员处理 | P0 | 已验收（2026-10-16） |
| [QYS-V04-004](https://github.com/C-destiny/QingYunSect/issues/4) | 统一战斗奖励入口与重复结算防护 | P0 | 已验收（2026-10-17） |
| [QYS-V04-005](https://github.com/C-destiny/QingYunSect/issues/5) | V0.3存档迁移与安全恢复 | P0 | 待验收（17组回归通过） |
| [QYS-V04-006](https://github.com/C-destiny/QingYunSect/issues/6) | 战斗界面与成员敌方关卡信息 | P1 | 待办（范围待批准） |
| [QYS-V04-007](https://github.com/C-destiny/QingYunSect/issues/7) | 结构化战斗日志与胜负奖励展示 | P1 | 待办（范围待批准） |
| [QYS-V04-008](https://github.com/C-destiny/QingYunSect/issues/8) | 战斗与宗门生产收益对照及数值确认 | P1 | 待办（范围待批准） |
| [QYS-V04-009](https://github.com/C-destiny/QingYunSect/issues/9) | 长时间挂机及跨系统回归测试 | P0 | 待办（范围待批准） |
| [QYS-V04-010](https://github.com/C-destiny/QingYunSect/issues/10) | V0.4 Windows交付与负责人版本验收 | P0 | 待办（范围待批准） |

## 下一步

负责人验收QYS-V04-005后将其标记已完成，再按依赖进入QYS-V04-006。
本次对V0.4范围的确认不等于验收后续任务；每项编码测试后仍单独进入待验收。

## 同步欠账

- 10个真实Issue已创建、保持open；全部未关联Milestone。
- 13个Milestone及“青云宗开发计划”Project未创建：连接器无相关接口、gh命令不存在、已登录浏览器读页面连续超时。
- 完整待创建数据：docs/github/milestones.json、docs/github/project.json；人类可读路线见docs/ROADMAP.md。
- 通道恢复后先查询已存在对象，避免重复创建；创建/复用后关联这10个Issue、回填真实URL。
- 游戏代码与本轮文档尚未推送远端；不把远端管理对象当作双机源码已同步。
