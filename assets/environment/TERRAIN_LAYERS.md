# 地形分层材质来源（候选8）

2026-10-20～21，使用内置 ImageGen / imagegen 技能生成三张独立层素材。按工具适用条件用于本项目，不宣称独占版权；无外部抓取素材。PNG原样复制入仓库，地面投影与岩壁变形由Godot几何完成，没有修改原生成图像。旧courtyard_fusion_atlas仅取低栏杆，授权与来源沿用COURTYARD_FUSION.md。

| 文件 | 尺寸 | 字节 | SHA256 |
|---|---|---|---|
| sect_cloud_distance.png | 1672×941 | 1851533 | 995A257713C86A785CD8CA391D73C570F245D6D881C14B2CF8463864827A8BFC |
| sect_limestone_paving.png | 1254×1254 | 3450161 | 3BB381DB3F4F4D0775D0307783C50CB25C8A033A22BAF896C57084BB0FFACFDC |
| sect_cliff_material.png | 1254×1254 | 3781560 | F1FCAFD49FFB09EA7CB5921995A33339A1B366EA8F317524A1E8BD36F3A2FE53 |

生成目录C:/Users/72736/.codex/generated_images/01a153d7-60aa-73e2-ba1d-18d6cf2ad70e/，依次为exec-1fecb9e5-9448-40ff-8b61-add03c1c66a3.png、exec-17f4b303-6f3a-4502-bd91-04dc200b8cf7.png、exec-534cc8b7-e369-4d65-be78-032ba5af0e48.png。

## 完整提示词：背景

Use case: stylized-concept. Production BACKGROUND layer only for a Chinese cultivation sect isometric strategy game. Wide landscape 16:9, blue-white cloud sea and distant blue-gray karst mountains fading into mist. Layered distant pine-covered peaks with waterfalls, subtle pink blossoms on far side peaks. Keep the CENTRAL and LOWER 80 percent an uninterrupted SOFT CLOUD SEA with depth, suitable behind a separately rendered elevated playable island. Distant mountains concentrated at upper horizon and far left/right margins. Semi-realistic painted Chinese landscape, restrained ink-wash atmospheric distance, coherent warm daylight from upper left. NO foreground island, NO foreground terraces or paving, NO stone stairs, NO railings, NO bridge in central area, NO architecture, NO people, NO UI, NO words. The runtime engine creates ALL playable ground and cliffs above this background. Avoid any central ledge or solid foreground land that would intersect runtime buildings. Crisp high quality game art, subtle distant detail, soft cloud whites, muted jade and cool blue mountains. No frame or watermark.

## 完整提示词：铺装

Use case: stylized-concept. A production seamless square texture, orthographic straight-down view, NOT isometric: weathered pale warm ivory limestone paving for a Chinese mountain temple courtyard. Closely fitted rectangular stone slabs of varied modest sizes, restrained thin gray-beige mortar seams, subtle mineral grain, small scattered pale jade moss in a few joints. Neutral diffuse daylight baked with NO directional cast shadows. Seamlessly tileable on every edge. Consistent moderate detail and color, no medallions, no border, no steps, no cliff, no railing, no objects, no text, no frame, no sky. Painted semi-realistic game material matching pale limestone Chinese temple architecture, not photorealistic, no dramatic dirt or cracks. Fill entire square with the paving material, no transparency.

## 完整提示词：岩壁

Production game material texture, square image, fills entire frame edge to edge: a continuous vertical FACE of gray-blue mountain limestone cliff. Straight-on view of rock wall only, NOT top-down and NOT isometric. Long irregular vertical fractured strata, broad stone masses, sparse muted jade moss in crevices. Painted semi-realistic Chinese fantasy game aesthetic, restrained detail, low contrast, diffuse neutral lighting. Seamless horizontally. Absolutely NO sky, NO clouds, NO waterfall, NO flowers, NO trees, NO stairs, NO railings, NO ground top, NO buildings, NO island silhouette, NO text or frame. A practical rock wall material which will be mapped onto runtime cliff geometry.
