# V0.8 局部背景融合素材

- 日期：2026-10-22。来源：OpenAI内置ImageGen，edit模式；没有使用CLI或第三方下载素材。
- 编辑目标：项目既有`sect_open_terraces.png`，来源沿用`OPEN_TERRACES.md`。本次不包含人物照片或第三方商标。
- 输出：`sect_courtyard_fusion16.png`，1672×941，不透明PNG。
- SHA256：`0F9918BE1275EA1904944A3E9B2CC2A6EDFA375130F2F27C6CCD90785667F7B8`。
- 用途：《青云宗》V0.8固定场景视觉样板；原图未覆盖。运行仅在主殿和弟子居两个羽化窗口内叠加改稿，其他区域继续原背景。
- 许可边界：AI生成资产按服务适用条款用于本项目；不声称独占版权或经过外部法律审核。未引入需另行授权的外部素材。
- 松石与苔草复用`TERRAIN_NATURE.md`已登记素材；入口铺装与羽化由项目代码绘制。

## 完整最终提示词

```text
Use case: precise-object-edit. Asset type: production 2D isometric Chinese cultivation game BACKGROUND, no buildings, no UI. Image 1 is the edit target. Maintain EXACT same wide 1672:941 canvas, framing, perspective, island silhouette, main staircase positions, bridges, distant mountains, waterfalls, and seven open building sites. Only refine two areas: top central main-hall terrace and lower middle disciple residential courtyard. All other sites remain unchanged.
The background will have separate existing building sprites placed on top, so do NOT draw any houses, temple roofs, columns or permanent buildings. In source-image pixel coordinates, leave the main-hall footprint (x565..915,y145..265) completely clear with stone beneath, and residential footprint (x910..1100,y635..735) completely clear. Keep all stairs usable.
Top terrace: replace the excessive giant ornamental empty paving with calm warm pale limestone courtyard paving matched to miniature semi-realistic architectural sprites, subtle worn edges and subdued fine joints. A clear arrival apron leads from the center bottom of the hall footprint (740,255) toward the existing stairs at (785,320). Add small irregular moss/grass planting pockets at outer left and right of this apron only, not inside building footprint or across routes.
Residential lower-middle area: reduce the giant uninterrupted stone plaza with contained muted green grass and moss planting beds around the residential footprint, never on it. Establish a welcoming modest residential garden, retaining a clear pale stone connection from its southwest-facing entry near (965,720) toward the adjacent central path near (865,655); no new stairs on this same flat terrace. Low planting and tiny weathered rocks blend gently into existing stone. No tall trees inside building sites. Nothing obstructs the neighbor fields centered near (770,710), the forge at (600,610), or the right-side mine at (1410,680). Keep the other terraces unchanged.
Style: stylized semi-realistic Chinese fantasy, weak linework, crisp but not photographic limestone material, warm sunlight from upper left, restrained ambient shadows, less visual noise. Do not add text, signs, icons, characters, watermarks, outlines, roads across cliffs or extra platforms. Preserve the overall background rather than redesign the whole composition.
```
