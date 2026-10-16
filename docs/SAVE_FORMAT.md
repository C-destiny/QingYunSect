# 当前存档事实与迁移边界

核验基线：V0.3 / 1567995；本轮不变更格式。

## 实际格式

scripts/core/save_manager.gd使用JSON，SAVE_VERSION=1，路径user://savegame.json。未启用自定义user目录；按当前Windows Godot应用名通常映射到%APPDATA%/Godot/app_userdata/青云宗/savegame.json，具体路径需由引擎globalize_path核实，本轮未打开玩家存档。

外层：version、saved_at_unix、game_state。游戏V0.3不等于存档版本3；V0.1～V0.3仍沿用version=1。时间戳目前只记录，不产生离线收益。

game_state由GameState.export_save_data导出：

- resources（wood、spirit_stone、food）。
- total_disciples、assignments、production_progress。
- buildings、next_building_id；建筑含instance_id、type、cell_x/y、remaining、build_time、completed、level、upgrading及升级时的target_level、upgrade_remaining/time。
- recruitment_remaining、food_consumption_progress。
- training_disciples、cultivation_points。
- disciples（id、name、realm_level、cultivation、job）、next_disciple_id、sect_level。
- battle_party、selected_battle_stage、highest_unlocked_stage、highest_cleared_stage、battle_victories。
- battle_running、auto_battle_enabled、battle_player_hp/max_hp、battle_enemy_hp/max_hp、battle_round_progress、battle_restart_cooldown、battle_message。

## 当前兼容实现

load_game仅接受version=1；import_save_data使用默认值填充，旧聚合弟子数据可生成个人记录。该方式不是显式版本迁移链。
岗位计数由个人记录重算，battle_party另外恢复。QYS-V04-003 起：字段存在时必须与 combat 岗位集合完全一致；字段缺失时仍从 combat 岗位构建，以兼容旧档。格式字段和 SAVE_VERSION 均未改变。
写入直接FileAccess.WRITE目标文件后flush，未见备份或临时文件原子替换。
加载逐字段直接修改运行对象，后续失败不回滚（已复现）。

## V0.4必要工作

Issue #5先提交方案：旧档字段映射、默认值、状态一致性校验、失败不修改当前状态、安全保存和备份；与#4的战斗结算标识同步设计。
测试覆盖战斗中/胜利等待/停止、合法旧档、损坏及类型异常、重复读取、失败写入。只能用合成夹具及隔离路径；保留原始旧档以证明迁移，不用新版重写后冒充旧档。
本轮test_save_manager使用res://tests/.test_savegame.json，诊断主场景使用不存在的res://tests/.audit_v03_unused.json，均不覆盖玩家正式存档。
