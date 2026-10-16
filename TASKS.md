# 当前任务摘要

快照日期：2026-10-16。具体状态以[GitHub Issues](https://github.com/C-destiny/QingYunSect/issues)正文任务控制区及负责人确认记录为准。本文件不是第二份任务正文。

- 当前历史已完成版本：V0.4；负责人于2026-10-17明确确认整体验收完毕，QYS-V04-001～010均ACCEPTED。
- 目标版本：V0.5 离线收益与长期挂机，已批准开发。
- 当前任务：QYS-V05-001，时间基线、存档迁移与结算契约。
- V0.5批准范围共7项，完整流程和验收标准见docs/V0.5_DEVELOPMENT_PLAN.md；每项编码测试后仍须负责人验收。
- V0.6、V0.7获准按版本继续推进，但进入时仍需先拆分任务；V0.8调整为宗门挂机美术、UI与体验定稿，肉鸽从V0.9开始。

| 编号 / GitHub | 任务 | 优先级 | 本轮快照 |
|---|---|---|---|
| [QYS-V04-001](https://github.com/C-destiny/QingYunSect/issues/1) | V0.3工程核验与V0.4开发拆分 | P0 | 已验收（2026-10-16） |
| [QYS-V04-002](https://github.com/C-destiny/QingYunSect/issues/2) | 明确战斗公式与状态转换契约 | P0 | 已验收（2026-10-16） |
| [QYS-V04-003](https://github.com/C-destiny/QingYunSect/issues/3) | 统一队伍与岗位互斥及异常成员处理 | P0 | 已验收（2026-10-16） |
| [QYS-V04-004](https://github.com/C-destiny/QingYunSect/issues/4) | 统一战斗奖励入口与重复结算防护 | P0 | 已验收（2026-10-17） |
| [QYS-V04-005](https://github.com/C-destiny/QingYunSect/issues/5) | V0.3存档迁移与安全恢复 | P0 | 已验收（2026-10-17） |
| [QYS-V04-006](https://github.com/C-destiny/QingYunSect/issues/6) | 战斗界面与成员敌方关卡信息 | P1 | 已验收（2026-10-17） |
| [QYS-V04-007](https://github.com/C-destiny/QingYunSect/issues/7) | 结构化战斗日志与胜负奖励展示 | P1 | 已验收（2026-10-17） |
| [QYS-V04-008](https://github.com/C-destiny/QingYunSect/issues/8) | 战斗与宗门生产收益对照及数值确认 | P1 | 已验收（2026-10-17，保留现行数值） |
| [QYS-V04-009](https://github.com/C-destiny/QingYunSect/issues/9) | 长时间挂机及跨系统回归测试 | P0 | 已验收（2026-10-17） |
| [QYS-V04-010](https://github.com/C-destiny/QingYunSect/issues/10) | V0.4 Windows交付与负责人版本验收 | P0 | 已验收（2026-10-17） |

## 下一步

QYS-V05-001已编码并通过22组快速回归，等待负责人验收；验收后进入QYS-V05-002离线经营与灵谷分段计算。

| 编号 / GitHub | V0.5任务 | 优先级 | 本轮快照 |
|---|---|---|---|
| [QYS-V05-001](https://github.com/C-destiny/QingYunSect/issues/11) | 时间基线、存档迁移与结算契约 | P0 | 待验收 |
| [QYS-V05-002](https://github.com/C-destiny/QingYunSect/issues/12) | 离线经营与灵谷分段计算 | P0 | 待开发 |
| [QYS-V05-003](https://github.com/C-destiny/QingYunSect/issues/13) | 离线战斗解析模拟 | P0 | 待开发 |
| [QYS-V05-004](https://github.com/C-destiny/QingYunSect/issues/14) | 离线施工招募与修炼推进 | P1 | 待开发 |
| [QYS-V05-005](https://github.com/C-destiny/QingYunSect/issues/15) | 离线结算原子性与防重复领取 | P0 | 待开发 |
| [QYS-V05-006](https://github.com/C-destiny/QingYunSect/issues/16) | 离线收益明细界面 | P1 | 待开发 |
| [QYS-V05-007](https://github.com/C-destiny/QingYunSect/issues/17) | V0.5回归、长时与Windows交付 | P0 | 待开发 |

## 同步欠账

- V0.4的10个Issue已验收关闭；V0.5的7个Issue已创建并保持open，均未关联Milestone。
- 13个Milestone及“青云宗开发计划”Project未创建：连接器无相关接口、gh命令不存在、已登录浏览器读页面连续超时。
- 完整待创建数据：docs/github/milestones.json、docs/github/project.json；人类可读路线见docs/ROADMAP.md。
- 通道恢复后先查询已存在对象，避免重复创建；创建/复用后关联这10个Issue、回填真实URL。
- 2026-10-17已将 `docs/development-management` 推送至 `origin/docs/development-management`，包含V0.4候选源码、测试和文档；尚未合并main，也未上传Windows构建或创建完成标签。
