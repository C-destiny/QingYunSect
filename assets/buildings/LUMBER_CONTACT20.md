# 伐木场接地样板20：来源与处理

- 日期2026-10-23，待负责人视觉验收。只试伐木场，不替换原六联图集及其他建筑。
- 内置ImageGen，透明PNG；参考本项目sect-buildings-unified.png的左上伐木场以及docs/art/v08-courtyard19-after.png的环境/主殿，不使用外部人物、商标或下载素材。
- 首稿缓存exec-13bcffc9-d9ea-4634-bcdb-46dbed14578c.png；二稿exec-d194e3d0-c03a-4791-ac19-ccebc73bc09b.png，两稿均实际1254×1254，未精确遵守1024与10%留白要求。首稿边缘触边，不交付。
- 二稿真实Alpha0～255，之后用Godot Image做等比尺寸和透明画布归一化，不重绘艺术内容，不用Python改图；脚本tests/prepare_lumber_asset.gd，原生成图保留缓存。派生文件不能声称保留原C2PA嵌入数据，此文档保留生成/处理链。
- 最终assets/buildings/lumber-contact20.png，1024×1024，652980字节；SHA256 8938FE5D3C965BEF600E49DD9EE48C2F69CC6C76DB89D4FF1E52588DB2453E95。
- Alpha检查：820444透明像素，非透明包围盒(138,121)～(873,814)，满足四边至少10%留白。原始content=0,69..1214,1230，不把模型输出当精确规格。
- 显示内部区域Rect2(102,102,820,820)，脚点由整图(0.5,0.8)换算至区域(0.5,(819.2-102)/820)，以抵消安全边造成的体积缩水；地图世界脚点不变。运行可关闭lumber_contact_sample回看旧图。
- 权利边界：AI生成及原项目参考素材，按服务适用条款用于本项目，不声称独占版权/精确3D或外部法律审查。没有新增第三方素材许可。
- 已知视觉限制：色温偏暖、基座轮廓仍明显，尚未证明比旧稿更融洽；等实际尺寸对照确认后再决定，不自动推广。

## 首稿完整提示词

```text
Use case: stylized-concept. Asset type: ONE genuine transparent PNG building sprite, a lumber workshop for QingYunSect Chinese xianxia management game. Reference image 1 is the existing six-building atlas: use ONLY the top-left lumber workshop as identity/silhouette reference. Reference image 2 is the actual game screenshot: use its main hall as camera/roof orientation reference and its pale warm stone garden ground as material/lighting context. Do not reproduce the screenshot or the other five buildings. Output one square sprite canvas 1024x1024, not an atlas. Genuine transparent background, no colored matte, no gradients outside the object, no scene.
Preserve recognisable compact Chinese timber workshop with side sawbench, circular saw, stacked cut logs and boards, simple dark desaturated blue-grey/cyan tile roof and modest muted gold tips. Three-quarter elevated orthographic camera matching the existing main hall reference: ground directions approximately down-right slope +0.40 and down-left slope +0.60; do not rotate the workshop to another facing. Keep front/right walls visible as in original top-left workshop. Semi-realistic painted game materials, soft warm upper-left daylight, warm brown timber, pale ivory limestone. Low-key material contrast that belongs in the screenshot, neither toy-like nor photo-real.
Foot integration: compact ultra-thin weathered ivory limestone foundation, only one low course, flush to imaginary garden paving. Ground-contact anchor at canvas normalized (0.5,0.80). Stone surfaces have small warm-grey seams and sparse tiny moss flecks. Foundation must NOT be a freestanding thick slab or a scenic patch: sparse irregular stone chips and moss tufts soften only its immediate contact edge using genuine alpha, without expanding a broad grass island. Do not attach trees or rocks. Ambient occlusion only where walls/logs meet their stone base, NO large cast shadow outside the base, NO black oval or rectangular floor. Roof/wall edges stay opaque and clear, no blurred or white halo and no transparent haze; lower contrast on far roof edge through color only.
Composition: entire building and its base fully within canvas with at least 10 percent clear margin on all four edges; horizontal object centered, never cropped. Critical sawbench/log silhouettes must remain readable when displayed about 180px wide in game. No text, labels, UI, people, other buildings, sky, cliff, water, checkerboard, border or watermark. This is a single production sprite trial, not a finished scene render.
```

## 第二次编辑完整提示词

```text
Use case: precise-object-edit. Edit target: this one transparent lumber workshop sprite. Fix ONLY framing and ground contact, preserve the original building identity, timber, roof shape, tools, logs, colors and facing. Output one SQUARE transparent PNG, ideally 1024x1024. CRITICAL: shrink the entire existing workshop artwork uniformly so its opaque contents fit strictly between x=12%..88% of the canvas and y=12%..85%. There must be at least 10% completely transparent gutter on EVERY edge, with nothing touching or cut by the canvas. Place the frontmost ground-contact tip around canvas normalized (0.50,0.80); leave empty transparent area below. The previous output touched canvas edges, this is forbidden. Do not enlarge the object to fill the canvas.
Ground contact: reduce base thickness to an ultra-thin limestone course, sparse tiny moss flecks along uneven edges only; no broad garden patch or big shadow. Crisp opaque roof/walls. Genuine alpha outside, no white matte, no colored background, no checkerboard, no labels, no frame, no extra objects. Do not change camera, roof or architecture. Need complete uncropped silhouette with abundant transparent padding.
```
