extends RefCounted

# 视觉投影不持久化。未来区域扩展沿用原点与旧格坐标，不按地图宽高重排旧建筑。
const TILE_SIZE := Vector2(104, 52)
const MAIN_HALL_CELL := Vector2i(4, 3)

static func project(cell: Vector2i, origin: Vector2) -> Vector2:
	return origin + Vector2(cell.x - cell.y, (cell.x + cell.y) * 0.5) * Vector2(TILE_SIZE.x * 0.5, TILE_SIZE.y)

static func unproject(point: Vector2, origin: Vector2, bounds: Rect2i) -> Vector2i:
	var local := point - origin
	var cell := Vector2i(floori(local.x / TILE_SIZE.x + local.y / TILE_SIZE.y + 0.5),
		floori(local.y / TILE_SIZE.y - local.x / TILE_SIZE.x + 0.5))
	return cell if bounds.has_point(cell) else Vector2i(-1, -1)
