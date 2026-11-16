extends RefCounted
## 图鉴：怪物 / 武器 / 技能 / 遗物
## - 遇到即收录（杀怪、捡到、换装）
## - 存档写 user://codex.cfg，重启游戏后仍然保留

const W = preload("res://scripts/weapons.gd")
const SkillsLib = preload("res://scripts/skills.gd")
const ItemsLib = preload("res://scripts/items.gd")

const SAVE_PATH := "user://codex.cfg"
const CATS := ["monsters", "weapons", "skills", "items"]
const CAT_NAMES := ["怪物", "武器", "技能", "遗物"]

const MONSTERS := {
	"slime": {
		"name": "史莱姆", "hp": "38", "dmg": "9",
		"desc": "蓄力后弹跳扑向玩家，落地产生冲击；死亡会分裂成两只小史莱姆。",
	},
	"slime_mini": {
		"name": "小史莱姆", "hp": "16", "dmg": "6",
		"desc": "史莱姆分裂之物，跳得更快、很脆。",
	},
	"zombie": {
		"name": "腐尸僵尸", "hp": "74", "dmg": "14",
		"desc": "缓慢逼近，近距离前摇 0.3 秒后猛冲抓咬；抗击退，会留下大量血迹。",
	},
	"goblin": {
		"name": "哥布林", "hp": "46", "dmg": "10",
		"desc": "保持中距离投掷飞刀，遇到障碍会跳过去；被逼近时也会挥刀反击。",
	},
	"elite": {
		"name": "精英怪", "hp": "×2.7", "dmg": "×1.5",
		"desc": "第 2 层起每层一只，体型更大、带紫色光环；必掉遗物，有几率掉技能与武器。",
	},
	"skeleton": {"name": "骷髅怪", "hp": "58", "dmg": "13", "desc": "白骨士兵，眼窝发蓝光，移动比僵尸快但很脆。"},
	"flesh": {"name": "腐肉怪", "hp": "150", "dmg": "18", "desc": "缝合的巨型肉块，行动迟缓但血量极高、抗击退。"},
	"slime_blue": {"name": "蓝史莱姆", "hp": "46", "dmg": "10", "desc": "水元素史莱姆，死亡分裂成两只更小的蓝史莱姆。"},
	"slime_metal": {"name": "金史莱姆", "hp": "50", "dmg": "12", "desc": "金属性，五行相克中土属性最克制它之外的都不怕"},
	"slime_wood": {"name": "木史莱姆", "hp": "46", "dmg": "10", "desc": "木属性，被火属性克制"},
	"slime_earth": {"name": "土史莱姆", "hp": "62", "dmg": "13", "desc": "土属性，血最厚，被木属性克制"},
	"slime_red": {"name": "红史莱姆", "hp": "44", "dmg": "12", "desc": "火元素史莱姆，死亡分裂成两只更小的红史莱姆。"},
	"slime_king": {"name": "史莱姆王", "hp": "460", "dmg": "20", "desc": "王级 BOSS：戴金冠的巨大史莱姆，死亡爆出 6 只红史莱姆。"},
	"slime_queen": {"name": "史莱姆王后", "hp": "400", "dmg": "18", "desc": "王级 BOSS：紫冠史莱姆，死亡爆出 6 只蓝史莱姆。"},
	"drake_small": {"name": "小型飞龙", "hp": "78", "dmg": "12", "desc": "会飞的火属性幼龙，保持距离喷吐火球。"},
	"drake_large": {"name": "大型飞龙", "hp": "210", "dmg": "18", "desc": "成年赤龙，血厚且火球更大。"},
	"drake_king": {"name": "飞龙王", "hp": "620", "dmg": "26", "desc": "王级 BOSS：击败后可能获得飞龙召唤与飞龙王套装（附带灼烧）。"},
	"seadrake_small": {"name": "小海龙", "hp": "84", "dmg": "11", "desc": "蓝色飞龙，喷水柱减速玩家。"},
	"seadrake_large": {"name": "大海龙", "hp": "224", "dmg": "17", "desc": "成年海龙，水柱更强。"},
	"seadrake_king": {"name": "海龙王", "hp": "660", "dmg": "24", "desc": "王级 BOSS：击败后可能获得海龙召唤与海龙王套装（附带缓速）。"},
}

var seen: Dictionary = {}
var dirty := false
var _cache: Dictionary = {}


func _init() -> void:
	seen = {"monsters": {}, "weapons": {}, "skills": {}, "items": {}}
	load_save()


# ---------------------------------------------------------------- 分类
func cat_count() -> int:
	return CATS.size()


func cat_id(i: int) -> String:
	var n: int = CATS.size()
	var k: int = ((i % n) + n) % n
	return str(CATS[k])


func cat_name(i: int) -> String:
	var n: int = CAT_NAMES.size()
	var k: int = ((i % n) + n) % n
	return str(CAT_NAMES[k])


# ---------------------------------------------------------------- 收录
func mark(cat: String, id: String) -> void:
	if not seen.has(cat):
		return
	if id == "":
		return
	var bucket: Dictionary = seen[cat]
	if bucket.has(id):
		return
	bucket[id] = true
	dirty = true


func is_seen(cat: String, id: String) -> bool:
	if not seen.has(cat):
		return false
	var bucket: Dictionary = seen[cat]
	return bucket.has(id)


func seen_count(cat: String) -> int:
	var n: int = 0
	var list: Array = entries(cat)
	for i in range(list.size()):
		var e: Dictionary = list[i]
		if is_seen(cat, str(e["id"])):
			n += 1
	return n


func total_count(cat: String) -> int:
	return entries(cat).size()


# ---------------------------------------------------------------- 条目数据
func entries(cat: String) -> Array:
	if _cache.has(cat):
		return _cache[cat]
	var out: Array = []
	if cat == "monsters":
		out = _monster_entries()
	elif cat == "weapons":
		out = _weapon_entries()
	elif cat == "skills":
		out = _skill_entries()
	else:
		out = _item_entries()
	_cache[cat] = out
	return out


func _monster_entries() -> Array:
	var out: Array = []
	var ids: Array = ["slime", "slime_mini", "slime_blue", "slime_red", "slime_metal", "slime_wood", "slime_earth", "slime_king", "slime_queen",
		"zombie", "skeleton", "flesh", "goblin",
		"drake_small", "drake_large", "drake_king",
		"seadrake_small", "seadrake_large", "seadrake_king", "elite"]
	for i in range(ids.size()):
		var id: String = str(ids[i])
		var d: Dictionary = MONSTERS[id]
		out.append({
			"id": id,
			"name": str(d["name"]),
			"desc": str(d["desc"]),
			"extra": "生命 %s    接触伤害 %s" % [str(d["hp"]), str(d["dmg"])],
			"col": Color(0.86, 0.62, 0.62),
		})
	return out


func _weapon_entries() -> Array:
	var out: Array = []
	for i in range(W.SWORD_IDS.size()):
		var id: String = str(W.SWORD_IDS[i])
		var d: Dictionary = W.SWORDS[id]
		var dm: Array = d["dmg"]
		out.append({
			"id": id,
			"name": "剑 · " + str(d["name"]),
			"desc": str(d["desc"]),
			"extra": "三段伤害 %d / %d / %d    攻击范围 %d" % [int(dm[0]), int(dm[1]), int(dm[2]), int(d["reach"])],
			"col": d["col"],
		})
	for i in range(W.GUN_IDS.size()):
		var id2: String = str(W.GUN_IDS[i])
		var g: Dictionary = W.gun(id2)
		var gd: Array = g["dmg"]
		var ammo_txt: String = "无限"
		if int(g["ammo"]) > 0:
			ammo_txt = "%d 发" % int(g["ammo"])
		out.append({
			"id": id2,
			"name": "远程 · " + str(g["name"]),
			"desc": str(g["desc"]),
			"extra": "伤害 %d    弹药 %s    换弹 %.1f 秒" % [int(gd[0]), ammo_txt, float(g["reload"])],
			"col": g["col"],
		})
	for i in range(W.SHIELD_IDS.size()):
		var id3: String = str(W.SHIELD_IDS[i])
		var s: Dictionary = W.SHIELDS[id3]
		out.append({
			"id": id3,
			"name": "盾 · " + str(s["name"]),
			"desc": str(s["desc"]),
			"extra": "装备后自动生效",
			"col": s["col"],
		})
	return out


func _skill_entries() -> Array:
	var out: Array = []
	for id in SkillsLib.DEFS.keys():
		var sid: String = str(id)
		var d: Dictionary = SkillsLib.DEFS[sid]
		out.append({
			"id": sid,
			"name": str(d["name"]),
			"desc": str(d["desc"]),
			"extra": "增益" if bool(d["good"]) else "诅咒（开宝箱时可能强加）",
			"col": Color(0.6, 1.0, 0.72) if bool(d["good"]) else Color(1.0, 0.5, 0.5),
		})
	return out


func _item_entries() -> Array:
	var out: Array = []
	for id in ItemsLib.DEFS.keys():
		var iid: String = str(id)
		var d: Dictionary = ItemsLib.DEFS[iid]
		out.append({
			"id": iid,
			"name": str(d["name"]),
			"desc": str(d["desc"]),
			"extra": "可叠加，叠加越多越强",
			"col": d["col"],
		})
	return out


# ---------------------------------------------------------------- 存档
func load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for i in range(CATS.size()):
		var cat: String = str(CATS[i])
		var arr: Array = cfg.get_value("codex", cat, [])
		for k in range(arr.size()):
			mark(cat, str(arr[k]))
	dirty = false


func save_now() -> void:
	if not dirty:
		return
	var cfg := ConfigFile.new()
	for i in range(CATS.size()):
		var cat: String = str(CATS[i])
		var arr: Array = []
		var bucket: Dictionary = seen[cat]
		for id in bucket.keys():
			arr.append(str(id))
		cfg.set_value("codex", cat, arr)
	cfg.save(SAVE_PATH)
	dirty = false
