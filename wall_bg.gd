extends Node2D
## 屏幕固定的场景墙壁：始终铺满整个屏幕，不随镜头滚动

const Art = preload("res://scripts/art.gd")

var theme_ref: Dictionary = {}


func setup(th: Dictionary) -> void:
	theme_ref = th
	queue_redraw()


func _draw() -> void:
	var vs: Vector2 = get_viewport_rect().size
	if theme_ref.is_empty():
		draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.10, 0.10, 0.14))
		return
	# 屏幕坐标平铺：位置固定为 (0,0)，不参与相机变换
	Art.draw_walls_screen(self, get_viewport_rect().size * 0.5, vs, theme_ref)
