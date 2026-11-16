extends Node2D
var shop_sel := 0
var pause_sel := 0
## 主控制：无限楼层 / 死亡重生 / 输入 / 摄像机 / 宝箱 / 金币商店升级

const Art = preload("res://scripts/art.gd")
const DungeonScript = preload("res://scripts/dungeon.gd")
const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const ShotScript = preload("res://scripts/projectile.gd")
const FxScript = preload("res://scripts/fx.gd")
const HudScript = preload("res://scripts/hud.gd")
const SfxScript = preload("res://scripts/sfx.gd")
const ItemsScript = preload("res://scripts/items.gd")
const SkillsScript = preload("res://scripts/skills.gd")
const WeaponsScript = preload("res://scripts/weapons.gd")
const CodexScript = preload("res://scripts/codex.gd")
const StorageScript = preload("res://scripts/storage.gd")
const SummonScript = preload("res://scripts/summon.gd")
const WallBgScript = preload("res://scripts/wall_bg.gd")

const TILE := 32
const MAX_ENEMIES := 260

# ---- 显示相关选项
const RES_OPTS: Array = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
const RES_NAMES: Array = ["1280 x 720", "1600 x 900", "1920 x 1080", "2560 x 1440"]
const FPS_OPTS: Array = [30, 60, 90, 120, 0]
const FPS_NAMES: Array = ["30", "60", "90", "120", "不限"]
const QUALITY_NAMES: Array = ["低", "中", "高"]
const SETTINGS_ROWS := 14
const TRAIN_MONSTERS: Array = ["slime", "slime_blue", "slime_red", "slime_metal", "slime_wood", "slime_earth",
	"slime_king", "slime_queen", "zombie", "skeleton", "flesh", "goblin",
	"drake_small", "drake_large", "drake_king", "seadrake_small", "seadrake_large", "seadrake_king"]

var state := "title"

var level_holder: Node2D
var entity_holder: Node2D
var fx = null
var sfx = null
var hud = null
var wall_bg = null
var items = null
var skills = null
var codex = null
var storage = null
var cam: Camera2D

var dungeon = null
var player = null
var enemies: Array = []
var shots: Array = []
var summons: Array = []

# ---- 本局数据
var floor_index := 1
var run_seed := 0
var kills := 0
var kills_required := 0
var run_time := 0.0
var coins := 200
var best_floor := 1
var runs := 0

# ---- 金币商店等级（无限叠加）
var phys_level := 0
var magic_level := 0
var defense_level := 0
var hp_level := 0
var mana_level := 0

# ---- 统计：累计伤害 / 连击
var total_damage := 0.0
var combo := 0
var combo_timer := 0.0
var combo_best := 0
var run_kills := 0
var prism_granted := false
var error_sword_granted := false
var err_loop_granted := false
var err_armor_granted := false

# ---- 训练房
var training_mode := false
var dummy_kind := "slime"
var dummy_ref = null
var train_tab := 0
var train_idx := 0
var train_sword := "long"
var train_ranged := "bow"
var train_shield := "iron"
var train_skills: Dictionary = {}
var train_items: Dictionary = {}
var train_dummy := "slime"
var train_levels: Dictionary = {"phys": 3, "magic": 3, "def": 3, "hp": 3, "mana": 3}
var near_pedestal := -1

# ---- 武器（跨层继承，只有死亡才重置）
var sword_id := "long"
var ranged_id := "bow"
var shield_id := "iron"

var hitstop := 0.0
var shake_amount := 0.0
var banner_time := 0.0
var mouse_pos := Vector2.ZERO
var prev: Dictionary = {}
var portal_was_open := false
var portal_hint_shown := false
var pending_tp: Dictionary = {}
var title_pan := 0.0
var shop_msg := ""
var codex_tab := 0
var codex_index := 0
var codex_prev_state := "play"

# ---- 存档 / 设置 / 拾取询问
var settings := {}
var total_playtime := 0.0
var run_active := false
var menu_prev_state := "title"
var menu_index := 0
var settings_index := 0
var menu_msg := ""
var pending_weapon := {}
var weapon_queue: Array = []
var pickup_prev_state := "play"
var slot_cache: Array = []
var quit_armed := false
var quit_timer := 0.0


## 关闭窗口 / 退出时自动保存设置与图鉴
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save_settings_now()
		if codex != null:
			codex.save_now()
		save_to_slot(0) if false else null
		get_tree().quit()


func _ready() -> void:
	randomize()
	level_holder = Node2D.new()
	level_holder.name = "Level"
	add_child(level_holder)

	entity_holder = Node2D.new()
	entity_holder.name = "Entities"
	add_child(entity_holder)

	items = ItemsScript.new()
	items.name = "Items"
	items.setup(self)
	entity_holder.add_child(items)

	skills = SkillsScript.new()
	codex = CodexScript.new()
	storage = StorageScript.new()
	settings = storage.load_settings()
	total_playtime = float(settings.get("total_time", 0.0))
	refresh_slots()

	fx = FxScript.new()
	fx.name = "Fx"
	add_child(fx)

	sfx = SfxScript.new()
	sfx.name = "Sfx"
	add_child(sfx)

	cam = Camera2D.new()
	cam.name = "Camera"
	cam.position_smoothing_enabled = false
	add_child(cam)
	cam.make_current()

	# 固定屏幕墙壁层（可在设置里开关）
	var bl := CanvasLayer.new()
	bl.name = "WallLayer"
	bl.layer = -10
	add_child(bl)
	wall_bg = WallBgScript.new()
	wall_bg.name = "WallBg"
	wall_bg.visible = false
	bl.add_child(wall_bg)

	var cl := CanvasLayer.new()
	cl.name = "UiLayer"
	cl.layer = 10
	add_child(cl)
	hud = HudScript.new()
	hud.name = "Hud"
	cl.add_child(hud)
	hud.setup(self)

	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	run_seed = int(Time.get_ticks_usec() % 99999989)
	build_floor(true)
	state = "title"
	title_pan = cam.position.x
	keys_cfg = settings.get("keys", storage.default_keys())
	pad_cfg = settings.get("pad", storage.default_pad())
	apply_settings()
	# 调试：验证训练场进入流程


# ---------------------------------------------------------------- 设置
## 全局画质等级：0 低 / 1 中 / 2 高
func quality() -> int:
	return clampi(int(settings.get("quality", 1)), 0, 2)


func apply_settings() -> void:
	if hud != null and is_instance_valid(hud):
		hud.show_crosshair = bool(settings.get("crosshair", true))
	# 音量
	var vol: float = clampf(float(settings.get("volume", 0.8)), 0.0, 1.0)
	if sfx != null:
		sfx.set_master_volume(vol)
	# 全屏 / 分辨率
	var full: bool = bool(settings.get("fullscreen", false))
	if full:
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var ri: int = clampi(int(settings.get("resolution", 0)), 0, RES_OPTS.size() - 1)
		var want: Vector2i = RES_OPTS[ri]
		if DisplayServer.window_get_size() != want:
			DisplayServer.window_set_size(want)
			var scr: Vector2i = DisplayServer.screen_get_size()
			DisplayServer.window_set_position((scr - want) / 2)
	# 帧率上限
	var fi: int = clampi(int(settings.get("fps", 1)), 0, FPS_OPTS.size() - 1)
	Engine.max_fps = int(FPS_OPTS[fi])
	# 画质
	apply_quality()
	if hud != null:
		hud.show_crosshair = bool(settings.get("crosshair", true))
		hud.show_fps = bool(settings.get("show_fps", false))


## 把画质设置应用到所有已存在的对象
func apply_quality() -> void:
	var q: int = quality()
	if fx != null:
		fx.set_quality(q)
	if dungeon != null and is_instance_valid(dungeon):
		dungeon.set_glow_on(q > 0)
	for i in range(enemies.size()):
		var e = enemies[i]
		if e != null and is_instance_valid(e):
			e.apply_quality(q)
	if hud != null:
		hud.show_vignette = q > 0


func quality_name() -> String:
	return str(QUALITY_NAMES[clampi(quality(), 0, 2)])


func res_name() -> String:
	return str(RES_NAMES[clampi(int(settings.get("resolution", 0)), 0, RES_NAMES.size() - 1)])


func fps_name() -> String:
	return str(FPS_NAMES[clampi(int(settings.get("fps", 1)), 0, FPS_NAMES.size() - 1)])


func save_settings_now() -> void:
	if storage == null:
		return
	settings["total_time"] = total_playtime
	storage.save_settings(settings)


## 退出游戏（先按一次进入确认状态，再按一次才真的退出）
func request_quit() -> void:
	if quit_armed:
		save_settings_now()
		if codex != null:
			codex.save_now()
		get_tree().quit()
		return
	quit_armed = true
	quit_timer = 3.0
	menu_msg = "再按一次确认退出游戏"
	sfx_play("block", 0.9, -8.0)


func toggle_fullscreen() -> void:
	settings["fullscreen"] = not bool(settings.get("fullscreen", false))
	apply_settings()
	save_settings_now()
	if hud != null:
		hud.msg("全屏：%s" % ("开" if bool(settings.get("fullscreen", false)) else "关"), Color(0.85, 0.9, 1.0), 1.4)


# ---------------------------------------------------------------- 数值曲线
func stat_mult() -> float:
	return pow(2.0, float(int((floor_index - 1) / 5)))


func count_mult() -> int:
	return int(pow(2.0, float(int((floor_index - 1) / 10))))


func coin_gain() -> int:
	var base: float = (5.0 + float(floor_index) * 3.0) * sqrt(stat_mult())
	if skills != null:
		base *= skills.val("coin")
	if items != null and is_instance_valid(items):
		base *= items.coin_mult()
	return maxi(1, int(round(base)))


func pickup_radius() -> float:
	var r: float = 44.0
	if skills != null:
		r *= skills.val("pickup")
	if items != null and is_instance_valid(items):
		r *= items.pickup_mult()
	return r


## 等级无上限（无限升级），只为防止数值溢出做了封顶
func upgrade_cost(kind: String) -> int:
	var lvl: int = level_of(kind)
	var v: float = 18.0 * pow(1.17, float(lvl))
	if v > 90000000.0:
		v = 90000000.0
	return int(round(v))


func level_of(kind: String) -> int:
	if kind == "phys":
		return phys_level
	if kind == "magic":
		return magic_level
	if kind == "def":
		return defense_level
	if kind == "mana":
		return mana_level
	return hp_level


func upgrade_name(kind: String) -> String:
	if kind == "phys":
		return "物理等级"
	if kind == "magic":
		return "魔法等级"
	if kind == "def":
		return "防御等级"
	if kind == "mana":
		return "法力等级"
	return "生命等级"


func upgrade_desc(kind: String) -> String:
	if kind == "phys":
		return "剑与枪械伤害 +10%"
	if kind == "magic":
		return "遗物魔法伤害 +10%"
	if kind == "def":
		return "受到伤害 ×0.94"
	if kind == "mana":
		return "法杖法力上限 +18，并回满"
	return "最大生命 +15"


# ---------------------------------------------------------------- 楼层构建
func build_floor(is_title: bool = false) -> void:
	if dungeon != null and is_instance_valid(dungeon):
		dungeon.queue_free()
		dungeon = null
	if player != null and is_instance_valid(player):
		player.queue_free()
	player = null
	for i in range(enemies.size()):
		var e = enemies[i]
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	for i in range(shots.size()):
		var s = shots[i]
		if is_instance_valid(s):
			s.queue_free()
	shots.clear()
	if fx != null:
		fx.clear_all()
	portal_was_open = false
	portal_hint_shown = false

	var sd: int = run_seed + floor_index * 7919 + runs * 131
	dungeon = DungeonScript.new(floor_index, sd, count_mult(), training_mode, train_corridor_len())
	level_holder.add_child(dungeon)
	dungeon.view_size = get_viewport_rect().size
	if wall_bg != null and is_instance_valid(wall_bg):
		wall_bg.setup(dungeon.theme)

	var lr: Rect2 = dungeon.level_rect()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(lr.size.x)
	cam.limit_bottom = int(lr.size.y)

	# 换层清空召唤物
	for si in range(summons.size()):
		var ss = summons[si]
		if ss != null and is_instance_valid(ss):
			ss.queue_free()
	summons.clear()
	# 玩家
	player = PlayerScript.new()
	player.name = "Player"
	entity_holder.add_child(player)
	player.setup(self, dungeon, dungeon.spawn_point)
	apply_loadout()
	recalc_player_stats()
	player.hp = player.max_hp
	player.flasks = player.max_flasks
	cam.position = player.position + Vector2(0, -40)
	cam.offset = Vector2.ZERO

	# 敌人：先按「每层 +10、封顶 350」重排数量（地图代码是编译版，不能改，所以在主控里调整）
	_tune_enemy_count()
	var mult: float = stat_mult()
	var spawned: int = 0
	for i in range(dungeon.enemy_spawns.size()):
		if spawned >= MAX_ENEMIES:
			break
		var sp: Dictionary = dungeon.enemy_spawns[i]
		spawn_enemy(str(sp["kind"]), sp["pos"], bool(sp["elite"]), mult)
		spawned += 1
	kills = 0
	# 通关条件：击杀半数，但每层最多 349 只（不超过 349）
	kills_required = clampi(int(ceil(float(dungeon.total_enemies) * 0.5)), 1, 349)
	dungeon.portal_open = false
	banner_time = 3.0
	dungeon.cam_pos = cam.position
	if items != null and is_instance_valid(items):
		items.bind(dungeon, player)
		entity_holder.move_child(items, entity_holder.get_child_count() - 1)
	if player != null and is_instance_valid(player):
		player.max_mana = 60.0 + 18.0 * float(mana_level)
		player.mana = player.max_mana
	if not is_title:
		hud.msg("第 %d 层 · %s" % [floor_index, theme_name()], Color(0.92, 0.9, 0.84), 2.2)
	apply_quality()


# ---------------------------------------------------------------- 装备继承
## 每层怪物数量：基础 40，逐层 +40，封顶 350
## 不改地图脚本，但按「房间」均匀分散到所有楼层带，避免怪物全挤在同一层
func _tune_enemy_count() -> void:
	if dungeon == null or not is_instance_valid(dungeon):
		return
	if training_mode:
		return
	var want: int = mini(350, 40 + (floor_index - 1) * 40)
	var rooms_list: Array = dungeon.rooms
	if rooms_list.size() == 0:
		return
	# 复用原生成结果的怪物种类，保证各层怪物种类分布不变
	var kinds_pool: Array = []
	var src: Array = dungeon.enemy_spawns
	for i in range(src.size()):
		kinds_pool.append(str(src[i]["kind"]))
	if kinds_pool.is_empty():
		kinds_pool = ["slime"]
	var out: Array = []
	var room_n: int = rooms_list.size()
	var base_n: int = int(want / room_n)
	var extra: int = want % room_n
	for r in range(room_n):
		var info: Dictionary = rooms_list[r]
		var rc: Rect2i = info["rect"]
		var fy: int = int(info["floor"])
		var cnt: int = base_n + (1 if r < extra else 0)
		if cnt <= 0:
			continue
		var span: int = maxi(1, rc.size.x - 2)
		for k in range(cnt):
			# 房间里横向均匀铺开，交错落脚，避免堆叠
			var off: int = int(float(k + 0.5) * float(span) / float(cnt))
			var tx: int = rc.position.x + 1 + clampi(off, 0, span - 1)
			var kind: String = str(kinds_pool[(r + k) % kinds_pool.size()])
			out.append({
				"pos": Vector2(float(tx) * 32.0 + 16.0, float(fy * 32.0)),
				"kind": kind,
				"elite": false,
			})
	dungeon.enemy_spawns = out
	dungeon.total_enemies = out.size()


## 把 main 里记录的武器配置装到当前玩家身上（换关 / 读档后都会调用）
func apply_loadout() -> void:
	if player == null or not is_instance_valid(player):
		return
	player.equip_sword(sword_id)
	player.equip_ranged(ranged_id)
	player.equip_shield(shield_id)


func recalc_player_stats() -> void:
	if player == null or not is_instance_valid(player):
		return
	var add: float = 0.0
	var mult: float = 1.0
	var fl: int = 3
	if skills != null:
		add = skills.add_val("hp_add")
		mult = skills.val("hp_mult")
		fl = 3 + int(skills.add_val("flask"))
	if player != null and is_instance_valid(player):
		player.max_mana = 60.0 + 18.0 * float(mana_level)
	var base: float = 100.0 + 15.0 * float(hp_level) + add
	player.max_hp = maxf(30.0, base * mult)
	player.max_flasks = maxi(1, fl)
	if player.hp > player.max_hp:
		player.hp = player.max_hp
	if player.flasks > player.max_flasks:
		player.flasks = player.max_flasks


func start_run() -> void:
	if sfx != null:
		sfx.play("start")
	runs += 1
	floor_index = 1
	run_seed = int(Time.get_ticks_usec() % 99999989)
	kills = 0
	run_time = 0.0
	coins = 200
	phys_level = 0
	magic_level = 0
	defense_level = 0
	hp_level = 0
	mana_level = 0
	total_damage = 0.0
	combo = 0
	combo_best = 0
	run_kills = 0
	error_sword_granted = false
	prism_granted = false
	sword_id = "long"
	ranged_id = "bow"
	shield_id = "iron"
	shop_msg = ""
	menu_msg = ""
	run_active = true
	pending_weapon = {}
	weapon_queue.clear()
	if skills != null:
		skills.clear()
	if items != null and is_instance_valid(items):
		items.clear()
	state = "play"
	build_floor(false)
	prev.clear()


# ---------------------------------------------------------------- 商店 / 下潜
func open_shop() -> void:
	state = "shop"
	shop_msg = ""
	sfx_play("portal")
	recalc_player_stats()


func descend() -> void:
	var bonus: int = 20 + floor_index * 10
	coins += bonus
	floor_index += 1
	if floor_index > best_floor:
		best_floor = floor_index
	if floor_index % 3 == 0 and items != null:
		grant_item(items.random_id())
	state = "play"
	build_floor(false)
	prev.clear()
	hud.msg("下潜到第 %d 层 · 金币 +%d" % [floor_index, bonus], Color(0.85, 0.9, 1.0), 2.2)


func buy_upgrade(kind: String) -> void:
	var cost: int = upgrade_cost(kind)
	if coins < cost:
		sfx_play("block", 0.8, -6.0)
		shop_msg = "金币不足（需要 %d）" % cost
		return
	coins -= cost
	if kind == "phys":
		phys_level += 1
	elif kind == "magic":
		magic_level += 1
	elif kind == "def":
		defense_level += 1
	elif kind == "mana":
		mana_level += 1
		if player != null and is_instance_valid(player):
			player.max_mana = 60.0 + 18.0 * float(mana_level)
			player.mana = player.max_mana
	else:
		hp_level += 1
	recalc_player_stats()
	sfx_play("item", 1.1)
	shop_msg = upgrade_name(kind) + " → Lv." + str(level_of(kind))


# ---------------------------------------------------------------- 武器拾取询问
func offer_weapon(cat: int, id: String) -> void:
	if player == null or not is_instance_valid(player):
		return
	if not WeaponsScript.SWORDS.has(id) and not WeaponsScript.has_gun(id) and not WeaponsScript.SHIELDS.has(id):
		return
	if state == "pickup":
		# 已经有询问界面了，排队等它关掉
		weapon_queue.append({"kind": "weapon", "cat": cat, "id": id})
		return
	pending_weapon = {"kind": "weapon", "cat": cat, "id": id}
	pickup_prev_state = state
	state = "pickup"
	if codex != null:
		codex.mark("weapons", id)
	sfx_play("item", 1.2, -4.0)


## 翅膀类遗物：已有翅膀时询问是否替换
func offer_relic(id: String, old_id: String) -> void:
	if player == null or not is_instance_valid(player):
		return
	if state == "pickup":
		weapon_queue.append({"kind": "relic", "id": id, "old": old_id})
		return
	pending_weapon = {"kind": "relic", "id": id, "old": old_id}
	pickup_prev_state = state
	state = "pickup"
	if codex != null:
		codex.mark("items", id)
	sfx_play("item", 1.2, -4.0)


func accept_weapon() -> void:
	if pending_weapon.is_empty():
		_finish_pickup()
		return
	var kind: String = str(pending_weapon.get("kind", "weapon"))
	var id: String = str(pending_weapon.get("id", ""))
	if kind == "item":
		if items != null and is_instance_valid(items):
			grant_item(id)
		pending_weapon = {}
		_finish_pickup()
		return
	if kind == "relic":
		# 替换翅膀
		if items != null and is_instance_valid(items):
			items.replace_wing(id)
			var rn: String = items.item_name(id)
			hud.msg("已装备遗物：" + rn, Color(1.0, 0.94, 0.8), 2.4)
			sfx_play("item", 1.15)
			if fx != null and player != null and is_instance_valid(player):
				fx.ring_spawn(player.position + Vector2(0, -26), 60.0, Color(1.0, 0.94, 0.8))
				fx.text(player.position + Vector2(0, -86), rn, Color(1.0, 0.94, 0.8), 20)
		pending_weapon = {}
		_finish_pickup()
		return
	var cat: int = int(pending_weapon.get("cat", 0))
	if cat == 0:
		sword_id = id
	elif cat == 1:
		ranged_id = id
	else:
		shield_id = id
	apply_loadout()
	var nm: String = ""
	if cat == 0:
		nm = WeaponsScript.sword_name(id)
	elif cat == 1:
		nm = WeaponsScript.gun_name(id)
	else:
		nm = WeaponsScript.shield_name(id)
	hud.msg("已装备：" + nm, Color(0.86, 0.94, 1.0), 2.2)
	sfx_play("item", 1.15)
	if fx != null and player != null and is_instance_valid(player):
		fx.ring_spawn(player.position + Vector2(0, -26), 54.0, Color(0.9, 0.95, 1.0))
		fx.text(player.position + Vector2(0, -84), nm, Color(0.9, 0.96, 1.0), 20)
	pending_weapon = {}
	_finish_pickup()


func decline_weapon() -> void:
	pending_weapon = {}
	sfx_play("block", 0.9, -8.0)
	_finish_pickup()


func _finish_pickup() -> void:
	if drop_queue.size() > 0:
		state = pickup_prev_state
		call_deferred("_pump_drop_queue")
		return
	if weapon_queue.size() > 0:
		var nxt: Dictionary = weapon_queue.pop_front()
		state = "pickup"
		if str(nxt.get("kind", "weapon")) == "relic":
			offer_relic(str(nxt.get("id", "")), str(nxt.get("old", "")))
		else:
			offer_weapon(int(nxt.get("cat", 0)), str(nxt.get("id", "")))
		return
	state = pickup_prev_state


# ---------------------------------------------------------------- 存档界面
func refresh_slots() -> void:
	slot_cache.clear()
	for i in range(3):
		if storage != null and storage.has_slot(i):
			slot_cache.append(storage.load_slot(i))
		else:
			slot_cache.append({})


## 打开训练房配置界面（标题页按 T）
func open_training_cfg() -> void:
	train_tab = 0
	train_idx = 0
	state = "train_cfg"
	sfx_play("guard_up", 1.0, -6.0)


func close_training_cfg() -> void:
	state = "title"
	sfx_play("block", 1.0, -10.0)


## 当前分类的条目列表
func train_entries() -> Array:
	var out: Array = []
	if train_tab == 0:
		for i in range(WeaponsScript.SWORD_IDS.size()):
			var sid: String = str(WeaponsScript.SWORD_IDS[i])
			var d: Dictionary = WeaponsScript.sword(sid)
			out.append({"kind": "sword", "id": sid, "name": str(d["name"]), "desc": str(d["desc"]), "col": d["col"], "on": sid == train_sword})
		for i in range(WeaponsScript.GUN_IDS.size()):
			var gid: String = str(WeaponsScript.GUN_IDS[i])
			var g: Dictionary = WeaponsScript.gun(gid)
			out.append({"kind": "ranged", "id": gid, "name": str(g["name"]), "desc": str(g["desc"]), "col": g["col"], "on": gid == train_ranged})
		for i in range(WeaponsScript.SHIELD_IDS.size()):
			var hid: String = str(WeaponsScript.SHIELD_IDS[i])
			var s: Dictionary = WeaponsScript.shield(hid)
			out.append({"kind": "shield", "id": hid, "name": str(s["name"]), "desc": str(s["desc"]), "col": s["col"], "on": hid == train_shield})
	elif train_tab == 1:
		var ids: Array = SkillsScript.DEFS.keys()
		for i in range(ids.size()):
			var kid: String = str(ids[i])
			var d2: Dictionary = SkillsScript.DEFS[kid]
			out.append({"kind": "skill", "id": kid, "name": str(d2["name"]), "desc": str(d2["desc"]),
				"col": Color(0.6, 1.0, 0.72) if bool(d2["good"]) else Color(1.0, 0.5, 0.5), "on": int(train_skills.get(kid, 0)), "count": int(train_skills.get(kid, 0))})
	elif train_tab == 2:
		var iids: Array = ItemsScript.DEFS.keys()
		for i in range(iids.size()):
			var iid: String = str(iids[i])
			var d3: Dictionary = ItemsScript.DEFS[iid]
			out.append({"kind": "item", "id": iid, "name": str(d3["name"]), "desc": str(d3["desc"]), "col": d3["col"], "on": int(train_items.get(iid, 0)), "count": int(train_items.get(iid, 0))})
	elif train_tab == 4:
		var lv_keys: Array = ["phys", "magic", "def", "hp", "mana"]
		var lv_names: Array = ["物理等级", "魔法等级", "防御等级", "生命等级", "法力等级"]
		for i2 in range(lv_keys.size()):
			var lk: String = str(lv_keys[i2])
			out.append({"kind": "level", "id": lk, "name": str(lv_names[i2]), "desc": "← → 调整数值（0~99）", "col": Color(0.86, 0.92, 1.0), "on": 1, "count": maxi(1, int(train_levels.get(lk, 3)))})
	else:
		for i in range(TRAIN_MONSTERS.size()):
			var mid: String = str(TRAIN_MONSTERS[i])
			var nm: String = mid
			var ds: String = ""
			if codex != null and codex.MONSTERS.has(mid):
				nm = str(codex.MONSTERS[mid]["name"])
				ds = str(codex.MONSTERS[mid]["desc"])
			out.append({"kind": "dummy", "id": mid, "name": nm, "desc": ds, "col": Color(0.86, 0.74, 0.74), "on": mid == train_dummy})
	return out


## 在配置界面按回车：选中 / 勾选
func train_activate(dir: int = 1) -> void:
	var list: Array = train_entries()
	if list.size() == 0:
		return
	var e: Dictionary = list[clampi(train_idx, 0, list.size() - 1)]
	var id: String = str(e["id"])
	var kind: String = str(e["kind"])
	if kind == "sword":
		train_sword = id
	elif kind == "ranged":
		train_ranged = id
	elif kind == "shield":
		train_shield = id
	elif kind == "level":
		train_levels[id] = clampi(int(train_levels.get(id, 3)) + dir, 0, 99)
	elif kind == "skill":
		train_skills[id] = int(train_skills.get(id, 0)) + 1
	elif kind == "item":
		train_items[id] = int(train_items.get(id, 0)) + 1
	else:
		train_dummy = id
	sfx_play("step", 1.2, -10.0)



## 沿走廊摆放所有可拾取的装备 / 技能 / 遗物
## 走廊长度 = 所有可拾取物名字的字符总数
func train_corridor_len() -> int:
	var total: int = 0
	for i in range(WeaponsScript.SWORD_IDS.size()):
		total += WeaponsScript.sword_name(str(WeaponsScript.SWORD_IDS[i])).length() + 2
	for i in range(WeaponsScript.GUN_IDS.size()):
		total += WeaponsScript.gun_name(str(WeaponsScript.GUN_IDS[i])).length() + 2
	for i in range(WeaponsScript.SHIELD_IDS.size()):
		total += WeaponsScript.shield_name(str(WeaponsScript.SHIELD_IDS[i])).length() + 2
	for id in SkillsScript.DEFS.keys():
		total += str(SkillsScript.DEFS[id]["name"]).length() + 2
	for id2 in ItemsScript.DEFS.keys():
		total += str(ItemsScript.DEFS[id2]["name"]).length() + 2
	return clampi(total, 60, 900)


func fill_train_pedestals() -> void:
	if dungeon == null or not is_instance_valid(dungeon):
		return
	dungeon.train_pedestals.clear()
	var entries: Array = []
	for i in range(WeaponsScript.SWORD_IDS.size()):
		var sid: String = str(WeaponsScript.SWORD_IDS[i])
		entries.append({"kind": "weapon", "cat": 0, "id": sid, "col": WeaponsScript.sword(sid)["col"]})
	for i in range(WeaponsScript.GUN_IDS.size()):
		var gid: String = str(WeaponsScript.GUN_IDS[i])
		entries.append({"kind": "weapon", "cat": 1, "id": gid, "col": WeaponsScript.gun(gid)["col"]})
	for i in range(WeaponsScript.SHIELD_IDS.size()):
		var hid: String = str(WeaponsScript.SHIELD_IDS[i])
		entries.append({"kind": "weapon", "cat": 2, "id": hid, "col": WeaponsScript.shield(hid)["col"]})
	var sids: Array = SkillsScript.DEFS.keys()
	for i in range(sids.size()):
		var kid: String = str(sids[i])
		entries.append({"kind": "skill", "id": kid, "col": SkillsScript.DEFS[kid]["col"] if SkillsScript.DEFS[kid].has("col") else Color(0.6, 1.0, 0.72)})
	var iids: Array = ItemsScript.DEFS.keys()
	for i in range(iids.size()):
		var iid: String = str(iids[i])
		entries.append({"kind": "item", "id": iid, "col": ItemsScript.DEFS[iid]["col"]})
	var n: int = entries.size()
	# 走廊从 22 格开始摆，间距 = 物品名字字符数 + 2（与 train_corridor_len 保持一致的规则）
	var corridor: int = train_corridor_len()
	for i in range(n):
		var e: Dictionary = entries[i]
		var nm: String = str(e["id"])
		if str(e["kind"]) == "weapon":
			var cat2: int = int(e.get("cat", 0))
			if cat2 == 0:
				nm = WeaponsScript.sword_name(str(e["id"]))
			elif cat2 == 1:
				nm = WeaponsScript.gun_name(str(e["id"]))
			else:
				nm = WeaponsScript.shield_name(str(e["id"]))
		elif str(e["kind"]) == "skill":
			nm = skills.name_of(str(e["id"])) if skills != null else str(e["id"])
		elif str(e["kind"]) == "item":
			nm = items.item_name(str(e["id"])) if items != null else str(e["id"])
		var nm_len: int = maxi(2, nm.length())
		var x: float = 24.0 + float(corridor) * float(i) / float(maxi(n, 1))
		nm_len = nm_len
		dungeon.train_pedestals.append({
			"kind": str(e["kind"]), "cat": int(e.get("cat", 0)), "id": str(e["id"]),
			"col": e["col"], "pos": Vector2(x * TILE, 28.0 * TILE), "taken": false,
		})


## 训练房：走过去按 T 拾取展示台上的东西
func train_try_pickup() -> void:
	if not training_mode or dungeon == null or player == null:
		return
	if near_pedestal < 0 or near_pedestal >= dungeon.train_pedestals.size():
		return
	var ped: Dictionary = dungeon.train_pedestals[near_pedestal]
	if bool(ped["taken"]):
		return
	ped["taken"] = true
	dungeon.train_pedestals[near_pedestal] = ped
	var id: String = str(ped["id"])
	if str(ped["kind"]) == "weapon":
		var cat: int = int(ped["cat"])
		if cat == 0:
			sword_id = id
		elif cat == 1:
			ranged_id = id
		else:
			shield_id = id
		apply_loadout()
		hud.msg("拾取武器：" + id, Color(0.9, 0.95, 1.0), 1.6)
	elif str(ped["kind"]) == "skill":
		grant_skill(false)
		if skills != null:
			skills.add(id)
		recalc_player_stats()
		hud.msg("获得技能：" + skills.name_of(id), Color(0.75, 1.0, 0.8), 1.6)
	else:
		grant_item(id)
	sfx_play("item", 1.1)
## 训练房：无限血木桩 + 自定义装备 / 遗物 / 技能
func start_training() -> void:
	training_mode = true
	run_active = false
	floor_index = 1
	run_seed = int(Time.get_ticks_usec() % 99999989)
	phys_level = int(train_levels.get("phys", 3))
	magic_level = int(train_levels.get("magic", 3))
	defense_level = int(train_levels.get("def", 3))
	hp_level = int(train_levels.get("hp", 3))
	mana_level = int(train_levels.get("mana", 3))
	sword_id = train_sword
	ranged_id = train_ranged
	shield_id = train_shield
	if skills != null:
		skills.clear()
		for sid2 in train_skills.keys():
			for k2 in range(int(train_skills[sid2])):
				skills.add(str(sid2))
	if items != null and is_instance_valid(items):
		items.clear()
		for iid2 in train_items.keys():
			for k3 in range(int(train_items[iid2])):
				items.add_item(str(iid2))
	state = "play"
	prev.clear()
	build_floor(false)
	fill_train_pedestals()
	apply_loadout()
	recalc_player_stats()
	# 清场，只留一个木桩
	for i in range(enemies.size()):
		var e = enemies[i]
		if e != null and is_instance_valid(e):
			e.queue_free()
	enemies.clear()
	dummy_kind = train_dummy
	spawn_dummy()
	# 把木桩挪到方形房间里
	if dummy_ref != null and is_instance_valid(dummy_ref) and dungeon != null:
		dummy_ref.position = dungeon.dummy_point
	hud.msg("训练房：走廊里走近物品按 T 拾取 · 1/2/3 换装 4遗物 5技能 6换木桩 · Esc 返回", Color(0.7, 0.95, 1.0), 6.0)


func spawn_dummy() -> void:
	if player == null or not is_instance_valid(player):
		return
	var pos: Vector2 = player.position + Vector2(150.0, 0.0)
	spawn_enemy(dummy_kind, pos, false, 1.0)
	if enemies.size() > 0:
		var e = enemies[enemies.size() - 1]
		if e != null and is_instance_valid(e):
			e.draw_scale = 1.45
			e.size = e.size * 1.35
			e.infinite_hp = true
			e.frozen = true
			e.can_split = false
			e.max_hp = 999999.0
			e.hp = e.max_hp
			dummy_ref = e


func leave_training() -> void:
	training_mode = false
	state = "title"
	build_floor(true)
	title_pan = cam.position.x


func training_cycle(slot: int) -> void:
	if not training_mode or player == null:
		return
	if slot == 0:
		var ids: Array = WeaponsScript.SWORD_IDS
		var i0: int = ids.find(sword_id)
		sword_id = str(ids[(i0 + 1) % ids.size()])
	elif slot == 1:
		var ids2: Array = WeaponsScript.GUN_IDS
		var i1: int = ids2.find(ranged_id)
		ranged_id = str(ids2[(i1 + 1) % ids2.size()])
	else:
		var ids3: Array = WeaponsScript.SHIELD_IDS
		var i2: int = ids3.find(shield_id)
		shield_id = str(ids3[(i2 + 1) % ids3.size()])
	apply_loadout()
	if codex != null:
		if slot == 0:
			codex.mark("weapons", sword_id)
		elif slot == 1:
			codex.mark("weapons", ranged_id)
		else:
			codex.mark("weapons", shield_id)


func training_cycle_dummy() -> void:
	var kinds: Array = ["slime", "slime_red", "slime_blue", "slime_metal", "slime_wood", "slime_earth",
		"zombie", "skeleton", "flesh", "goblin", "drake_small", "drake_large", "seadrake_large", "slime_king"]
	var i: int = kinds.find(dummy_kind)
	dummy_kind = str(kinds[(i + 1) % kinds.size()])
	if dummy_ref != null and is_instance_valid(dummy_ref):
		dummy_ref.queue_free()
	dummy_ref = null
	spawn_dummy()


func open_saves() -> void:
	refresh_slots()
	menu_prev_state = state
	state = "saves"
	menu_index = 0
	menu_msg = ""
	sfx_play("guard_up", 1.0, -6.0)


func open_settings() -> void:
	menu_prev_state = state
	state = "settings"
	settings_index = 0
	menu_msg = ""
	sfx_play("guard_up", 1.0, -6.0)


func close_menu() -> void:
	state = menu_prev_state
	menu_msg = ""
	save_settings_now()


func build_save_data() -> Dictionary:
	var it: Dictionary = {}
	if items != null and is_instance_valid(items):
		it = items.counts.duplicate()
	var sk: Dictionary = {}
	if skills != null:
		sk = skills.counts.duplicate()
	var guard: int = 0
	if items != null and is_instance_valid(items):
		guard = items.guard_charges
	return {
		"floor": floor_index,
		"coins": coins,
		"phys": phys_level,
		"magic": magic_level,
		"def": defense_level,
		"hp_lv": hp_level,
		"mana_lv": mana_level,
		"total_dmg": total_damage,
		"combo_best": combo_best,
		"run_kills": run_kills,
		"prism": prism_granted,
		"errsword": error_sword_granted,
		"errloop": err_loop_granted,
		"errarmor": err_armor_granted,
		"sword": sword_id,
		"ranged": ranged_id,
		"shield": shield_id,
		"skills": sk,
		"items": it,
		"guard": guard,
		"run_time": run_time,
		"best_floor": best_floor,
		"playtime": total_playtime,
		"saved_at": Time.get_datetime_string_from_system(),
	}


func save_to_slot(i: int) -> void:
	if storage == null:
		return
	if not run_active:
		menu_msg = "当前没有进行中的冒险，无法存档"
		sfx_play("block", 0.9, -8.0)
		return
	if storage.save_slot(i, build_save_data()):
		menu_msg = "已保存到存档 %d" % (i + 1)
		sfx_play("item", 1.2)
	else:
		menu_msg = "存档写入失败"
		sfx_play("block", 0.9, -8.0)
	refresh_slots()


func load_from_slot(i: int) -> void:
	if storage == null or not storage.has_slot(i):
		menu_msg = "槽位 %d 没有存档" % (i + 1)
		sfx_play("block", 0.9, -8.0)
		return
	var d: Dictionary = storage.load_slot(i)
	if d.is_empty():
		menu_msg = "存档损坏，无法读取"
		sfx_play("block", 0.9, -8.0)
		return
	apply_save_data(d)


func delete_slot(i: int) -> void:
	if storage == null:
		return
	if storage.has_slot(i):
		storage.delete_slot(i)
		menu_msg = "已删除存档 %d" % (i + 1)
		sfx_play("roll", 1.2, -8.0)
	else:
		menu_msg = "槽位 %d 没有存档" % (i + 1)
	refresh_slots()


func apply_save_data(d: Dictionary) -> void:
	floor_index = maxi(1, int(d.get("floor", 1)))
	coins = int(d.get("coins", 200))
	phys_level = int(d.get("phys", 0))
	magic_level = int(d.get("magic", 0))
	defense_level = int(d.get("def", 0))
	hp_level = int(d.get("hp_lv", 0))
	mana_level = int(d.get("mana_lv", 0))
	total_damage = float(d.get("total_dmg", 0.0))
	combo_best = int(d.get("combo_best", 0))
	run_kills = int(d.get("run_kills", 0))
	prism_granted = bool(d.get("prism", false))
	error_sword_granted = bool(d.get("errsword", false))
	err_loop_granted = bool(d.get("errloop", false))
	err_armor_granted = bool(d.get("errarmor", false))
	var sw: String = str(d.get("sword", "long"))
	var rg: String = str(d.get("ranged", "bow"))
	var sh: String = str(d.get("shield", "iron"))
	if WeaponsScript.SWORDS.has(sw):
		sword_id = sw
	else:
		sword_id = "long"
	if WeaponsScript.has_gun(rg):
		ranged_id = rg
	else:
		ranged_id = "bow"
	if WeaponsScript.SHIELDS.has(sh):
		shield_id = sh
	else:
		shield_id = "iron"
	run_time = float(d.get("run_time", 0.0))
	best_floor = maxi(best_floor, int(d.get("best_floor", 1)))
	var sk = d.get("skills", {})
	if skills != null:
		if typeof(sk) == TYPE_DICTIONARY:
			skills.restore(sk)
		else:
			skills.clear()
	var it = d.get("items", {})
	if items != null and is_instance_valid(items):
		if typeof(it) == TYPE_DICTIONARY:
			items.restore(it, int(d.get("guard", 0)))
		else:
			items.restore({}, 0)
	run_seed = int(Time.get_ticks_usec() % 99999989)
	kills = 0
	run_active = true
	weapon_queue.clear()
	pending_weapon = {}
	state = "play"
	build_floor(false)
	prev.clear()
	hud.msg("读取存档 · 第 %d 层" % floor_index, Color(0.8, 0.95, 1.0), 2.4)
	sfx_play("portal")


func adjust_setting(dir: int) -> void:
	if settings_index == 0:
		settings["volume"] = clampf(float(settings.get("volume", 0.8)) + float(dir) * 0.1, 0.0, 1.0)
	elif settings_index == 1:
		settings["shake"] = clampf(float(settings.get("shake", 1.0)) + float(dir) * 0.25, 0.0, 2.0)
	elif settings_index == 2:
		settings["fullscreen"] = not bool(settings.get("fullscreen", false))
	elif settings_index == 3:
		var ri: int = clampi(int(settings.get("resolution", 0)) + dir, 0, RES_OPTS.size() - 1)
		settings["resolution"] = ri
	elif settings_index == 4:
		var fi: int = (clampi(int(settings.get("fps", 1)), 0, FPS_OPTS.size() - 1) + dir + FPS_OPTS.size()) % FPS_OPTS.size()
		settings["fps"] = fi
	elif settings_index == 5:
		settings["show_fps"] = not bool(settings.get("show_fps", false))
	elif settings_index == 6:
		settings["quality"] = clampi(quality() + dir, 0, 2)
	elif settings_index == 7:
		settings["crosshair"] = not bool(settings.get("crosshair", true))
	elif settings_index == 9:
		settings["autoaim"] = not bool(settings.get("autoaim", false))
	elif settings_index == 10:
		settings["stickaim"] = not bool(settings.get("stickaim", true))
	elif settings_index == 11:
		settings["mouseaim"] = not bool(settings.get("mouseaim", true))
	elif settings_index == 12:
		settings["customkeys"] = not bool(settings.get("customkeys", true))
	elif settings_index == 8:
		open_keys()
	else:
		request_quit()
		return
	apply_settings()
	save_settings_now()
	sfx_play("step", 1.25, -10.0)


## 鼠标点击设置条目：选中并调整
func click_setting(i: int, rx: float, rw: float) -> void:
	settings_index = clampi(i, 0, SETTINGS_ROWS - 1)
	if i == 8:
		request_quit()
		return
	if i == 0 or i == 1:
		var t: float = clampf((rx - rw * 0.30) / (rw * 0.5), 0.0, 1.0)
		if i == 0:
			settings["volume"] = t
		else:
			settings["shake"] = t * 2.0
		apply_settings()
		save_settings_now()
		sfx_play("step", 1.25, -10.0)
		return
	adjust_setting(1)


# ---------------------------------------------------------------- 图鉴
func open_codex() -> void:
	codex_prev_state = state
	state = "codex"
	codex_index = 0
	sfx_play("guard_up", 1.0, -6.0)


func close_codex() -> void:
	if codex != null:
		codex.save_now()
	state = codex_prev_state


func theme_name() -> String:
	if dungeon == null:
		return ""
	return str(dungeon.theme["name"])


func theme_sub() -> String:
	if dungeon == null:
		return ""
	return str(dungeon.theme["sub"])


# ---------------------------------------------------------------- 主循环
func _physics_process(delta: float) -> void:
	_poll_pad()

	delta = minf(delta, 1.0 / 30.0)
	mouse_pos = get_viewport().get_mouse_position()

	# 菜单里显示鼠标指针，战斗中隐藏
	var menu_open: bool = state == "title" or state == "pause" or state == "dead" or state == "codex" or state == "saves" or state == "settings" or state == "shop" or state == "train_cfg" or state == "tp_confirm" or state == "keys"
	var want_mm: int = Input.MOUSE_MODE_VISIBLE if menu_open else Input.MOUSE_MODE_HIDDEN
	if Input.get_mouse_mode() != want_mm:
		Input.set_mouse_mode(want_mm)

	if quit_armed:
		quit_timer -= delta
		if quit_timer <= 0.0:
			quit_armed = false
			menu_msg = ""

	if dungeon != null and is_instance_valid(dungeon) and player != null and is_instance_valid(player):
		dungeon.mark_visited(player.position)
	if training_mode and cam != null and dungeon != null and is_instance_valid(dungeon):
		cam.position.y = dungeon.portal_point.y - 150.0
	if state == "play" or state == "shop" or state == "dead":
		total_playtime += delta
	# 训练房：检测最近的可拾取展示台
	if training_mode and dungeon != null and is_instance_valid(dungeon) and player != null and is_instance_valid(player):
		near_pedestal = -1
		var best_d: float = 64.0
		for i in range(dungeon.train_pedestals.size()):
			var pd: Dictionary = dungeon.train_pedestals[i]
			if bool(pd["taken"]):
				continue
			var dpos: Vector2 = pd["pos"]
			var dd: float = dpos.distance_to(player.position + Vector2(0, -20.0))
			if dd < best_d:
				best_d = dd
				near_pedestal = i
	else:
		near_pedestal = -1
	if combo > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0
			combo_timer = 0.0

	if state == "title":
		_title_update(delta)
		return
	if state == "codex":
		return
	if state == "saves" or state == "settings" or state == "pickup" or state == "train_cfg" or state == "tp_confirm" or state == "keys":
		return
	if state == "shop":
		if dungeon != null and is_instance_valid(dungeon):
			dungeon.update(delta)
		if fx != null:
			fx.update(delta)
		_update_camera(delta)
		return
	if state == "pause":
		# 暂停：冻结世界，只处理手柄导航
		_pad_pause_menu()
		_update_camera(delta)
		if fx != null:
			fx.update(delta)
		return

	var dt: float = delta
	if hitstop > 0.0:
		hitstop -= delta
		dt = 0.0

	if dt > 0.0:
		if state == "play":
			if training_mode and player != null and is_instance_valid(player):
				player.hp = player.max_hp
				player.mana = player.max_mana
			run_time += dt
			var inp: Dictionary = gather_input()
			if player != null and is_instance_valid(player):
				player.update(dt, inp)
			for i in range(enemies.size()):
				var e = enemies[i]
				if not is_instance_valid(e):
					continue
				var e_near: bool = bool(e.dead) or e.position.distance_to(player.position) < 1500.0
				e.visible = e_near
				if e_near:
					e.update(dt, player)
			_update_shots(dt)
			_update_summons(dt)
			_check_loot()
			_check_items()
			_check_chests()
			if items != null and is_instance_valid(items):
				items.update(dt)
		elif state == "dead":
			for i in range(enemies.size()):
				var e2 = enemies[i]
				if is_instance_valid(e2):
					e2.update(dt * 0.55, player)
			_update_shots(dt)
			_update_summons(dt)

	if state == "play":
		_check_portal()

	banner_time = maxf(0.0, banner_time - delta)
	if dungeon != null and is_instance_valid(dungeon):
		dungeon.update(delta)
	if fx != null:
		fx.update(delta)
	_update_camera(delta)
	_cleanup()
	shake_amount = move_toward(shake_amount, 0.0, 70.0 * delta)


func _title_update(delta: float) -> void:
	if dungeon == null or not is_instance_valid(dungeon):
		return
	title_pan += delta * 52.0
	var lr: Rect2 = dungeon.level_rect()
	var max_x: float = maxf(0.0, lr.size.x - 900.0)
	var span: float = max_x + 600.0
	var x: float = fmod(title_pan, span) - 300.0
	cam.position = Vector2(clampf(x, 0.0, max_x), lr.size.y * 0.45)
	dungeon.cam_pos = cam.position
	dungeon.view_size = get_viewport_rect().size
	dungeon.update(delta)
	for i in range(enemies.size()):
		var e = enemies[i]
		if is_instance_valid(e):
			e.update(delta, null)
	if fx != null:
		fx.update(delta)
	if player != null and is_instance_valid(player):
		player.queue_redraw()


func _update_camera(dt: float) -> void:
	if cam == null:
		return
	if dungeon != null and is_instance_valid(dungeon):
		dungeon.cam_pos = cam.position
		dungeon.view_size = get_viewport_rect().size
	if player == null or not is_instance_valid(player):
		return
	var target: Vector2 = player.position + Vector2(0, -34)
	if training_mode:
		target.y = dungeon.portal_point.y - 150.0 if dungeon != null and is_instance_valid(dungeon) else target.y
	if state == "play" and not training_mode:
		var ax: float = clampf(cos(player.aim), -1.0, 1.0)
		var ay: float = clampf(sin(player.aim), -1.0, 1.0)
		target += Vector2(ax * 40.0, ay * 16.0)
	cam.position = cam.position.lerp(target, clampf(dt * 8.0, 0.0, 1.0))
	if shake_amount > 0.2:
		cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_amount
	else:
		cam.offset = Vector2.ZERO


# ---------------------------------------------------------------- 输入
func _edge(name: String, down: bool) -> Dictionary:
	var was: bool = bool(prev.get(name, false))
	prev[name] = down
	return {"p": down and not was, "r": (not down) and was}


func gather_input() -> Dictionary:
	var k: Dictionary = {}
	var left: bool = _act("left")
	var right: bool = _act("right")
	var down: bool = _act("down")
	var jump: bool = _act("jump") or _act("up")
	var sword: bool = _act("sword") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var bow: bool = _act("bow") or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	var shield: bool = _act("shield") or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)
	var roll: bool = _act("roll")
	var heal: bool = _act("heal")
	var reload: bool = _act("reload")

	k["left"] = left
	k["right"] = right
	k["down"] = down
	k["up"] = _act("up") or _act("jump")
	k["jump_held"] = jump
	k["jump_pressed"] = bool(_edge("jump", jump)["p"])
	k["jump_released"] = bool(_edge("jump_rel", not jump)["p"])
	k["sword_held"] = sword
	k["sword_pressed"] = bool(_edge("sword", sword)["p"])
	k["bow_held"] = bow
	k["shield_held"] = shield
	k["roll_pressed"] = bool(_edge("roll", roll)["p"])
	k["heal_pressed"] = bool(_edge("heal", heal)["p"])
	k["reload_pressed"] = bool(_edge("reload", reload)["p"])

	# 右摇杆：移动即瞄准该方向并自动攻击
	var rs: Vector2 = Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	# ===== 瞄准优先级：自动瞄准 > 摇杆瞄准 > 鼠标 =====
	# 三个开关各自独立；任一关闭即彻底不参与，不会互相抢夺
	var use_auto: bool = bool(settings.get("autoaim", false))
	var use_stick: bool = bool(settings.get("stickaim", true))
	var use_mouse: bool = bool(settings.get("mouseaim", true))
	var rstick: bool = use_stick and rs.length() > 0.45
	var mp_now: Vector2 = get_global_mouse_position()
	var mouse_moved: bool = use_mouse and mp_now.distance_to(last_mouse) > 2.0
	last_mouse = mp_now
	if rstick:
		stick_aim_angle = rs.angle()
	# ① 自动瞄准：开关打开且有目标时独占（不再被摇杆/鼠标打断）
	var lock_on = null
	if use_auto and player != null and is_instance_valid(player):
		lock_on = _nearest_enemy_for_aim(player.position, 760.0)
	if lock_on != null:
		var at: Vector2 = lock_on.position + Vector2(0, -lock_on.size.y * 0.5)
		k["aim"] = (at - player.position).angle()
		stick_aim = true
		crosshair_world = at
	elif rstick:
		# ② 摇杆瞄准（仅在开启时）
		k["aim"] = stick_aim_angle
		stick_aim = true
		crosshair_world = player.position + Vector2(0, -34.0) + rs.normalized() * 170.0
	elif mouse_moved:
		# ③ 鼠标瞄准
		stick_aim = false
		k["aim"] = (mp_now - player.position).angle()
	else:
		# 保持上一次朝向，不抖动
		k["aim"] = stick_aim_angle
		if not use_auto:
			stick_aim = false
			k["aim"] = (mp_now - player.position).angle()
	return k




func _input(event: InputEvent) -> void:
	if state == "keys" and capturing:
		if event is InputEventKey and event.pressed and not event.echo:
			bind_captured(false, int(event.physical_keycode))
			get_viewport().set_input_as_handled()
			return
		if event is InputEventJoypadButton and event.pressed:
			bind_captured(true, int(event.button_index))
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo:
		var kc: int = event.physical_keycode
		if kc == KEY_F11:
			toggle_fullscreen()
			return
		if state == "pickup":
			if kc == KEY_E or kc == KEY_ENTER or kc == KEY_KP_ENTER or kc == KEY_SPACE:
				accept_weapon()
			elif kc == KEY_Q or kc == KEY_ESCAPE:
				decline_weapon()
			return
		if state == "tp_confirm":
			if kc == KEY_ENTER or kc == KEY_KP_ENTER or kc == KEY_SPACE or kc == KEY_F:
				confirm_teleport()
			elif kc == KEY_ESCAPE or kc == KEY_Q:
				cancel_teleport()
			return
		if state == "settings":
			if kc == KEY_9 or kc == KEY_KP_9:
				open_keys()
				return
			if kc == KEY_ESCAPE:
				close_menu()
				return
		if state == "keys":
			if kc == KEY_LEFT or kc == KEY_A or kc == KEY_1:
				keys_tab = 0
				capturing = false
				return
			if kc == KEY_RIGHT or kc == KEY_D or kc == KEY_2:
				keys_tab = 1
				capturing = false
				return
			if kc == KEY_UP:
				keys_index = (keys_index + ACTIONS.size() - 1) % ACTIONS.size()
				capturing = false
			elif kc == KEY_DOWN:
				keys_index = (keys_index + 1) % ACTIONS.size()
				capturing = false
			elif kc == KEY_ENTER or kc == KEY_KP_ENTER or kc == KEY_SPACE:
				capturing = true
			elif kc == KEY_DELETE or kc == KEY_BACKSPACE:
				reset_controls()
			elif kc == KEY_ESCAPE:
				close_keys()
			return
		if state == "train_cfg":
			var n_entry: int = train_entries().size()
			if kc == KEY_UP:
				train_idx = (train_idx + n_entry - 1) % maxi(n_entry, 1)
			elif kc == KEY_DOWN:
				train_idx = (train_idx + 1) % maxi(n_entry, 1)
			elif kc == KEY_LEFT or kc == KEY_A:
				start_training()
			elif kc == KEY_1:
				train_tab = 0
				train_idx = 0
			elif kc == KEY_2:
				train_tab = 1
				train_idx = 0
			elif kc == KEY_3:
				train_tab = 2
				train_idx = 0
			elif kc == KEY_4:
				train_tab = 3
				train_idx = 0
			elif kc == KEY_5:
				train_tab = 4
				train_idx = 0
			elif kc == KEY_E:
				train_tab = (train_tab + 1) % 5
				train_idx = 0
			elif kc == KEY_Q:
				train_tab = (train_tab + 4) % 5
				train_idx = 0
			elif kc == KEY_ENTER or kc == KEY_KP_ENTER or kc == KEY_SPACE:
				train_activate()
			elif kc == KEY_Y:
				start_training()
			elif kc == KEY_S:
				start_training()
			elif kc == KEY_ESCAPE:
				close_training_cfg()
			return
		if state == "saves":
			if kc == KEY_UP:
				menu_index = (menu_index + 2) % 3
			elif kc == KEY_DOWN:
				menu_index = (menu_index + 1) % 3
			elif kc == KEY_ENTER or kc == KEY_KP_ENTER:
				load_from_slot(menu_index)
			elif kc == KEY_F5 or kc == KEY_Y:
				save_to_slot(menu_index)
			elif kc == KEY_DELETE or kc == KEY_BACKSPACE:
				delete_slot(menu_index)
			elif kc == KEY_ESCAPE:
				close_menu()
			return
		if state == "settings":
			if kc == KEY_UP or kc == KEY_W:
				settings_index = (settings_index + SETTINGS_ROWS - 1) % SETTINGS_ROWS
			elif kc == KEY_DOWN or kc == KEY_S:
				settings_index = (settings_index + 1) % SETTINGS_ROWS
			elif kc == KEY_LEFT or kc == KEY_A:
				adjust_setting(-1)
			elif kc == KEY_RIGHT or kc == KEY_D:
				adjust_setting(1)
			elif kc == KEY_ENTER or kc == KEY_KP_ENTER or kc == KEY_SPACE:
				if settings_index == 13:
					request_quit()
				else:
					adjust_setting(1)
			elif kc == KEY_ESCAPE:
				quit_armed = false
				close_menu()
			return
		if state == "codex":
			if kc == KEY_TAB or kc == KEY_ESCAPE or kc == KEY_C:
				close_codex()
			elif kc == KEY_1 or kc == KEY_KP_1:
				codex_tab = 0
				codex_index = 0
			elif kc == KEY_2 or kc == KEY_KP_2:
				codex_tab = 1
				codex_index = 0
			elif kc == KEY_3 or kc == KEY_KP_3:
				codex_tab = 2
				codex_index = 0
			elif kc == KEY_4 or kc == KEY_KP_4:
				codex_tab = 3
				codex_index = 0
			elif kc == KEY_DOWN or kc == KEY_S:
				codex_index += 1
			elif kc == KEY_UP or kc == KEY_W:
				codex_index -= 1
			elif kc == KEY_LEFT or kc == KEY_A:
				codex_tab = (codex_tab + 3) % 4
				codex_index = 0
			elif kc == KEY_RIGHT or kc == KEY_D:
				codex_tab = (codex_tab + 1) % 4
				codex_index = 0
			if codex != null:
				var total: int = codex.total_count(codex.cat_id(codex_tab))
				codex_index = clampi(codex_index, 0, maxi(0, total - 1))
			return
		if state == "title":
			if kc == KEY_TAB or kc == KEY_C:
				open_codex()
				return
			if kc == KEY_O:
				open_settings()
				return
			if kc == KEY_F4:
				open_saves()
				return
			if kc == KEY_T:
				open_training_cfg()
				return
			if kc == KEY_K:
				open_keys()
				return
			start_run()
			return
		if kc == KEY_F4:
			if state == "play" or state == "pause" or state == "dead":
				open_saves()
				return
		if state == "shop":
			if kc == KEY_UP or kc == KEY_W:
				shop_sel = (shop_sel + 4) % 5
				return
			if kc == KEY_DOWN or kc == KEY_S:
				shop_sel = (shop_sel + 1) % 5
				return
			if kc == KEY_F or kc == KEY_LEFT or kc == KEY_A or kc == KEY_RIGHT or kc == KEY_D:
				var sk2: Array = ["phys", "magic", "def", "hp", "mana"]
				buy_upgrade(str(sk2[clampi(shop_sel, 0, 4)]))
				return
			if kc == KEY_1 or kc == KEY_KP_1:
				buy_upgrade("phys")
			elif kc == KEY_2 or kc == KEY_KP_2:
				buy_upgrade("magic")
			elif kc == KEY_3 or kc == KEY_KP_3:
				buy_upgrade("def")
			elif kc == KEY_4 or kc == KEY_KP_4:
				buy_upgrade("hp")
			elif kc == KEY_5 or kc == KEY_KP_5:
				buy_upgrade("mana")
			elif kc == KEY_ENTER or kc == KEY_KP_ENTER or kc == KEY_SPACE:
				descend()
			elif kc == KEY_ESCAPE:
				# 不进下一关，回到本层继续探索
				state = "play"
				shop_msg = ""
				sfx_play("block", 1.1, -10.0)
				hud.msg("已关闭商店（可继续在本层探索）", Color(0.85, 0.9, 1.0), 1.8)
			return
		if state == "play" and kc == KEY_F:
			try_interact()
			return
		if state == "play" and (kc == KEY_ENTER or kc == KEY_KP_ENTER or kc == KEY_SPACE):
			if dungeon != null and is_instance_valid(dungeon) and player != null and is_instance_valid(player):
				if not training_mode and dungeon.portal_open:
					if dungeon.portal_point.distance_to(player.position + Vector2(0, -20.0)) <= 96.0:
						open_shop()
						return
		if training_mode and state == "play":
			if kc == KEY_T:
				train_try_pickup()
				return
			if kc == KEY_F:
				try_interact()
				return
			if kc == KEY_1:
				training_cycle(0)
				return
			if kc == KEY_2:
				training_cycle(1)
				return
			if kc == KEY_3:
				training_cycle(2)
				return
			if kc == KEY_4:
				grant_item(items.random_id())
				return
			if kc == KEY_5:
				grant_skill(false)
				return
			if kc == KEY_6:
				training_cycle_dummy()
				return
			if kc == KEY_ESCAPE:
				leave_training()
				return
		if kc == KEY_TAB or kc == KEY_C:
			if state == "play" or state == "dead" or state == "pause":
				open_codex()
				return
		if kc == KEY_F4:
			if state == "play" or state == "pause" or state == "dead":
				open_saves()
				return
		if state == "pause":
			if kc == KEY_UP or kc == KEY_W:
				pause_sel = (pause_sel + 3) % 5
				return
			if kc == KEY_DOWN or kc == KEY_S:
				pause_sel = (pause_sel + 1) % 5
				return
			if kc == KEY_ENTER or kc == KEY_KP_ENTER or kc == KEY_SPACE:
				if pause_sel == 0:
					state = "play"
				elif pause_sel == 1:
					open_settings()
				elif pause_sel == 2:
					back_to_title()
				elif pause_sel == 3:
					open_saves()
				else:
					request_quit()
				return
		if kc == KEY_O:
			if state == "pause" or state == "dead":
				open_settings()
				return
		if kc == KEY_Q:
			if state == "play":
				if player != null and is_instance_valid(player):
					if player.flasks < player.max_flasks:
						player.flasks += 1
						game_regen_flask_msg()
				return
		if kc == KEY_ESCAPE:
			if state == "play":
				state = "pause"
			elif state == "pause":
				state = "play"
		elif kc == KEY_R:
			if state == "dead" or state == "pause":
				start_run()
		elif kc == KEY_N:
			if sfx != null:
				sfx.set_muted(not sfx.muted)
				hud.msg("静音：%s" % ("开" if sfx.muted else "关"), Color(0.8, 0.8, 0.8), 1.2)
	elif event is InputEventMouseButton and event.pressed:
		var mp: Vector2 = get_viewport().get_mouse_position()
		var vs2: Vector2 = get_viewport_rect().size
		if state == "shop":
			if hud != null:
				var kinds3: Array = ["phys", "magic", "def", "hp", "mana"]
				for i in range(5):
					if hud.shop_row_rect(i, vs2).has_point(mp):
						shop_sel = i
						buy_upgrade(str(kinds3[i]))
						return
			return
		if state == "pause":
			if hud != null:
				for i in range(5):
					if hud.pause_opt_rect(i, vs2).has_point(mp):
						pause_sel = i
						if i == 0:
							state = "play"
						elif i == 1:
							open_settings()
						elif i == 2:
							back_to_title()
						elif i == 3:
							open_saves()
						else:
							request_quit()
						return
			return
		if state == "title":
			if hud != null:
				if hud.title_quit_rect(vs2).has_point(mp):
					request_quit()
					return
				if hud.title_menu_rect(vs2).has_point(mp):
					open_saves()
					return
			start_run()
			return
		if state == "settings":
			if hud != null:
				for i in range(SETTINGS_ROWS):
					var r: Rect2 = hud.settings_row_rect(i, vs2)
					if r.has_point(mp):
						click_setting(i, mp.x - r.position.x, r.size.x)
						return
			return
		if state == "saves":
			if hud != null:
				for i in range(3):
					if hud.slot_rect(i, vs2).has_point(mp):
						if i == int(menu_index):
							load_from_slot(i)
						else:
							menu_index = i
						return
			return
func spawn_enemy(kind: String, pos: Vector2, elite: bool = false, mult: float = 1.0) -> void:
	if dungeon == null:
		return
	if enemies.size() >= MAX_ENEMIES:
		return
	var e = EnemyScript.new()
	e.setup(self, dungeon, kind, pos, elite, mult)
	entity_holder.add_child(e)
	e.apply_quality(quality())
	enemies.append(e)
	if codex != null:
		codex.mark("monsters", kind)
		if elite:
			codex.mark("monsters", "elite")


## 生成一只召唤物（召唤类武器）
func spawn_summon(variant: String, pos: Vector2, col: Color, dmg_v: float, elem_v: String, ghost_v: bool, support_v: bool, life_v: float = 15.0, splash_v: float = 0.0, heal_v: float = 0.0, speed_v: float = 1.0) -> void:
	if dungeon == null or player == null:
		return
	if summons.size() >= 24:
		return
	var s = SummonScript.new()
	s.setup(self, dungeon, player, variant, col)
	s.configure(dmg_v, elem_v, ghost_v, support_v, life_v, summons.size())
	s.splash = splash_v
	s.heal_amt = heal_v
	s.speed *= speed_v
	s.position = pos
	entity_holder.add_child(s)
	summons.append(s)


func _update_summons(dt: float) -> void:
	var i: int = summons.size() - 1
	while i >= 0:
		var s = summons[i]
		if s == null or not is_instance_valid(s):
			summons.remove_at(i)
			i -= 1
			continue
		s.update(dt)
		i -= 1


func spawn_shot(kind: String, pos: Vector2, vel: Vector2, dmg: float, from_player: bool, scale_v: float = 1.0, elem: String = "", pierce: int = 0, status: String = "", status2: String = "") -> void:
	if dungeon == null:
		return
	var s = ShotScript.new()
	s.setup(self, dungeon, kind, pos, vel, dmg, from_player, scale_v, elem, pierce, status, status2)
	entity_holder.add_child(s)
	shots.append(s)


## 范围伤害（元素爆炸 / 冲击波用）
func damage_area(pos: Vector2, radius: float, dmg: float, dir: Vector2, from_player: bool = true) -> int:
	var n: int = 0
	if from_player:
		for i in range(enemies.size()):
			var e = enemies[i]
			if e == null or not is_instance_valid(e) or e.dead:
				continue
			var c: Vector2 = e.position + Vector2(0, -e.size.y * 0.5)
			if c.distance_to(pos) <= radius:
				var d2: Vector2 = (c - pos)
				if d2.length() < 0.1:
					d2 = dir
				e.hurt(dmg, d2.normalized(), 200.0, 0.18)
				n += 1
	else:
		if player != null and is_instance_valid(player) and not player.dead:
			var cp: Vector2 = player.position + Vector2(0, -player.size.y * 0.5)
			if cp.distance_to(pos) <= radius:
				player.hurt(dmg, pos, "trap")
				n += 1
	return n


func _update_shots(dt: float) -> void:
	var i: int = shots.size() - 1
	while i >= 0:
		var s = shots[i]
		if s == null or not is_instance_valid(s):
			shots.remove_at(i)
			i -= 1
			continue
		if bool(s.kill_me):
			s.queue_free()
			shots.remove_at(i)
			i -= 1
			continue
		s.update(dt)
		i -= 1


## 记录一次伤害：累计伤害 + 连击
func note_damage(amount: float) -> void:
	total_damage += maxf(0.0, amount)
	combo += 1
	combo_timer = 2.6
	if combo > combo_best:
		combo_best = combo


## 连击越高，伤害数字越大
func combo_scale() -> float:
	return clampf(1.0 + float(combo) * 0.018, 1.0, 2.2)


func hit_feedback(pos: Vector2, dir: Vector2, crit: bool) -> void:
	if fx == null:
		return
	if crit:
		fx.spark_spawn(pos + Vector2(0, -16), dir, 14, Color(1.0, 0.86, 0.45))
		fx.ring_spawn(pos + Vector2(0, -16), 34.0, Color(1.0, 0.9, 0.6))
		shake(3.5)
	else:
		fx.spark_spawn(pos + Vector2(0, -16), dir, 7, Color(0.92, 0.92, 1.0))


func reflect_shots(center: Vector2, dir_x: float) -> void:
	for i in range(shots.size()):
		var s = shots[i]
		if s == null or not is_instance_valid(s):
			continue
		if bool(s.from_player):
			continue
		if s.position.distance_to(center) < 190.0:
			s.from_player = true
			s.vel = Vector2(-s.vel.x * 1.4, -s.vel.y * 0.4 - 120.0)
			s.dmg = float(s.dmg) * 1.7 + 6.0
			if fx != null:
				fx.spark_spawn(s.position, Vector2(dir_x, -0.4), 8, Color(0.75, 0.95, 1.0))


func hit_stop(sec: float) -> void:
	hitstop = maxf(hitstop, sec)


func shake(amount: float) -> void:
	var k: float = float(settings.get("shake", 1.0))
	if k <= 0.01:
		return
	shake_amount = maxf(shake_amount, amount * k)


func sfx_play(sound: String, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	if sfx != null:
		sfx.play(sound, pitch, vol_db)


# ---------------------------------------------------------------- 掉落 / 宝箱
func on_enemy_killed(e) -> void:
	kills += 1
	run_kills += 1
	# ---- 极稀有掉落（0.001%），只在普通小怪身上判定 ----
	if not bool(e.elite) and not bool(e.boss):
		if not prism_granted and ranged_id != "staff_prism":
			if randf() < 0.00001:
				prism_granted = true
				hud.msg("泰拉棱镜降临！", Color(0.86, 0.96, 1.0), 2.6)
				sfx_play("portal")
				offer_weapon(1, "staff_prism")
		if not error_sword_granted and sword_id != "error_sword":
			if randf() < 0.00001:
				error_sword_granted = true
				hud.msg("错误剑出现了…", Color(1.0, 0.3, 0.9), 2.6)
				sfx_play("portal")
				offer_weapon(0, "error_sword")
		if not err_armor_granted and shield_id != "armor_error":
			if randf() < 0.00001:
				err_armor_granted = true
				hud.msg("错误之甲出现了…", Color(1.0, 0.24, 0.88), 2.6)
				sfx_play("portal")
				offer_weapon(2, "armor_error")
		if not err_loop_granted and items != null and items.count_of("orbit_error") <= 0:
			if randf() < 0.00001:
				err_loop_granted = true
				hud.msg("错误之环出现了…", Color(1.0, 0.24, 0.88), 2.6)
				sfx_play("portal")
				grant_item("orbit_error")
	# 汲魔石等：击杀回蓝
	if player != null and is_instance_valid(player) and items != null and is_instance_valid(items):
		var km: float = items.kill_mana()
		if km > 0.0:
			player.mana = minf(player.max_mana, player.mana + km)
	if bool(e.boss):
		_boss_reward(e)
	if dungeon == null or not is_instance_valid(dungeon):
		return
	var drop_pos: Vector2 = e.position + Vector2(0, -18)
	dungeon.loots.append({"pos": drop_pos, "kind": "coin", "taken": false, "seed": randf()})
	if bool(e.elite):
		for i in range(3):
			dungeon.loots.append({"pos": e.position + Vector2(-24.0 + float(i) * 24.0, -26.0), "kind": "coin", "taken": false, "seed": randf()})
		if items != null and is_instance_valid(items):
			dungeon.item_drops.append({"pos": e.position, "id": items.random_id(), "taken": false, "seed": randf()})
		if randf() < 0.35:
			grant_skill(false)
		if randf() < 0.25:
			grant_weapon()
		shake(6.0)
	if randf() < 0.12:
		dungeon.loots.append({"pos": e.position + Vector2(18.0, -30.0), "kind": "coin", "taken": false, "seed": randf()})
	if randf() < 0.14:
		dungeon.loots.append({"pos": e.position + Vector2(-20.0, -24.0), "kind": "hp", "taken": false, "seed": randf()})
	if randf() < 0.05 and items != null and is_instance_valid(items):
		dungeon.item_drops.append({"pos": e.position, "id": items.random_id(), "taken": false, "seed": randf()})
	if randf() < 0.02:
		grant_skill(randf() < 0.45)


func _check_loot() -> void:
	if dungeon == null or player == null or not is_instance_valid(player):
		return
	var loots: Array = dungeon.loots
	var body: Vector2 = player.position + Vector2(0, -22)
	var rad: float = pickup_radius()
	for i in range(loots.size()):
		var lt: Dictionary = loots[i]
		if bool(lt["taken"]):
			continue
		var lp: Vector2 = lt["pos"]
		if lp.distance_to(body) < rad:
			lt["taken"] = true
			var kd: String = str(lt["kind"])
			if kd == "coin" or kd == "cells":
				var gain: int = coin_gain()
				coins += gain
				sfx_play("coin", 1.0 + randf() * 0.12, -6.0)
			elif kd == "hp":
				player.hp = minf(player.max_hp, player.hp + player.max_hp * 0.22)
				sfx_play("heal")
				fx.text(lp, "生命 +22%", Color(0.5, 1.0, 0.62), 16)


func _check_items() -> void:
	if dungeon == null or player == null or not is_instance_valid(player):
		return
	var body: Vector2 = player.position + Vector2(0, -22)
	var rad: float = pickup_radius()
	var drops: Array = dungeon.item_drops
	for i in range(drops.size()):
		var it: Dictionary = drops[i]
		if bool(it["taken"]):
			continue
		var ip: Vector2 = it["pos"] + Vector2(0, -20)
		if ip.distance_to(body) < rad:
			it["taken"] = true
			grant_item(str(it["id"]))


func _check_chests() -> void:
	if dungeon == null or player == null:
		return
	var body: Vector2 = player.position + Vector2(0, -20)
	for i in range(dungeon.chests.size()):
		var ch: Dictionary = dungeon.chests[i]
		if bool(ch["opened"]):
			continue
		var cp: Vector2 = ch["pos"] + Vector2(0, -20)
		if cp.distance_to(body) < 54.0:
			ch["opened"] = true
			_open_chest(ch["pos"])


func _open_chest(pos: Vector2) -> void:
	sfx_play("chest")
	shake(3.0)
	if fx != null:
		fx.ring_spawn(pos + Vector2(0, -20), 62.0, Color(1.0, 0.86, 0.42))
		fx.spark_spawn(pos + Vector2(0, -20), Vector2(0, -1), 20, Color(1.0, 0.9, 0.5))
	var roll: float = randf()
	if roll < 0.40:
		grant_random_item()
	elif roll < 0.66:
		grant_weapon()
	elif roll < 0.86:
		grant_skill(false)
	else:
		var c: int = int(round((18.0 + float(floor_index) * 8.0) * sqrt(stat_mult()) * (skills.val("coin") if skills != null else 1.0)))
		coins += c
		hud.msg("宝箱：金币 +" + str(c), Color(0.95, 0.84, 0.42), 1.8)


func grant_item(id: String) -> void:
	if items == null or not is_instance_valid(items):
		return
	# 翅膀是互斥遗物：已经有另一种翅膀时先问要不要换
	if items.is_wing(id):
		var old_wing: String = items.wing_id()
		if old_wing != "" and old_wing != id:
			offer_relic(id, old_wing)
			return
	items.add_item(id)
	var col: Color = items.item_col(id)
	var nm: String = items.item_name(id)
	var n: int = items.count_of(id)
	if codex != null:
		codex.mark("items", id)
	hud.msg("获得遗物：" + nm + " ×" + str(n) + " · " + items.item_desc(id), col, 2.8)
	sfx_play("item")
	if fx != null and player != null and is_instance_valid(player):
		var pos: Vector2 = player.position
		fx.ring_spawn(pos + Vector2(0, -24), 56.0, col)
		fx.text(pos + Vector2(0, -74), nm, col, 21)
		fx.spark_spawn(pos + Vector2(0, -26), Vector2(0, -1), 14, col)


func grant_random_item() -> void:
	if items == null or not is_instance_valid(items):
		return
	grant_item(items.random_id())


func grant_weapon() -> void:
	if player == null or not is_instance_valid(player):
		return
	var cat: int = randi() % 3
	var id: String = ""
	# 召唤类武器单独加权：额外 20% 概率直接掉落一把召唤杖
	if randf() < 0.20:
		cat = 1
		id = WeaponsScript.random_summon()
	elif cat == 0:
		id = WeaponsScript.random_sword()
	elif cat == 1:
		id = WeaponsScript.random_gun()
	else:
		id = WeaponsScript.random_shield()
	# 不再直接替换，而是弹出对比界面询问玩家
	offer_weapon(cat, id)


func grant_skill(force_bad: bool = false) -> void:
	if skills == null:
		return
	var bad: bool = force_bad or randf() < 0.3
	var id: String = skills.random_bad() if bad else skills.random_good()
	skills.add(id)
	if codex != null:
		codex.mark("skills", id)
	recalc_player_stats()
	var col: Color = skills.col_of(id)
	hud.msg(("诅咒：" if bad else "技能：") + skills.name_of(id) + " · " + skills.desc_of(id), col, 2.9)
	sfx_play("item", 0.9 if bad else 1.1)
	if fx != null and player != null and is_instance_valid(player):
		fx.ring_spawn(player.position + Vector2(0, -24), 50.0, col)


func _check_portal() -> void:
	if dungeon == null or player == null or not is_instance_valid(player):
		return
	# 训练房没有传送门
	if training_mode:
		dungeon.portal_open = false
		return
	dungeon.portal_open = kills >= kills_required
	if dungeon.portal_open and not portal_was_open:
		portal_was_open = true
		hud.msg("封印解除 · 传送门已开启", Color(0.6, 1.0, 0.82), 2.4)
		sfx_play("portal")
		fx.ring_spawn(dungeon.portal_point + Vector2(0, -30), 90.0, Color(0.6, 1.0, 0.85))
	# 传送门不再自动进入：靠近后按 F 交互（见 try_interact）
	if dungeon.portal_open and not portal_hint_shown and player.position.distance_to(dungeon.portal_point) < 90.0:
		portal_hint_shown = true
		hud.msg("按 F 进入传送门", Color(0.75, 0.95, 1.0), 2.0)


func on_player_death() -> void:
	runs += 1
	run_active = false
	if floor_index > best_floor:
		best_floor = floor_index
	state = "dead"
	sfx_play("dead")
	shake(15.0)
	if codex != null:
		codex.save_now()
	save_settings_now()
	if fx != null and player != null:
		fx.blood_spawn(player.position + Vector2(0, -24), Vector2(0, -1), 46, Color(0.5, 0.05, 0.10))
		fx.ring_spawn(player.position + Vector2(0, -20), 70.0, Color(0.6, 0.1, 0.12))
	hud.msg("你死了", Color(0.8, 0.3, 0.3), 2.0)


func _cleanup() -> void:
	var i: int = enemies.size() - 1
	while i >= 0:
		var e = enemies[i]
		if e == null or not is_instance_valid(e):
			enemies.remove_at(i)
		elif bool(e.dead) and float(e.dead_timer) > 1.15:
			e.queue_free()
			enemies.remove_at(i)
		i -= 1

var drop_queue: Array = []


## 逐个处理掉落：技能立即获得，装备/遗物弹询问
func _pump_drop_queue() -> void:
	if drop_queue.size() == 0:
		return
	if state == "pickup":
		return
	var it: Dictionary = drop_queue.pop_front()
	if str(it["kind"]) == "wep":
		offer_weapon(int(it["cat"]), str(it["id"]))
	else:
		# 遗物 / 召唤物：先问是否拾取
		offer_item(str(it["id"]))


## 确认传送
func confirm_teleport() -> void:
	if pending_tp.is_empty():
		state = "play"
		return
	var tp: Dictionary = pending_tp
	# 楼层传送门：确认后进入下一关商店
	if bool(tp.get("portal", false)):
		pending_tp = {}
		state = "play"
		open_shop()
		return
	pending_tp = {}
	state = "play"
	if player == null or not is_instance_valid(player):
		return
	player.position = tp["target"] + Vector2(0, -2.0)
	player.vel = Vector2.ZERO
	cam.position = player.position + Vector2(0, -40)
	if dungeon != null and is_instance_valid(dungeon):
		dungeon.mark_visited(player.position)
	sfx_play("portal", 1.2, -4.0)
	fx.ring_spawn(player.position + Vector2(0, -24), 70.0, Color(0.6, 0.95, 1.0))
	hud.msg("传送 · " + str(tp["label"]), Color(0.8, 0.95, 1.0), 1.6)


## 取消传送（留在当前房间继续探索）
func cancel_teleport() -> void:
	pending_tp = {}
	state = "play"
	sfx_play("block", 1.1, -10.0)
	hud.msg("已取消传送", Color(0.8, 0.82, 0.88), 1.2)


## 询问是否拾取一件遗物
func offer_item(id: String) -> void:
	if items == null or not is_instance_valid(items) or not items.DEFS.has(id):
		return
	if state == "pickup":
		drop_queue.append({"kind": "item", "id": id})
		return
	pending_weapon = {"kind": "item", "id": id}
	pickup_prev_state = state
	state = "pickup"
	if codex != null:
		codex.mark("items", id)
	sfx_play("item", 1.2, -4.0)


## F 键交互：训练房双向传送门 / 普通模式进入下一关商店
func try_interact() -> void:
	if player == null or not is_instance_valid(player):
		return
	if dungeon == null or not is_instance_valid(dungeon):
		return
	# 优先：楼层传送门（进入下一关的升级商店）
	if not training_mode and dungeon.portal_open:
		if dungeon.portal_point.distance_to(player.position + Vector2(0, -20.0)) <= 96.0:
			# 弹出确认，确认后才进入下一关商店
			pending_tp = {"label": "下一关", "portal": true, "target": Vector2.ZERO}
			state = "tp_confirm"
			sfx_play("guard_up", 1.05, -8.0)
			return
	for i in range(dungeon.teleporters.size()):
		var tp: Dictionary = dungeon.teleporters[i]
		var tp_pos: Vector2 = tp["pos"]
		if tp_pos.distance_to(player.position + Vector2(0, -20.0)) <= 62.0:
			# 先弹确认，取消就留在本房间继续探索
			pending_tp = tp
			state = "tp_confirm"
			sfx_play("guard_up", 1.05, -8.0)
			return
	if training_mode:
		return




# ---------------------------------------------------------------- 按键 / 手柄
const ACTIONS := ["left", "right", "up", "down", "jump", "sword", "bow", "shield", "roll", "heal", "reload", "interact"]

var keys_cfg: Dictionary = {}
var pad_cfg: Dictionary = {}
var keys_index := 0
var keys_tab := 0
var _pad_prev: Dictionary = {}
var stick_aim := false
var stick_aim_angle := 0.0
var last_mouse := Vector2.ZERO
var autoaim_target = null
var crosshair_world := Vector2.ZERO
var capturing := false


func actions() -> Array:
	return ACTIONS


func action_name(a: String) -> String:
	match a:
		"left": return "左移动"
		"right": return "右移动"
		"up": return "上 / 抬头"
		"down": return "下蹲"
		"jump": return "跳跃"
		"sword": return "近战攻击"
		"bow": return "远程攻击"
		"shield": return "举盾"
		"roll": return "翻滚"
		"heal": return "喝药"
		"reload": return "换弹"
		"interact": return "交互"
	return a


func key_name(code: int) -> String:
	if code <= 0:
		return "—"
	var s: String = OS.get_keycode_string(code)
	return s if s != "" else str(code)


func pad_name(btn: int) -> String:
	if btn < 0:
		return "—"
	var names: Dictionary = {
		JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
		JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
		JOY_BUTTON_BACK: "BACK", JOY_BUTTON_START: "START",
		JOY_BUTTON_DPAD_UP: "↑", JOY_BUTTON_DPAD_DOWN: "↓",
		JOY_BUTTON_DPAD_LEFT: "←", JOY_BUTTON_DPAD_RIGHT: "→",
	}
	return str(names.get(btn, "BTN" + str(btn)))


## 某个动作当前是否被按下（键盘 + 手柄 + 摇杆）
func _act(a: String) -> bool:
	# 自定义按键关闭时使用内置默认键位（但仍可玩）
	if not bool(settings.get("customkeys", true)):
		var dk: Dictionary = storage.default_keys()
		var dp: Dictionary = storage.default_pad()
		var dks: Array = dk.get(a, [])
		for i2 in range(dks.size()):
			if Input.is_physical_key_pressed(int(dks[i2])):
				return true
		var dps: Array = dp.get(a, [])
		for i3 in range(dps.size()):
			if Input.is_joy_button_pressed(0, int(dps[i3])):
				return true
	var ks: Array = keys_cfg.get(a, [])
	for i in range(ks.size()):
		if Input.is_physical_key_pressed(int(ks[i])):
			return true
	var bs: Array = pad_cfg.get(a, [])
	for i in range(bs.size()):
		if _pad_down(int(bs[i])):
			return true
	# 左摇杆
	var ax: float = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var ay: float = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if a == "left" and ax < -0.45:
		return true
	if a == "right" and ax > 0.45:
		return true
	if a == "down" and ay > 0.55:
		return true
	if a == "up" and ay < -0.55:
		return true
	# 扳机
	if a == "sword" and Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0.4:
		return true
	if a == "shield" and Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT) > 0.4:
		return true
	return false


func open_keys() -> void:
	if settings.has("keys") and settings["keys"] is Dictionary:
		keys_cfg = settings["keys"].duplicate(true)
	if settings.has("pad") and settings["pad"] is Dictionary:
		pad_cfg = settings["pad"].duplicate(true)
	keys_index = 0
	capturing = false
	state = "keys"
	sfx_play("step", 1.1, -8.0)


func close_keys() -> void:
	settings["keys"] = keys_cfg
	settings["pad"] = pad_cfg
	save_settings_now()
	state = "settings"
	sfx_play("block", 1.0, -10.0)


## 捕获一次按键 / 手柄键并绑定
func bind_captured(is_pad: bool, code: int) -> void:
	var a: String = str(ACTIONS[clampi(keys_index, 0, ACTIONS.size() - 1)])
	if is_pad:
		pad_cfg[a] = [code]
	else:
		keys_cfg[a] = [code]
	capturing = false
	sfx_play("item", 1.1)


func reset_controls() -> void:
	keys_cfg = storage.default_keys()
	pad_cfg = storage.default_pad()
	capturing = false
	sfx_play("step", 1.0, -8.0)






## 应用「固定墙壁背景」设置
func apply_wall_setting() -> void:
	var on: bool = bool(settings.get("wall_bg", false))
	if dungeon != null and is_instance_valid(dungeon):
		dungeon.wall_on = on
		dungeon.queue_redraw()
	if wall_bg != null and is_instance_valid(wall_bg):
		wall_bg.visible = false

## 把已保存的配置与默认值合并（缺项自动补默认，旧存档也能用手柄/键盘）
func _merge_cfg(def: Dictionary, saved) -> Dictionary:
	var out: Dictionary = def.duplicate(true)
	if saved is Dictionary:
		for k in saved.keys():
			var v = saved[k]
			if v is Array and v.size() > 0:
				out[str(k)] = v
	return out








# ---------------------------------------------------------------- 手柄 → 键盘事件
var _pad_state: Dictionary = {}
var _pad_axis: Vector2 = Vector2.ZERO
var _lt_prev := 0.0
var _rt_prev := 0.0


func _pad_down(btn: int) -> bool:
	var pads: Array = Input.get_connected_joypads()
	if pads.size() == 0:
		return false
	return Input.is_joy_button_pressed(int(pads[0]), btn)


## 边沿检测
func _pad_edge(btn: int) -> bool:
	var now: bool = _pad_down(btn)
	var was: bool = bool(_pad_state.get(btn, false))
	_pad_state[btn] = now
	return now and not was


func _fake_key(code: int) -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.physical_keycode = code
	_input(ev)
	var up := InputEventKey.new()
	up.pressed = false
	up.physical_keycode = code
	_input(up)


## 把手柄按键映射成全游戏通用的按键事件
func _poll_pad() -> void:
	if Input.get_connected_joypads().size() == 0:
		_pad_state.clear()
		return
	# 传送确认界面：A 确认 / B 取消
	if state == "tp_confirm":
		if _pad_edge(JOY_BUTTON_A):
			confirm_teleport()
			return
		if _pad_edge(JOY_BUTTON_B):
			cancel_teleport()
			return
		return
	# 战斗中：START = 暂停；其余按键由 _act() 轮询，避免与菜单返回键冲突
	if state == "play":
		if _pad_edge(JOY_BUTTON_START):
			state = "pause"
			sfx_play("ui", 1.0, -8.0)
		# 手柄交互键（默认 Y）→ 传送门 / 训练场拾取
		var ibs: Array = pad_cfg.get("interact", [])
		var ibtn: int = int(ibs[0]) if ibs.size() > 0 else JOY_BUTTON_Y
		if _pad_edge(ibtn):
			if training_mode:
				train_try_pickup()
			try_interact()
		return
	# 训练场配置页：LB/RB 翻页，LT/RT 调节数量
	if state == "train_cfg":
		var n_e: int = train_entries().size()
		if _pad_edge(JOY_BUTTON_DPAD_UP):
			train_idx = (train_idx + n_e - 1) % maxi(n_e, 1)
			return
		if _pad_edge(JOY_BUTTON_DPAD_DOWN):
			train_idx = (train_idx + 1) % maxi(n_e, 1)
			return
		if _pad_edge(JOY_BUTTON_A):
			train_activate()
			return
		if _pad_edge(JOY_BUTTON_DPAD_LEFT):
			start_training()
			return
		if _pad_edge(JOY_BUTTON_RIGHT_SHOULDER):
			train_tab = (train_tab + 1) % 5
			train_idx = 0
			return
		if _pad_edge(JOY_BUTTON_LEFT_SHOULDER):
			train_tab = (train_tab + 4) % 5
			train_idx = 0
			return
		var lt2: float = Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT)
		var rt2: float = Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT)
		if lt2 > 0.4 and _lt_prev <= 0.4:
			train_activate(-1)
		if rt2 > 0.4 and _rt_prev <= 0.4:
			train_activate(1)
		_lt_prev = lt2
		_rt_prev = rt2
		if _pad_edge(JOY_BUTTON_B):
			close_training_cfg()
		return
	# 商店 / 升级界面：上下选择，右键（D-pad →）确认升级，A 下潜
	# 商店 / 升级界面：上下选择，右键（D-pad →）确认升级，A 下潜
	if state == "shop":
		if _pad_edge(JOY_BUTTON_DPAD_UP) or _pad_edge(JOY_BUTTON_DPAD_LEFT):
			shop_sel = (shop_sel + 4) % 5
		if _pad_edge(JOY_BUTTON_DPAD_DOWN):
			shop_sel = (shop_sel + 1) % 5
		if _pad_edge(JOY_BUTTON_DPAD_RIGHT) or _pad_edge(JOY_BUTTON_X):
			var kinds: Array = ["phys", "magic", "def", "hp", "mana"]
			buy_upgrade(str(kinds[clampi(shop_sel, 0, 4)]))
		if _pad_edge(JOY_BUTTON_B):
			state = "play"
			sfx_play("ui", 1.0, -8.0)
			return
		if _pad_edge(JOY_BUTTON_A):
			descend()
		return
	# 标题页 / 死亡页：A = 开始 / 重生
	if state == "title":
		if _pad_edge(JOY_BUTTON_DPAD_LEFT):
			_fake_key(KEY_T)
			return
		if _pad_edge(JOY_BUTTON_START):
			_fake_key(KEY_O)
			return
		if _pad_edge(JOY_BUTTON_BACK):
			_fake_key(KEY_F4)
			return
		if _pad_edge(JOY_BUTTON_Y):
			_fake_key(KEY_T)
			return
		if _pad_edge(JOY_BUTTON_X):
			_fake_key(KEY_F4)
			return
		if _pad_edge(JOY_BUTTON_DPAD_RIGHT):
			_fake_key(KEY_ENTER)
			return
		if _pad_edge(JOY_BUTTON_A):
			_fake_key(KEY_ENTER)
		return
	if state == "dead":
		if _pad_edge(JOY_BUTTON_A):
			start_run()
		if _pad_edge(JOY_BUTTON_B) or _pad_edge(JOY_BUTTON_START):
			_fake_key(KEY_ESCAPE)
		return
	# 菜单类界面：方向 + 确认 + 返回 + 快捷入口
	var ax: Vector2 = Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if _pad_edge(JOY_BUTTON_DPAD_UP) or (ax.y < -0.55 and _pad_axis.y >= -0.55):
		_fake_key(KEY_UP)
	if _pad_edge(JOY_BUTTON_DPAD_DOWN) or (ax.y > 0.55 and _pad_axis.y <= 0.55):
		_fake_key(KEY_DOWN)
	if _pad_edge(JOY_BUTTON_DPAD_LEFT) or (ax.x < -0.55 and _pad_axis.x >= -0.55):
		_fake_key(KEY_LEFT)
	if _pad_edge(JOY_BUTTON_DPAD_RIGHT) or (ax.x > 0.55 and _pad_axis.x <= 0.55):
		_fake_key(KEY_RIGHT)
	_pad_axis = ax
	# 按键设置页：RB / LB 也能切页
	if state == "keys":
		if _pad_edge(JOY_BUTTON_RIGHT_SHOULDER):
			_fake_key(KEY_RIGHT)
		if _pad_edge(JOY_BUTTON_LEFT_SHOULDER):
			_fake_key(KEY_LEFT)
	if _pad_edge(JOY_BUTTON_A):
		_fake_key(KEY_ENTER)
	if _pad_edge(JOY_BUTTON_B):
		_fake_key(KEY_ESCAPE)
	if _pad_edge(JOY_BUTTON_START):
		_fake_key(KEY_O)
	if _pad_edge(JOY_BUTTON_BACK):
		_fake_key(KEY_F4)
	if _pad_edge(JOY_BUTTON_Y):
		# 训练场配置页 / 存档页：Y 执行主操作
		if state == "train_cfg":
			start_training()
			return
		if state == "saves":
			save_to_slot(menu_index)
			return
		_fake_key(KEY_C)
	if _pad_edge(JOY_BUTTON_X):
		_fake_key(KEY_N)



## 自动瞄准：最近的敌人（限定距离）
func _nearest_enemy_for_aim(from: Vector2, max_dist: float):
	if enemies.is_empty():
		return null
	var best = null
	var best_d: float = max_dist
	for i in range(enemies.size()):
		var e = enemies[i]
		if e == null or not is_instance_valid(e) or e.dead:
			continue
		var d: float = from.distance_to(e.position)
		if d < best_d:
			best_d = d
			best = e
	return best

## 暂停页的手柄导航：A 重开本局 / START 设置 / BACK 存档 / X 静音 / Y 图鉴 / B 继续
func _pad_pause_menu() -> void:
	if _pad_edge(JOY_BUTTON_DPAD_UP):
		pause_sel = (pause_sel + 4) % 5
		return
	if _pad_edge(JOY_BUTTON_DPAD_DOWN):
		pause_sel = (pause_sel + 1) % 5
		return
	if _pad_edge(JOY_BUTTON_A):
		if pause_sel == 0:
			state = "play"
		elif pause_sel == 1:
			open_settings()
		elif pause_sel == 2:
			back_to_title()
		elif pause_sel == 3:
			open_saves()
		else:
			request_quit()
		return
	if _pad_edge(JOY_BUTTON_BACK):
		open_saves()
		return
	if _pad_edge(JOY_BUTTON_B):
		state = "play"
		return
	if _pad_edge(JOY_BUTTON_START):
		open_settings()
		return
	if _pad_edge(JOY_BUTTON_X):
		open_saves()
		return
	if _pad_edge(JOY_BUTTON_Y):
		open_codex()
		return


## 调试用：补充药瓶提示
func game_regen_flask_msg() -> void:
	if hud != null and player != null:
		hud.msg("药瓶 +1（%d/%d）" % [player.flasks, player.max_flasks], Color(0.9, 0.6, 0.7), 1.4)

## 王级 BOSS 掉落：1~3 件，逐个询问
func _boss_reward(e) -> void:
	var k: String = str(e.kind)
	var summon: String = ""
	var set_prefix: String = ""
	if k == "drake_king":
		summon = "summon_drake"
		set_prefix = "king_drake"
	elif k == "seadrake_king":
		summon = "summon_seadrake"
		set_prefix = "king_sea"
	elif k == "slime_king":
		summon = "summon_slime"
		set_prefix = "king_slime"
	elif k == "slime_queen":
		summon = "summon_slime"
		set_prefix = "queen_slime"
	var drops: int = 1 + randi() % 3
	var pool: Array = []
	if summon != "":
		pool.append({"kind": "item", "id": summon})
	if set_prefix != "":
		pool.append({"kind": "wep", "cat": 0, "id": set_prefix + "_sword"})
		pool.append({"kind": "wep", "cat": 1, "id": set_prefix + "_wand"})
		pool.append({"kind": "wep", "cat": 2, "id": set_prefix + "_shield"})
	for i in range(drops):
		if pool.size() == 0:
			break
		var pick_i: int = randi() % pool.size()
		var it: Dictionary = pool[pick_i]
		pool.remove_at(pick_i)
		drop_queue.append(it)
	call_deferred("_pump_drop_queue")






## 退回主界面
func back_to_title() -> void:
	save_settings_now()
	training_mode = false
	run_active = false
	pause_sel = 0
	state = "title"
	build_floor(true)
	title_pan = cam.position.x
	sfx_play("block", 1.0, -8.0)














