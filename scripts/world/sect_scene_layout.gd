extends RefCounted

# 仅用于渲染：保持104×52逻辑投影及12×8存档坐标，放宽视觉地面间距。
# 建筑素材不随地面间距同比放大，留出庭院和通路；不改变占地/解锁规则。
const GROUND_SPACING := 1.45
const ORIGIN_RATIO := Vector2(0.42, 0.13)

static func origin(view_size: Vector2) -> Vector2:
	return Vector2(view_size.x * ORIGIN_RATIO.x, maxf(100.0, view_size.y * ORIGIN_RATIO.y))

static func to_scene(projected: Vector2, origin_point: Vector2) -> Vector2:
	return origin_point + (projected - origin_point) * GROUND_SPACING

static func to_projection(point: Vector2, origin_point: Vector2) -> Vector2:
	return origin_point + (point - origin_point) / GROUND_SPACING
