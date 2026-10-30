# 当前存档事实与迁移边界

2026-10-28 P3过渡：负责人暂缓核心身份/晋升/单独招募，先用现有免费普通弟子。无新增身份、赠送标记或存档字段，仍version3；新档沿用3人、旧档保留原人数。养成界面保存失败用完整导出快照回滚岗位/境界/装备和旧队伍。

2026-10-28核心玩法P1/P2：普通模式恢复自由建造，沿旧建筑ID/逻辑坐标显示；P1已由负责人验收。P2新增的资源收支、粮食维持时间、缺口估算和发展建议均为只读派生数据，不写入JSON、不新增领取标记；旧发展奖励ID、顺序和version3不变。核心弟子与主动副本尚未接入，后续如新增身份/物品再单独制定迁移。

2026-10-22候选17：fixed_sect_layout的foot/width/resource_points是背景像素显示配置，按新园林重校准；不写回建筑cell_x/y、ID、等级或数量。无新存档字段，无版本升级，version3及旧档兼容逻辑不变。普通固定院落仍付费计时，七院落展示仍在独立演示档中运行。

V0.8固定院落候选11（2026-10-21）：负责人批准普通显示改固定院落，原cell_x/y仍仅作逻辑存储，不改写旧实例。一个院落展示该类所有实例，保留逐项管理/升级/收益；不合并或删除数据。新建设扫描TerritoryCatalog已有已解锁空格，调用原start_construction付费计时，保存失败恢复操作前完整状态。SAVE_VERSION仍3，无新增字段；正式普通模式不免费生成七建筑。自由建造备份通过--legacy-free-build启用。--fixed-layout-demo和--fixed-layout-showcase在首次读档前切换user://v08_fixed_layout_demo.json，停用自动存档；前者空院落付费试玩，后者只在演示内扣原成本并推进完工。测试与截图不读取正式savegame.json。

V0.8局部融合候选7：台基/道路接缝/前景栏杆均为渲染数据，不占地、不新增持久化字段。仅显式--courtyard-demo在首次读档检查前设置user://v08_courtyard_visual_demo.json并预置1栋侧翼，普通入口不调用演示布置。玩家原ID、格坐标、等级、资源和进度保持，version3兼容契约不变。

V0.8开阔台地候选6追加：sect_scene_layout只改变逻辑投影到画面的位置和间距，不写回building.cell_x/y。12×8、104×52逻辑契约、主殿(4,3)、旧建筑身份/等级/数值及SAVE_VERSION=3保持；普通读档不执行新演示摆位，无迁移/重置。--full-scene-demo仍只使用独立演示路径。

兼容基线：V0.3 / 1567995；当前实现包含V0.4、V0.5向后兼容字段、V0.6角色装备及V0.7领地迁移契约。

## 实际格式

scripts/core/save_manager.gd使用JSON，当前SAVE_VERSION=3，同时接受version=1、2迁移；主路径user://savegame.json，临时文件追加.tmp，备份追加.bak。未启用自定义user目录；按当前Windows Godot应用名通常映射到%APPDATA%/Godot/app_userdata/青云宗/savegame.json。测试仅使用res://tests下的隔离路径，不打开玩家正式存档。

外层：version、saved_at_unix、game_state。游戏版本号不等于存档格式版本；V0.7当前写入version=3。V0.5起，成功读取后以实际读取文件的saved_at_unix生成最多8小时的离线窗口；缺失时间戳的更早有效存档仍可读取，但首次不追溯收益。

game_state由GameState.export_save_data导出：

- resources（wood、spirit_stone、food）。
- total_disciples、assignments、production_progress。
- buildings、next_building_id；建筑含instance_id、type、cell_x/y、remaining、build_time、completed、level、upgrading及升级时的target_level、upgrade_remaining/time。
- recruitment_remaining、food_consumption_progress。
- training_disciples、cultivation_points。
- disciples（id、name、realm_level、cultivation、job）、next_disciple_id、sect_level。
- V0.6：弟子新增profession（sword/mage）与equipment（weapon/armor/ring对应装备实例ID）；根状态新增equipment_inventory和next_equipment_instance_id。
- V0.7：根状态新增unlocked_regions（按core、east、south顺序的永久解锁区域ID）与equipment_crafts_completed（非负打造完成次数）。
- V0.7发展目标：claimed_development_goals按目录顺序保存已领取目标ID；早期version 3存档缺失该字段时迁移为空列表。
- battle_party、selected_battle_stage、highest_unlocked_stage、highest_cleared_stage、battle_victories。
- battle_encounter_sequence、active_battle_encounter_id、last_settled_battle_encounter_id（QYS-V04-004新增；用于结算幂等）。
- battle_running、auto_battle_enabled、battle_player_hp/max_hp、battle_enemy_hp/max_hp、battle_round_progress、battle_restart_cooldown、battle_message。
- battle_round_number、battle_log、last_battle_result（QYS-V04-007新增；分别保存独立回合计数、最多30条结构化事件及上一场胜负奖励摘要）。

## 当前兼容实现

load_game接受version=1、2和3；version=1通过默认值迁移，旧聚合弟子数据可生成个人记录；version=2必须包含角色装备结构；version=3还必须包含领地与打造计数字段。
岗位计数由个人记录重算，battle_party另外恢复。QYS-V04-003 起：字段存在时必须与 combat 岗位集合完全一致；字段缺失时仍从 combat 岗位构建，以兼容旧档。格式字段和 SAVE_VERSION 均未改变。
QYS-V04-004新增三个可选场次跟踪字段但仍保持SAVE_VERSION=1：V0.3缺字段存档在战斗中读取时生成有效场次号，非战斗状态保持零；新字段部分缺失或编号关系无效时拒绝读取。详细语义见BATTLE_REWARD_SETTLEMENT.md。
QYS-V04-005起，读档先保存内存快照；任一字段校验失败会用快照完整回滚，避免部分字段污染当前游戏。资源容器、数组/字典容器、队伍和战斗状态矛盾均显式拒绝。
QYS-V04-007新增的日志字段均为可选字段：V0.3存档缺失时使用0、空日志和空结果；新版本读取日志时限制为最近30条，防止日志随挂机无限增长。
QYS-V06-001将外层存档版本提升到2，同时显式接受version=1。旧弟子按稳定ID补齐剑修/法修职业和三个空装备槽，旧档补齐空库存及下一装备实例ID。version=2严格校验职业、实例ID、部位、品质、属性容器和穿戴唯一性；同一实例不得被多人或多个部位引用。
QYS-V06-003起，装备实例必须匹配equipment_catalog中的固定模板、部位、品质和确定属性；库存上限60件。任意属性篡改、未知模板或超量库存都会使读档失败并回滚。
QYS-V07-002将外层存档版本提升到3。version 1、2默认只解锁core原8×6区域，打造次数为0；所有原建筑坐标、角色装备、队伍和离线状态保持原值。version 3严格校验区域ID唯一性、core必有、east/south依赖顺序、12×8边界、建筑只能位于已解锁区，以及打造次数非负。未知/重复/缺依赖区域、锁定区建筑、越界或重叠建筑会使读档失败并回滚。
QYS-V07-004～005在version 3既有契约内增加artifact_forge、scripture_library两种合法建筑type，并正式使用equipment_crafts_completed记录成功打造次数。装备实例仍由equipment_inventory和next_equipment_instance_id保存；保存失败时打造界面恢复完整GameState快照，不留下装备、扣款或实例ID缺口。
QYS-V07-007在version 3内增加可选claimed_development_goals字段；只接受目录前缀顺序且不允许未知、跳序或重复ID。目标领取与保存失败时完整回滚，避免重复奖励。为兼容QYS-V07-002～005期间已生成的version 3存档，字段缺失按未领取处理。
保存先写.tmp并重新解析、校验完整游戏状态；校验成功后保留上一份有效主档为.bak，再以同目录重命名替换主档。替换失败时尝试由备份恢复。主档不存在或损坏时可读取.bak，并明确显示“从备份读取”，不会静默覆盖主档。

## 失败与恢复语义

- 主档有效：读取主档。
- 主档损坏且备份有效：读取备份并向界面报告，不自动覆盖损坏主档。
- 主档和备份均无效：读取失败，当前内存状态保持不变。
- 保存临时写入、校验、备份或替换任一步失败：返回失败并保留可恢复的旧主档/备份；不能显示“已保存”。
- V0.3战斗中、胜利等待、停止状态分别迁移；结算ID缺失时按BATTLE_REWARD_SETTLEMENT.md生成默认值。

专项测试使用res://tests下的合成存档，覆盖往返、V0.3三类战斗状态、较早聚合弟子数据、损坏JSON、错误容器、无效队伍、矛盾战斗状态、重复读取、临时文件清理与备份恢复，不覆盖user://savegame.json。

## V0.8视觉整改局部样板

候选10：前侧岩岸只向逻辑矩形外侧扩出，外扩装饰不增加可建格；草地/铺装/道路/松石均为渲染数据，不改占地、区域规则或version3。铺装跟随既有脚点并裁剪，道路/园林相交时让位，不迁移玩家建筑。test_terrain_nature.gd验证查询前后状态一致、外扩和裁剪、道路连接/施工避让，基准测试扩到五阶段1920次输入映射。

候选9：ground_frame、terrain_detail_stage和visual_plane_lift均为渲染状态；可建区域默认零标高，外沿台阶不增加逻辑格或占地。test_terrain_baseline.gd验证两种纯视觉标高、四阶段输入映射及查询前后原状态一致。没有新增持久化字段或迁移，原建筑ID/类型/位置/等级/资源保持。

2026-10-21地基整改候选8：--courtyard-demo沿用独立user://v08_courtyard_visual_demo.json，仅该入口启用新连续地形；地面/外缘/装饰开关为运行时状态，不增加version3字段、不改变旧档身份/坐标/等级/资源。test_courtyard_fusion.gd检查渲染前后状态不变与隔离存档往返；普通和全图入口未推广新地形。

投影/边界推导/建筑卡/池水均不增加存档字段，version 3及旧建筑身份/位置保持。仅显式--visual-sample参数会在首次has_save前切换到user://v08_hall_visual_demo.json，预置2栋演示建筑且不读正式savegame.json；普通启动不添加示例。后续真正扩区仍须对区域ID、解锁默认值与旧档校验另作兼容验证，本轮没有放宽未知区域拒绝规则。

V0.8全图推广：--full-scene-demo使用独立user://v08_full_visual_demo.json，七类建筑预置只用于演示；普通启动不调用visual_demo.populate_full_scene。贴图/脚点/影子/预览/景观让位均为渲染状态，不进入version 3字段；七类完整状态往返与原身份/坐标由test_full_scene_visuals.gd验证。

P4试炼仅有运行时状态与入场属性副本；不新增字段、不改变version3。入场先保存，失败不进入；退出恢复宗门进程，不发奖励。

P5局内等级/经验/强化/首领/胜败均仅运行时状态，不写version3；重试新建模拟，无永久奖励。

## P6存档与恢复契约（2026-10-28）

当前写入version4，支持1/2/3/4读取。4必须有dungeon_progress；旧1～3缺失时默认sequence/settled/wins/pending_weapon=0、active为空。账本中的编号/数量/引用有严格校验，无效时整体回滚。active持久化出战弟子ID、击杀检查点、有效战斗时间，不记录完整敌人和局内强化，启动后按失败恢复已确认收益。

旧包无法读取version4；回退须用迁移前备份与旧包，不能把version数字改成3。副本开始/检查点/结算/领取装备均经过原临时文件验证和备份替换。保存失败恢复操作前全状态，不把未保存胜利恢复为通关。正常暂停不会积累生产；应用退出后沿既有最多8小时宗门离线规则，主动副本绝不离线胜利。崩溃丢失的运行时宗门进度按上次保存时钟重算，不重复已保存收益。

2026-10-29最新：SAVE_VERSION=5，SUPPORTED_SAVE_VERSIONS为1、2、3、4、5。根game_state新增medicine={stock:0..20整数,remaining:0..60有限秒数}，库存20时不可有在制订单。旧1～4缺失默认空；新5必须包含字段。禁止非法值并完整回滚。前文version3/4均为历史记录，回退使用相应旧备份及保留构建。


## 2026-10-30 修炼丹已验收，P7永久功法候选

负责人确认上一批修炼丹验收并授权继续。两门试制功法各20灵石，在已建藏经阁学习，每人单槽运转，统一进入战斗属性；学习/切换保存失败回滚。存档6读取旧1～5，旧档功法为空。新功法待验收，未进入P8，不将旧原型局内强化当永久学习。详情docs/CORE_P7_TECHNIQUES.md，未提交推送，GitHub P7搜索为空、远端未同步。

techniques={弟子ID字符串:{learned:[合法唯一功法ID],active:空字符串或已学功法ID}}。新6强制字段；旧1～5缺省空。v5起medicine强制字段的规则继续生效。
