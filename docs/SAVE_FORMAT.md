# 当前存档事实与迁移边界

兼容基线：V0.3 / 1567995；当前实现包含V0.4、V0.5向后兼容字段与V0.6角色装备迁移契约。

## 实际格式

scripts/core/save_manager.gd使用JSON，当前SAVE_VERSION=2，同时接受version=1迁移；主路径user://savegame.json，临时文件追加.tmp，备份追加.bak。未启用自定义user目录；按当前Windows Godot应用名通常映射到%APPDATA%/Godot/app_userdata/青云宗/savegame.json。测试仅使用res://tests下的隔离路径，不打开玩家正式存档。

外层：version、saved_at_unix、game_state。游戏版本号不等于存档格式版本；V0.6当前写入version=2。V0.5起，成功读取后以实际读取文件的saved_at_unix生成最多8小时的离线窗口；缺失时间戳的更早有效存档仍可读取，但首次不追溯收益。

game_state由GameState.export_save_data导出：

- resources（wood、spirit_stone、food）。
- total_disciples、assignments、production_progress。
- buildings、next_building_id；建筑含instance_id、type、cell_x/y、remaining、build_time、completed、level、upgrading及升级时的target_level、upgrade_remaining/time。
- recruitment_remaining、food_consumption_progress。
- training_disciples、cultivation_points。
- disciples（id、name、realm_level、cultivation、job）、next_disciple_id、sect_level。
- V0.6：弟子新增profession（sword/mage）与equipment（weapon/armor/ring对应装备实例ID）；根状态新增equipment_inventory和next_equipment_instance_id。
- battle_party、selected_battle_stage、highest_unlocked_stage、highest_cleared_stage、battle_victories。
- battle_encounter_sequence、active_battle_encounter_id、last_settled_battle_encounter_id（QYS-V04-004新增；用于结算幂等）。
- battle_running、auto_battle_enabled、battle_player_hp/max_hp、battle_enemy_hp/max_hp、battle_round_progress、battle_restart_cooldown、battle_message。
- battle_round_number、battle_log、last_battle_result（QYS-V04-007新增；分别保存独立回合计数、最多30条结构化事件及上一场胜负奖励摘要）。

## 当前兼容实现

load_game接受version=1和2；version=1通过默认值迁移，旧聚合弟子数据可生成个人记录；version=2必须包含角色装备结构。
岗位计数由个人记录重算，battle_party另外恢复。QYS-V04-003 起：字段存在时必须与 combat 岗位集合完全一致；字段缺失时仍从 combat 岗位构建，以兼容旧档。格式字段和 SAVE_VERSION 均未改变。
QYS-V04-004新增三个可选场次跟踪字段但仍保持SAVE_VERSION=1：V0.3缺字段存档在战斗中读取时生成有效场次号，非战斗状态保持零；新字段部分缺失或编号关系无效时拒绝读取。详细语义见BATTLE_REWARD_SETTLEMENT.md。
QYS-V04-005起，读档先保存内存快照；任一字段校验失败会用快照完整回滚，避免部分字段污染当前游戏。资源容器、数组/字典容器、队伍和战斗状态矛盾均显式拒绝。
QYS-V04-007新增的日志字段均为可选字段：V0.3存档缺失时使用0、空日志和空结果；新版本读取日志时限制为最近30条，防止日志随挂机无限增长。
QYS-V06-001将外层存档版本提升到2，同时显式接受version=1。旧弟子按稳定ID补齐剑修/法修职业和三个空装备槽，旧档补齐空库存及下一装备实例ID。version=2严格校验职业、实例ID、部位、品质、属性容器和穿戴唯一性；同一实例不得被多人或多个部位引用。
保存先写.tmp并重新解析、校验完整游戏状态；校验成功后保留上一份有效主档为.bak，再以同目录重命名替换主档。替换失败时尝试由备份恢复。主档不存在或损坏时可读取.bak，并明确显示“从备份读取”，不会静默覆盖主档。

## 失败与恢复语义

- 主档有效：读取主档。
- 主档损坏且备份有效：读取备份并向界面报告，不自动覆盖损坏主档。
- 主档和备份均无效：读取失败，当前内存状态保持不变。
- 保存临时写入、校验、备份或替换任一步失败：返回失败并保留可恢复的旧主档/备份；不能显示“已保存”。
- V0.3战斗中、胜利等待、停止状态分别迁移；结算ID缺失时按BATTLE_REWARD_SETTLEMENT.md生成默认值。

专项测试使用res://tests下的合成存档，覆盖往返、V0.3三类战斗状态、较早聚合弟子数据、损坏JSON、错误容器、无效队伍、矛盾战斗状态、重复读取、临时文件清理与备份恢复，不覆盖user://savegame.json。
