extends SceneTree

# 仅尺寸/透明画布归一化，不重绘内容；原生成文件保留。
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		quit(1)
		return
	var source := Image.load_from_file(args[0])
	if source == null or source.is_empty():
		quit(1)
		return
	var used := source.get_used_rect()
	var content := source.get_region(used)
	var factor := minf(818.0 / content.get_width(), 714.0 / content.get_height())
	var extent := Vector2i(roundi(content.get_width() * factor), roundi(content.get_height() * factor))
	content.resize(extent.x, extent.y, Image.INTERPOLATE_LANCZOS)
	var output := Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	output.blit_rect(content, Rect2i(Vector2i.ZERO, extent), Vector2i((1024 - extent.x) / 2, 819 - extent.y))
	var error := output.save_png(args[1])
	print("PASS: normalized 1024 canvas; content=", output.get_used_rect(), "; original preserved")
	quit(0 if error == OK else 1)
