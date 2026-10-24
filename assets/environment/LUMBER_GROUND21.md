# 伐木场地面校准候选21

2026-10-23，负责人要求再次修改建筑台基与背景地块朝向冲突。本轮只处理伐木场，不将其他候选记为验收。

- 文件：`assets/environment/sect_lumber_clear21.png`，1672×941，3586704字节。
- SHA256：`C0DF3E4CCCDE6BA04FC20A6A09E10CE1E19723088353C0A1DF096018A987063A`。
- 来源：内置ImageGen，编辑目标为项目既有`sect_garden_scene17.png`；按工具适用条件用于本项目，非外部抓取素材，不宣称独占版权或三维模型。
- 原始输出：`C:/Users/72736/.codex/generated_images/01a142b2-f60d-7421-8760-8fc6289a81ab/exec-201698f9-97c3-421a-b1c4-c68abbc8722a.png`。原样复制，保留原缓存，未重新编码/压缩图片。
- 运行时仅采用参考图坐标Rect(360,285,300,160)的羽化窗口，不把整张生成图替换全场景；主殿、弟子居仍沿用候选19，其他区域原图保持。
- 复用既有`sect_limestone_paving.png`俯视材质，由Godot映射小院平面；其原来源见`assets/environment/TERRAIN_LAYERS.md`。本轮未重画该材质，也未重画建筑图集。
- 建筑不透明台基手工读点：左(199,575)、前(530,743)、右(870,575)，地面两轴斜率约+0.50755/-0.49412。不是对整栋精灵旋转，也不是承诺整张背景共用精确相机。
- 验收状态：TESTED，待负责人判断原生尺寸的透视、石材比例与草地过渡。仅局部样板，不推广其余建筑。

## 完整提示词

Use case: precise-object-edit. Asset type: existing game environment underlay. Image 1 is the EDIT TARGET, an existing 1672x941 Chinese xianxia garden scene. Preserve exact framing, canvas size, lighting, every other courtyard, mountains, trees, pond, stairs and paths. Change ONLY the empty rectangular paved courtyard at approximately x380..635, y302..428 (the second empty courtyard down on the LEFT, directly below the upper-left empty courtyard and left of the central path). REMOVE that courtyard's geometric rectangular stone border and its directional paving seams. Replace its interior and narrow border with unobtrusive irregular grass, fine gravel and subtly mottled beige earth, blending naturally into existing verge, no geometric frame or marked building pad, no large rocks or vegetation taller than grass inside this cleared spot. Keep surrounding connecting paths, lanterns and all other landmarks. No buildings, people, text, UI, labels or new decorations. Purpose: engine will lay a small precisely projected stone yard in this ONE cleared area; don't draw any new rectangular plot or directional grid there. Soft warm upper-left daylight unchanged. Output same landscape composition and exact1672x941 if possible.
