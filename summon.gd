extends Node2D
## 召唤物：自动追击并攻击最近的敌人，存在 20 秒
## 由「召唤类武器」生成，伤害固定（不吃武器倍率）

const Art = preload("res://scripts/art.gd")
const TAU := 6.283185307179586

var game = null
var level = null
var player = null

var variant := "imp"
var color := Color(0.72, 0.90, 1.0)
var dmg := 10.0
var life := 20.0
var speed := 235.0
var ghost := false          # true = 可穿墙
var elem := ""              # 命中附加的元素状态
var support := false        # 辅助型：命中时治疗玩家
var heal_amt := 3.0

var t := 0.0
var phase := 0.0
var atk_cd := 0.0
var target = null
var bob := 0.0
var atk_interval := 0.55
var splash := 0.0
var slot := 0
var idle_base := Vector2.ZERO
var life_max := 15.0
var lifesteal := 0.0
var mana_gain := 0.0
var aoe_radius := 0.0
var knock_power := 140.0


func setup(p_game, p_level, p_player, p_variant: String, p_col: Color) -> void:
	game = p_game
	level = p_level
	player = p_player
	variant = p_variant
	color = p_col
	z_index = 5
	life = 15.0
	life_max = 15.0
	bob = randf() * TAU
	# 各召唤物的独特能力
	if variant == "prism":
		# 泰拉棱镜：极速、可穿墙、极快斩击
		atk_interval = 0.18
		speed = 3200.0
		ghost = true
		knock_power = 200.0
	elif variant == "imp":
		# 恶魔：攻速快，命中灼烧
		atk_interval = 0.42
		speed = 300.0
	elif variant == "bat":
		# 蝙蝠：吸血（命中给玩家回血），可穿墙
		atk_interval = 0.50
		speed = 320.0
		lifesteal = 1.6
	elif variant == "skull":
		# 骷髅：单发高击退，能撞开怪群
		atk_interval = 0.60
		speed = 210.0
		knock_power = 420.0
	elif variant == "wisp":
		# 精灵：命中给玩家回血 + 回法力
		atk_interval = 0.50
		speed = 250.0
		mana_gain = 4.0
		knock_power = 80.0
	elif variant == "void":
		# 虚空：命中溅射周围敌人（可穿墙）
		atk_interval = 0.55
		speed = 300.0
		aoe_radius = 52.0
	elif variant == "tide":
		# 潮汐：命中减速并给玩家小额治疗
		atk_interval = 0.55
		speed = 240.0
		knock_power = 100.0


func configure(p_dmg: float, p_elem: String, p_ghost: bool, p_support: bool, p_life: float = 15.0, p_slot: int = 0) -> void:
	dmg = p_dmg
	elem = p_elem
	ghost = p_ghost
	support = p_support
	life = p_life
	life_max = maxf(1.0, p_life)
	slot = p_slot


func update(dt: float) -> void:
	t += dt
	phase += dt * 6.0
	life -= dt
	if life <= 0.0:
		queue_free()
		return
	atk_cd = maxf(0.0, atk_cd - dt)

	# 目标选择：最近的敌人
	if target == null or not is_instance_valid(target) or target.dead:
		target = _nearest_enemy()

	var goal: Vector2
	if target != null:
		goal = target.position + Vector2(0, -target.size.y * 0.5)
	elif player != null and is_instance_valid(player):
		# 无怪时：扇形排列在角色后方
		var back: float = -player.facing
		var spread_a: float = -0.75 + float(slot % 5) * 0.37
		var radius: float = 34.0 + float(slot % 3) * 10.0
		goal = player.position + Vector2(back * radius * cos(spread_a), -34.0 + sin(spread_a) * 18.0)
	else:
		goal = position

	var to_goal: Vector2 = goal - position
	var dist: float = to_goal.length()
	if dist > 8.0:
		var dir: Vector2 = to_goal / dist
		var step: Vector2 = dir * speed * dt
		if ghost:
			position += step
		else:
			var res: Dictionary = level.move_body(position, Vector2(16, 16), step, false)
			position = res["pos"]
		# 卡住时稍微上下浮动
		if not ghost and bool(res_has_stuck(step)):
			position.y -= 12.0 * dt
			position.x += 8.0 * dt
	position.y += sin(t * 4.0 + bob) * 8.0 * dt

	if target != null and dist < 30.0 and atk_cd <= 0.0:
		_attack(target)


func res_has_stuck(step: Vector2) -> bool:
	return absf(step.x) > 0.5


func _attack(e) -> void:
	atk_cd = atk_interval
	var dir: Vector2 = ((e.position + Vector2(0, -e.size.y * 0.5)) - position)
	if dir.length() < 0.1:
		dir = Vector2(1, 0)
	dir = dir.normalized()
	var res: String = e.hurt(dmg, dir, knock_power, 0.12, elem)
	# 虚空：命中溅射周围敌人
	if aoe_radius > 0.0 and game != null:
		for i in range(game.enemies.size()):
			var o = game.enemies[i]
			if o == null or not is_instance_valid(o) or o.dead or o == e:
				continue
			var oc: Vector2 = o.position + Vector2(0, -o.size.y * 0.5)
			if position.distance_to(oc) <= aoe_radius:
				o.hurt(dmg * 0.5, dir, knock_power * 0.5, 0.08, elem)
		game.fx.ring_spawn(position, aoe_radius, Color(0.80, 0.55, 1.0))
	# 蝙蝠：吸血给玩家
	# 溅射：命中波及周围敌人
	if splash > 0.0 and game != null:
		for si in range(game.enemies.size()):
			var se = game.enemies[si]
			if se == null or not is_instance_valid(se) or se.dead or se == e:
				continue
			var sc2: Vector2 = se.position + Vector2(0, -se.size.y * 0.5)
			if position.distance_to(sc2) <= splash:
				se.hurt(dmg * 0.6, dir, knock_power * 0.4, 0.05, elem)
		game.fx.ring_spawn(position, splash, color)
	if lifesteal > 0.0 and player != null and is_instance_valid(player) and not player.dead:
		player.hp = minf(player.max_hp, player.hp + lifesteal)
		if game != null:
			game.fx.text(position + Vector2(0, -26.0), "+%d" % int(lifesteal), Color(1.0, 0.55, 0.62), 12)
	# 精灵：命中回法力
	if mana_gain > 0.0 and player != null and is_instance_valid(player):
		player.mana = minf(player.max_mana, player.mana + mana_gain)
		if game != null:
			game.fx.text(position + Vector2(0, -14.0), "+%d 法力" % int(mana_gain), Color(0.55, 0.82, 1.0), 12)
	if game != null:
		game.hit_feedback(e.position, dir, res == "crit")
		game.note_damage(dmg)
		if variant == "prism":
			# 横向大斩击光效
			var ang2: float = dir.angle()
			game.fx.slash_spawn(position, ang2, 52.0, Color(1.0, 0.96, 0.78), 1.0)
			game.fx.slash_spawn(position + dir * 12.0, ang2, 38.0, Color(0.74, 0.64, 1.0), -1.0)
			game.fx.ring_spawn(position, 38.0, Color(0.86, 0.96, 1.0))
			game.fx.spark_spawn(position, dir, 16, Color(1.0, 1.0, 0.9))
			game.shake(2.4)
			game.sfx_play("slash", 1.35, -3.0)
		else:
			game.fx.spark_spawn(position, dir, 4, color)
	if support and player != null and is_instance_valid(player) and not player.dead:
		player.hp = minf(player.max_hp, player.hp + heal_amt)
		if game != null:
			game.fx.text(position + Vector2(0, -20.0), "+%d" % int(heal_amt), Color(0.6, 1.0, 0.7), 13)


func _nearest_enemy():
	if game == null:
		return null
	var best = null
	var best_d: float = 520.0
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
	var a: float = 0.65 + 0.35 * sin(t * 5.0)
	draw_circle(Vector2.ZERO, 13.0, Color(color.r, color.g, color.b, 0.12))
	if variant == "bat":
		# 蝙蝠
		draw_colored_polygon(PackedVector2Array([Vector2(-4, 0), Vector2(-13, -7), Vector2(-9, 5)]), color)
		draw_colored_polygon(PackedVector2Array([Vector2(4, 0), Vector2(13, -7), Vector2(9, 5)]), color)
		draw_circle(Vector2.ZERO, 5.0, color.darkened(0.2))
		draw_rect(Rect2(-3.0, -1.5, 2.0, 2.0), Color(1, 1, 1, 0.9))
		draw_rect(Rect2(1.0, -1.5, 2.0, 2.0), Color(1, 1, 1, 0.9))
	elif variant == "skull":
		draw_circle(Vector2.ZERO, 8.0, Color(0.90, 0.88, 0.80))
		draw_rect(Rect2(-4.0, 3.0, 8.0, 4.0), Color(0.90, 0.88, 0.80))
		draw_circle(Vector2(-3.0, -1.0), 2.2, Color(0.35, 0.95, 1.0))
		draw_circle(Vector2(3.0, -1.0), 2.2, Color(0.35, 0.95, 1.0))
	elif variant == "wisp":
		draw_circle(Vector2.ZERO, 9.0, Color(color.r, color.g, color.b, a * 0.5))
		draw_circle(Vector2.ZERO, 5.0, Color(1, 1, 1, 0.85))
		for k in range(4):
			var ang: float = t * 3.0 + float(k) * TAU / 4.0
			draw_circle(Vector2(cos(ang), sin(ang)) * 11.0, 1.8, color)
	elif variant == "prism":
		var spin: float = 1.5708 + sin(t * 1.6) * 0.28 + t * 0.25
		var hue: Array = [
			Color(1.00, 0.55, 0.62), Color(1.00, 0.72, 0.42), Color(1.00, 0.95, 0.48),
			Color(0.62, 1.00, 0.62), Color(0.48, 0.90, 1.00), Color(0.72, 0.62, 1.00),
		]
		# 环绕彩色光点
		for k0 in range(6):
			var ga: float = t * 2.2 + float(k0) * TAU / 6.0
			var gc: Color = hue[k0 % hue.size()]
			draw_circle(Vector2(cos(ga), sin(ga)) * 15.0, 4.0, Color(gc.r, gc.g, gc.b, 0.22))
		draw_circle(Vector2.ZERO, 20.0, Color(0.85, 0.95, 1.0, 0.10))
		draw_set_transform(Vector2.ZERO, spin, Vector2.ONE)
		# 剑身：6 段彩虹渐变
		for k in range(6):
			var y0: float = -21.0 + float(k) * 4.0
			var hw: float = 3.8 - float(k) * 0.34
			var bc: Color = hue[k % hue.size()]
			draw_rect(Rect2(-hw, y0, hw * 2.0, 4.2), bc)
			draw_rect(Rect2(-hw, y0, hw * 0.7, 4.2), Color(1, 1, 1, 0.35))
		# 剑尖
		draw_colored_polygon(PackedVector2Array([
			Vector2(0.0, -26.0), Vector2(-3.8, -21.0), Vector2(3.8, -21.0),
		]), hue[0])
		# 护手 / 剑柄 / 宝珠
		draw_rect(Rect2(-7.5, 3.6, 15.0, 2.8), Color(0.96, 0.86, 0.46))
		draw_rect(Rect2(-1.9, 6.4, 3.8, 7.0), Color(0.42, 0.28, 0.20))
		draw_circle(Vector2(0.0, 14.4), 2.8, Color(1.0, 1.0, 0.92, 0.95))
		draw_circle(Vector2(0.0, 14.4), 5.0, Color(1.0, 0.95, 0.6, 0.20))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# 剑刃上流动的高光
		var hl: float = fmod(t * 0.8, 1.0)
		draw_circle(Vector2(0.0, 6.0 - hl * 26.0), 2.2, Color(1, 1, 1, 0.55))

	elif variant == "void":
		draw_circle(Vector2.ZERO, 10.0, Color(0.30, 0.18, 0.40, 0.7))
		draw_arc(Vector2.ZERO, 9.0, t * 4.0, t * 4.0 + 4.4, 18, color, 2.0)
		draw_circle(Vector2.ZERO, 3.0, Color(1, 0.9, 1, 0.9))
	else:
		# imp / tide：小恶魔造型
		draw_colored_polygon(PackedVector2Array([
			Vector2(-8, 6), Vector2(-2, -8), Vector2(6, 6),
		]), color)
		draw_circle(Vector2.ZERO, 6.0, color.darkened(0.15))
		draw_rect(Rect2(-4.0, -2.0, 2.4, 2.4), Color(1.0, 0.95, 0.6))
		draw_rect(Rect2(1.6, -2.0, 2.4, 2.4), Color(1.0, 0.95, 0.6))
		draw_colored_polygon(PackedVector2Array([Vector2(-5, -4), Vector2(-8, -11), Vector2(-1, -6)]), color.darkened(0.3))
	# 剩余时间条
	var ratio: float = clampf(life / 20.0, 0.0, 1.0)
	draw_rect(Rect2(-11.0, 14.0, 22.0, 2.4), Color(0.05, 0.05, 0.08, 0.8))
	draw_rect(Rect2(-11.0, 14.0, 22.0 * ratio, 2.4), Color(color.r, color.g, color.b, 0.9))
