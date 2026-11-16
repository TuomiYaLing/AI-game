extends Node2D
## 玩家：多武器（短剑/长剑/唐刀/武士刀 · 弓/冲锋枪/步枪/加特林/狙击枪 · 铁盾/反伤盾/闪避盾）
## 跳跃、二段跳（技能）、下蹲、翻滚、喝药、魔法保护、技能加成

const Art = preload("res://scripts/art.gd")
const W = preload("res://scripts/weapons.gd")
const TILE := 32

const SPEED := 305.0
const ACCEL := 2700.0
const FRICTION := 2900.0
const AIR_ACCEL := 1800.0
const JUMP_VEL := -765.0
const GRAVITY := 2450.0
const MAX_FALL := 1250.0
const CROUCH_SPEED := 115.0
const ROLL_SPEED := 650.0
const ROLL_TIME := 0.28
const ROLL_CD := 0.42
const STAND_H := 46.0
const CROUCH_H := 27.0
# ---- 翅膀飞行参数
const FLY_FALL := 0.0        # 0 = 完全悬停（松手就一直飘着，不会往下掉）
const FLY_RISE := -549.0   # 与横向飞行速度一致（305 * 1.8）
const FLY_DIVE := 549.0    # 与横向飞行速度一致
const FLY_SPEED_MUL := 1.8   # 原 +20% 再 +50% → 飞行移速 +80%

var game = null
var level = null

# ---- 装备
var sword_id := "long"
var ranged_id := "bow"
var shield_id := "iron"

# ---- 远程武器状态
var ammo := 0
var reloading := 0.0
var reload_total := 0.0
var fire_cd := 0.0
var muzzle_flash := 0.0

var vel := Vector2.ZERO
var size := Vector2(20.0, 46.0)
var on_ground := false
var facing := 1.0
var hp := 100.0
var max_hp := 100.0
var flasks := 3
var max_flasks := 3
var coins := 0

var coyote := 0.0
var jump_buffer := 0.0
var invul := 0.0
var roll_time := 0.0
var roll_cd := 0.0
var atk_time := 0.0
var atk_total := 0.3
var atk_stage := 0
var atk_hit_ids := {}
var combo_window := 0.0
var attack_aim := 0.0
var bow_active := false
var bow_charge := 0.0
var guard := 0.0
var parry_window := 0.0
var heal_time := 0.0
var hurt_time := 0.0
var flash := 0.0
var dead := false
var crouch_amt := 0.0
var run_phase := 0.0
var t := 0.0
var aim := 0.0
var step_visual := 0.0
var state := "idle"
var last_safe := Vector2.ZERO
var flame_glow: Sprite2D = null
var footstep_cd := 0.0
var air_jumps := 0
var crouch_hold := 0.0
var platform_drop := 0.0
var bleed_time := 0.0
var mana := 60.0
var max_mana := 60.0
var mana_idle := 0.0
var err_imm := 0.0
var err_cd := 0.0
var wall_dir := 0
var wall_slide := 0.0
var wall_jump_cd := 0.0
var flying := 0.0
var dodge_cd := 0.0


func setup(p_game, p_level, p_pos: Vector2) -> void:
	game = p_game
	level = p_level
	position = p_pos
	last_safe = p_pos
	size = Vector2(20.0, STAND_H)
	flame_glow = Art.make_glow(Color(0.35, 0.85, 1.0, 0.30), 95.0)
	flame_glow.position = Vector2(0.0, -52.0)
	add_child(flame_glow)
	refill_ammo()


func refill_ammo() -> void:
	var g: Dictionary = W.gun(ranged_id)
	ammo = int(g["ammo"])
	reloading = 0.0
	reload_total = 0.0


func rect() -> Rect2:
	return Rect2(position.x - size.x * 0.5, position.y - size.y, size.x, size.y)


func head_pos() -> Vector2:
	return position + Vector2(0.0, -size.y * 0.62)


func aim_vec() -> Vector2:
	return Vector2(cos(aim), sin(aim))


func is_alive() -> bool:
	return not dead


# ---------------------------------------------------------------- 技能 / 倍率
func _skill(key: String) -> float:
	if game != null and game.skills != null:
		return game.skills.val(key)
	return 1.0


func _skill_flag(key: String) -> bool:
	if game != null and game.skills != null:
		return game.skills.flag(key)
	return false


func _phys_mult() -> float:
	var m := 1.0
	if game != null:
		m *= 1.0 + 0.10 * float(game.phys_level)
	return m * _skill("phys")


## 魔法伤害倍率（魔法等级 + 秘法共鸣技能）
func _magic_mult() -> float:
	var m := 1.0
	if game != null:
		m *= 1.0 + 0.10 * float(game.magic_level)
	return m * _skill("magic")


func taken_mult() -> float:
	var m := 1.0
	if game != null:
		m *= pow(0.94, float(game.defense_level))
	# 盔甲：防御力 ×20（占盾位）
	if W.SHIELDS.has(shield_id):
		var sd: Dictionary = W.SHIELDS[shield_id]
		if bool(sd.get("armor", false)):
			m /= float(sd.get("def_mult", 20.0))
	return m * _skill("taken")


func lifesteal() -> float:
	var v := 0.0
	if game != null and game.skills != null:
		v += game.skills.add_val("lifesteal")
	if game != null and game.items != null:
		v += game.items.wings_lifesteal()
	return v


## 当前翅膀类型：0 无 / 1 天使 / 2 恶魔
func wings_kind() -> int:
	if game == null or game.items == null:
		return 0
	var w: String = game.items.wing_id()
	if w == "wing_angel":
		return 1
	if w == "wing_demon":
		return 2
	return 0


## 空中可跳次数：基础 1 次（二段跳），有「跃升」技能再 +1
func air_jump_limit() -> int:
	var n: int = 1
	if _skill_flag("djump"):
		n += 1
	return n


## 检测身体两侧是否有可攀的墙：返回 -1（左手边） / 0（无） / 1（右手边）
func _detect_wall() -> int:
	if level == null:
		return 0
	var ty0: int = int(floor((position.y - size.y + 6.0) / TILE))
	var ty1: int = int(floor((position.y - 8.0) / TILE))
	var half: float = size.x * 0.5
	var sides: Array = [-1, 1]
	for i in range(sides.size()):
		var s: int = int(sides[i])
		var tx: int = int(floor((position.x + float(s) * (half + 2.0)) / TILE))
		for ty in range(ty0, ty1 + 1):
			if level.is_solid(tx, ty):
				return s
	return 0


# ---------------------------------------------------------------- 装备切换
func equip_sword(id: String) -> void:
	if W.SWORDS.has(id):
		sword_id = id
		atk_time = 0.0
		combo_window = 0.0


func equip_ranged(id: String) -> void:
	if W.has_gun(id):
		ranged_id = id
		bow_active = false
		bow_charge = 0.0
		refill_ammo()


func equip_shield(id: String) -> void:
	if W.SHIELDS.has(id):
		shield_id = id
		guard = 0.0


# ---------------------------------------------------------------- 每帧更新
func update(dt: float, inp: Dictionary) -> void:
	t += dt
	aim = inp.get("aim", 0.0)
	step_visual = move_toward(step_visual, 0.0, 340.0 * dt)
	invul = maxf(0.0, invul - dt)
	roll_cd = maxf(0.0, roll_cd - dt)
	parry_window = maxf(0.0, parry_window - dt)
	hurt_time = maxf(0.0, hurt_time - dt)
	flash = maxf(0.0, flash - dt * 3.2)
	coyote = maxf(0.0, coyote - dt)
	jump_buffer = maxf(0.0, jump_buffer - dt)
	combo_window = maxf(0.0, combo_window - dt)
	footstep_cd = maxf(0.0, footstep_cd - dt)
	dodge_cd = maxf(0.0, dodge_cd - dt)
	muzzle_flash = maxf(0.0, muzzle_flash - dt * 6.0)

	if dead:
		state = "dead"
		vel.y = minf(MAX_FALL, vel.y + GRAVITY * dt)
		var dres: Dictionary = level.move_body(position, size, vel * dt, false)
		position = dres["pos"]
		queue_redraw()
		return

	if flame_glow != null:
		var m: Color = flame_glow.modulate
		m.a = 0.26 + 0.07 * sin(t * 9.0) + (0.10 if bow_active else 0.0)
		flame_glow.modulate = m
		flame_glow.position = Vector2(0.0, -52.0 + crouch_amt * 9.0)

	# ---- 治疗
	if heal_time > 0.0:
		heal_time -= dt
		if heal_time <= 0.0:
			var heal_amt: float = 45.0 * (1.0 + 0.05 * float(game.hp_level))
			hp = minf(max_hp, hp + heal_amt)
			game.fx.text(position + Vector2(0, -70), "+" + str(int(heal_amt)), Color(0.5, 1.0, 0.6))
			game.fx.spark_spawn(position + Vector2(0, -30), Vector2(0, -1), 14, Color(0.45, 1.0, 0.5))
			game.sfx_play("heal")
	if inp.get("heal_pressed", false) and heal_time <= 0.0 and flasks > 0 and atk_time <= 0.0 and roll_time <= 0.0:
		heal_time = 0.5
		flasks -= 1
		game.sfx_play("flask")

	# ---- 朝向
	if inp.get("sword_held", false) or inp.get("bow_held", false) or inp.get("shield_held", false):
		if absf(cos(aim)) > 0.18:
			facing = signf(cos(aim))

	# ---- 输入方向
	var ax: float = 0.0
	if inp.get("left", false):
		ax -= 1.0
	if inp.get("right", false):
		ax += 1.0

	# 有翅膀悬空时，下键代表"下降"而不是下蹲
	var can_crouch_here: bool = not (wings_kind() > 0 and not on_ground)
	var want_crouch: bool = inp.get("down", false) and can_crouch_here and roll_time <= 0.0 and heal_time <= 0.0
	if want_crouch:
		crouch_amt = minf(1.0, crouch_amt + dt * 11.0)
	elif can_stand():
		crouch_amt = maxf(0.0, crouch_amt - dt * 11.0)
	size.y = lerpf(STAND_H, CROUCH_H, crouch_amt)
	var crouching: bool = crouch_amt > 0.55

	# ---- 翻滚
	if inp.get("roll_pressed", false) and roll_cd <= 0.0 and roll_time <= 0.0 and heal_time <= 0.0:
		roll_time = ROLL_TIME
		roll_cd = ROLL_CD
		invul = maxf(invul, ROLL_TIME + 0.04)
		bow_active = false
		bow_charge = 0.0
		game.sfx_play("roll")
		game.fx.spark_spawn(position + Vector2(0, -12), Vector2(-facing, -0.3), 10, Color(0.5, 0.55, 0.6))

	if roll_time > 0.0:
		roll_time -= dt
		vel.x = facing * ROLL_SPEED
	else:
		var target: float = 0.0
		if ax != 0.0 and heal_time <= 0.0:
			var sp: float = SPEED * _skill("speed")
			if crouching:
				sp = CROUCH_SPEED
			if bow_active:
				sp *= 0.75
			# 飞行状态下移动速度 +20%
			if wings_kind() > 0 and not on_ground and not crouching:
				sp *= FLY_SPEED_MUL
			target = ax * sp
		var acc: float = ACCEL
		if not on_ground:
			acc = AIR_ACCEL
		if absf(target) < 1.0:
			acc = FRICTION if on_ground else AIR_ACCEL * 0.6
		vel.x = move_toward(vel.x, target, acc * dt)
		if ax != 0.0 and heal_time <= 0.0:
			if not inp.get("bow_held", false) and not inp.get("shield_held", false):
				facing = ax

	# ---- 跳跃 / 穿过单向平台 / 二段跳
	var on_platform_now: bool = false
	if on_ground:
		var pty0: int = int(floor((position.y + 3.0) / TILE))
		var cx0: int = int(floor((position.x - size.x * 0.4) / TILE))
		var cx1: int = int(floor((position.x + size.x * 0.4) / TILE))
		for cxi in range(cx0, cx1 + 1):
			if level.is_platform(cxi, pty0):
				on_platform_now = true
				break
	# 站在单向平台上按住下蹲（或下蹲+跳）就会往下掉
	if on_platform_now and inp.get("down", false):
		crouch_hold += dt
	else:
		crouch_hold = 0.0
	var want_drop: bool = on_platform_now and inp.get("down", false) and (crouch_hold > 0.10 or inp.get("jump_pressed", false))
	platform_drop = maxf(0.0, platform_drop - dt)
	if want_drop:
		platform_drop = 0.22

	if inp.get("jump_pressed", false):
		jump_buffer = 0.13
	if want_drop:
		# 关键：一定要在写入 jump_buffer 之后清掉，否则下一帧会变成"空中跳"，人又被弹回平台上
		jump_buffer = 0.0

	# ---- 攀墙：检测左右是否有可攀的墙面
	wall_jump_cd = maxf(0.0, wall_jump_cd - dt)
	wall_dir = 0
	wall_slide = 0.0
	if (not on_ground) and roll_time <= 0.0:
		wall_dir = _detect_wall()
		if wall_dir != 0:
			var push_in: bool = (wall_dir < 0 and inp.get("left", false)) or (wall_dir > 0 and inp.get("right", false))
			if push_in:
				wall_slide = 1.0

	if jump_buffer > 0.0 and (on_ground or coyote > 0.0) and roll_time <= 0.0 and heal_time <= 0.0 and not want_drop:
		vel.y = JUMP_VEL
		on_ground = false
		coyote = 0.0
		jump_buffer = 0.0
		air_jumps = 0
		crouch_amt = minf(crouch_amt, 0.2)
		game.sfx_play("jump")
		game.fx.spark_spawn(position, Vector2(0, 1), 6, Color(0.45, 0.5, 0.6))
	elif jump_buffer > 0.0 and wall_dir != 0 and wall_jump_cd <= 0.0 and roll_time <= 0.0:
		# 攀墙跳跃：蹬墙向上 + 反向弹开，落地前还能再二段跳一次
		vel.y = JUMP_VEL * 0.96
		vel.x = -float(wall_dir) * 430.0
		air_jumps = 0
		jump_buffer = 0.0
		wall_jump_cd = 0.16
		game.sfx_play("roll", 1.35, -8.0)
		game.fx.spark_spawn(position + Vector2(float(wall_dir) * size.x * 0.5, -18.0), Vector2(-float(wall_dir), -0.6), 7, Color(0.86, 0.92, 1.0))
		game.fx.ring_spawn(position + Vector2(0, -16), 30.0, Color(0.8, 0.92, 1.0))
	elif jump_buffer > 0.0 and (not on_ground) and air_jumps < air_jump_limit():
		# 二段跳（基础能力）；获得「跃升」技能后还能三段跳
		vel.y = JUMP_VEL * 0.92
		air_jumps += 1
		jump_buffer = 0.0
		game.sfx_play("jump", 1.18 + 0.08 * float(air_jumps))
		game.fx.ring_spawn(position + Vector2(0, -10), 34.0, Color(0.72, 0.92, 1.0))
	if inp.get("jump_released", false) and vel.y < -230.0:
		vel.y = -230.0

	# ---- 错误之甲：100 秒免疫 / 50 秒冷却循环
	if shield_id == "armor_error":
		if err_imm > 0.0:
			err_imm -= dt
			if err_imm <= 0.0:
				err_cd = 50.0
		elif err_cd > 0.0:
			err_cd -= dt
		else:
			err_imm = 100.0
			if game != null:
				game.fx.text(position + Vector2(0, -92), "错误免疫", Color(1.0, 0.3, 0.9), 22)

	# ---- 法力：施法后 1.2 秒才回蓝，保证看得到消耗
	var mm: float = 60.0 + 18.0 * float(game.mana_level if game != null else 0)
	var add_m: float = 0.0
	var mul_m: float = 1.0
	var regen_bonus: float = 0.0
	if game != null and game.skills != null:
		add_m = game.skills.add_val("mana_add")
		mul_m = game.skills.val("mana_mult")
		regen_bonus = game.skills.add_val("mana_regen")
	if game != null and game.items != null:
		add_m += game.items.mana_max_bonus()
		regen_bonus += game.items.mana_regen()
	max_mana = maxf(10.0, (mm + add_m) * mul_m)
	mana_idle += dt
	if mana_idle > 1.2 and mana < max_mana:
		mana = minf(max_mana, mana + (11.0 + regen_bonus) * dt)
	if is_arcane_weapon() and mana < max_mana:
		mana = minf(max_mana, mana + 5.0 * dt)
	if mana > max_mana:
		mana = max_mana

	# ---- 流血（恶魔之翼的代价）
	if bleed_time > 0.0:
		bleed_time = maxf(0.0, bleed_time - dt)
		hp = maxf(1.0, hp - 5.0 * dt)
		if game != null and randf() < dt * 9.0:
			game.fx.blood_spawn(position + Vector2(randf_range(-6.0, 6.0), -16.0), Vector2(0, 1), 1, Color(0.55, 0.05, 0.08))

	# ---- 盾牌（闪避盾是被动，不举盾）
	if inp.get("shield_held", false) and shield_id != "dodge" and roll_time <= 0.0 and heal_time <= 0.0:
		if guard <= 0.01:
			parry_window = 0.20
			game.sfx_play("guard_up")
		guard = 1.0
		bow_active = false
		bow_charge = 0.0
	else:
		guard = 0.0

	# ---- 远程武器
	_update_ranged(dt, inp)

	# ---- 长剑
	if inp.get("sword_pressed", false) and atk_time <= 0.0 and roll_time <= 0.0 and heal_time <= 0.0:
		start_attack()

	if atk_time > 0.0:
		atk_time -= dt
		var progress: float = 1.0 - atk_time / maxf(0.01, atk_total)
		if progress > 0.18 and progress < 0.62:
			do_sword_hits()
		if atk_time <= 0.0:
			combo_window = 0.34

	# ---- 重力与移动
	var wk: int = wings_kind()
	var aloft: bool = wk > 0 and (not on_ground) and roll_time <= 0.0 and heal_time <= 0.0
	flying = 0.0
	if aloft:
		# 翅膀：飞到空中后一直保持漂浮（松手也不掉），可上下左右操控
		flying = 1.0
		var up_held: bool = inp.get("up", false)
		var dn_held: bool = inp.get("down", false)
		if up_held:
			vel.y = move_toward(vel.y, FLY_RISE, 4200.0 * dt)
		elif dn_held:
			vel.y = move_toward(vel.y, FLY_DIVE, 4200.0 * dt)
		elif vel.y < 0.0:
			# 上升阶段用正常重力自然减速，避免起跳被拉长
			vel.y = minf(0.0, vel.y + GRAVITY * dt)
		else:
			# 悬停：速度归零，一直停在空中
			vel.y = move_toward(vel.y, FLY_FALL, 900.0 * dt)
		if game != null and randf() < dt * 12.0:
			var wc: Color = Color(1.0, 0.96, 0.74) if wk == 1 else Color(1.0, 0.38, 0.42)
			game.fx.spark_spawn(position + Vector2(randf_range(-9.0, 9.0), -6.0), Vector2(0, 1), 1, wc)
	else:
		vel.y = minf(MAX_FALL, vel.y + GRAVITY * dt)

	# ---- 贴墙下滑
	if wall_slide > 0.0 and vel.y > 110.0:
		vel.y = 110.0
		if game != null and randf() < dt * 6.0:
			game.fx.spark_spawn(position + Vector2(float(wall_dir) * size.x * 0.5, -20.0), Vector2(0, 1), 1, Color(0.75, 0.8, 0.9))

	# 下穿平台：在 platform_drop 计时内都忽略单向平台，保证一定穿得下去
	var drop_through: bool = platform_drop > 0.0
	if drop_through and on_ground and platform_drop > 0.16:
		vel.y = maxf(vel.y, 240.0)
	if drop_through:
		on_ground = false
		coyote = 0.0
	var move: Vector2 = vel * dt
	var res: Dictionary = level.move_body(position, size, move, drop_through)
	position = res["pos"]

	if bool(res["hit_x"]):
		if on_ground:
			var stepped: Vector2 = level.try_step_up(position, size, signf(vel.x))
			if stepped != position:
				position = stepped
				step_visual = -TILE
			else:
				vel.x = 0.0
		else:
			vel.x = 0.0
	if bool(res["on_ground"]):
		if vel.y > 0.0:
			vel.y = 0.0
		on_ground = true
		coyote = 0.10
		air_jumps = 0
	else:
		on_ground = false
	if bool(res["ceiling"]) and vel.y < 0.0:
		vel.y = 0.0

	# ---- 地面音效
	if on_ground and absf(vel.x) > 60.0 and footstep_cd <= 0.0:
		footstep_cd = 0.26
		game.sfx_play("step", 1.0 + (0.1 if crouching else 0.0), -14.0)

	# ---- 尖刺 / 坠落
	if level.hazard_at_point(position + Vector2(0, -3.0)):
		var spike_dmg: float = 13.0 * (1.0 + float(game.floor_index) * 0.15)
		var r1: String = hurt(spike_dmg, position + Vector2(-facing * 40.0, 0.0), "trap")
		if r1 == "hit":
			vel.y = -420.0
			vel.x = -facing * 220.0
	var world_bottom: float = float(level.height_tiles * TILE)
	if position.y > world_bottom + 40.0:
		if not dead:
			hp -= 22.0
			flash = 1.0
			invul = 0.6
			game.sfx_play("hurt")
			game.shake(10.0)
			if hp <= 0.0:
				die()
			else:
				position = last_safe
				vel = Vector2.ZERO
	else:
		if on_ground and not level.hazard_at_point(position + Vector2(0, -3.0)):
			last_safe = position

	# ---- 动画状态
	if roll_time > 0.0:
		state = "roll"
	elif hurt_time > 0.22:
		state = "hurt"
	elif crouching:
		state = "crouch"
	elif not on_ground:
		state = "jump" if vel.y < -20.0 else "fall"
	elif absf(vel.x) > 24.0:
		state = "run"
	else:
		state = "idle"
	if state == "run":
		run_phase += absf(vel.x) * dt * 0.0125
	queue_redraw()


# ---------------------------------------------------------------- 远程武器
func _update_ranged(dt: float, inp: Dictionary) -> void:
	var g: Dictionary = W.gun(ranged_id)
	var mode: String = str(g["mode"])
	var max_ammo: int = int(g["ammo"])
	fire_cd = maxf(0.0, fire_cd - dt)

	if reloading > 0.0:
		reloading -= dt
		if reloading <= 0.0:
			reloading = 0.0
			ammo = max_ammo
			game.sfx_play("reload_done", 1.0)

	if inp.get("reload_pressed", false):
		if max_ammo > 0 and reloading <= 0.0 and ammo < max_ammo:
			_start_reload(g)

	var can_act: bool = roll_time <= 0.0 and heal_time <= 0.0 and guard <= 0.0 and atk_time <= 0.0
	var want: bool = inp.get("bow_held", false) and can_act

	if mode == "auto" or mode == "magic" or mode == "summon":
		bow_active = false
		bow_charge = 0.0
		if want and fire_cd <= 0.0 and reloading <= 0.0:
			# ammo==0 且上限为 0 表示"无限弹药"（魔法杖 / 魔导法典）
			if ammo > 0 or max_ammo <= 0:
				_fire_auto(g)
			elif max_ammo > 0:
				_start_reload(g)
		return

	# 蓄力型：弓 / 狙击枪
	var can_fire: bool = reloading <= 0.0 and (max_ammo <= 0 or ammo > 0)
	if want and can_fire:
		if not bow_active:
			bow_active = true
			bow_charge = 0.0
			game.sfx_play("draw", 1.0, -16.0)
		bow_charge = minf(1.0, bow_charge + dt / maxf(0.05, float(g["charge"])))
	elif bow_active:
		bow_active = false
		var need: float = 0.55
		if str(g["bullet"]) == "arrow":
			need = 0.05
		if bow_charge >= need:
			_fire_charge(g, bow_charge)
		bow_charge = 0.0


func _start_reload(g: Dictionary) -> void:
	var rt: float = float(g["reload"])
	if rt <= 0.0 or reloading > 0.0:
		return
	reloading = rt
	reload_total = rt
	game.sfx_play("reload", 1.0, -6.0)


func _fire_auto(g: Dictionary) -> void:
	# ---- 召唤类武器：本身无伤害，只召唤生物（每只 20 法力）
	if str(g.get("mode", "auto")) == "summon":
		var cnt: int = int(g.get("count", 1))
		if game != null and game.items != null:
			cnt += game.items.summon_extra()
		if game != null and game.skills != null:
			cnt += game.skills.summon_extra()
		cnt = clampi(cnt, 1, 12)
		var per: float = float(g.get("mana", 20.0))
		var need: float = per * float(cnt)
		if mana < need:
			game.sfx_play("block", 1.5, -14.0)
			fire_cd = 0.35
			game.fx.text(position + Vector2(0, -70), "法力不足（需 %d）" % int(need), Color(0.55, 0.75, 1.0), 15)
			return
		mana = maxf(0.0, mana - need)
		mana_idle = 0.0
		var scol: Color = g.get("col", Color(0.7, 0.9, 1.0))
		var selem: String = str(g.get("elem", ""))
		var sghost: bool = bool(g.get("summon_ghost", false))
		var ssup: bool = bool(g.get("summon_support", false))
		var sdmg: float = float(g.get("summon_dmg", 10.0))
		var life2: float = float(g.get("summon_life", 15.0))
		var ghost2: bool = sghost
		var splash2: float = 0.0
		var heal2: float = 0.0
		var spd2: float = 1.0
		if game != null and game.items != null:
			life2 += game.items.summon_life_bonus()
			splash2 = maxf(splash2, game.items.summon_splash())
			heal2 += game.items.summon_heal()
			spd2 *= game.items.summon_speed()
			if game.items.summon_ghost():
				ghost2 = true
		if game != null and game.skills != null:
			life2 += game.skills.summon_life_bonus()
			splash2 = maxf(splash2, game.skills.summon_splash())
			heal2 += game.skills.summon_heal()
			spd2 *= game.skills.summon_speed()
			if game.skills.summon_ghost():
				ghost2 = true
		# 召唤物伤害倍率：遗物 + 技能
		if game != null and game.items != null:
			sdmg *= game.items.summon_mult()
		if game != null and game.skills != null:
			sdmg *= game.skills.val("summon_mult")
		for k in range(cnt):
			var ang2: float = -PI * 0.5 + float(k) * (TAU / float(maxi(cnt, 1)))
			var sp2: Vector2 = position + Vector2(0, -30.0) + Vector2(cos(ang2), sin(ang2)) * 26.0
			game.spawn_summon(str(g.get("summon", "imp")), sp2, scol, sdmg, selem, ghost2, ssup, life2, splash2, heal2, spd2)
			game.fx.ring_spawn(sp2, 26.0, Color(scol.r, scol.g, scol.b, 0.9))
			game.fx.spark_spawn(sp2, Vector2(0, -1), 8, scol)
		game.sfx_play("magic", 0.9, -6.0)
		game.shake(1.6)
		muzzle_flash = 1.0
		fire_cd = float(g.get("delay", 1.2))
		return
	var dirv: Vector2 = aim_vec()
	var spread: float = float(g["spread"])
	if spread > 0.0:
		dirv = dirv.rotated(randf_range(-spread, spread))
	var dmg_arr: Array = g["dmg"]
	var spd_arr: Array = g["speed"]
	var is_magic: bool = str(g.get("mode", "auto")) == "magic"
	# 魔法类武器每发消耗法力（不够就打不出来）
	if is_magic:
		var cost: float = 20.0 * _skill("mana_cost")
		if mana < cost:
			game.sfx_play("block", 1.5, -14.0)
			fire_cd = 0.3
			game.fx.text(position + Vector2(0, -70), "法力不足", Color(0.55, 0.75, 1.0), 15)
			return
		mana = maxf(0.0, mana - cost)
		mana_idle = 0.0
	var dmg: float = float(dmg_arr[0]) * (_magic_mult() if is_magic else _phys_mult())
	if is_arcane_weapon():
		dmg *= 0.55
	var muzzle: Vector2 = position + Vector2(0, -size.y * 0.58) + dirv * 24.0
	var elem: String = str(g.get("elem", ""))
	var prc: int = int(g.get("pierce", 0))
	var st1: String = str(g.get("status", ""))
	var st2: String = str(g.get("status2", ""))
	var fan: int = int(g.get("fan", 1))
	var col: Color = g.get("col", Color(1.0, 0.9, 0.6))
	if fan > 1:
		for k in range(fan):
			var f2: float = (float(k) - float(fan - 1) * 0.5) * 0.22
			game.spawn_shot(str(g["bullet"]), muzzle, dirv.rotated(f2) * float(spd_arr[0]), dmg, true, 1.0, elem, prc, st1, st2)
	else:
		game.spawn_shot(str(g["bullet"]), muzzle, dirv * float(spd_arr[0]), dmg, true, 1.0, elem, prc, st1, st2)
	if is_magic:
		game.sfx_play("magic", 0.95 + randf() * 0.16, -7.0)
		game.fx.ring_spawn(muzzle, 20.0, Color(col.r, col.g, col.b, 0.8))
		game.fx.spark_spawn(muzzle, dirv, 5, col)
	else:
		game.sfx_play("gun", 0.92 + randf() * 0.16, -8.0)
		game.fx.spark_spawn(muzzle, dirv, 3, Color(1.0, 0.86, 0.5))
	game.shake(1.3)
	muzzle_flash = 1.0
	fire_cd = float(g["delay"])
	if int(g["ammo"]) > 0:
		ammo -= 1
		if ammo <= 0:
			ammo = 0
			_start_reload(g)


func _fire_charge(g: Dictionary, ch: float) -> void:
	var dirv: Vector2 = aim_vec()
	var dmg_arr: Array = g["dmg"]
	var spd_arr: Array = g["speed"]
	var d0: float = float(dmg_arr[0])
	var d1: float = float(dmg_arr[1])
	var s0: float = float(spd_arr[0])
	var s1: float = float(spd_arr[1])
	var dmg: float
	var spd: float
	if str(g["bullet"]) == "sniper":
		dmg = d0 * (0.4 + 0.6 * ch) * _phys_mult()
		spd = s0
	else:
		dmg = lerpf(d0, d1, ch) * _phys_mult()
		spd = lerpf(s0, s1, ch)
	var muzzle: Vector2 = position + Vector2(0, -size.y * 0.58) + dirv * 26.0
	game.spawn_shot(str(g["bullet"]), muzzle, dirv * spd, dmg, true, 1.0 + ch * 0.5)
	if str(g["bullet"]) == "arrow":
		game.sfx_play("bow", 0.9 + ch * 0.5)
	else:
		game.sfx_play("sniper", 0.9 + ch * 0.35)
		game.shake(5.0)
	game.shake(1.5 + ch * 2.0)
	muzzle_flash = 1.0
	game.fx.spark_spawn(muzzle, dirv, int(3.0 + ch * 7.0), Color(0.95, 0.92, 0.75))
	if int(g["ammo"]) > 0:
		ammo -= 1
		if ammo <= 0:
			ammo = 0
			_start_reload(g)


func reload_ratio() -> float:
	if reload_total <= 0.0:
		return 0.0
	return clampf(1.0 - reloading / reload_total, 0.0, 1.0)


func can_stand() -> bool:
	if crouch_amt <= 0.01:
		return true
	var half_w: float = size.x * 0.5
	var x0: int = int(floor((position.x - half_w + 2.0) / TILE))
	var x1: int = int(floor((position.x + half_w - 2.0) / TILE))
	var y0: int = int(floor((position.y - STAND_H + 2.0) / TILE))
	var y1: int = int(floor((position.y - 2.0) / TILE))
	for ty in range(y0, y1 + 1):
		for tx in range(x0, x1 + 1):
			if level.is_solid(tx, ty):
				return false
	return true


# ---------------------------------------------------------------- 长剑
func start_attack() -> void:
	var s: Dictionary = W.sword(sword_id)
	if combo_window > 0.0:
		atk_stage = (atk_stage + 1) % 3
	else:
		atk_stage = 0
	combo_window = 0.0
	attack_aim = aim
	atk_hit_ids.clear()
	var durs: Array = s["dur"]
	atk_total = float(durs[atk_stage]) / _skill("atkspd")
	atk_time = atk_total
	game.sfx_play("slash", 1.0 + float(atk_stage) * 0.08)
	# 错误剑：不挥常规弧光，直接闪现斩杀
	if sword_id == "error_sword":
		_error_sword_strike()
		return
	if absf(cos(attack_aim)) > 0.18:
		facing = signf(cos(attack_aim))
	if is_whip():
		# 鞭子：长鞭甩出 + 拖尾（快速伸出、缓慢回缩）
		game.fx.whip_spawn(position + Vector2(0, -size.y * 0.52), attack_aim, sword_reach(), s["col"], facing, 0.20, self)
	else:
		game.fx.slash_spawn(position + Vector2(0, -size.y * 0.5), attack_aim, sword_reach() - 6.0, s["col"], facing)


## 是否是鞭类武器（超远距离、更细的挥击）
func is_whip() -> bool:
	return sword_id.begins_with("whip_")


func sword_reach() -> float:
	var s: Dictionary = W.sword(sword_id)
	return float(s["reach"]) + float(atk_stage) * 9.0


func sword_damage() -> float:
	var s: Dictionary = W.sword(sword_id)
	var dmgs: Array = s["dmg"]
	var mul: float = _magic_mult() if bool(s.get("magic", false)) else _phys_mult()
	return float(dmgs[atk_stage]) * mul


## 命中的瞬间：魔法剑会溅出奥术冲击
func _sword_proc(pos: Vector2, dirv: Vector2, dmg: float) -> void:
	var s: Dictionary = W.sword(sword_id)
	if not bool(s.get("magic", false)):
		return
	if game == null:
		return
	var col: Color = s["col"]
	game.damage_area(pos, 52.0, dmg * 0.35, dirv, false)
	game.fx.ring_spawn(pos, 46.0, Color(col.r, col.g, col.b, 0.85))
	game.fx.spark_spawn(pos, dirv, 8, col)


func do_sword_hits() -> void:
	var reach: float = sword_reach()
	var dirv := Vector2(cos(attack_aim), sin(attack_aim))
	var center: Vector2 = position + Vector2(0, -size.y * 0.55) + dirv * (reach * 0.48)
	var half := Vector2(reach * 0.52, reach * (0.16 if is_whip() else 0.46))
	var hit_rect := Rect2(center - half, half * 2.0)
	if game == null:
		return
	var dmg: float = sword_damage()
	var ls: float = lifesteal()
	var enemies: Array = game.enemies
	for i in range(enemies.size()):
		var e = enemies[i]
		if e == null or not is_instance_valid(e):
			continue
		if e.dead:
			continue
		var eid: int = e.get_instance_id()
		if atk_hit_ids.has(eid):
			continue
		if hit_rect.intersects(e.rect()):
			atk_hit_ids[eid] = true
			var knock: float = 240.0 + float(atk_stage) * 120.0
			var res: String = e.hurt(dmg, dirv, knock, 0.24)
			game.hit_feedback(e.position, dirv, res == "crit")
			if ls > 0.0:
				hp = minf(max_hp, hp + dmg * ls)
			_apply_sword_status(e)
			_sword_proc(e.position, dirv, dmg)
	# 剑可以打掉飞行物
	var shots: Array = game.shots
	for i in range(shots.size()):
		var sh = shots[i]
		if sh == null or not is_instance_valid(sh):
			continue
		if sh.from_player:
			continue
		if hit_rect.intersects(Rect2(sh.position - Vector2(8, 8), Vector2(16, 16))):
			sh.kill_me = true
			game.fx.spark_spawn(sh.position, dirv, 8, Color(0.9, 0.9, 1.0))
			game.sfx_play("clink")


# ---------------------------------------------------------------- 受伤 / 死亡
func hurt(dmg: float, from: Vector2, kind: String = "melee", attacker = null) -> String:
	if dead:
		return "none"

	# 错误之甲：免疫期间完全不受伤（100 秒免疫 / 50 秒冷却）
	if shield_id == "armor_error" and err_imm > 0.0:
		if game != null and randf() < 0.35:
			game.fx.text(position + Vector2(randf_range(-22.0, 22.0), -84.0), "免疫", Color(1.0, 0.4, 0.92), 17)
		return "none"
	if invul > 0.0:
		return "none"

	# 闪避盾：受到攻击瞬间自动闪避
	if shield_id == "dodge" and dodge_cd <= 0.0:
		dodge_cd = 2.0
		invul = 0.55
		vel.x = -facing * 340.0
		game.fx.text(position + Vector2(0, -76), "闪避!", Color(0.6, 1.0, 0.82), 20)
		game.fx.ring_spawn(position + Vector2(0, -24), 44.0, Color(0.6, 1.0, 0.82))
		game.sfx_play("roll", 1.35)
		return "dodge"

	# 魔法保护：完全免伤
	if game != null and game.items != null and is_instance_valid(game.items) and game.items.guard_charges > 0:
		game.items.guard_charges -= 1
		invul = 0.42
		game.fx.ring_spawn(position + Vector2(0, -26), 54.0, Color(0.78, 0.96, 1.0))
		game.fx.text(position + Vector2(0, -82), "魔法保护!", Color(0.80, 0.95, 1.0), 19)
		game.sfx_play("parry", 1.25)
		return "guard"

	# 盾牌格挡 / 弹反
	if guard > 0.0:
		var to_attacker: Vector2 = (from - position)
		if to_attacker.length() > 0.1:
			to_attacker = to_attacker.normalized()
		if to_attacker.x * facing > -0.15:
			if parry_window > 0.0:
				parry_window = 0.0
				invul = 0.22
				game.sfx_play("parry", 1.05)
				game.shake(7.0)
				game.fx.ring_spawn(position + Vector2(facing * 22.0, -size.y * 0.55), 46.0, Color(0.7, 0.95, 1.0))
				game.fx.text(position + Vector2(0, -76), "弹反!", Color(0.7, 1.0, 1.0))
				game.reflect_shots(position, facing)
				_thorns(dmg, attacker)
				_arcane_burst()
				_shield_status_burst()
				return "parry"
			invul = 0.20
			game.sfx_play("block")
			game.shake(3.0)
			game.fx.spark_spawn(position + Vector2(facing * 20.0, -size.y * 0.5), Vector2(facing, 0), 12, Color(0.8, 0.85, 1.0))
			_thorns(dmg, attacker)
			_arcane_burst()
			_shield_status_burst()
			return "block"

	# 真实伤害
	var real: float = dmg * taken_mult()
	hp -= real
	flash = 1.0
	hurt_time = 0.34
	invul = 0.55
	bow_active = false
	bow_charge = 0.0
	# 恶魔之翼的代价：受伤后持续流血 5 秒（每秒 -5）
	if wings_kind() == 2:
		bleed_time = 5.0
		game.fx.text(position + Vector2(0, -100), "流血!", Color(0.95, 0.35, 0.35), 17)
	game.sfx_play("hurt")
	game.shake(9.0)
	var dir: Vector2 = (position - from)
	if dir.length() < 0.1:
		dir = Vector2(-facing, 0)
	dir = dir.normalized()
	vel.x = dir.x * 230.0
	if kind != "trap":
		vel.y = -170.0
	game.fx.blood_spawn(position + Vector2(0, -size.y * 0.5), dir, 16, Color(0.55, 0.05, 0.10))
	if game.items != null and is_instance_valid(game.items):
		game.items.on_hurt()
		var hmf: float = game.items.hurt_mana()
		if hmf > 0.0:
			mana = minf(max_mana, mana + hmf)
			game.fx.text(position + Vector2(0, -112), "+%d 法力" % int(hmf), Color(0.55, 0.82, 1.0), 14)
	game.hit_stop(0.05)
	if hp <= 0.0:
		hp = 0.0
		die()
		return "dead"
	return "hit"


## 剑的附加状态（王级武器：灼烧 / 缓速 / 吞噬 / 混乱）
func _apply_sword_status(e) -> void:
	if e == null or not is_instance_valid(e) or not e.has_method("apply_status"):
		return
	var s: Dictionary = W.sword(sword_id)
	var st: String = str(s.get("status", ""))
	if st == "":
		return
	e.apply_status(st, 5.0)
	var st2: String = str(s.get("status2", ""))
	if st2 != "":
		e.apply_status(st2, 5.0)


## 盾的附加状态：格挡 / 弹反时给周围怪物挂上
func _shield_status_burst() -> void:
	if game == null:
		return
	var s: Dictionary = W.shield(shield_id)
	var st: String = str(s.get("status", ""))
	if st == "":
		return
	var st2: String = str(s.get("status2", ""))
	var c: Vector2 = position + Vector2(0, -size.y * 0.5)
	for i in range(game.enemies.size()):
		var e = game.enemies[i]
		if e == null or not is_instance_valid(e) or e.dead:
			continue
		if e.position.distance_to(c) <= 112.0:
			e.apply_status(st, 5.0)
			if st2 != "":
				e.apply_status(st2, 5.0)
	game.fx.ring_spawn(c, 112.0, Color(0.9, 0.92, 1.0, 0.55))


## 秘法盾：格挡/弹反时释放奥术冲击
func _arcane_burst() -> void:
	if shield_id != "arcane":
		return
	if game == null:
		return
	var d: float = 14.0 + 6.0 * float(game.magic_level)
	var c: Vector2 = position + Vector2(0, -size.y * 0.5)
	game.damage_area(c, 86.0, d, Vector2(facing, 0))
	game.fx.ring_spawn(c, 86.0, Color(0.78, 0.62, 1.0))
	game.fx.spark_spawn(c, Vector2(facing, 0), 12, Color(0.82, 0.70, 1.0))
	game.sfx_play("magic", 1.22, -6.0)
	if game.player != null:
		game.shake(3.0)


func _thorns(dmg: float, attacker) -> void:
	if shield_id != "thorns":
		return
	if attacker == null or not is_instance_valid(attacker):
		return
	if not attacker.has_method("hurt"):
		return
	var back: float = dmg * 0.5
	var dirv: Vector2 = (attacker.position - position)
	if dirv.length() < 0.1:
		dirv = Vector2(facing, 0)
	dirv = dirv.normalized()
	attacker.hurt(back, dirv, 140.0, 0.1)
	game.fx.text(attacker.position + Vector2(0, -40), "反伤", Color(1.0, 0.62, 0.42), 16)
	game.sfx_play("clink", 0.9)


func die() -> void:
	if dead:
		return
	# 不死鸟之羽：每层一次的复活
	if game != null and game.items != null and is_instance_valid(game.items):
		if game.items.try_revive():
			return
	dead = true
	state = "dead"
	game.on_player_death()
	queue_redraw()


func heal_full() -> void:
	hp = max_hp


# ---------------------------------------------------------------- 绘制
func _draw() -> void:
	draw_set_transform(Vector2(0.0, step_visual))
	var g: Dictionary = W.gun(ranged_id)
	var is_gun: bool = str(g["mode"]) == "auto"
	var a: Dictionary = {
		"face": facing,
		"state": state,
		"t": t,
		"run": run_phase,
		"crouch": crouch_amt,
		"flash": flash,
		"aim": attack_aim if atk_time > 0.0 else aim,
		"atk": -1.0,
		"roll": 0.0,
		"guard": guard,
		"bow": bow_charge if (bow_active and not is_gun) else 0.0,
		"charge": bow_charge,
		"gun": 1.0 if is_gun else 0.0,
		"muzzle": muzzle_flash,
		"sword_col": W.sword(sword_id)["col"],
		"wings": wings_kind(),
	}
	if atk_time > 0.0:
		a["atk"] = 1.0 - atk_time / maxf(0.01, atk_total)
	if roll_time > 0.0:
		a["roll"] = 1.0 - roll_time / ROLL_TIME
	var mc: Color = modulate
	if invul > 0.0 and roll_time <= 0.0:
		mc.a = 0.55 + 0.45 * sin(invul * 46.0)
	else:
		mc.a = 1.0
	modulate = mc
	Art.draw_player(self, a)

## 当前是否携带秘法类武器（秘法盾 / 奥术法杖 / 魔导法典）
func is_arcane_weapon() -> bool:
	if shield_id == "arcane":
		return true
	var g: Dictionary = W.gun(ranged_id)
	if str(g.get("elem", "")) == "arcane":
		return true
	return false


## 元素 → 状态（持续 5 秒，结束后 2 秒冷却）
func _elem_status(e: String) -> String:
	if e == "fire":
		return "burn"
	if e == "water":
		return "slow"
	if e == "wood":
		return "root"
	if e == "metal":
		return "gather"
	if e == "earth":
		return ""
	if e == "shock":
		return "shock"
	return ""


## 错误剑：闪现到最近的怪物身旁直接斩杀（冷却 1 秒）
func _error_sword_strike() -> void:
	if game == null:
		return
	# 1 秒冷却
	atk_total = 1.0
	atk_time = 1.0
	var best = null
	var best_d: float = 99999.0
	for i in range(game.enemies.size()):
		var e = game.enemies[i]
		if e == null or not is_instance_valid(e) or e.dead:
			continue
		var d: float = position.distance_to(e.position)
		if d < best_d:
			best_d = d
			best = e
	if best == null:
		return
	# 闪现到怪物身旁
	var side: float = signf(position.x - best.position.x)
	if absf(side) < 0.1:
		side = 1.0
	position = best.position + Vector2(side * 40.0, 0.0)
	vel = Vector2.ZERO
	game.fx.slash_spawn(best.position + Vector2(0, -best.size.y * 0.5), 0.0, 90.0, Color(1.0, 0.24, 0.88), 1.0)
	game.fx.ring_spawn(best.position + Vector2(0, -best.size.y * 0.5), 70.0, Color(1.0, 0.3, 0.9))
	game.fx.text(best.position + Vector2(0, -60), "ERROR", Color(1.0, 0.3, 0.9), 26)
	game.sfx_play("slash", 0.7, 0.0)
	game.shake(6.0)
	best.hurt(999999.0, Vector2(side, 0), 0.0, 0.0, "")
	game.note_damage(999999.0)
