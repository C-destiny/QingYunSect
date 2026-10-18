# V0.8 UI图标图集

`qingyun_ui_icon_atlas.png`用于主界面顶部资源信息与底部功能导航，尺寸1284×1225，按3×3等分区域在Godot中以`AtlasTexture`裁切。图标顺序：

1. 木材、灵石、灵谷。
2. 弟子、宗门、建设。
3. 养成、挂机、更多。

生成方式：OpenAI内置图像生成工具，生成日期2026-10-17。负责人提供的主界面截图仅作为风格与使用位置参考，不作为编辑目标或项目素材入库。

最终提示词：

```text
Use case: stylized-concept
Asset type: transparent 3x3 game UI icon atlas for the Chinese cultivation management game QingYunSect
Primary request: Create exactly nine distinct square UI icons arranged in a perfectly regular 3 by 3 grid with equal cell sizes and generous transparent padding. Row 1: stacked timber logs, glowing blue spirit crystal, golden rice/grain sheaf. Row 2: disciple/person silhouette in flowing robe, sect mountain crest with pavilion, traditional Chinese construction hall. Row 3: cultivation hand/meditation symbol, crossed sword and spell talisman for idle battle, ornate gear/more symbol.
Style/medium: polished stylized semi-realistic Chinese fantasy game UI, dark blue-green jade frames, restrained antique gold rims, clean material definition, readable at 40-64 pixels, matching the attached interface reference
Composition/framing: each icon centered in its own cell, identical scale and framing, no objects crossing cell boundaries, no combined scene
Color palette: teal, dark navy, jade green, antique gold, with resource-specific accent colors
Constraints: genuinely transparent background; exactly nine icons; strict 3x3 atlas; no text, no numerals, no letters, no watermark, no logo; crisp silhouettes; consistent lighting and border thickness
Avoid: photorealism, chibi, neon sci-fi, excessive glow, busy backgrounds, merged icons
```

SHA-256：`04E50C3B613475AE5135317FA14FA9060EFA52161A101596CDE1FE0812C59E5B`

使用范围：《青云宗》项目运行时UI；当前为V0.8待负责人验收素材。
