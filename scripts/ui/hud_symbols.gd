extends RefCounted

# 本项目原创矢量符号；不依赖低分辨率截图或外部图标字体。
const PATHS := {
	"wood": '<path fill="#aa7442" d="M10 43 42 13 54 24 22 54Z"/><path fill="#dfb97c" d="m10 43 12 11 5-9-11-10Z"/><path d="m23 32 23-20m-18 29 23-22M12 44l8 7"/>',
	"stone": '<path fill="#3da8de" stroke="#bdeeff" d="m31 5 18 22-7 27-23 3-9-28Z"/><path fill="#a9eaff" d="m31 5-6 24 17 25 7-27Z"/><path stroke="#e5f9ff" d="m10 29 15 0 24-2M25 29l-6 28"/>',
	"food": '<path d="M32 55V12M32 39Q11 38 13 24q17 0 19 15Zm0-12Q17 25 19 13q12 1 13 14Zm0 20Q52 45 51 32q-16 1-19 15Zm0-19Q47 26 46 13q-12 0-14 15Z"/>',
	"people": '<circle cx="32" cy="19" r="8" fill="#e9d9b4"/><circle cx="13" cy="25" r="6" fill="#c6b58f"/><circle cx="51" cy="25" r="6" fill="#c6b58f"/><path fill="#c6b58f" d="M3 50V40q10-16 20 0v10m18 0V40q10-16 20 0v10"/><path fill="#e9d9b4" d="M19 55V40q13-20 26 0v15Z"/>',
	"sect": '<path fill="#d9c399" d="M17 52V28h30v24Zm6-2V37h7v13m5 0V37h7v13"/><path fill="#ead7ac" d="M7 28q14-4 25-16 11 12 25 16ZM14 16q11-3 18-12 7 9 18 12Z"/><path d="M10 54h44M13 32h38M32 4V1"/>',
	"build": '<path d="m16 51 28-31" stroke-width="8"/><path fill="#dfc99c" d="M26 12 35 4 56 23 47 33Z"/><path d="m8 17 39 36" stroke-width="5"/><path d="m5 10 9 1 5 12-7-2Z" fill="#c9b48b"/>',
	"growth": '<path d="M9 48q23-5 46 0M32 45V17M32 36Q9 35 8 19q20-1 24 17Zm0 0q23-1 24-17-20-1-24 17ZM32 27Q17 17 32 5q15 12 0 22Z"/><circle cx="32" cy="52" r="3" fill="#ead7ac"/>',
	"battle": '<path fill="#e4d0a5" d="m8 5 11 4 29 35-5 5L9 16Zm48 0-11 4-29 35 5 5 34-33Z"/><path d="m34 49 15-15M15 34l15 15M45 47l10 11M19 47 9 58" stroke-width="4"/>',
}

static func make_texture(kind: String) -> Texture2D:
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><g fill="none" stroke="#e7d2a5" stroke-width="2.4" stroke-linejoin="round" stroke-linecap="round">%s</g></svg>' % PATHS[kind]
	var image := Image.new()
	var result := image.load_svg_from_string(svg, 2.0)
	if result != OK:
		push_error("HUD symbol could not be rasterized: " + kind)
		return null
	return ImageTexture.create_from_image(image)
