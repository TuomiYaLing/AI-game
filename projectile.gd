extends Node2D
## 飞行物：箭矢 / 飞刀 / 追踪魔弹 / 火球 / 枪弹 / 狙击弹

const Art = preload("res://scripts/art.gd")
const TILE := 32

var game = null
var level = null
var kind := "arrow"
var vel := Vector2.ZERO
var dmg := 10.0
var from_player := true
var life := 3.0
var kill_me := false
var stuck := false
var stuck_t := 0.0
var spin := 0.0
var draw_scale := 1.0
var t := 0.0
var pierce := 0
var hit_set: Dictionary = {}
var elem := ""
var no_chain := false
var status := ""
var status2 := ""
var tilt := 0.0
var grow := 1.0


func setup(p_game, p_level, p_kind: String, p_pos: Vector2, p_vel: Vector2, p_dmg: float, p_from_player: bool, p_scale: float = 1.0, p_elem: String = "", p_pierce: int = 0, p_status: String = "", p_status2: String = "") -> void:
	game = p_game
	level = p_level
	kind = p_kind
	position = p_pos
	vel = p_vel
	dmg = p_dmg
	from_player = p_from_player
	draw_scale = p_scale
	elem = p_elem
	tilt = randf_range(-0.16, 0.16)
	status = p_status
	status2 = p_status2
	z_index = 3
	if kind == "sniper":
		pierce = 3
		life = 2.0
	elif kind == "bullet":
		life = 1.2
	elif kind == "element":
		pierce = p_pierce
		life = 2.4
		z_index = 4


func update(dt: float) -> void:
	t += dt
	# 连击越高弹幕越大；弹幕会轻微左右倾斜
	if game != null:
		grow = game.combo_scale()
	if kill_me:
		return
	if stuck:
		stuck_t += dt
		if stuck_t > 0.55:
			kill_me = true
		queue_redraw()
		return
	life -= dt
	if life <= 0.0:
		kill_me = true
		return

	var gravity: float = 0.0
	if kind == "arrow":
		gravity = 240.0
	elif kind == "knife":
		gravity = 90.0

	# 魔法弹 / 木属性 / 奥术弹会追踪最近的敌人
	var homing: bool = kind == "magic" or (kind == "element" and (elem == "wood" or elem == "arcane"))
	if homing and from_player:
		var tgt = _nearest_enemy()
		if tgt != null:
			var want: Vector2 = (tgt.position + Vector2(0, -tgt.size.y * 0.5) - position).normalized()
			var spd: float = vel.length()
			vel = vel.normalized().lerp(want, clampf(3.2 * dt, 0.0, 1.0)).normalized() * spd

	vel.y += gravity * dt
	position += vel * dt

	if kind == "knife":
		spin += dt * 22.0
		rotation = spin
	elif kind == "magic":
		pass
	else:
		rotation = vel.angle()

	# 撞墙
	var tx: int = int(floor(position.x / TILE))
	var ty: int = int(floor(position.y / TILE))
	if level.is_solid(tx, ty):
		if kind == "arrow" and from_player:
			stuck = true
			position -= vel * dt
			game.fx.spark_spawn(position, -vel.normalized(), 5, Color(0.85, 0.85, 0.9))
		elif kind == "magic":
			kill_me = true
			game.fx.ring_spawn(position, 26.0, Color(0.6, 0.85, 1.0))
			game.fx.spark_spawn(position, -vel.normalized(), 8, Color(0.7, 0.9, 1.0))
		elif kind == "sniper":
			kill_me = true
			game.fx.spark_spawn(position, -vel.normalized(), 12, Color(0.95, 0.98, 1.0))
			game.fx.ring_spawn(position, 30.0, Color(0.8, 0.95, 1.0))
		elif kind == "element":
			kill_me = true
			game.fx.ring_spawn(position, 24.0, _elem_col())
			game.fx.spark_spawn(position, -vel.normalized(), 7, _elem_col())
		else:
			kill_me = true
			game.fx.spark_spawn(position, -vel.normalized(), 4, Color(0.85, 0.85, 0.8))
		return
	if position.y > float(level.height_tiles * TILE) + 60.0:
		kill_me = true
		return

	# 命中判定
	if from_player:
		var enemies: Array = game.enemies
		for i in range(enemies.size()):
			var e = enemies[i]
			if e == null or not is_instance_valid(e):
				continue
			if e.dead:
				continue
			var eid: int = e.get_instance_id()
			if hit_set.has(eid):
				continue
			if Rect2(position - Vector2(5, 5), Vector2(10, 10)).intersects(e.rect()):
				hit_set[eid] = true
				var res: String = e.hurt(dmg, vel.normalized(), 180.0, 0.16, elem)
				if status != "" and e != null and is_instance_valid(e) and e.has_method("apply_status"):
					e.apply_status(status, 5.0)
					if status2 != "":
						e.apply_status(status2, 5.0)
				if kind == "element":
					game.fx.spark_spawn(position, vel.normalized(), 9, _elem_col())
					game.fx.ring_spawn(position, 22.0, _elem_col())
					_on_element_hit(e)
				elif kind == "magic":
					game.fx.spark_spawn(position, vel.normalized(), 9, Color(0.75, 0.92, 1.0))
				elif kind == "sniper":
					game.fx.spark_spawn(position, vel.normalized(), 14, Color(1.0, 0.98, 0.85))
					game.fx.ring_spawn(position, 34.0, Color(0.9, 0.98, 1.0))
				else:
					game.fx.spark_spawn(position, vel.normalized(), 8, Color(0.95, 0.9, 0.7))
				game.sfx_play("arrow_hit", 1.0 + randf() * 0.1, -3.0)
				if res == "crit":
					game.shake(4.0)
				if pierce > 0:
					pierce -= 1
					continue
				kill_me = true
				return
		queue_redraw()
		return

	var pl = game.player
	if pl != null and not pl.dead:
		if Rect2(position - Vector2(5, 5), Vector2(10, 10)).intersects(pl.rect()):
			var res2: String = pl.hurt(dmg, position, "projectile", self)
			if res2 == "parry":
				from_player = true
				vel = -vel * 1.45
				dmg *= 1.8
				game.sfx_play("parry", 1.1)
				game.fx.ring_spawn(position, 30.0, Color(0.8, 0.95, 1.0))
			elif res2 == "block" or res2 == "dodge" or res2 == "guard":
				kill_me = true
				game.fx.spark_spawn(position, -vel.normalized(), 8, Color(0.85, 0.9, 1.0))
			else:
				kill_me = true
			return
	queue_redraw()


func _elem_col() -> Color:
	if elem == "metal":
		return Color(1.00, 0.92, 0.52)
	if elem == "wood":
		return Color(0.55, 0.95, 0.55)
	if elem == "water":
		return Color(0.48, 0.82, 1.00)
	if elem == "fire":
		return Color(1.00, 0.52, 0.24)
	if elem == "shock":
		return Color(0.90, 0.96, 1.00)
	if elem == "earth":
		return Color(0.86, 0.66, 0.38)
	return Color(0.80, 0.66, 1.00)


## 元素附带的额外效果：火爆炸 / 水溅射 / 土重击
func _on_element_hit(e) -> void:
	if not from_player or no_chain:
		return
	if game == null:
		return
	if elem == "fire":
		game.damage_area(position, 52.0, dmg * 0.55, vel.normalized())
		game.fx.ring_spawn(position, 54.0, Color(1.0, 0.55, 0.25))
		game.shake(3.0)
	elif elem == "water":
		for k in range(3):
			var ang: float = vel.angle() + randf_range(-0.9, 0.9)
			_spawn_child(Vector2(cos(ang), sin(ang)) * 520.0, dmg * 0.45, elem)
	elif elem == "earth":
		if e != null and is_instance_valid(e) and not bool(e.dead):
			e.hurt(dmg * 0.15, vel.normalized(), 380.0, 0.2)


func _spawn_child(v: Vector2, d: float, el: String) -> void:
	if game == null:
		return
	game.spawn_shot("element", position + v.normalized() * 6.0, v, d, from_player, 0.72, el, 0, status, status2)
	# 子水滴不再分裂，避免无限连锁
	if game.shots.size() > 0:
		var s = game.shots[game.shots.size() - 1]
		if s != null and is_instance_valid(s):
			s.no_chain = true


func _nearest_enemy():
	if game == null:
		return null
	var best = null
	var best_d: float = 420.0
	for i in range(game.enemies.size()):
		var e = game.enemies[i]
		if e == null or not is_instance_valid(e) or e.dead:
			continue
		var c: Vector2 = e.position + Vector2(0, -e.size.y * 0.5)
		var d: float = position.distance_to(c)
		if d < best_d:
			best_d = d
			best = e
	return best


func _draw() -> void:
	# 魔法类弹幕：左右倾斜 + 随连击变大（其它弹道保持朝向）
	if kind == "element" or kind == "magic":
		var wob: float = sin(t * 9.0) * 0.10 + tilt
		draw_set_transform(Vector2.ZERO, wob, Vector2(grow, grow))
	if kind == "element":
		var c: Color = _elem_col()
		draw_circle(Vector2.ZERO, 13.0 * draw_scale, Color(c.r, c.g, c.b, 0.16))
		draw_circle(Vector2.ZERO, 7.0 * draw_scale, Color(c.r, c.g, c.b, 0.72))
		draw_circle(Vector2.ZERO, 3.4 * draw_scale, Color(1.0, 1.0, 1.0, 0.95))
		if elem == "metal":
			draw_rect(Rect2(-13.0 * draw_scale, -1.6, 26.0 * draw_scale, 3.2), Color(1.0, 0.96, 0.72, 0.9))
			draw_colored_polygon(PackedVector2Array([
				Vector2(13.0 * draw_scale, -3.4), Vector2(19.0 * draw_scale, 0.0), Vector2(13.0 * draw_scale, 3.4),
			]), Color(1.0, 0.98, 0.86, 0.95))
		elif elem == "wood":
			draw_rect(Rect2(-10.0, -1.2, 9.0, 2.4), Color(0.36, 0.70, 0.34, 0.9))
			draw_rect(Rect2(-12.0, -3.4, 4.0, 6.8), Color(0.44, 0.80, 0.42, 0.9))
		elif elem == "water":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-8.0 * draw_scale, 0.0), Vector2(0.0, -7.0 * draw_scale), Vector2(8.0 * draw_scale, 0.0), Vector2(0.0, 7.0 * draw_scale),
			]), Color(0.62, 0.90, 1.0, 0.75))
		elif elem == "fire":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-13.0 * draw_scale, -3.6), Vector2(-4.0, 0.0), Vector2(-13.0 * draw_scale, 3.6),
			]), Color(1.0, 0.62, 0.24, 0.75))
		elif elem == "shock":
			draw_colored_polygon(PackedVector2Array([
				Vector2(3.0 * draw_scale, -11.0 * draw_scale), Vector2(-6.0 * draw_scale, 0.0), Vector2(0.0, 0.0),
				Vector2(-3.0 * draw_scale, 11.0 * draw_scale), Vector2(7.0 * draw_scale, -2.0 * draw_scale), Vector2(1.0, -2.0),
			]), Color(0.92, 0.97, 1.0, 0.95))
		elif elem == "earth":
			draw_rect(Rect2(-8.0 * draw_scale, -8.0 * draw_scale, 16.0 * draw_scale, 16.0 * draw_scale), Color(0.62, 0.46, 0.28, 0.9))
			draw_rect(Rect2(-8.0 * draw_scale, -8.0 * draw_scale, 16.0 * draw_scale, 3.0), Color(0.78, 0.62, 0.40, 0.9))
		else:
			var a2: float = t * 8.0
			draw_set_transform(Vector2.ZERO, a2, Vector2.ONE)
			draw_rect(Rect2(-1.2, -10.0 * draw_scale, 2.4, 20.0 * draw_scale), Color(0.86, 0.74, 1.0, 0.8))
			draw_rect(Rect2(-10.0 * draw_scale, -1.2, 20.0 * draw_scale, 2.4), Color(0.86, 0.74, 1.0, 0.8))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	if kind == "magic":
		var mc: Color = _elem_col() if elem != "" else Color(0.62, 0.88, 1.0)
		draw_circle(Vector2.ZERO, 13.0, Color(mc.r, mc.g, mc.b, 0.14))
		draw_circle(Vector2.ZERO, 7.0, Color(mc.r, mc.g, mc.b, 0.55))
		draw_circle(Vector2.ZERO, 4.0, Color(1.0, 1.0, 1.0, 0.95))
		var a: float = t * 7.0
		draw_set_transform(Vector2.ZERO, a, Vector2(1.0, 1.0))
		draw_rect(Rect2(-1.0, -9.0, 2.0, 18.0), Color(0.72, 0.92, 1.0, 0.75))
		draw_rect(Rect2(-9.0, -1.0, 18.0, 2.0), Color(0.72, 0.92, 1.0, 0.75))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	if kind == "pet_bolt":
		draw_circle(Vector2.ZERO, 11.0, Color(1.0, 0.52, 0.22, 0.16))
		draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.62, 0.28, 0.7))
		draw_circle(Vector2.ZERO, 3.2, Color(1.0, 0.92, 0.62, 0.95))
		draw_rect(Rect2(-12.0, -1.6, 10.0, 3.2), Color(1.0, 0.55, 0.25, 0.45))
		return
	if kind == "bullet":
		draw_rect(Rect2(-10.0, -1.2, 16.0, 2.4), Color(1.0, 0.92, 0.55, 0.9))
		draw_rect(Rect2(4.0, -1.8, 6.0, 3.6), Color(1.0, 1.0, 0.85, 1.0))
		draw_rect(Rect2(-16.0, -0.8, 8.0, 1.6), Color(1.0, 0.75, 0.35, 0.35))
		return
	if kind == "sniper":
		draw_rect(Rect2(-26.0, -2.4, 34.0, 4.8), Color(0.72, 0.92, 1.0, 0.55))
		draw_rect(Rect2(-16.0, -1.2, 26.0, 2.4), Color(0.95, 0.99, 1.0, 0.95))
		draw_circle(Vector2(6.0, 0.0), 4.0, Color(1.0, 1.0, 1.0, 0.9))
		return
	var col_shaft := Color(0.72, 0.60, 0.45)
	if kind == "arrow":
		var tail := Color(0.35, 0.85, 1.0)
		draw_rect(Rect2(-12.0 * draw_scale, -1.2, 20.0 * draw_scale, 2.4), col_shaft)
		draw_colored_polygon(PackedVector2Array([
			Vector2(9.0 * draw_scale, -3.4),
			Vector2(16.0 * draw_scale, 0.0),
			Vector2(9.0 * draw_scale, 3.4),
		]), Color(0.88, 0.90, 0.95))
		draw_rect(Rect2(-13.0 * draw_scale, -3.0, 4.0, 6.0), tail)
	else:
		draw_rect(Rect2(-6.0, -1.6, 12.0, 3.2), Color(0.70, 0.72, 0.78))
		draw_colored_polygon(PackedVector2Array([
			Vector2(6.0, -3.0),
			Vector2(13.0, 0.0),
			Vector2(6.0, 3.0),
		]), Color(0.85, 0.87, 0.92))
		draw_rect(Rect2(-8.0, -3.6, 2.6, 7.2), Color(0.35, 0.26, 0.16))
