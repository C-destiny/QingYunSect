# 全院落地面融合试稿22 — 来源与制作记录

2026-10-23，负责人明确“试一下全部建筑”，授权将伐木场试做方向推广到主殿和全部七功能院落，不是整版验收。

- 最终素材：`assets/environment/sect_sites_clear22.png`，1672×941，3325298字节；SHA256 `15B356411B959E619B34D147049D5EE2F154B345A7CE1CAD4645E87449F82A96`。
- 工具：内置ImageGen，非CLI/API回退、非Python改图。生成PNG原样复制，没有本地重编码，原缓存保留；按工具适用条件用于本项目，不宣称独占版权，不是3D模型。
- 输入为项目已有`sect_lumber_clear21.png`，来源沿用LUMBER_GROUND21.md。首轮清除其他七处地块框/纹样，实机发现主殿背景楼梯和建筑自身台阶冲突，第二轮只清掉背景楼梯并以自然石径衔接。
- 原始生成目录：`C:/Users/72736/.codex/generated_images/01a142b2-f60d-7421-8760-8fc6289a81ab/`；首轮`exec-abb07b8c-987b-4652-8acd-6d9f623f171b.png`，最终`exec-8e9c2c88-c076-4115-9ac8-06bd87898172.png`。
- 引擎仅从最终图取`Planar.ALL_CLEAR_WINDOWS`七个羽化窗口，伐木场沿用21；不是整张生成图替换所有风景。窗口内的草地、石径、景观细节可能随生成变化，未宣称窗口内非地块逐像素锁定。
- 六处石材院坪复用俯视纹理`sect_limestone_paving.png`（来源TERRAIN_LAYERS.md），按各自台基参考线映射；演武场保留精灵自带圆台，不叠矩形；灵田保留自然土草地，不铺石板。
- 仅Godot运行时做材质映射/羽化，不重绘或改写建筑图集。原图集SHA256仍为`D971A224251FCBC23C341F8336795AFB3A739B32BDCB9D0234F32111539D2CCF`。
- 主殿台基为复杂阶梯组合，使用紧凑承托区近似，不宣称整栋所有台阶具有精确统一3D相机。其他台基手工参考点见`Planar.SITE_BASES`；弟子居沿用已有显示校准，未新增旋转。
- 状态：TESTED，待负责人视觉验收；判断以实际游戏大小的截图/试玩为准，不以生成底图为准。

## 提示词1：清除旧地块框定

Use case: precise-object-edit. Asset type: background underlay for QingYunSect existing isometric game. Image 1 is the EDIT TARGET, a 1672x941 Chinese garden mountain scene with EIGHT empty building sites. Preserve exact canvas, framing, all distant mountains/clouds, cliffs/waterfalls, pond, surrounding trees/rocks/lanterns and connecting stone paths. Remove ONLY the old building-site pad patterns and geometric border frames: upper-left rectangular pad x110..400 y210..315; left-middle pad x380..630 y305..430 (already natural grass, KEEP this); centre-left rectangle x520..800 y420..535; lower-left brown tilled rectangle x510..810 y530..660; lower-centre rectangle x910..1205 y535..680; right rectangle x1310..1600 y510..640; circular patterned court near pond x1010..1250 y305..415; main top raised terrace interior x560..950 y110..255. Replace each pad with low, irregular natural grass/beige earth/fine gravel matching its surrounding verge, NO directional paving seams, NO rectangular frames, NO border stones, NO ring patterns, NO new building platforms. For main top terrace use softly mottled pale stone/earth and moss with NO regular grid or inner rectangular outline; keep the existing approach staircase and supporting rock topography, but remove front railing fragments inside the central building site. Keep connecting paths intact, keep footprints open/flat and vegetation low, do not place bushes/rocks on cleared sites. Do not move any other landmark, do not fill pond, do not add architecture/people/UI/text. Warm upper-left daylight and semi-realistic painted Chinese game style unchanged. The engine will overlay compact grounds aligned with each actual sprite; these cleared sites must be unframed natural ground, NOT new AI-drawn squares. Exact1672x941 landscape composition.

## 提示词2：清除主殿背景重复楼梯

Use case: precise-object-edit. Image 1 is the EDIT TARGET, the just-cleared1672x941 garden underlay. ONE correction only: remove the large straight approach staircase in front of the top central main-hall clearing, approximately x630..810 y205..290. It conflicts with the actual building sprite's own diagonal staircase. Remove its stair treads, straight side railings and boxed landing. Replace ONLY this stair footprint with an unobtrusive gently sloped natural stone-and-earth approach, irregular small worn limestone flagstones with moss, WITHOUT straight parallel risers, WITHOUT large square paving, WITHOUT railings. Let the existing lower central garden path meet the top clearing via a soft short gently bending approach toward its lower-left side. Keep elevation suggested by surrounding rock/grass banks, no cliffs or holes in this footprint. Preserve all surrounding paths, every cleared site, pond, lanterns outside the stair footprint, trees, rocks, mountains, clouds, image dimensions and exact framing unchanged. Do not add buildings, people, platforms, UI or text. This is a surgical background correction, not a new composition. Same muted beige stone and warm upper-left daylight.
