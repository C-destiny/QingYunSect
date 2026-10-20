# V0.8 全图推广建筑图集

2026-10-20，内置ImageGen生成；前两次带参考请求网络失败，第三次使用文字规格成功，无CLI/API替代。最终项目路径assets/buildings/sect-buildings-unified.png，1536×1024，3×2等分（512×512）。

上排：伐木场、采灵坊、灵田；下排：演武场、炼器坊、藏经阁。弟子居继续使用已验收独立样板，不重复替换。低石台、青灰瓦、暖木与左上光源同系，不生成独立岩山。

SHA-256 D971A224251FCBC23C341F8336795AFB3A739B32BDCB9D0234F32111539D2CCF，2836839字节。按生成工具适用条件供本项目游戏使用，未抓取外部素材、不宣称独占版权。原生成输出留在Codex generated_images，游戏不引用该目录。

运行配置为每类宽度166～194，图格等比缩放，归一化脚点(0.5,0.80)，Lv2/3沿原小幅缩放与标签，不是三套独立等级建筑。阴影/拾取/预览/小卡共享同一视觉配置；透明通道与实际渲染需验证。

最终完整提示词：

Generate ONE transparent sprite atlas for a Chinese cultivation temple management game, 3 equal columns x 2 equal rows, landscape 1536x1024. Six complete separate isometric buildings, elevated 2:1 ground perspective, NO labels or dividers. Warm timber, charcoal blue-gray tile roofs, thin ivory stone bases flush to ground, restrained muted gold trim, semi-realistic painted game materials, upper-left light, soft lower-right shadow. Not cartoon, no rocky islands, no cliffs, no large glow. Each sprite stays inside its cell with 10% transparent gutter, ground base center at cell normalized (0.5,0.80). TOP ROW left to right: small lumber workshop with sawbench/logs; small spirit-stone processing workshop with a few pale blue crystals; low rectangular grain field with small rear shelter. BOTTOM ROW left to right: round training court with target/rack and tiny rear pavilion; artisan forge workshop with modest chimney/anvil and gentle furnace glow; narrow two-storey scripture library smaller than grand main hall. Same coherent scale and roof orientation. Genuine transparency between all six assets and around edges. No people, no text, no UI, no sky, no checkerboard, no watermarks.
