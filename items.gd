extends Node2D
## 遗物系统 v2：飞剑 · 魔法光环 · 魔导书 · 三种宠物 · 三种替身 · 魔法保护
## 可叠加；物理/魔法伤害会随「物理等级 / 魔法等级」与技能倍率提升。

const Art = preload("res://scripts/art.gd")
const TAU := 6.283185307179586

const DEFS := {
	"sword": {"name": "飞剑", "col": Color(0.72, 0.94, 1.0), "desc": "环绕飞剑，触碰敌人造成物理伤害"},
	"halo": {"name": "魔法光环", "col": Color(1.0, 0.86, 0.42), "desc": "法球环绕，持续灼烧近身敌人（魔法）"},
	"book": {"name": "魔导书", "col": Color(0.62, 0.80, 1.0), "desc": "自动发射追踪魔弹（魔法）"},
	"pet_imp": {"name": "小恶魔", "col": Color(1.0, 0.55, 0.32), "desc": "吐火球攻击（魔法）"},
	"pet_cat": {"name": "幽灵猫", "col": Color(0.70, 0.85, 1.0), "desc": "瞬移扑咬敌人（物理）"},
	"pet_sprite": {"name": "光精灵", "col": Color(0.72, 1.0, 0.72), "desc": "定时治疗你"},
	"stand_shadow": {"name": "替身·幽影", "col": Color(0.76, 0.58, 1.0), "desc": "现身欧拉连打（物理）"},
	"stand_ward": {"name": "替身·守护", "col": Color(0.62, 0.92, 1.0), "desc": "震荡波护主并短暂无敌（物理）"},
	"stand_arcane": {"name": "替身·秘法", "col": Color(1.0, 0.72, 0.95), "desc": "扇形发射秘法弹（魔法）"},
	"guard": {"name": "魔法保护", "col": Color(0.80, 0.90, 1.0), "desc": "获得 2 次完全免伤"},
	"wing_angel": {"name": "天使之翼", "col": Color(1.0, 0.96, 0.74), "desc": "空中永久悬停(↑上升 ↓下降，移速+80%)；每 6 秒圣光，5 秒内每秒回复 5 点生命"},
	"wing_demon": {"name": "恶魔之翼", "col": Color(0.92, 0.34, 0.42), "desc": "空中永久悬停(↑上升 ↓下降，移速+80%)；命中吸血 15%；受伤会流血 5 秒每秒 -5"},
	"laser": {"name": "圣裁之眼", "col": Color(0.98, 0.86, 0.45), "desc": "每 5 秒向最近的敌人射出一道贯穿激光"},
	"thunder": {"name": "雷罚护符", "col": Color(0.74, 0.88, 1.0), "desc": "每 3.5 秒降下雷电，劈向附近的敌人"},
	"frost": {"name": "霜华之心", "col": Color(0.62, 0.92, 1.0), "desc": "寒气领域：持续冻伤身边的敌人"},
	"thorn": {"name": "荆棘之环", "col": Color(0.68, 0.92, 0.58), "desc": "受伤时爆发荆棘，伤害周围敌人"},
	"crown": {"name": "亡者王冠", "col": Color(1.0, 0.82, 0.36), "desc": "金币收益 +30%"},
	"magnet": {"name": "引铁磁石", "col": Color(0.88, 0.64, 0.48), "desc": "拾取范围扩大 80%"},
	"pet_skull": {"name": "骷髅仆从", "col": Color(0.88, 0.88, 0.80), "desc": "召唤骷髅兵冲撞敌人（物理）"},
	"phoenix": {"name": "不死鸟之羽", "col": Color(1.0, 0.62, 0.28), "desc": "每层一次：致命伤时复活并恢复 40% 生命"},
	"mana_gem": {"name": "秘蓝宝石", "col": Color(0.42, 0.70, 1.0), "desc": "法力回复 +3/秒", "regen": 3.0},
	"mana_crystal": {"name": "法力结晶", "col": Color(0.55, 0.82, 1.0), "desc": "法力上限 +25", "mana_max": 25.0},
	"mana_orb": {"name": "奥术宝珠", "col": Color(0.66, 0.72, 1.0), "desc": "法力回复 +2/秒，每 6 秒额外 +10", "regen": 2.0, "pulse": 10.0, "pulse_cd": 6.0},
	"mana_spring": {"name": "灵泉之心", "col": Color(0.50, 0.90, 0.95), "desc": "法力回复 +1.5/秒，药瓶治疗 +25%", "regen": 1.5, "heal_mult": 0.25},
	"mana_leech": {"name": "汲魔石", "col": Color(0.72, 0.55, 1.0), "desc": "每击杀一只怪物回复 6 点法力", "kill_mana": 6.0},
	"mana_font": {"name": "法力之泉", "col": Color(0.40, 0.86, 1.0), "desc": "每 5 秒回复 12 点法力", "pulse": 12.0, "pulse_cd": 5.0},
	"mana_sage": {"name": "贤者石", "col": Color(0.86, 0.90, 0.62), "desc": "法力回复 +2/秒，受伤时回复 8 点法力", "regen": 2.0, "hurt_mana": 8.0},
	"mana_pearl": {"name": "秘法珍珠", "col": Color(0.90, 0.70, 1.0), "desc": "法力回复 +4/秒，但受伤 +10%", "regen": 4.0, "taken": 1.10},
	"mana_core": {"name": "魔力核心", "col": Color(0.55, 0.62, 1.0), "desc": "法力上限 +40，回复 +1/秒", "mana_max": 40.0, "regen": 1.0},
	"mana_star": {"name": "星辉之尘", "col": Color(1.0, 0.95, 0.66), "desc": "法力回复 +5/秒，遗物魔法伤害 +10%", "regen": 5.0, "magic_mult": 1.10},
	"orbit_blade": {"name": "旋刃之环", "col": Color(0.86, 0.94, 1.00), "desc": "环绕利刃，半径 96，持续斩击周围敌人", "orbit": 96.0, "orbit_dmg": 26.0, "orbit_cd": 0.55},
	"orbit_flame": {"name": "炎环", "col": Color(1.00, 0.60, 0.28), "desc": "火焰环，半径 88，灼烧周围敌人", "orbit": 88.0, "orbit_dmg": 20.0, "orbit_cd": 0.7, "orbit_status": "burn"},
	"orbit_frost": {"name": "霜环", "col": Color(0.62, 0.90, 1.00), "desc": "寒霜之环，半径 92，缓速周围敌人", "orbit": 92.0, "orbit_dmg": 16.0, "orbit_cd": 0.7, "orbit_status": "slow"},
	"orbit_storm": {"name": "雷环", "col": Color(0.88, 0.96, 1.00), "desc": "雷电之环，半径 84，电击周围敌人", "orbit": 84.0, "orbit_dmg": 24.0, "orbit_cd": 0.6, "orbit_status": "shock"},
	"orbit_thorn": {"name": "荆棘轮", "col": Color(0.86, 0.52, 0.72), "desc": "荆棘轮盘，半径 78，命中附带流血", "orbit": 78.0, "orbit_dmg": 30.0, "orbit_cd": 0.65},
	"orbit_void": {"name": "虚空星环", "col": Color(0.74, 0.56, 1.00), "desc": "虚空星环，半径 104，混乱周围敌人", "orbit": 104.0, "orbit_dmg": 22.0, "orbit_cd": 0.75, "orbit_status": "confuse"},
	"orbit_holy": {"name": "圣光冠冕", "col": Color(1.00, 0.94, 0.66), "desc": "圣光环，半径 110，命中时回复生命", "orbit": 110.0, "orbit_dmg": 18.0, "orbit_cd": 0.8, "orbit_heal": 1.5},
	"orbit_blood": {"name": "血月轮", "col": Color(0.94, 0.32, 0.42), "desc": "血月轮，半径 86，命中时吸血", "orbit": 86.0, "orbit_dmg": 28.0, "orbit_cd": 0.7, "orbit_heal": 1.0},
	"orbit_hex": {"name": "咒怨环", "col": Color(0.80, 0.52, 0.94), "desc": "咒怨环，半径 98，命中弱化敌人（受伤 +20%）", "orbit": 98.0, "orbit_dmg": 20.0, "orbit_cd": 0.85},
	"sk_herd": {"name": "亡灵牧者", "col": Color(0.72, 0.70, 0.92), "desc": "召唤物伤害 +45%", "summon_mult": 1.45},
	"sk_twin": {"name": "双生契约", "col": Color(0.86, 0.62, 1.00), "desc": "每次召唤额外再召 1 只", "summon_extra": 1},
	"sk_frenzy": {"name": "狂魂共鸣", "col": Color(1.00, 0.62, 0.42), "desc": "召唤物攻速大幅提升", "summon_speed": 1.6},
	"sk_endure": {"name": "不朽契印", "col": Color(0.80, 0.96, 0.72), "desc": "召唤物存在时间 +8 秒", "summon_life": 8.0},
	"sk_phase": {"name": "相位共振", "col": Color(0.62, 0.88, 1.00), "desc": "所有召唤物可穿墙", "summon_ghost": true},
	"sk_bloodpact": {"name": "血之契约", "col": Color(0.94, 0.32, 0.42), "desc": "召唤物伤害 +30%，命中时为你回血", "summon_mult": 1.30, "summon_heal": 1.0},
	"sk_soulfire": {"name": "魂焰之环", "col": Color(1.00, 0.60, 0.28), "desc": "召唤物命中附加【灼烧】", "summon_status": "burn"},
	"sk_glacier": {"name": "霜魂契", "col": Color(0.62, 0.90, 1.00), "desc": "召唤物命中附加【缓速】", "summon_status": "slow"},
	"sk_stormcall": {"name": "唤雷者", "col": Color(0.88, 0.96, 1.00), "desc": "召唤物命中附加【电击】", "summon_status": "shock"},
	"sk_legion": {"name": "亡者军团", "col": Color(0.66, 0.86, 1.00), "desc": "召唤物伤害 +25% 且额外 +1 只", "summon_mult": 1.25, "summon_extra": 1},
	"sk_crown": {"name": "召唤之冠", "col": Color(1.00, 0.92, 0.62), "desc": "召唤物伤害 +60%", "summon_mult": 1.60},
	"sk_abyss": {"name": "深渊低语", "col": Color(0.74, 0.56, 1.00), "desc": "召唤物伤害 +35% 且命中即可穿墙溅射", "summon_mult": 1.35, "summon_splash": 40.0},
	"orbit_error": {"name": "错误环", "col": Color(1.00, 0.24, 0.88), "desc": "错误之环（0.5% 极低概率）：半径 120，极大范围高频打击", "orbit": 120.0, "orbit_dmg": 34.0, "orbit_cd": 0.4},
	"summon_drake": {"name": "飞龙召唤", "col": Color(1.0, 0.50, 0.24), "desc": "召唤飞龙随行，定期喷射火焰并附加【灼烧】"},
	"summon_seadrake": {"name": "海龙召唤", "col": Color(0.44, 0.82, 1.0), "desc": "召唤海龙随行，喷水枪减速并推开怪物（附加【缓速】）"},
	"summon_slime": {"name": "史莱姆召唤", "col": Color(0.66, 0.94, 0.44), "desc": "召唤大型友方史莱姆，死亡时分裂成 5 只小史莱姆"},
}

const POOL := [
	"sword", "sword", "halo", "halo", "book",
	"pet_imp", "pet_cat", "pet_sprite", "pet_skull",
	"stand_shadow", "stand_ward", "stand_arcane", "guard",
	"wing_angel", "wing_demon",
	"laser", "thunder", "frost", "thorn", "crown", "magnet", "phoenix",
]

var game = null
var level = null
var player = null

var counts: Dictionary = {}
var order: Array = []
var guard_charges := 0

var t := 0.0
var orbit_a := 0.0
var halo_a := 0.0
var book_cd := 1.4
var hit_cd: Dictionary = {}
var pet_pos: Dictionary = {}
var pet_cd: Dictionary = {}
var stand_life := 0.0
var stand_tick := 0.0
var shadow_cd := 2.0
var ward_cd := 3.0
var ward_flash := 0.0
var arcane_cd := 2.0
var arcane_flash := 0.0
var angel_cd := 3.0
var angel_life := 0.0
var angel_flash := 0.0
var laser_cd := 5.0
var laser_life := 0.0
var laser_from := Vector2.ZERO
var laser_to := Vector2.ZERO
var thunder_cd := 3.5
var frost_cd := 0.55
var revive_used := false
var sum_cd := 0.0
var mana_pulse_cd := 5.0
var redraw_tick := 0
var agg_frame := -1
var agg := {}
var orbit_ang := 0.0
var orbit_cd := 0.0
var sum_slime_life := 0.0
# 每帧只遍历一次敌人：缓存玩家附近的敌人列表，飞剑/光环/冰霜/宠物/激光共用
var _near_frame := -1
var _near_list: Array = []
var sum_slime_split := false


func setup(p_game) -> void:
	game = p_game
	z_index = 6


func bind(p_level, p_player) -> void:
	level = p_level
	player = p_player
	pet_pos.clear()
	reset_floor_relics()


func clear() -> void:
	counts.clear()
	order.clear()
	hit_cd.clear()
	pet_pos.clear()
	pet_cd.clear()
	guard_charges = 0
	book_cd = 1.4
	stand_life = 0.0
	ward_cd = 3.0
	arcane_cd = 2.0


func count_of(id: String) -> int:
	return int(counts.get(id, 0))


func has_any() -> bool:
	return order.size() > 0


func item_name(id: String) -> String:
	if DEFS.has(id):
		return str(DEFS[id]["name"])
	return id


func item_col(id: String) -> Color:
	if DEFS.has(id):
		return DEFS[id]["col"]
	return Color(0.8, 0.8, 0.8)


func item_desc(id: String) -> String:
	if DEFS.has(id):
		return str(DEFS[id]["desc"])
	return ""


func add_item(id: String) -> void:
	if not DEFS.has(id):
		return
	counts[id] = count_of(id) + 1
	if not order.has(id):
		order.append(id)
	if id == "guard":
		guard_charges += 2
		if game != null:
			game.sfx_play("guard_up", 1.05)


func random_id() -> String:
	return str(POOL[randi() % POOL.size()])


## 当前拥有的翅膀（"" 表示没有）
func wing_id() -> String:
	if count_of("wing_angel") > 0:
		return "wing_angel"
	if count_of("wing_demon") > 0:
		return "wing_demon"
	return ""


func is_wing(id: String) -> bool:
	return id == "wing_angel" or id == "wing_demon"


## 恶魔之翼的吸血比例
func wings_lifesteal() -> float:
	if count_of("wing_demon") > 0:
		return 0.15
	return 0.0


## 翅膀互斥：换翅膀时先摘掉旧的
func replace_wing(id: String) -> void:
	var old: String = wing_id()
	if old != "" and counts.has(old):
		counts.erase(old)
		order.erase(old)
	add_item(id)



## 召唤物：飞龙 / 海龙喷吐元素弹，史莱姆冲撞并分裂
func _update_summons(dt: float, mag: float) -> void:
	var nd: int = count_of("summon_drake")
	var ns: int = count_of("summon_seadrake")
	var nsl: int = count_of("summon_slime")
	if nd <= 0 and ns <= 0 and nsl <= 0:
		return
	sum_cd -= dt
	var anchor: Vector2 = player.position + Vector2(-player.facing * 46.0, -62.0)
	if sum_cd <= 0.0 and (nd > 0 or ns > 0):
		sum_cd = 2.2 if nd > 0 else 2.0
		var tgt = _nearest_enemy(player.position, 480.0)
		if tgt != null:
			var tp: Vector2 = tgt.position + Vector2(0, -tgt.size.y * 0.5)
			var dir: Vector2 = (tp - anchor).normalized()
			if nd > 0:
				game.spawn_shot("element", anchor + dir * 16.0, dir * 620.0, (9.0 + 3.0 * float(nd)) * mag, true, 1.0, "fire", 0, "burn", "")
				game.fx.spark_spawn(anchor + dir * 16.0, dir, 8, Color(1.0, 0.6, 0.25))
			else:
				game.spawn_shot("element", anchor + dir * 16.0, dir * 700.0, (7.0 + 2.5 * float(ns)) * mag, true, 1.0, "water", 0, "slow", "")
				game.fx.spark_spawn(anchor + dir * 16.0, dir, 8, Color(0.5, 0.88, 1.0))
			game.sfx_play("magic", 1.15, -12.0)
	# 史莱姆召唤：冲撞 + 死亡分裂
	if nsl > 0:
		if sum_slime_life <= 0.0:
			sum_slime_life = 12.0
			sum_slime_split = false
		sum_slime_life -= dt
		var stgt = _nearest_enemy(player.position, 320.0)
		if stgt != null:
			var sp2: Vector2 = stgt.position + Vector2(0, -stgt.size.y * 0.5)
			if sp2.distance_to(anchor) < 46.0:
				stgt.hurt((10.0 + 4.0 * float(nsl)) * _phys_mult(), (sp2 - anchor).normalized(), 180.0, 0.15)
				game.fx.spark_spawn(sp2, Vector2(0, -1), 8, Color(0.66, 0.94, 0.44))
		if sum_slime_life <= 0.0:
			# 死亡 → 分裂一次
			if not sum_slime_split:
				sum_slime_split = true
				for i in range(5):
					var off: float = -40.0 + float(i) * 20.0
					game.fx.ring_spawn(player.position + Vector2(off, -20.0), 26.0, Color(0.66, 0.94, 0.44))
				game.fx.text(player.position + Vector2(0, -84.0), "分裂!", Color(0.7, 0.95, 0.5), 20)
				# 小史莱姆直接造成一次伤害并退场
				for i in range(game.enemies.size()):
					var me = game.enemies[i]
					if me == null or not is_instance_valid(me) or me.dead:
						continue
					if me.position.distance_to(player.position) < 220.0:
						me.hurt(14.0 * _phys_mult(), Vector2(0, -1), 120.0, 0.12)
			sum_slime_life = 12.0


## 每件遗物都有独立的模型，环绕在角色身上
func _draw_relic_models() -> void:
	# 只画有独立造型的遗物，且最多 10 个，避免攻击瞬间掉帧
	var ids: Array = ["laser", "thunder", "frost", "thorn", "crown", "magnet", "pet_skull", "phoenix",
		"orbit_blade", "orbit_flame", "orbit_frost", "orbit_storm", "orbit_thorn",
		"orbit_void", "orbit_holy", "orbit_blood", "orbit_hex", "orbit_error"]
	var shown: int = 0
	for k in range(ids.size()):
		if shown >= 10:
			break
		var id: String = str(ids[k])
		if count_of(id) <= 0:
			continue
		var ang: float = t * 0.9 + float(shown) * (TAU / float(mini(ids.size(), 10)))
		var p: Vector2 = player.position + Vector2(0, -30.0) + Vector2(cos(ang), sin(ang) * 0.45) * 34.0
		var col: Color = DEFS[id]["col"]
		if game != null and game.quality() == 0:
			draw_circle(p, 5.0, col)
		else:
			draw_circle(p, 9.0, Color(col.r, col.g, col.b, 0.20))
			draw_circle(p, 5.5, col)
			draw_circle(p + Vector2(-1.5, -1.5), 2.0, Color(1, 1, 1, 0.75))
		shown += 1


func _draw_relic_model(p: Vector2, id: String, n: int) -> void:
	var col: Color = DEFS[id]["col"]
	if id == "laser":
		draw_circle(p, 9.0, Color(col.r, col.g, col.b, 0.16))
		draw_arc(p, 7.0, 0.0, TAU, 18, Color(col.r, col.g, col.b, 0.9), 1.8)
		draw_circle(p, 3.2, Color(1.0, 0.98, 0.8, 0.95))
		draw_line(p + Vector2(-11.0, 0), p + Vector2(-5.0, 0), Color(1.0, 0.95, 0.6, 0.8), 1.6)
	elif id == "thunder":
		draw_circle(p, 8.0, Color(col.r, col.g, col.b, 0.14))
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(2.0, -8.0), p + Vector2(-3.0, 0.0), p + Vector2(1.0, 0.0),
			p + Vector2(-2.0, 8.0), p + Vector2(5.0, -2.0), p + Vector2(0.5, -2.0),
		]), Color(col.r, col.g, col.b, 0.95))
	elif id == "frost":
		draw_circle(p, 8.0, Color(col.r, col.g, col.b, 0.14))
		for k in range(3):
			var a2: float = t * 1.6 + float(k) * TAU / 3.0
			var d2: Vector2 = Vector2(cos(a2), sin(a2)) * 7.0
			draw_line(p - d2, p + d2, Color(col.r, col.g, col.b, 0.95), 1.6)
	elif id == "thorn":
		draw_arc(p, 8.0, 0.0, TAU, 16, Color(col.r, col.g, col.b, 0.9), 1.8)
		for k in range(4):
			var a3: float = t * 2.2 + float(k) * TAU / 4.0
			var d3: Vector2 = Vector2(cos(a3), sin(a3))
			draw_line(p + d3 * 6.0, p + d3 * 12.0, Color(col.r, col.g, col.b, 0.85), 1.6)
	elif id == "crown":
		draw_rect(Rect2(p.x - 8.0, p.y - 1.0, 16.0, 4.0), Color(col.r, col.g, col.b, 0.95))
		for k in range(3):
			var kx: float = -6.0 + float(k) * 6.0
			draw_colored_polygon(PackedVector2Array([
				p + Vector2(kx - 2.0, -1.0), p + Vector2(kx, -7.0), p + Vector2(kx + 2.0, -1.0),
			]), Color(1.0, 0.94, 0.55, 0.95))
	elif id == "magnet":
		draw_arc(p, 7.0, -1.1, 1.1, 12, Color(col.r, col.g, col.b, 0.95), 2.4)
		draw_rect(Rect2(p.x - 8.0, p.y - 3.0, 3.0, 6.0), Color(0.9, 0.35, 0.32))
		draw_rect(Rect2(p.x + 5.0, p.y - 3.0, 3.0, 6.0), Color(0.9, 0.35, 0.32))
	elif id == "pet_skull":
		draw_circle(p, 7.0, Color(0.90, 0.88, 0.80, 0.95))
		draw_rect(Rect2(p.x - 4.0, p.y + 1.0, 8.0, 4.0), Color(0.90, 0.88, 0.80, 0.95))
		draw_rect(Rect2(p.x - 3.5, p.y - 2.0, 2.6, 3.0), Color(0.10, 0.10, 0.12))
		draw_rect(Rect2(p.x + 1.0, p.y - 2.0, 2.6, 3.0), Color(0.10, 0.10, 0.12))
	else:
		# 不死鸟之羽
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(0.0, -10.0), p + Vector2(6.0, 2.0), p + Vector2(0.0, 9.0), p + Vector2(-6.0, 2.0),
		]), Color(col.r, col.g, col.b, 0.85))
		draw_circle(p + Vector2(0.0, -1.0), 2.4, Color(1.0, 0.92, 0.6, 0.95))


## 沿直线发射激光：命中路径上的所有敌人
func _fire_laser(from: Vector2, dir: Vector2, length: float, dmg: float) -> void:
	if game == null:
		return
	var cand: Array = _near_cache(from)
	for i in range(cand.size()):
		var e = cand[i]
		if e == null or not is_instance_valid(e) or e.dead:
			continue
		var c: Vector2 = e.position + Vector2(0, -e.size.y * 0.5)
		var along: float = clampf((c - from).dot(dir), 0.0, length)
		var proj: Vector2 = from + dir * along
		if proj.distance_to(c) <= 28.0:
			var res: String = e.hurt(dmg, dir, 160.0, 0.15)
			game.hit_feedback(c, dir, res == "crit")


## 被玩家受伤时调用（荆棘之环）
func on_hurt() -> void:
	var nth: int = count_of("thorn")
	if nth <= 0 or game == null or player == null or not is_instance_valid(player):
		return
	var c: Vector2 = player.position + Vector2(0, -player.size.y * 0.5)
	game.damage_area(c, 76.0, (10.0 + 6.0 * float(nth)) * _phys_mult(), Vector2(0, -1))
	game.fx.ring_spawn(c, 76.0, Color(0.62, 0.95, 0.52))
	game.fx.spark_spawn(c, Vector2(0, -1), 12, Color(0.68, 0.95, 0.58))
	game.sfx_play("parry", 1.3, -6.0)


## 法力回复加成（加法）
func mana_regen() -> float:
	return agg_val("mana_regen", 0.0)
## 法力上限加成
func mana_max_bonus() -> float:
	return agg_val("mana_max", 0.0)
## 击杀回蓝
func kill_mana() -> float:
	return agg_val("kill_mana", 0.0)
## 受伤回蓝
func hurt_mana() -> float:
	return agg_val("hurt_mana", 0.0)
## 遗物魔法伤害倍率（星辉）
func magic_item_mult() -> float:
	return agg_val("magic_mult", 1.0)
## 金币收益倍率（亡者王冠）
func coin_mult() -> float:
	return agg_val("coin", 1.0)
## 拾取范围倍率（引铁磁石）
func pickup_mult() -> float:
	return agg_val("pickup", 1.0)
## 不死鸟：致命伤时复活一次（每层刷新）
func try_revive() -> bool:
	if count_of("phoenix") <= 0 or revive_used:
		return false
	if player == null or not is_instance_valid(player):
		return false
	revive_used = true
	player.hp = player.max_hp * 0.4
	player.invul = 1.6
	player.bleed_time = 0.0
	if game != null:
		game.fx.ring_spawn(player.position + Vector2(0, -24), 110.0, Color(1.0, 0.62, 0.28))
		game.fx.text(player.position + Vector2(0, -100), "不死鸟!", Color(1.0, 0.66, 0.32), 24)
		game.sfx_play("heal", 1.4, -2.0)
		game.shake(9.0)
	return true


func reset_floor_relics() -> void:
	revive_used = false
	laser_cd = 0.6
	thunder_cd = 1.0
## 从存档恢复
func restore(d: Dictionary, guards: int) -> void:
	clear()
	var keys: Array = d.keys()
	for i in range(keys.size()):
		var id: String = str(keys[i])
		if not DEFS.has(id):
			continue
		counts[id] = int(d[keys[i]])
		order.append(id)
	guard_charges = maxi(0, guards)


# ---------------------------------------------------------------- 倍率
func _phys_mult() -> float:
	var m := 1.0
	if game != null:
		m *= 1.0 + 0.10 * float(game.phys_level)
		if game.skills != null:
			m *= game.skills.val("phys")
	return m


func _magic_mult() -> float:
	var m := magic_item_mult()
	if game != null:
		m *= 1.0 + 0.10 * float(game.magic_level)
		if game.skills != null:
			m *= game.skills.val("magic")
	return m


# ---------------------------------------------------------------- 更新
func update(dt: float) -> void:
	t += dt
	var keys: Array = hit_cd.keys()
	for i in range(keys.size()):
		var k: String = str(keys[i])
		var v: float = float(hit_cd[k]) - dt
		if v <= 0.0:
			hit_cd.erase(k)
		else:
			hit_cd[k] = v

	if player == null or not is_instance_valid(player) or player.dead:
		queue_redraw()
		return

	var phys := _phys_mult()
	var mag := _magic_mult()

	# ---- 天使之翼：每 6 秒圣光，5 秒内每秒回复 5 点生命
	var nangel: int = count_of("wing_angel")
	if nangel > 0:
		angel_cd -= dt
		angel_flash = maxf(0.0, angel_flash - dt)
		if angel_cd <= 0.0:
			angel_cd = 6.0
			angel_life = 5.0
			angel_flash = 0.7
			game.sfx_play("heal", 1.15, -8.0)
			game.fx.ring_spawn(player.position + Vector2(0, -26), 74.0, Color(1.0, 0.96, 0.72))
			game.fx.text(player.position + Vector2(0, -92), "圣光", Color(1.0, 0.96, 0.72), 18)
		if angel_life > 0.0:
			angel_life -= dt
			player.hp = minf(player.max_hp, player.hp + 5.0 * float(nangel) * dt)
			if randf() < dt * 8.0:
				game.fx.spark_spawn(player.position + Vector2(randf_range(-12.0, 12.0), randf_range(-40.0, -6.0)), Vector2(0, -1), 1, Color(1.0, 0.96, 0.72))
	else:
		angel_life = 0.0

	# ---- 回法力遗物的周期性效果
	mana_pulse_cd -= dt
	if mana_pulse_cd <= 0.0:
		mana_pulse_cd = 99.0
		var pulse_amt: float = 0.0
		var pulse_period: float = 99.0
		for id in DEFS.keys():
			var sid: String = str(id)
			if count_of(sid) <= 0 or not DEFS[sid].has("pulse"):
				continue
			pulse_amt += float(DEFS[sid]["pulse"]) * float(count_of(sid))
			pulse_period = minf(pulse_period, float(DEFS[sid].get("pulse_cd", 5.0)))
		if pulse_amt > 0.0:
			mana_pulse_cd = pulse_period
			player.mana = minf(player.max_mana, player.mana + pulse_amt)
			game.fx.text(player.position + Vector2(0, -74), "+%d 法力" % int(pulse_amt), Color(0.55, 0.82, 1.0), 15)

	_update_orbits(dt, mag)

	# ---- 召唤物：飞龙 / 海龙 / 史莱姆
	_update_summons(dt, mag)

	# ---- 圣裁之眼：每 5 秒贯穿激光
	var nlaser: int = count_of("laser")
	laser_life = maxf(0.0, laser_life - dt)
	if nlaser > 0:
		laser_cd -= dt
		if laser_cd <= 0.0:
			var ltgt = _nearest_enemy(player.position, 640.0)
			if ltgt == null:
				laser_cd = 0.4
			else:
				laser_cd = 5.0
				laser_life = 0.26
				var lfrom: Vector2 = player.position + Vector2(0, -30.0)
				var lto: Vector2 = ltgt.position + Vector2(0, -ltgt.size.y * 0.5)
				laser_from = lfrom
				laser_to = lto
				_fire_laser(lfrom, (lto - lfrom).normalized(), 760.0, (26.0 + 10.0 * float(nlaser)) * mag)
				game.sfx_play("sniper", 1.25, -4.0)
				game.shake(4.0)

	# ---- 雷罚护符：每 3.5 秒落雷
	var nthunder: int = count_of("thunder")
	if nthunder > 0:
		thunder_cd -= dt
		if thunder_cd <= 0.0:
			var ttgt = _nearest_enemy(player.position, 460.0)
			if ttgt == null:
				thunder_cd = 0.5
			else:
				thunder_cd = 3.5
				var tp: Vector2 = ttgt.position + Vector2(0, -ttgt.size.y * 0.5)
				var tdmg: float = (20.0 + 9.0 * float(nthunder)) * mag
				var tres: String = ttgt.hurt(tdmg, Vector2(0, -1), 200.0, 0.2)
				game.hit_feedback(tp, Vector2(0, -1), tres == "crit")
				game.fx.ring_spawn(tp, 44.0, Color(0.78, 0.92, 1.0))
				game.fx.spark_spawn(tp, Vector2(0, -1), 14, Color(0.88, 0.96, 1.0))
				game.fx.text(tp + Vector2(0, -26), "雷", Color(0.85, 0.95, 1.0), 18)
				game.sfx_play("hit", 1.5, -4.0)
				game.shake(2.5)

	# ---- 霜华之心：持续冻伤周围
	var nfrost: int = count_of("frost")
	if nfrost > 0:
		frost_cd -= dt
		if frost_cd <= 0.0:
			frost_cd = 0.55
			var fc: Vector2 = player.position + Vector2(0, -24.0)
			var hit_any: bool = false
			var fcand: Array = _near_cache(fc)
			for i in range(fcand.size()):
				var fe = fcand[i]
				if fe == null or not is_instance_valid(fe) or fe.dead:
					continue
				var fcc: Vector2 = fe.position + Vector2(0, -fe.size.y * 0.5)
				if fcc.distance_to(fc) <= 98.0:
					fe.hurt((4.0 + 2.5 * float(nfrost)) * mag, (fcc - fc).normalized(), 30.0, 0.1)
					hit_any = true
			if hit_any:
				game.fx.ring_spawn(fc, 98.0, Color(0.62, 0.92, 1.0))

	# ---- 飞剑（物理）
	var ns: int = count_of("sword")
	orbit_a += dt * (2.1 + 0.2 * float(ns))
	for i in range(ns):
		var ang: float = orbit_a + float(i) * TAU / float(ns)
		var rad: float = 54.0 + float(i % 2) * 7.0
		var p: Vector2 = player.position + Vector2(0, -26) + Vector2(cos(ang), sin(ang)) * rad
		_damage_reach(p, 17.0, (10.0 + 3.0 * float(ns)) * phys, "sword", 170.0)

	# ---- 魔法光环（魔法）
	var nh: int = count_of("halo")
	halo_a -= dt * 3.7
	if nh > 0:
		var orbs: int = nh * 2
		for i in range(orbs):
			var ang2: float = halo_a + float(i) * TAU / float(orbs)
			var p2: Vector2 = player.position + Vector2(0, -26) + Vector2(cos(ang2), sin(ang2)) * 38.0
			_damage_reach(p2, 13.0, (6.0 + 2.0 * float(nh)) * mag, "halo", 80.0)

	_update_book(dt, count_of("book"), mag)
	_update_pets(dt, phys, mag)
	_update_stands(dt, phys, mag)
	# 环绕模型多时降频重绘，避免帧数骤降
	redraw_tick += 1
	if (not _orbit_heavy()) or (redraw_tick % 2 == 0):
		queue_redraw()


## 每帧只遍历一次敌人，返回玩家附近的敌人列表（之后所有环绕/宠物/激光都复用它）
func _near_cache(center: Vector2) -> Array:
	var f: int = Engine.get_process_frames()
	if _near_frame == f:
		return _near_list
	_near_frame = f
	_near_list.clear()
	if game == null:
		return _near_list
	var es: Array = game.enemies
	var r2: float = 760.0 * 760.0
	for i in range(es.size()):
		var e = es[i]
		if e == null or not is_instance_valid(e) or e.dead:
			continue
		if e.position.distance_squared_to(center) <= r2:
			_near_list.append(e)
	return _near_list


func _nearest_enemy(from: Vector2, max_dist: float):
	if game == null:
		return null
	var best = null
	var best_d: float = max_dist
	var cand: Array = _near_cache(from)
	for i in range(cand.size()):
		var e = cand[i]
		if e == null or not is_instance_valid(e) or e.dead:
			continue
		var c: Vector2 = e.position + Vector2(0, -e.size.y * 0.5)
		var d: float = from.distance_to(c)
		if d < best_d:
			best_d = d
			best = e
	return best


func _damage_reach(pos: Vector2, radius: float, dmg: float, key: String, knock: float) -> void:
	if game == null:
		return
	var cand2: Array = _near_cache(player.position if player != null else pos)
	for i in range(cand2.size()):
		var e = cand2[i]
		if e == null or not is_instance_valid(e) or e.dead:
			continue
		var c: Vector2 = e.position + Vector2(0, -e.size.y * 0.5)
		var rad: float = radius + e.size.x * 0.45
		if pos.distance_to(c) > rad:
			continue
		var k: String = key + ":" + str(e.get_instance_id())
		if float(hit_cd.get(k, 0.0)) > 0.0:
			continue
		if key == "stand":
			hit_cd[k] = 0.11
		else:
			hit_cd[k] = 0.45
		var dir: Vector2 = c - pos
		if dir.length() < 0.01:
			dir = Vector2(0, -1)
		dir = dir.normalized()
		var res: String = e.hurt(dmg, dir, knock, 0.12)
		game.hit_feedback(e.position, dir, res == "crit")


func _update_book(dt: float, n: int, mag: float) -> void:
	if n <= 0:
		return
	book_cd -= dt
	if book_cd > 0.0:
		return
	book_cd = 2.6 / (1.0 + 0.25 * float(n - 1))
	var muzzle: Vector2 = player.position + Vector2(0, -80)
	var target = _nearest_enemy(muzzle, 560.0)
	var dir: Vector2
	if target != null:
		dir = (target.position + Vector2(0, -target.size.y * 0.5) - muzzle).normalized()
	else:
		dir = Vector2(player.facing, 0).normalized()
	game.spawn_shot("magic", muzzle, dir * 470.0, (11.0 + 5.0 * float(n)) * mag, true, 1.0)
	game.fx.spark_spawn(muzzle, dir, 7, Color(0.62, 0.86, 1.0))
	game.sfx_play("magic", 1.0 + 0.04 * float(n), -8.0)


# ---------------------------------------------------------------- 宠物
func _update_pets(dt: float, phys: float, mag: float) -> void:
	var kinds: Array = ["pet_imp", "pet_cat", "pet_sprite", "pet_skull"]
	for idx in range(kinds.size()):
		var pid: String = str(kinds[idx])
		var n: int = count_of(pid)
		if n <= 0:
			continue
		var anchor: Vector2 = player.position + Vector2(-player.facing * (44.0 + float(idx) * 26.0), -58.0 - float(idx) * 8.0)
		if not pet_pos.has(pid):
			pet_pos[pid] = anchor
			pet_cd[pid] = 0.6
		var cur: Vector2 = pet_pos[pid]
		var wobble := Vector2(sin(t * 2.1 + float(idx)) * 7.0, cos(t * 2.7 + float(idx)) * 5.0)
		pet_pos[pid] = cur.lerp(anchor + wobble, clampf(dt * 6.0, 0.0, 1.0))
		var cd: float = float(pet_cd.get(pid, 0.0)) - dt
		if cd > 0.0:
			pet_cd[pid] = cd
			continue
		var pos: Vector2 = pet_pos[pid]
		if pid == "pet_imp":
			var target = _nearest_enemy(pos, 430.0)
			if target == null:
				pet_cd[pid] = 0.25
			else:
				pet_cd[pid] = 1.8 / (1.0 + 0.28 * float(n - 1))
				var dir: Vector2 = (target.position + Vector2(0, -target.size.y * 0.5) - pos).normalized()
				game.spawn_shot("pet_bolt", pos + dir * 14.0, dir * 560.0, (8.0 + 4.0 * float(n)) * mag, true, 1.0)
				game.sfx_play("pet", 1.0 + randf() * 0.15, -10.0)
		elif pid == "pet_cat":
			var target2 = _nearest_enemy(player.position, 300.0)
			if target2 == null:
				pet_cd[pid] = 0.3
			else:
				pet_cd[pid] = 2.2 / (1.0 + 0.22 * float(n - 1))
				var tp: Vector2 = target2.position + Vector2(0, -target2.size.y * 0.5)
				game.fx.spark_spawn(pos, (tp - pos).normalized(), 8, Color(0.7, 0.9, 1.0))
				pet_pos[pid] = tp + Vector2(-player.facing * 26.0, 6.0)
				var res: String = target2.hurt((14.0 + 5.0 * float(n)) * phys, (tp - pos).normalized(), 150.0, 0.2)
				game.hit_feedback(target2.position, (tp - pos).normalized(), res == "crit")
				game.fx.spark_spawn(tp, Vector2(-player.facing, -0.3), 10, Color(0.8, 0.95, 1.0))
				game.sfx_play("pet", 0.9, -8.0)
		elif pid == "pet_skull":
			var target3 = _nearest_enemy(player.position, 340.0)
			if target3 == null:
				pet_cd[pid] = 0.35
			else:
				pet_cd[pid] = 1.9 / (1.0 + 0.25 * float(n - 1))
				var tp3: Vector2 = target3.position + Vector2(0, -target3.size.y * 0.5)
				var dir3: Vector2 = (tp3 - pos).normalized()
				var res3: String = target3.hurt((11.0 + 5.0 * float(n)) * phys, dir3, 220.0, 0.2)
				game.hit_feedback(target3.position, dir3, res3 == "crit")
				game.fx.spark_spawn(tp3, dir3, 9, Color(0.92, 0.92, 0.84))
				game.fx.text(tp3 + Vector2(0, -22), "咔", Color(0.9, 0.9, 0.84), 15)
				game.sfx_play("clink", 1.1, -8.0)
		else:
			pet_cd[pid] = 6.0 / (1.0 + 0.25 * float(n - 1))
			var heal: float = 10.0 + 4.0 * float(n)
			player.hp = minf(player.max_hp, player.hp + heal)
			game.fx.text(player.position + Vector2(0, -70), "+" + str(int(heal)), Color(0.6, 1.0, 0.7), 17)
			game.fx.spark_spawn(player.position + Vector2(0, -26), Vector2(0, -1), 10, Color(0.7, 1.0, 0.75))
			game.sfx_play("heal", 1.2, -10.0)


# ---------------------------------------------------------------- 替身
func _update_stands(dt: float, phys: float, mag: float) -> void:
	# 幽影：欧拉连打
	var ns: int = count_of("stand_shadow")
	if ns > 0:
		shadow_cd = maxf(0.0, shadow_cd - dt)
		if stand_life > 0.0:
			stand_life -= dt
			stand_tick -= dt
			if stand_tick <= 0.0:
				stand_tick = 0.07
				var center: Vector2 = player.position + Vector2(player.facing * 54.0, -24.0)
				_damage_reach(center, 36.0, (4.0 + 2.0 * float(ns)) * phys, "stand", 60.0)
				game.fx.spark_spawn(
					center + Vector2(randf_range(-12.0, 12.0), randf_range(-16.0, 16.0)),
					Vector2(player.facing, -0.2), 3, Color(0.92, 0.78, 1.0)
				)
				game.shake(1.8)
		elif shadow_cd <= 0.0:
			var target = _nearest_enemy(player.position + Vector2(0, -22), 240.0)
			if target != null:
				shadow_cd = maxf(2.8, 5.4 - 0.5 * float(ns))
				stand_life = 0.62
				stand_tick = 0.0
				game.sfx_play("stand", 1.0)
				game.fx.text(player.position + Vector2(0, -88), "オラオラオラ!", Color(0.88, 0.72, 1.0), 20)
				game.fx.ring_spawn(player.position + Vector2(0, -26), 62.0, Color(0.80, 0.60, 1.0))
				game.shake(5.0)
				game.hit_stop(0.05)

	# 守护：护主震荡波 + 短暂无敌
	var nw: int = count_of("stand_ward")
	if nw > 0:
		ward_cd -= dt
		ward_flash = maxf(0.0, ward_flash - dt)
		if ward_cd <= 0.0:
			ward_cd = maxf(3.6, 7.0 - 0.6 * float(nw))
			ward_flash = 0.5
			player.invul = maxf(player.invul, 0.7)
			game.fx.ring_spawn(player.position + Vector2(0, -24), 96.0, Color(0.62, 0.95, 1.0))
			game.fx.text(player.position + Vector2(0, -84), "守护!", Color(0.62, 0.95, 1.0), 19)
			game.sfx_play("guard_up", 0.9)
			for i in range(game.enemies.size()):
				var e = game.enemies[i]
				if e == null or not is_instance_valid(e) or e.dead:
					continue
				var c: Vector2 = e.position + Vector2(0, -e.size.y * 0.5)
				if c.distance_to(player.position + Vector2(0, -24)) < 110.0:
					var dir2: Vector2 = (c - player.position).normalized()
					e.hurt((3.0 + 2.0 * float(nw)) * phys, dir2, 320.0, 0.2)
					game.fx.spark_spawn(c, dir2, 6, Color(0.7, 0.95, 1.0))
			game.shake(4.0)

	# 秘法：扇形秘法弹
	var na: int = count_of("stand_arcane")
	if na > 0:
		arcane_cd -= dt
		arcane_flash = maxf(0.0, arcane_flash - dt)
		if arcane_cd <= 0.0:
			var target3 = _nearest_enemy(player.position, 540.0)
			if target3 == null:
				arcane_cd = 0.3
			else:
				arcane_cd = maxf(1.8, 3.6 - 0.3 * float(na))
				arcane_flash = 0.35
				var base_dir: Vector2 = (target3.position + Vector2(0, -target3.size.y * 0.5) - (player.position + Vector2(0, -30.0))).normalized()
				var muzzle: Vector2 = player.position + Vector2(0, -46)
				for k in range(3):
					var spread: float = (float(k) - 1.0) * 0.16
					game.spawn_shot("magic", muzzle, base_dir.rotated(spread) * 520.0, (9.0 + 3.0 * float(na)) * mag, true, 1.0)
				game.sfx_play("magic", 1.15, -6.0)
				game.fx.spark_spawn(muzzle, base_dir, 10, Color(1.0, 0.75, 0.95))


# ---------------------------------------------------------------- 绘制
func _draw() -> void:
	if player == null or not is_instance_valid(player):
		return
	# 召唤物：飞龙 / 海龙 / 史莱姆
	var nd2: int = count_of("summon_drake")
	var ns2: int = count_of("summon_seadrake")
	var nsl2: int = count_of("summon_slime")
	if nd2 + ns2 + nsl2 > 0:
		var ax: Vector2 = player.position + Vector2(-player.facing * 46.0, -62.0 + sin(t * 2.2) * 5.0)
		if nd2 > 0 or ns2 > 0:
			var fire2: bool = nd2 > 0
			var c1: Color = Color(0.72, 0.28, 0.20) if fire2 else Color(0.24, 0.52, 0.80)
			var c2: Color = Color(0.46, 0.14, 0.12) if fire2 else Color(0.12, 0.30, 0.52)
			draw_colored_polygon(PackedVector2Array([ax + Vector2(-16.0, 0.0), ax + Vector2(-6.0, -14.0), ax + Vector2(4.0, 0.0)]), Color(c1.r, c1.g, c1.b, 0.85))
			draw_colored_polygon(PackedVector2Array([ax + Vector2(6.0, 0.0), ax + Vector2(16.0, -13.0), ax + Vector2(20.0, 2.0)]), Color(c1.r, c1.g, c1.b, 0.7))
			draw_rect(Rect2(ax.x - 8.0, ax.y - 4.0, 18.0, 7.0), c1)
			draw_rect(Rect2(ax.x + 8.0, ax.y - 6.0, 7.0, 6.0), c2)
			draw_circle(ax + Vector2(12.0, -3.0), 1.6, Color(1.0, 0.9, 0.5) if fire2 else Color(0.6, 1.0, 1.0))
		if nsl2 > 0:
			var sx2: float = player.position.x + player.facing * 40.0
			var sy2: float = player.position.y + 2.0
			draw_rect(Rect2(sx2 - 12.0, sy2 - 16.0, 24.0, 15.0), Color(0.40, 0.82, 0.40, 0.9))
			draw_rect(Rect2(sx2 - 6.0, sy2 - 12.0, 4.0, 5.0), Color(0.05, 0.12, 0.08))
			draw_rect(Rect2(sx2 + 3.0, sy2 - 12.0, 4.0, 5.0), Color(0.05, 0.12, 0.08))
	# 霜华之心：寒气领域
	if count_of("frost") > 0:
		var fc: Vector2 = player.position + Vector2(0, -24.0)
		draw_circle(fc, 98.0, Color(0.55, 0.88, 1.0, 0.055))
		draw_arc(fc, 98.0 + sin(t * 2.4) * 4.0, 0.0, TAU, 40, Color(0.68, 0.94, 1.0, 0.28), 2.0)
	# 新遗物的独立模型（环绕在角色周身）
	_draw_relic_models()

	# 圣裁之眼：激光束
	if laser_life > 0.0:
		var a: float = clampf(laser_life / 0.26, 0.0, 1.0)
		var dir: Vector2 = (laser_to - laser_from)
		if dir.length() > 1.0:
			var ln: float = dir.length()
			var d2: Vector2 = dir / ln
			var w: float = 7.0 * a + 2.0
			draw_line(laser_from, laser_from + d2 * ln, Color(1.0, 0.92, 0.55, 0.30 * a), w * 2.6)
			draw_line(laser_from, laser_from + d2 * ln, Color(1.0, 0.97, 0.72, 0.80 * a), w)
			draw_line(laser_from, laser_from + d2 * ln, Color(1.0, 1.0, 0.98, 0.95 * a), w * 0.4)
			draw_circle(laser_from, 9.0 * a + 2.0, Color(1.0, 0.95, 0.6, 0.5 * a))
			draw_circle(laser_to, 11.0 * a + 2.0, Color(1.0, 0.92, 0.55, 0.45 * a))
	var nh: int = count_of("halo")
	var ns: int = count_of("sword")
	var nb: int = count_of("book")

	# 魔法光环
	if nh > 0:
		var orbs: int = nh * 2
		for i in range(orbs):
			var ang: float = halo_a + float(i) * TAU / float(orbs)
			var p: Vector2 = player.position + Vector2(0, -26) + Vector2(cos(ang), sin(ang)) * 38.0
			draw_circle(p, 10.0, Color(1.0, 0.85, 0.45, 0.12))
			draw_circle(p, 5.2, Color(1.0, 0.88, 0.55, 0.45))
			draw_circle(p, 2.6, Color(1.0, 0.98, 0.86, 0.95))

	# 飞剑
	if ns > 0:
		for i in range(ns):
			var ang2: float = orbit_a + float(i) * TAU / float(ns)
			var rad2: float = 54.0 + float(i % 2) * 7.0
			var p2: Vector2 = player.position + Vector2(0, -26) + Vector2(cos(ang2), sin(ang2)) * rad2
			draw_circle(p2, 12.0, Color(0.55, 0.85, 1.0, 0.12))
			draw_set_transform(p2, ang2 + PI * 0.5, Vector2(1.0, 1.0))
			draw_rect(Rect2(-1.6, -15.0, 3.2, 20.0), Color(0.86, 0.93, 1.0, 0.95))
			draw_rect(Rect2(-1.0, -15.0, 1.4, 18.0), Color(1.0, 1.0, 1.0, 0.6))
			draw_rect(Rect2(-4.5, 4.0, 9.0, 2.2), Color(0.64, 0.47, 0.28))
			draw_rect(Rect2(-1.3, 6.0, 2.6, 6.0), Color(0.45, 0.32, 0.20))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 魔导书
	if nb > 0:
		var bp: Vector2 = player.position + Vector2(-player.facing * 30.0, -84.0 + sin(t * 2.2) * 4.0)
		draw_circle(bp, 26.0, Color(0.45, 0.70, 1.0, 0.09))
		draw_set_transform(bp, sin(t * 1.7) * 0.16, Vector2(1.0, 1.0))
		draw_rect(Rect2(-16.0, -8.0, 32.0, 18.0), Color(0.26, 0.18, 0.32))
		draw_rect(Rect2(-14.0, -6.0, 13.0, 14.0), Color(0.86, 0.92, 1.0, 0.92))
		draw_rect(Rect2(1.0, -6.0, 13.0, 14.0), Color(0.90, 0.95, 1.0, 0.92))
		draw_rect(Rect2(-0.8, -8.0, 1.6, 18.0), Color(0.18, 0.12, 0.22))
		var rune: float = 0.5 + 0.5 * sin(t * 4.0)
		draw_rect(Rect2(-10.0, -2.0, 5.0, 1.6), Color(0.45, 0.85, 1.0, rune))
		draw_rect(Rect2(4.0, 0.0, 6.0, 1.6), Color(0.45, 0.85, 1.0, 1.0 - rune * 0.4))
		draw_rect(Rect2(-9.0, 3.0, 4.0, 1.4), Color(0.55, 0.75, 1.0, 0.8))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 宠物
	var pet_kinds: Array = ["pet_imp", "pet_cat", "pet_sprite"]
	for i in range(pet_kinds.size()):
		var pid: String = str(pet_kinds[i])
		if count_of(pid) <= 0:
			continue
		var pp: Vector2 = player.position
		if pet_pos.has(pid):
			pp = pet_pos[pid]
		_draw_pet(pid, pp)

	# 替身
	_draw_stand_family(player.position, player.facing)

	# 魔法保护气泡
	if guard_charges > 0:
		var gp: Vector2 = player.position + Vector2(0, -28)
		var pulse: float = 0.5 + 0.5 * sin(t * 4.0)
		draw_arc(gp, 34.0, 0.0, TAU, 26, Color(0.72, 0.92, 1.0, 0.20 + 0.14 * pulse), 2.0)
		for i in range(guard_charges):
			draw_circle(gp + Vector2(-8.0 + float(i) * 16.0, -40.0), 3.0, Color(0.85, 0.96, 1.0, 0.9))


func _draw_pet(pid: String, pos: Vector2) -> void:
	draw_circle(pos, 22.0, Color(0.9, 0.7, 0.5, 0.07))
	draw_set_transform(pos, 0.0, Vector2(1.0, 1.0))
	if pid == "pet_imp":
		var wing: float = sin(t * 9.0) * 4.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(-4.0, -5.0), Vector2(-18.0, -12.0 + wing), Vector2(-14.0, 3.0),
		]), Color(0.38, 0.16, 0.26, 0.92))
		draw_colored_polygon(PackedVector2Array([
			Vector2(4.0, -5.0), Vector2(18.0, -12.0 + wing), Vector2(14.0, 3.0),
		]), Color(0.38, 0.16, 0.26, 0.92))
		draw_rect(Rect2(-6.0, -9.0, 12.0, 12.0), Color(0.86, 0.36, 0.28))
		draw_rect(Rect2(-6.0, -9.0, 12.0, 3.0), Color(1.0, 0.58, 0.38))
		draw_rect(Rect2(-5.0, -13.0, 3.0, 4.0), Color(0.58, 0.20, 0.18))
		draw_rect(Rect2(2.0, -13.0, 3.0, 4.0), Color(0.58, 0.20, 0.18))
		draw_rect(Rect2(-4.0, -5.0, 3.0, 3.0), Color(1.0, 0.95, 0.55))
		draw_rect(Rect2(1.0, -5.0, 3.0, 3.0), Color(1.0, 0.95, 0.55))
	elif pid == "pet_cat":
		var wag: float = sin(t * 12.0) * 5.0
		draw_rect(Rect2(-8.0, -6.0, 16.0, 10.0), Color(0.78, 0.88, 1.0, 0.75))
		draw_rect(Rect2(-6.0, -11.0, 12.0, 7.0), Color(0.86, 0.94, 1.0, 0.85))
		draw_rect(Rect2(-5.0, -15.0, 3.0, 4.0), Color(0.80, 0.90, 1.0, 0.8))
		draw_rect(Rect2(2.0, -15.0, 3.0, 4.0), Color(0.80, 0.90, 1.0, 0.8))
		draw_rect(Rect2(-4.0, -9.0, 2.4, 2.4), Color(0.35, 0.95, 1.0))
		draw_rect(Rect2(2.0, -9.0, 2.4, 2.4), Color(0.35, 0.95, 1.0))
		draw_rect(Rect2(7.0, -8.0, 2.0, 8.0 + wag), Color(0.80, 0.90, 1.0, 0.6))
	else:
		var gl: float = 0.6 + 0.4 * sin(t * 5.0)
		draw_circle(Vector2.ZERO, 12.0, Color(0.7, 1.0, 0.75, 0.14 * gl))
		draw_rect(Rect2(-5.0, -9.0, 10.0, 12.0), Color(0.72, 1.0, 0.78, 0.85))
		draw_rect(Rect2(-7.0, -4.0, 3.0, 7.0), Color(0.85, 1.0, 0.88, 0.7))
		draw_rect(Rect2(4.0, -4.0, 3.0, 7.0), Color(0.85, 1.0, 0.88, 0.7))
		draw_rect(Rect2(-3.0, -6.0, 2.0, 2.0), Color(0.15, 0.35, 0.2))
		draw_rect(Rect2(1.0, -6.0, 2.0, 2.0), Color(0.15, 0.35, 0.2))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_stand_family(pos: Vector2, face: float) -> void:
	var ns: int = count_of("stand_shadow")
	var nw: int = count_of("stand_ward")
	var na: int = count_of("stand_arcane")
	if ns > 0:
		var active: bool = stand_life > 0.0
		var alpha: float = 0.74 if active else 0.20
		var off: Vector2 = Vector2(face * 34.0, 0.0) if active else Vector2(-face * 30.0, 0.0)
		_draw_stand(pos + off, face, alpha, active,
			Color(0.62, 0.45, 0.95, alpha), Color(0.34, 0.22, 0.60, alpha),
			Color(0.95, 0.88, 1.0, minf(1.0, alpha + 0.12)))
	if nw > 0:
		var a2: float = 0.42 if ward_flash > 0.0 else 0.16
		_draw_stand(pos + Vector2(-face * 40.0, 0.0), face, a2, ward_flash > 0.0,
			Color(0.42, 0.72, 0.95, a2), Color(0.20, 0.42, 0.62, a2),
			Color(0.80, 0.95, 1.0, minf(1.0, a2 + 0.16)))
		if ward_flash > 0.0:
			draw_circle(pos + Vector2(0, -26), 96.0 * (1.0 - ward_flash / 0.5) + 20.0,
				Color(0.55, 0.9, 1.0, ward_flash * 0.25))
	if na > 0:
		var a3: float = 0.46 if arcane_flash > 0.0 else 0.16
		_draw_stand(pos + Vector2(face * 44.0, 0.0), face, a3, arcane_flash > 0.0,
			Color(0.85, 0.55, 0.90, a3), Color(0.55, 0.28, 0.62, a3),
			Color(1.0, 0.85, 1.0, minf(1.0, a3 + 0.16)))


func _draw_stand(pos: Vector2, face: float, alpha: float, active: bool, c_main: Color, c_dark: Color, c_hi: Color) -> void:
	draw_circle(pos + Vector2(0.0, -30.0), 34.0, Color(c_main.r, c_main.g, c_main.b, alpha * 0.16))
	draw_set_transform(pos, 0.0, Vector2(1.35, 1.35))
	# 腿
	draw_rect(Rect2(-7.0, -20.0, 6.0, 20.0), c_dark)
	draw_rect(Rect2(1.0, -20.0, 6.0, 20.0), c_dark)
	# 躯干
	draw_rect(Rect2(-9.0, -44.0, 18.0, 25.0), c_main)
	draw_rect(Rect2(-9.0, -44.0, 18.0, 4.0), c_hi)
	draw_rect(Rect2(-2.0, -40.0, 4.0, 18.0), c_dark)
	# 肩甲
	draw_rect(Rect2(-14.0, -47.0, 7.0, 9.0), c_hi)
	draw_rect(Rect2(7.0, -47.0, 7.0, 9.0), c_hi)
	# 头
	draw_rect(Rect2(-6.0, -59.0, 12.0, 12.0), c_main)
	draw_rect(Rect2(-6.0, -59.0, 12.0, 2.0), c_hi)
	draw_rect(Rect2(-4.0, -53.0, 3.0, 3.0), Color(1.0, 0.96, 0.72, minf(1.0, alpha + 0.2)))
	draw_rect(Rect2(2.0, -53.0, 3.0, 3.0), Color(1.0, 0.96, 0.72, minf(1.0, alpha + 0.2)))
	# 后背手臂
	_dir_rect(-face * 8.0, -face, 8.0, -40.0, 7.0, c_dark)
	# 出拳
	if active:
		var reach: float = 12.0 + 26.0
		_dir_rect(face * 7.0, face, reach, -40.0, 8.0, c_main)
		_dir_rect(face * 7.0, face, reach, -40.0, 2.0, c_hi)
		var fist_x: float = face * (7.0 + reach)
		_dir_rect(fist_x, face, 9.0, -42.0, 12.0, c_hi)
		for i in range(3):
			var ly: float = -46.0 + float(i) * 6.0
			_dir_rect(face * (7.0 + reach * 0.45), face, 26.0, ly, 1.6, Color(1.0, 0.95, 1.0, alpha * 0.35))
	else:
		_dir_rect(face * 5.0, face, 7.0, -40.0, 8.0, c_dark)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 从 x_start 沿 dir 方向画一段矩形（自动处理负宽）
func _dir_rect(x_start: float, dir: float, length: float, y: float, h: float, col: Color) -> void:
	var x1: float = x_start + dir * length
	draw_rect(Rect2(minf(x_start, x1), y, absf(x1 - x_start), h), col)


## 环绕遗物是否很多（多则降频重绘）
func _orbit_heavy() -> bool:
	var ids: Array = ["laser", "thunder", "frost", "thorn", "crown", "magnet", "pet_skull", "phoenix",
		"orbit_blade", "orbit_flame", "orbit_frost", "orbit_storm", "orbit_thorn",
		"orbit_void", "orbit_holy", "orbit_blood", "orbit_hex", "orbit_error"]
	var n: int = 0
	for k in range(ids.size()):
		if count_of(str(ids[k])) > 0:
			n += 1
	return n > 5


## 环绕型遗物：旋转的大范围攻击环
func _update_orbits(dt: float, mag: float) -> void:
	orbit_ang += dt * 2.6
	orbit_cd -= dt
	if orbit_cd > 0.0:
		return
	orbit_cd = 0.25
	if player == null or not is_instance_valid(player) or game == null:
		return
	for id in DEFS.keys():
		var sid: String = str(id)
		if count_of(sid) <= 0:
			continue
		var d: Dictionary = DEFS[sid]
		if not d.has("orbit"):
			continue
		var radius: float = float(d["orbit"])
		var hit_dmg: float = float(d.get("orbit_dmg", 18.0)) * mag
		var st: String = str(d.get("orbit_status", ""))
		var heal: float = float(d.get("orbit_heal", 0.0))
		var ocand: Array = _near_cache(player.position)
		for i in range(ocand.size()):
			var e = ocand[i]
			if e == null or not is_instance_valid(e) or e.dead:
				continue
			var ec: Vector2 = e.position + Vector2(0, -e.size.y * 0.5)
			if player.position.distance_to(ec) > radius * 0.55:
				continue
			var dirv: Vector2 = (ec - player.position).normalized()
			e.hurt(hit_dmg, dirv, 90.0, 0.05, "")
			if st != "":
				e.apply_status(st, 5.0)
			game.note_damage(hit_dmg)
			if heal > 0.0:
				player.hp = minf(player.max_hp, player.hp + heal)
			game.fx.spark_spawn(ec, dirv, 3, d["col"])
		game.fx.ring_spawn(player.position + Vector2(0, -30), radius, d["col"])


## 召唤物伤害总倍率（遗物叠加）
func summon_mult() -> float:
	return agg_val("summon_mult", 1.0)
## 召唤物加成（遗物）
func summon_extra() -> int:
	var n := 0
	for id in DEFS.keys():
		var sid: String = str(id)
		if count_of(sid) > 0 and DEFS[sid].has("summon_extra"):
			n += int(DEFS[sid]["summon_extra"]) * count_of(sid)
	return n


func summon_speed() -> float:
	return agg_val("summon_speed", 1.0)

func summon_life_bonus() -> float:
	return agg_val("summon_life", 0.0)

func summon_ghost() -> bool:
	for id in DEFS.keys():
		var sid: String = str(id)
		if count_of(sid) > 0 and DEFS[sid].has("summon_ghost"):
			return true
	return false


func summon_splash() -> float:
	return agg_val("summon_splash", 0.0)

func summon_heal() -> float:
	return agg_val("summon_heal", 0.0)

func summon_status() -> String:
	for id in DEFS.keys():
		var sid: String = str(id)
		if count_of(sid) > 0 and DEFS[sid].has("summon_status"):
			return str(DEFS[sid]["summon_status"])
	return ""


## 每帧只聚合一次（遗物数量多时避免十几次全表遍历）
func _agg_now() -> Dictionary:
	var f: int = Engine.get_process_frames()
	if agg_frame == f and not agg.is_empty():
		return agg
	agg_frame = f
	var a := {
		"phys": 1.0, "magic": 1.0, "taken": 1.0, "coin": 1.0, "pickup": 1.0,
		"summon_mult": 1.0, "summon_speed": 1.0, "summon_life": 0.0, "summon_heal": 0.0,
		"summon_splash": 0.0, "summon_extra": 0, "summon_ghost": false, "summon_status": "",
		"mana_regen": 0.0, "mana_max": 0.0, "kill_mana": 0.0, "hurt_mana": 0.0,
		"magic_mult": 1.0, "heal_mult": 1.0, "orbit_count": 0,
		"laser": 0, "thunder": 0, "frost": 0, "thorn": 0, "crown": 0, "magnet": 0,
	}
	var keys: Array = counts.keys()
	for i in range(keys.size()):
		var sid: String = str(keys[i])
		var n: int = int(counts[sid])
		if n <= 0 or not DEFS.has(sid):
			continue
		var d: Dictionary = DEFS[sid]
		if d.has("phys"):
			a["phys"] = float(a["phys"]) * pow(float(d["phys"]), float(n))
		if d.has("magic"):
			a["magic"] = float(a["magic"]) * pow(float(d["magic"]), float(n))
		if d.has("taken"):
			a["taken"] = float(a["taken"]) * pow(float(d["taken"]), float(n))
		if d.has("coin"):
			a["coin"] = float(a["coin"]) * pow(float(d["coin"]), float(n))
		if d.has("pickup"):
			a["pickup"] = float(a["pickup"]) * pow(float(d["pickup"]), float(n))
		if d.has("magic_mult"):
			a["magic_mult"] = float(a["magic_mult"]) * pow(float(d["magic_mult"]), float(n))
		if d.has("heal_mult"):
			a["heal_mult"] = float(a["heal_mult"]) * (1.0 + float(d["heal_mult"]) * float(n))
		if d.has("summon_mult"):
			a["summon_mult"] = float(a["summon_mult"]) * pow(float(d["summon_mult"]), float(n))
		if d.has("summon_speed"):
			a["summon_speed"] = float(a["summon_speed"]) * pow(float(d["summon_speed"]), float(n))
		if d.has("summon_life"):
			a["summon_life"] = float(a["summon_life"]) + float(d["summon_life"]) * float(n)
		if d.has("summon_heal"):
			a["summon_heal"] = float(a["summon_heal"]) + float(d["summon_heal"]) * float(n)
		if d.has("summon_splash"):
			a["summon_splash"] = maxf(float(a["summon_splash"]), float(d["summon_splash"]))
		if d.has("summon_extra"):
			a["summon_extra"] = int(a["summon_extra"]) + int(d["summon_extra"]) * n
		if d.has("summon_ghost"):
			a["summon_ghost"] = true
		if d.has("summon_status") and str(a["summon_status"]) == "":
			a["summon_status"] = str(d["summon_status"])
		if d.has("regen"):
			a["mana_regen"] = float(a["mana_regen"]) + float(d["regen"]) * float(n)
		if d.has("mana_max"):
			a["mana_max"] = float(a["mana_max"]) + float(d["mana_max"]) * float(n)
		if d.has("kill_mana"):
			a["kill_mana"] = float(a["kill_mana"]) + float(d["kill_mana"]) * float(n)
		if d.has("hurt_mana"):
			a["hurt_mana"] = float(a["hurt_mana"]) + float(d["hurt_mana"]) * float(n)
		if d.has("orbit"):
			a["orbit_count"] = int(a["orbit_count"]) + n
		for kk in ["laser", "thunder", "frost", "thorn", "crown", "magnet"]:
			if sid == str(kk):
				a[kk] = int(a[kk]) + n
	return a


func agg_val(key: String, def: float = 0.0) -> float:
	var a: Dictionary = _agg_now()
	return float(a.get(key, def))
