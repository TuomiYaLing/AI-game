extends Node2D
## 敌人：史莱姆 / 僵尸 / 哥布林（含精英变体）

const Art = preload("res://scripts/art.gd")
const TILE := 32

var game = null
var level = null
var kind := "slime"
var family := "walker"
var flies := false
var boss := false
var elem := ""
var status: Dictionary = {}
var status_cd: Dictionary = {}
var atk_cd := 1.2
var can_split := true
var infinite_hp := false
var frozen := false
var confuse_dir := 0.0
var confuse_dir_t := 0.0
var elite := false
var hp := 40.0
var max_hp := 40.0
var size := Vector2(26.0, 26.0)
var vel := Vector2.ZERO
var on_ground := false
var facing := -1.0
var state := "idle"
var t := 0.0
var phase := 0.0
var state_time := 0.0
var cooldown := 0.0
var hop_timer := 0.5
var squash := 0.0
var atk_time := 0.0
var atk_total := 0.3
var stun := 0.0
var parry_stun := 0.0
var flash := 0.0
var dead := false
var dead_timer := 0.0
var dmg_mult := 1.0
var defense := 0.0
var contact_cd := 0.0
var base_dmg := 9.0
var glow: Sprite2D = null
var apply_quality_glow := true
var draw_scale := 1.0
var spawn_anim := 0.0


func setup(p_game, p_level, p_kind: String, p_pos: Vector2, p_elite: bool = false, p_mult: float = 1.0) -> void:
	game = p_game
	level = p_level
	kind = p_kind
	elite = p_elite
	position = p_pos
	t = randf() * 4.0

	family = "walker"
	flies = false
	boss = false
	elem = ""
	match kind:
		"slime":
			size = Vector2(28.0, 18.0)
			max_hp = 38.0
			base_dmg = 9.0
			hop_timer = randf() * 0.6
			family = "slime"
		"slime_mini":
			size = Vector2(19.0, 13.0)
			max_hp = 16.0
			base_dmg = 6.0
			hop_timer = randf() * 0.5
			family = "slime"
		"slime_blue":
			size = Vector2(28.0, 18.0)
			max_hp = 46.0
			base_dmg = 10.0
			hop_timer = randf() * 0.6
			family = "slime"
			elem = "water"
		"slime_red":
			size = Vector2(28.0, 18.0)
			max_hp = 44.0
			base_dmg = 12.0
			hop_timer = randf() * 0.6
			family = "slime"
			elem = "fire"
		"slime_metal":
			size = Vector2(28.0, 18.0)
			max_hp = 50.0
			base_dmg = 12.0
			hop_timer = randf() * 0.6
			family = "slime"
			elem = "metal"
		"slime_wood":
			size = Vector2(28.0, 18.0)
			max_hp = 46.0
			base_dmg = 10.0
			hop_timer = randf() * 0.6
			family = "slime"
			elem = "wood"
		"slime_earth":
			size = Vector2(30.0, 20.0)
			max_hp = 62.0
			base_dmg = 13.0
			hop_timer = randf() * 0.6
			family = "slime"
			elem = "earth"
		"slime_king":
			size = Vector2(48.0, 34.0)
			max_hp = 460.0
			base_dmg = 20.0
			hop_timer = randf() * 0.6
			family = "slime"
			elem = "earth"
			boss = true
		"slime_queen":
			size = Vector2(44.0, 32.0)
			max_hp = 400.0
			base_dmg = 18.0
			hop_timer = randf() * 0.6
			family = "slime"
			elem = "poison"
			boss = true
		"zombie":
			size = Vector2(24.0, 44.0)
			max_hp = 74.0
			base_dmg = 14.0
		"skeleton":
			size = Vector2(24.0, 42.0)
			max_hp = 58.0
			base_dmg = 13.0
			family = "walker"
			elem = "bone"
		"flesh":
			size = Vector2(30.0, 40.0)
			max_hp = 150.0
			base_dmg = 18.0
			family = "walker"
			elem = "flesh"
		"goblin":
			size = Vector2(22.0, 36.0)
			max_hp = 46.0
			base_dmg = 10.0
		"drake_small":
			size = Vector2(46.0, 26.0)
			max_hp = 78.0
			base_dmg = 12.0
			family = "drake"
			flies = true
			elem = "fire"
		"drake_large":
			size = Vector2(72.0, 40.0)
			max_hp = 210.0
			base_dmg = 18.0
			family = "drake"
			flies = true
			elem = "fire"
		"drake_king":
			size = Vector2(168.0, 96.0)
			max_hp = 720.0
			base_dmg = 28.0
			family = "drake"
			flies = true
			elem = "fire"
			boss = true
		"seadrake_small":
			size = Vector2(52.0, 30.0)
			max_hp = 92.0
			base_dmg = 11.0
			family = "seadrake"
			flies = false
			elem = "water"
		"seadrake_large":
			size = Vector2(84.0, 46.0)
			max_hp = 240.0
			base_dmg = 17.0
			family = "seadrake"
			flies = false
			elem = "water"
		"seadrake_king":
			size = Vector2(132.0, 74.0)
			max_hp = 700.0
			base_dmg = 25.0
			family = "seadrake"
			flies = false
			elem = "water"
			boss = true
		_:
			size = Vector2(24.0, 30.0)
			max_hp = 40.0

	max_hp *= p_mult
	hp = max_hp
	dmg_mult = 1.0 + (p_mult - 1.0) * 0.45
	defense = clampf((p_mult - 1.0) * 0.05, 0.0, 0.7)
	if elite:
		max_hp *= 2.7
		hp = max_hp
		base_dmg *= 1.5
		draw_scale = 1.32
		size *= 1.25
		var glow_col := Color(0.75, 0.42, 1.0, 0.55)
		glow = Art.make_glow(glow_col, 120.0)
		glow.position = Vector2(0.0, -size.y * 0.5)
		glow.visible = apply_quality_glow
		add_child(glow)
	spawn_anim = 0.0


## 画质：低画质关闭精英怪的辉光
func apply_quality(q: int) -> void:
	apply_quality_glow = q > 0
	if glow != null and is_instance_valid(glow):
		glow.visible = apply_quality_glow


func rect() -> Rect2:
	return Rect2(position.x - size.x * 0.5, position.y - size.y, size.x, size.y)


# ---------------------------------------------------------------- 更新
func update(dt: float, player) -> void:
	if frozen:
		flash = maxf(0.0, flash - dt * 3.6)
		var fres: Dictionary = level.move_body(position, size, Vector2(0, 240.0) * dt, false)
		position = fres["pos"]
		queue_redraw()
		return
	t += dt
	phase += absf(vel.x) * dt * 0.014
	flash = maxf(0.0, flash - dt * 3.6)
	contact_cd = maxf(0.0, contact_cd - dt)
	parry_stun = maxf(0.0, parry_stun - dt)
	if spawn_anim < 1.0:
		spawn_anim = minf(1.0, spawn_anim + dt * 4.0)

	if dead:
		dead_timer += dt
		vel.y = minf(1100.0, vel.y + 2200.0 * dt)
		var dres: Dictionary = level.move_body(position, size, vel * dt, false)
		position = dres["pos"]
		if bool(dres["on_ground"]):
			vel.x = move_toward(vel.x, 0.0, 1400.0 * dt)
		queue_redraw()
		return

	if glow != null:
		var m: Color = glow.modulate
		m.a = 0.45 + 0.18 * sin(t * 5.0)
		glow.modulate = m

	_update_status(dt)

	if stun > 0.0:
		stun -= dt
		state = "stun"
		vel.x = move_toward(vel.x, 0.0, 800.0 * dt)
		_physics(dt)
		if stun <= 0.0:
			state = "idle"
			state_time = 0.0
			hop_timer = 0.35
		queue_redraw()
		return

	if player == null or player.dead:
		vel.x = move_toward(vel.x, 0.0, 600.0 * dt)
		_physics(dt)
		state = "idle"
		queue_redraw()
		return

	# 混乱：完全丢失目标，5 秒内只乱走，不追击也不攻击
	if has_status("confuse"):
		_confused_wander(dt)
		_physics(dt)
		queue_redraw()
		return

	if has_status("gather") and game != null and player != null:
		var anchors: Array = []
		for gi in range(game.enemies.size()):
			var ge = game.enemies[gi]
			if ge == null or not is_instance_valid(ge) or ge == dead or ge == self:
				continue
			if ge.has_status("gather"):
				anchors.append(ge)
		if anchors.size() > 0:
			var tgt_e = anchors[0]
			var dxg: float = tgt_e.position.x - position.x
			if absf(dxg) > 18.0:
				vel.x = move_toward(vel.x, signf(dxg) * 150.0, 600.0 * dt)

	match family:
		"slime":
			_ai_slime(dt, player)
		"drake":
			_ai_flier(dt, player, true)
		"seadrake":
			_ai_ground_serpent(dt, player)
		_:
			if kind == "goblin":
				_ai_goblin(dt, player)
			else:
				_ai_zombie(dt, player)

	_physics(dt)
	_touch_damage(player)
	queue_redraw()


func _physics(dt: float) -> void:
	if has_status("root"):
		vel.x = 0.0
		if game != null and randf() < dt * 6.0:
			game.fx.spark_spawn(position + Vector2(0, -size.y * 0.5), Vector2(0, -1), 1, Color(0.62, 0.86, 0.55))
	if flies:
		vel.y = clampf(vel.y, -260.0, 260.0)
	else:
		vel.y = minf(1100.0, vel.y + 2300.0 * dt)
	var res: Dictionary = level.move_body(position, size, vel * dt, false)
	position = res["pos"]
	if bool(res["hit_x"]):
		vel.x = 0.0
	if bool(res["on_ground"]):
		if vel.y > 0.0:
			vel.y = 0.0
		on_ground = true
	else:
		on_ground = false
	if bool(res["ceiling"]) and vel.y < 0.0:
		vel.y = 0.0


# ---------------------------------------------------------------- 史莱姆 AI

# ---------------------------------------------------------------- 状态效果
const STATUS_DEFS := {
	"burn": {"name": "灼烧", "dps": 6.0, "dur": 5.0, "col": Color(1.0, 0.52, 0.20)},
	"slow": {"name": "缓速", "dps": 0.0, "dur": 5.0, "col": Color(0.52, 0.86, 1.0)},
	"devour": {"name": "吞噬", "dps": 3.0, "dur": 5.0, "col": Color(0.62, 1.0, 0.42)},
	"confuse": {"name": "混乱", "dps": 0.0, "dur": 5.0, "col": Color(0.92, 0.62, 1.0)},
	"shock": {"name": "电击", "dps": 4.0, "dur": 5.0, "col": Color(0.85, 0.94, 1.0)},
	"root": {"name": "定身", "dps": 0.0, "dur": 5.0, "col": Color(0.62, 0.86, 0.55)},
	"gather": {"name": "聚金", "dps": 0.0, "dur": 5.0, "col": Color(1.0, 0.92, 0.55)},
}


## 给怪物挂状态（重复挂同一状态会刷新时间；结束后有 3 秒冷却）
func apply_status(id: String, dur: float = 5.0) -> void:
	if id == "" or not STATUS_DEFS.has(id):
		return
	if float(status_cd.get(id, 0.0)) > 0.0:
		return
	status[id] = maxf(float(status.get(id, 0.0)), dur)
	if game != null:
		var d: Dictionary = STATUS_DEFS[id]
		game.fx.text(position + Vector2(0, -size.y - 14.0), str(d["name"]), d["col"], 16)


func has_status(id: String) -> bool:
	return float(status.get(id, 0.0)) > 0.0


func _update_status(dt: float) -> void:
	var keys: Array = status_cd.keys()
	for i in range(keys.size()):
		var k: String = str(keys[i])
		var v: float = float(status_cd[k]) - dt
		if v <= 0.0:
			status_cd.erase(k)
		else:
			status_cd[k] = v
	var sks: Array = status.keys()
	for i in range(sks.size()):
		var sid: String = str(sks[i])
		var left: float = float(status[sid]) - dt
		var d: Dictionary = STATUS_DEFS[sid]
		var dps: float = float(d["dps"])
		if dps > 0.0 and not dead:
			hp -= dps * dt
			if randf() < dt * 7.0 and game != null:
				game.fx.spark_spawn(position + Vector2(randf_range(-size.x * 0.35, size.x * 0.35), -size.y * 0.5), Vector2(0, -1), 1, d["col"])
			if hp <= 0.0:
				hp = 0.0
				if not dead:
					die()
				return
		if left <= 0.0:
			status.erase(sid)
			status_cd[sid] = 2.0
		else:
			status[sid] = left


## 缓速：速度 ×0.8
func _speed_mul() -> float:
	if has_status("slow"):
		return 0.8
	return 1.0



## 混乱时的乱走：随机换个方向，偶尔停一下，不会靠近玩家
func _confused_wander(dt: float) -> void:
	state = "idle"
	confuse_dir_t -= dt
	if confuse_dir_t <= 0.0:
		confuse_dir_t = randf_range(0.35, 0.9)
		confuse_dir = [-1.0, 0.0, 1.0][randi() % 3]
	var spd: float = 46.0 * _speed_mul()
	vel.x = move_toward(vel.x, confuse_dir * spd, 420.0 * dt)
	if confuse_dir == 0.0:
		vel.x = move_toward(vel.x, 0.0, 600.0 * dt)
	if game != null and randf() < dt * 3.0:
		game.fx.spark_spawn(position + Vector2(0, -size.y * 0.6), Vector2(0, -1), 1, Color(0.92, 0.62, 1.0))
## 海龙：只能在地面爬行，靠近后喷水柱
func _ai_ground_serpent(dt: float, player) -> void:
	if player == null:
		return
	var dx: float = player.position.x - position.x
	var adx: float = absf(dx)
	var dir: float = signf(dx)
	if dir == 0.0:
		dir = 1.0
	facing = dir
	var spd: float = (62.0 + (20.0 if boss else 0.0)) * _speed_mul()
	if has_status("confuse"):
		dir = sin(t * 2.1)
		adx = 400.0
	if adx > 230.0:
		vel.x = move_toward(vel.x, dir * spd, 520.0 * dt)
	else:
		vel.x = move_toward(vel.x, 0.0, 700.0 * dt)
	# 遇到墙跳一下
	if _wall_ahead() and on_ground:
		vel.y = -430.0
	atk_cd -= dt
	if atk_cd <= 0.0 and adx < 470.0 and not has_status("confuse"):
		atk_cd = 1.8 if boss else 2.5
		var muzzle: Vector2 = position + Vector2(dir * size.x * 0.35, -size.y * 0.62)
		var aimv: Vector2 = (player.position + Vector2(0, -player.size.y * 0.5) - muzzle).normalized()
		game.spawn_shot("element", muzzle, aimv * 440.0, base_dmg * 0.7 * dmg_mult, false, 1.15, "water", 0)
		game.sfx_play("magic", 1.05, -8.0)
		game.fx.spark_spawn(muzzle, aimv, 8, Color(0.5, 0.88, 1.0))


## 飞行怪（飞龙）：保持距离并喷吐火球
func _ai_flier(dt: float, player, is_fire: bool) -> void:
	if player == null:
		return
	var to_p: Vector2 = player.position + Vector2(0, -player.size.y * 0.5) - (position + Vector2(0, -size.y * 0.5))
	var dist: float = to_p.length()
	var dir: Vector2 = to_p.normalized()
	var want_dist: float = 190.0 if not boss else 230.0
	var spd: float = (74.0 + (28.0 if boss else 0.0)) * _speed_mul()
	if has_status("confuse"):
		dir = Vector2(sin(t * 2.3), cos(t * 2.1)).normalized()
		want_dist += 40.0
	if dist > want_dist + 40.0:
		vel.x = move_toward(vel.x, dir.x * spd, 420.0 * dt)
	elif dist < want_dist - 40.0:
		vel.x = move_toward(vel.x, -dir.x * spd * 0.8, 420.0 * dt)
	else:
		vel.x = move_toward(vel.x, 0.0, 400.0 * dt)
	# 悬停高度
	var target_y: float = -0.55 if dist > 120.0 else clampf(dir.y, -0.8, 0.5)
	vel.y = move_toward(vel.y, target_y * 120.0 + sin(t * 2.2) * 26.0, 380.0 * dt)
	# 喷吐
	atk_cd -= dt
	if atk_cd <= 0.0 and dist < 460.0 and not has_status("confuse"):
		atk_cd = (2.6 if not boss else 2.0) - 0.4
		var muzzle: Vector2 = position + Vector2(0, -size.y * 0.42) + dir * 20.0
		var el: String = "fire" if is_fire else "water"
		game.spawn_shot("element", muzzle, dir * 470.0, base_dmg * 0.7 * dmg_mult, false, 1.15, el, 0)
		game.sfx_play("magic" if not is_fire else "stand", 1.1, -8.0)
		game.fx.spark_spawn(muzzle, dir, 8, Color(1.0, 0.6, 0.3) if is_fire else Color(0.5, 0.85, 1.0))
func _ai_slime(dt: float, player) -> void:
	var dist: float = player.position.x - position.x
	var adist: float = absf(dist)
	var dy: float = absf(player.position.y - position.y)
	if adist > 6.0:
		facing = signf(dist)
	squash = move_toward(squash, 0.0, dt * 2.4)

	if state == "idle" or state == "":
		hop_timer -= dt
		vel.x = move_toward(vel.x, 0.0, 900.0 * dt)
		if hop_timer <= 0.0 and adist < 440.0 and dy < 190.0:
			state = "wind"
			state_time = 0.0
	elif state == "wind":
		state_time += dt
		squash = minf(0.6, squash + dt * 3.2)
		vel.x = 0.0
		if state_time > 0.30:
			state = "air"
			vel.y = -520.0 - (60.0 if kind == "slime_mini" else 0.0)
			vel.x = facing * clampf(adist * 0.95, 110.0, 290.0)
			game.sfx_play("hop", 1.0 + randf() * 0.2, -8.0)
	elif state == "air":
		if on_ground:
			state = "idle"
			hop_timer = 0.75 + randf() * 0.5
			squash = 0.62
			game.fx.spark_spawn(position + Vector2(0, -4), Vector2(0, -1), 5, Color(0.4, 0.8, 0.4))
			if adist < 62.0 and absf(player.position.y - position.y) < 60.0:
				_attack_player(player, base_dmg, 66.0, 70.0)


# ---------------------------------------------------------------- 僵尸 AI
func _ai_zombie(dt: float, player) -> void:
	var dist: float = player.position.x - position.x
	var adist: float = absf(dist)
	var dy: float = player.position.y - position.y
	if adist > 8.0:
		facing = signf(dist)
	cooldown = maxf(0.0, cooldown - dt)

	if state == "walk" or state == "" or state == "idle":
		state = "walk"
		var want: float = facing * 78.0
		if _no_floor_ahead() and on_ground:
			vel.x = move_toward(vel.x, 0.0, 500.0 * dt)
		else:
			vel.x = move_toward(vel.x, want, 640.0 * dt)
		if adist < 108.0 and absf(dy) < 90.0 and cooldown <= 0.0 and on_ground:
			state = "wind"
			state_time = 0.0
			game.sfx_play("groan", 0.9, -12.0)
	elif state == "wind":
		state_time += dt
		vel.x = move_toward(vel.x, 0.0, 1100.0 * dt)
		if state_time > 0.30:
			state = "lunge"
			state_time = 0.0
			vel.x = facing * 350.0
			game.sfx_play("lunge", 0.85, -4.0)
	elif state == "lunge":
		state_time += dt
		if state_time > 0.10 and adist < 76.0 and absf(dy) < 74.0:
			_attack_player(player, base_dmg, 78.0, 84.0)
		if state_time > 0.28:
			state = "walk"
			cooldown = 1.15 + randf() * 0.4


func _no_floor_ahead() -> bool:
	var probe_x: float = position.x + facing * (size.x * 0.5 + 8.0)
	var tx: int = int(floor(probe_x / TILE))
	var ty: int = int(floor((position.y + 6.0) / TILE))
	if level.is_solid(tx, ty) or level.is_platform(tx, ty):
		return false
	if level.is_solid(tx, ty + 1) or level.is_platform(tx, ty + 1):
		return false
	return true


# ---------------------------------------------------------------- 哥布林 AI
func _ai_goblin(dt: float, player) -> void:
	var dist: float = player.position.x - position.x
	var adist: float = absf(dist)
	var dy: float = player.position.y - position.y
	if adist > 8.0:
		facing = signf(dist)
	cooldown = maxf(0.0, cooldown - dt)

	if state == "idle" or state == "" or state == "walk":
		if adist < 132.0:
			vel.x = move_toward(vel.x, -facing * 125.0, 900.0 * dt)
		elif adist > 250.0:
			vel.x = move_toward(vel.x, facing * 135.0, 900.0 * dt)
		else:
			vel.x = move_toward(vel.x, 0.0, 1100.0 * dt)
		if _wall_ahead() and on_ground:
			vel.y = -560.0
		if cooldown <= 0.0 and adist < 430.0 and absf(dy) < 150.0:
			state = "wind"
			state_time = 0.0
	elif state == "wind":
		state_time += dt
		vel.x = move_toward(vel.x, 0.0, 1400.0 * dt)
		if state_time > 0.28:
			state = "idle"
			cooldown = 1.5 + randf() * 0.9
			_throw_knife(player)


func _wall_ahead() -> bool:
	var probe_x: float = position.x + facing * (size.x * 0.5 + 6.0)
	var tx: int = int(floor(probe_x / TILE))
	var ty0: int = int(floor((position.y - size.y * 0.6) / TILE))
	var ty1: int = int(floor((position.y - 6.0) / TILE))
	for ty in range(ty0, ty1 + 1):
		if level.is_solid(tx, ty):
			return true
	return false


# ---------------------------------------------------------------- 攻击 / 伤害
func _attack_player(player, dmg: float, reach: float, height: float) -> void:
	if player == null or player.dead:
		return
	var center: Vector2 = position + Vector2(facing * reach * 0.32, -size.y * 0.5)
	var hit := Rect2(center - Vector2(reach * 0.5, height * 0.5), Vector2(reach, height))
	if not hit.intersects(player.rect()):
		return
	var res: String = player.hurt(dmg * dmg_mult, position, "melee", self)
	if res == "parry":
		stun = 1.5
		parry_stun = 1.5
		state = "stun"
		flash = 1.0
		game.sfx_play("stun", 1.1)
		game.fx.ring_spawn(position + Vector2(0, -size.y * 0.5), 54.0, Color(1.0, 0.85, 0.4))


func _touch_damage(player) -> void:
	if contact_cd > 0.0 or player == null or player.dead:
		return
	if not rect().intersects(player.rect()):
		return
	contact_cd = 0.85
	var res: String = player.hurt(base_dmg * 0.55 * dmg_mult, position, "melee", self)
	if res == "parry":
		stun = 1.4
		parry_stun = 1.4
		state = "stun"
		flash = 1.0
	elif res == "block":
		var push: float = -facing * 130.0
		vel.x = push


func _throw_knife(player) -> void:
	var dirv: Vector2 = (player.position + Vector2(0, -22.0) - (position + Vector2(0, -size.y * 0.7))).normalized()
	var muzzle: Vector2 = position + Vector2(facing * 14.0, -size.y * 0.72)
	game.spawn_shot("knife", muzzle, dirv * 470.0, base_dmg * 0.95, false, 1.0)
	game.sfx_play("throw", 1.0 + randf() * 0.15, -6.0)
	game.fx.spark_spawn(muzzle, dirv, 4, Color(0.9, 0.8, 0.5))


## 五行克制：火>木>土>水>火，金对金
func _elem_mul(atk: String, def: String) -> float:
	if atk == "" or def == "":
		return 1.0
	var beats: Dictionary = {"fire": "wood", "wood": "earth", "earth": "water", "water": "fire", "metal": "metal"}
	if str(beats.get(atk, "")) == def:
		return 1.5
	if str(beats.get(def, "")) == atk:
		return 0.7
	return 1.0


func hurt(dmg: float, dir: Vector2, knock: float, stun_time: float, atk_elem: String = "") -> String:
	if dead:
		return "none"
	var real: float = dmg * (1.0 - defense) * _elem_mul(atk_elem, elem)
	if game != null:
		game.note_damage(real)
	hp -= real
	flash = 1.0
	state_time = 0.0
	var crit := false
	if parry_stun > 0.0:
		crit = true
		hp -= real * 0.5
	# 击退
	var resist: float = 1.0
	if kind == "zombie" or kind == "flesh":
		resist = 0.45
	if boss:
		resist *= 0.35
	if flies:
		resist *= 0.7
	if elite:
		resist *= 0.55
	vel.x = dir.x * knock * resist
	if kind != "zombie" and kind != "flesh" and on_ground and not flies:
		vel.y = -90.0 * resist
	stun = maxf(stun, stun_time * resist) if stun_time > 0.0 else stun
	# 伤害数字
	var num_col := Color(1.0, 0.95, 0.88)
	# 元素伤害：数字用元素配色；普通攻击保持白色
	if atk_elem == "fire":
		num_col = Color(1.0, 0.62, 0.30)
	elif atk_elem == "water":
		num_col = Color(0.45, 0.80, 1.0)
	elif atk_elem == "earth":
		num_col = Color(0.90, 0.72, 0.42)
	elif atk_elem == "metal":
		num_col = Color(0.92, 0.92, 0.78)
	elif atk_elem == "wood":
		num_col = Color(0.55, 1.0, 0.60)
	elif atk_elem == "shock":
		num_col = Color(0.88, 0.96, 1.0)
	elif atk_elem == "arcane":
		num_col = Color(0.78, 0.70, 1.0)
	var num_size := 17
	var cs: float = 1.0
	if game != null:
		cs = game.combo_scale()
	num_size = int(float(num_size) * cs)
	if crit:
		num_col = Color(1.0, 0.82, 0.32)
		num_size = 23
	game.fx.text(position + Vector2(0, -size.y - 12.0), str(int(real * (1.5 if crit else 1.0))), num_col, num_size)
	if infinite_hp:
		hp = max_hp
		flash = 1.0
		return "crit" if crit else "hit"
	if hp <= 0.0:
		die()
		return "crit" if crit else "kill"
	game.fx.blood_spawn(position + Vector2(0, -size.y * 0.55), dir, 10, _blood_color())
	game.sfx_play("hit", 1.0 + randf() * 0.1, -2.0)
	return "crit" if crit else "hit"


func _blood_color() -> Color:
	if family == "slime":
		if elem == "metal":
			return Color(0.86, 0.84, 0.72)
		if elem == "wood":
			return Color(0.42, 0.82, 0.44)
		if elem == "earth":
			return Color(0.74, 0.62, 0.36)
		if elem == "water":
			return Color(0.28, 0.62, 0.92)
		if elem == "fire":
			return Color(0.92, 0.36, 0.24)
		if elem == "earth":
			return Color(0.68, 0.54, 0.28)
		if elem == "poison":
			return Color(0.62, 0.42, 0.86)
		return Color(0.30, 0.75, 0.30)
	if family == "seadrake":
		return Color(0.24, 0.58, 0.86)
	if family == "drake":
		return Color(0.86, 0.32, 0.18)
	if elem == "bone":
		return Color(0.86, 0.84, 0.76)
	return Color(0.52, 0.06, 0.10)


func die() -> void:
	if dead:
		return
	dead = true
	state = "dead"
	vel.x = -facing * 90.0
	vel.y = -140.0
	game.sfx_play("kill", 1.0, -2.0)
	game.fx.blood_spawn(position + Vector2(0, -size.y * 0.5), Vector2(0, -1), 22, _blood_color())
	game.fx.ring_spawn(position + Vector2(0, -size.y * 0.5), 40.0, _blood_color())
	game.on_enemy_killed(self)
	# 分裂只允许发生一次：子代 can_split = false，避免无限分裂
	if not can_split or elite:
		return
	if kind == "slime":
		for i in range(2):
			var off: float = -26.0 + float(i) * 52.0
			_spawn_no_split("slime_mini", position + Vector2(off, -12.0), 1.0)
	elif kind == "slime_blue" or kind == "slime_red" or kind == "slime_metal" or kind == "slime_wood" or kind == "slime_earth":
		for i in range(2):
			var off2: float = -26.0 + float(i) * 52.0
			_spawn_no_split(kind, position + Vector2(off2, -12.0), 0.6)
	elif kind == "slime_king" or kind == "slime_queen":
		# 王/后死亡分裂出一批小史莱姆（不再继续分裂）
		for i in range(6):
			var ox: float = -60.0 + float(i) * 24.0
			var mini_kind: String = "slime_red" if kind == "slime_king" else "slime_blue"
			_spawn_no_split(mini_kind, position + Vector2(ox, -14.0), 0.7)
		game.shake(10.0)


## 生成一只"不会再分裂"的子代史莱姆
func _spawn_no_split(kind_id: String, pos: Vector2, mult: float) -> void:
	var before: int = game.enemies.size()
	game.spawn_enemy(kind_id, pos, false, mult)
	if game.enemies.size() > before:
		var e = game.enemies[game.enemies.size() - 1]
		if e != null and is_instance_valid(e):
			e.can_split = false


# ---------------------------------------------------------------- 绘制
func _draw() -> void:
	var sc: float = draw_scale * (0.55 + 0.45 * spawn_anim)
	if sc < 0.05:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(sc, sc))
	var a: Dictionary = {
		"t": t,
		"face": facing,
		"flash": flash,
		"state": state,
		"run": phase,
		"atk": -1.0,
		"squash": squash,
		"scale": 1.0 if kind == "slime" else 0.68,
	}
	if state == "wind" or state == "lunge" or state == "throw":
		a["atk"] = clampf(state_time / maxf(0.01, 0.3), 0.0, 1.0)
	if family == "slime":
		var sc2: Color = Color(0.32, 0.72, 0.34)
		if elem == "metal":
			sc2 = Color(0.84, 0.84, 0.78)
		elif elem == "wood":
			sc2 = Color(0.40, 0.80, 0.42)
		elif elem == "earth":
			sc2 = Color(0.74, 0.60, 0.34)
		elif elem == "water":
			sc2 = Color(0.30, 0.60, 0.94)
		elif elem == "metal":
			sc2 = Color(0.84, 0.84, 0.78)
		elif elem == "wood":
			sc2 = Color(0.40, 0.80, 0.42)
		elif elem == "earth":
			sc2 = Color(0.74, 0.60, 0.34)
		elif elem == "fire":
			sc2 = Color(0.92, 0.34, 0.26)
		elif elem == "earth":
			sc2 = Color(0.70, 0.56, 0.30)
		elif elem == "poison":
			sc2 = Color(0.66, 0.40, 0.90)
		a["col"] = sc2
		a["scale"] = 1.0 if kind != "slime_mini" else 0.68
		if kind == "slime_king" or kind == "slime_queen":
			a["scale"] = 1.6
			a["crown"] = true
		Art.draw_slime(self, a)
	elif family == "drake":
		if kind == "drake_king":
			a["scale"] = size.x / 100.0
			Art.draw_drake_king(self, a)
		else:
			a["scale"] = size.x / 46.0
			Art.draw_drake(self, a, true)
	elif family == "seadrake":
		a["scale"] = size.x / 52.0
		Art.draw_seadragon(self, a, boss)
	elif kind == "skeleton":
		Art.draw_skeleton(self, a)
	elif kind == "flesh":
		Art.draw_flesh(self, a)
	elif kind == "zombie":
		Art.draw_zombie(self, a)
	else:
		Art.draw_goblin(self, a)

	# 精英光环
	if elite:
		draw_circle(Vector2(0, -size.y * 0.5 / sc), size.x * 0.62 / sc, Color(0.7, 0.4, 1.0, 0.07))
		draw_circle(Vector2(0, -size.y * 0.5 / sc), size.x * 0.42 / sc, Color(0.85, 0.55, 1.0, 0.06))

	# 血条
	if hp < max_hp and not dead:
		var w: float = 30.0 / sc
		var y: float = (-size.y - 12.0) / sc
		draw_rect(Rect2(-w * 0.5, y, w, 4.0), Color(0.05, 0.04, 0.06, 0.85))
		draw_rect(Rect2(-w * 0.5 + 1.0, y + 1.0, (w - 2.0) * clampf(hp / max_hp, 0.0, 1.0), 2.0), Color(0.85, 0.22, 0.24))
