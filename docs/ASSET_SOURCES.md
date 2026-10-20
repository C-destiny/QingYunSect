# 素材来源与许可记录

本文件记录V0.8起引入项目的视觉、字体和音频素材。未列入本表的外部素材不得进入发布包。

| 文件 | 类型 | 来源/生成方式 | 许可/使用范围 | 状态 |
|---|---|---|---|---|
| `docs/art/v08-main-screen-concept.png` | 概念图 | OpenAI内置图像生成工具；完整提示词见`docs/art/V08_CONCEPT_PROMPT.md` | 只保留构图与色彩参考；偏卡通细节已被正式半写实方向取代，不直接进入运行包 | 历史参考 |
| `assets/characters/cui_yunchuan_model.png` | 人物模型立绘 | OpenAI内置图像生成工具；两张负责人提供的本人照片作为身份参考，原图不入库；哈希与提示词见`assets/characters/README.md` | 《青云宗》项目人物视觉展示 | 已生成并通过资源测试，待V08-005验收 |
| `assets/characters/zhou_mo_model.png` | 人物模型立绘 | OpenAI内置图像生成工具；两张负责人提供的本人照片作为身份参考，原图不入库；哈希与提示词见`assets/characters/README.md` | 《青云宗》项目人物视觉展示 | 已生成并通过资源测试，待V08-005验收 |
| `assets/environment/sect_floating_mountain.png` | 宗门地图底图 | OpenAI内置图像生成工具；负责人提供样式图作为方向参考；哈希与提示词见`assets/environment/README.md` | 《青云宗》运行时地图 | 已接入并通过资源测试，待视觉验收 |
| `assets/environment/sect_landmarks_atlas.png` | 主殿与资源点透明图集 | OpenAI内置图像生成工具；负责人提供样式图作为方向参考；哈希与提示词见`assets/environment/README.md` | 《青云宗》运行时地图 | 已接入并通过透明通道测试，待视觉验收 |
| `assets/buildings/sect_buildings_atlas.png` | 七建筑透明图集 | OpenAI内置图像生成工具；负责人提供样式图作为方向参考；哈希与提示词见`assets/buildings/README.md` | 《青云宗》运行时建筑 | 已接入并通过透明通道测试，待视觉验收 |
| `assets/ui/qingyun_ui_icon_atlas.png` | 资源与功能导航透明图集 | OpenAI内置图像生成工具；负责人提供主界面截图作为风格参考；哈希与提示词见`assets/ui/README.md` | 《青云宗》运行时UI | 已接入顶部信息栏与底部导航，待视觉验收 |

## 2026-10-19 主殿场景样板审计材料

- docs/art/v08-scene-reference.png：负责人本轮提供，内部美术方向对照，SHA-256 CE90491E91F9BBF2E466BF1C46C7C0273DC869E6EB72E9111BA45DBBBABAA584；不是运行素材，不根据图中标注改变玩法、资源或地图。
- docs/art/v08-scene-baseline-normal.png、v08-scene-baseline-construction.png：本项目Godot/RTX 2060真实渲染截图，由tests/audit_v08_scene.gd生成，1280×720；仅审计与前后对照，不进入运行包。
- 本阶段未引入外部字体、音效或新AI位图资产。

## 2026-10-19 主殿样板运行资产

- assets/buildings/main-hall-sample.png：内置ImageGen按负责人视觉要求生成的独立透明建筑，1254×1254；项目主殿视觉用途，非背景或UI；来源、完整提示词及哈希见assets/buildings/MAIN_HALL_SAMPLE.md。
- docs/art/v08-scene-stage3-normal.png、v08-scene-stage3-neighbor-selected.png：Godot实际运行截图，分别普通模式与旧建筑选中透显，用于参考/基线对照，不进入运行包。
- 素材不携带可读文字、数值或存档规则；主殿仍只占(4,3)，没有将参考图布局转换为逻辑坐标。

## 2026-10-20 弟子居样板运行资产

- assets/buildings/disciple-quarters-sample.png：内置ImageGen文字规格生成的独立透明生活院落，1254×1254，完整提示词/哈希/用途见assets/buildings/DISCIPLE_QUARTERS_SAMPLE.md；本项目建筑视觉用途，不含文字、HUD、背景或新玩法。
- docs/art/v08-scene-stage4-quarters-{construction,lv1,lv3}.png：Godot真实截图，仅测试与视觉对照；(5,5)额外建筑与1000测试资源只存在于隔离合成夹具。
- 原建筑图集保留，其他六类尚未推广；样板未获负责人最终视觉验收。

## 2026-10-20 阶段5实际渲染记录

docs/art/v08-scene-stage5-normal.png、v08-scene-stage5-occupied.png由本项目Godot隔离图形夹具生成，用于内部开发前后对照，底层素材授权沿用本文件原记录；不是新生成概念图。其他24张运行截图位于忽略的builds/v08-scene-audit。

## 2026-10-20 阶段6运行截图

docs/art/v08-scene-stage6-normal.png、v08-scene-stage6-panel-build.png由本项目Godot隔离图形夹具生成，用于内部开发对照。底层素材沿用既有来源记录，本轮没有新素材或AI生成图。

## 2026-10-20 布局提案A示意图

docs/art/v08-layout-proposal-a.png：由tools/draw_layout_proposal.py自绘矢量地形/道路/界面并编排既有主殿、弟子居与七建筑图集，Edge本地渲染，用于布局讨论。既有建筑素材来源及使用条件沿用上文记录；本轮无新外部素材，无新AI图（ImageGen连接失败）。图并非运行截图，不是可直接切割接入的环境资产；地图尺寸与示例内容未接入游戏。

## 2026-10-20 主殿局部山石池水

assets/environment/hall-garden-pond.png：内置ImageGen生成，1619×971/1473569字节，SHA-256 5C3173E7823482F74FF87CDDBE874307EDE371121D39BF90CB5376941AB898BA；完整提示词与项目使用范围见assets/environment/HALL_GARDEN_POND.md。仅作地面装饰，不占地，不是资源点。未使用外部抓取图片、不宣称独占版权。docs/art/v08-hall-sample1-normal.png与v08-hall-sample1-card.png为隔离Godot实际运行截图，底层素材沿用项目来源记录，演示建筑不进入正式存档。

## 2026-10-20 全图推广建筑图集

assets/buildings/sect-buildings-unified.png：内置ImageGen生成，1536×1024，3×2等分的六类既有建筑，2836839字节；SHA-256 D971A224251FCBC23C341F8336795AFB3A739B32BDCB9D0234F32111539D2CCF。完整最终提示词、失败重试与项目使用记录见assets/buildings/UNIFIED_BUILDINGS.md；按工具适用条件用于本游戏，不宣称独占版权，无外部抓取素材。旧图集保留作历史来源，弟子居继续独立已验收样板。docs/art/v08-full2-*.png是Godot隔离演示实际运行截图，不是概念图。
