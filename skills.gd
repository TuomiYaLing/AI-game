extends RefCounted
## 技能表（增益 + 诅咒）。可在宝箱中获得，效果按层数叠加。
## key 约定：
##   phys   物理伤害倍率      magic  魔法伤害倍率
##   taken  受伤倍率          speed  移速倍率      atkspd 攻速倍率
##   hp_mult 最大生命倍率     hp_add 最大生命加值  flask 药瓶加值
##   lifesteal 吸血比例       djump 空中跳跃次数 +1  pickup 拾取范围倍率
##   coin   金币倍率

const DEFS := {
	"rage": {"name": "狂怒", "good": true, "phys": 1.30, "desc": "物理伤害 +30%"},
	"arcane": {"name": "秘法共鸣", "good": true, "magic": 1.35, "desc": "魔法伤害 +35%"},
	"swift": {"name": "疾风", "good": true, "speed": 1.20, "atkspd": 1.15, "desc": "移速 +20%，攻速 +15%"},
	"vital": {"name": "生命涌动", "good": true, "hp_add": 35.0, "desc": "最大生命 +35"},
	"vital10": {"name": "血肉增生", "good": true, "hp_add": 55.0, "desc": "最大生命 +55"},
	"vital11": {"name": "钢铁血脉", "good": true, "hp_add": 80.0, "taken": 0.95, "desc": "最大生命 +80，受伤 -5%"},
	"vital12": {"name": "巨人心脏", "good": true, "hp_mult": 1.20, "desc": "最大生命 +20%"},
	"vital13": {"name": "龙血", "good": true, "hp_mult": 1.30, "hp_add": 20.0, "desc": "最大生命 +30% 与 +20"},
	"vital14": {"name": "不屈意志", "good": true, "hp_add": 40.0, "taken": 0.92, "desc": "最大生命 +40，受伤 -8%"},
	"vital15": {"name": "再生细胞", "good": true, "hp_add": 30.0, "lifesteal": 0.05, "desc": "最大生命 +30，吸血 +5%"},
	"vital16": {"name": "圣痕", "good": true, "hp_mult": 1.15, "flask": 1, "desc": "最大生命 +15%，药瓶 +1"},
	"vital17": {"name": "厚皮", "good": true, "hp_add": 25.0, "taken": 0.90, "desc": "最大生命 +25，受伤 -10%"},
	"vital18": {"name": "生命力场", "good": true, "hp_mult": 1.25, "desc": "最大生命 +25%"},
	"mana_well": {"name": "秘泉", "good": true, "mana_regen": 6.0, "desc": "法力回复 +6/秒"},
	"sk_beast": {"name": "兽性唤醒", "good": true, "summon_mult": 1.40, "desc": "召唤物伤害 +40%"},
	"sk_swarm": {"name": "群魔乱舞", "good": true, "summon_mult": 1.20, "summon_extra": 1, "desc": "召唤物伤害 +20%，并额外召唤 1 只"},
	"sk_haste": {"name": "疾魂", "good": true, "summon_speed": 1.45, "desc": "召唤物攻速 +45%"},
	"sk_persist": {"name": "长夜契约", "good": true, "summon_life": 6.0, "desc": "召唤物存在时间 +6 秒"},
	"sk_warp": {"name": "穿界术", "good": true, "summon_ghost": true, "desc": "所有召唤物可穿墙"},
	"sk_leech": {"name": "魂之汲取", "good": true, "summon_heal": 1.2, "desc": "召唤物命中时为你回复生命"},
	"sk_splash": {"name": "裂魂", "good": true, "summon_splash": 44.0, "desc": "召唤物命中会溅射周围敌人"},
	"sk_brim": {"name": "燃魂", "good": true, "summon_status": "burn", "desc": "召唤物命中附加【灼烧】"},
	"sk_fetters": {"name": "缚魂", "good": true, "summon_status": "root", "desc": "召唤物命中附加【定身】"},
	"sk_madness": {"name": "疯狂之赐", "good": true, "summon_mult": 1.50, "taken": 1.15, "desc": "召唤物伤害 +50%，但你受伤 +15%"},
	"sk_master": {"name": "万魂之主", "good": true, "summon_mult": 1.35, "summon_extra": 1, "summon_speed": 1.2, "desc": "召唤物伤害 +35%、+1 只、攻速 +20%"},
	"sk_eternal": {"name": "永劫不灭", "good": true, "summon_life": 10.0, "summon_mult": 1.25, "desc": "召唤物伤害 +25%，存在时间 +10 秒"},
	"mana_pool": {"name": "魔法池", "good": true, "mana_add": 30.0, "desc": "法力上限 +30"},
	"mana_flow": {"name": "法力涌动", "good": true, "mana_cost": 0.85, "desc": "法术消耗 -15%"},
	"mana_star": {"name": "星辰共鸣", "good": true, "mana_add": 45.0, "mana_regen": 3.0, "desc": "法力上限 +45，回复 +3/秒"},
	"curse_mana1": {"name": "法力枯竭", "good": false, "mana_mult": 0.80, "desc": "法力上限 -20%"},
	"curse_mana2": {"name": "法术反噬", "good": false, "mana_cost": 1.25, "desc": "法术消耗 +25%"},
	"curse_mana3": {"name": "魔力流失", "good": false, "mana_regen": -4.0, "desc": "法力回复 -4/秒"},
	"curse_mana4": {"name": "魔怔", "good": false, "mana_mult": 0.70, "mana_cost": 1.15, "desc": "法力上限 -30%，消耗 +15%"},
	"vital19": {"name": "不死之躯", "good": true, "hp_add": 120.0, "taken": 1.08, "desc": "最大生命 +120，但受伤 +8%"},
	"apothecary": {"name": "药剂师", "good": true, "flask": 1, "desc": "药瓶 +1"},
	"vampire": {"name": "吸血", "good": true, "lifesteal": 0.08, "desc": "造成伤害的 8% 回复生命"},
	"doublejump": {"name": "跃升", "good": true, "djump": 1, "desc": "空中跳跃次数 +1（角色本身已能二段跳，因此可三段跳）"},
	"magnet": {"name": "磁力", "good": true, "pickup": 1.9, "desc": "拾取范围 +90%"},
	"greed": {"name": "贪婪", "good": true, "coin": 1.5, "desc": "金币收益 +50%"},
	"ironskin": {"name": "铁皮", "good": true, "taken": 0.85, "desc": "受到伤害 -15%"},
	"glasscannon": {"name": "玻璃大炮", "good": false, "phys": 1.60, "magic": 1.60, "taken": 1.45, "hp_mult": 0.80, "desc": "伤害 +60%，受伤 +45%，生命 -20%"},
	"frail": {"name": "脆弱", "good": false, "taken": 1.30, "desc": "受到伤害 +30%"},
	"weak": {"name": "虚弱", "good": false, "phys": 0.75, "desc": "物理伤害 -25%"},
	"sluggish": {"name": "迟钝", "good": false, "speed": 0.85, "atkspd": 0.88, "desc": "移速 -15%，攻速 -12%"},
	"anemia": {"name": "贫血", "good": false, "hp_mult": 0.75, "desc": "最大生命 -25%"},
	"hex": {"name": "咒印", "good": false, "magic": 0.70, "desc": "魔法伤害 -30%"},
	"chaosdeal": {"name": "混沌交易", "good": false, "phys": 1.45, "magic": 1.45, "hp_mult": 0.65, "desc": "伤害 +45%，最大生命 -35%"},
}

const GOOD_IDS := [
	"rage", "arcane", "swift", "vital", "apothecary", "vampire",
	"doublejump", "magnet", "greed", "ironskin",
	"vital10", "vital11", "vital12", "vital13", "vital14", "vital15", "vital16", "vital17", "vital18", "vital19",
	"mana_well", "mana_pool", "mana_flow", "mana_star",
	"sk_beast",
	"sk_swarm",
	"sk_haste",
	"sk_persist",
	"sk_warp",
	"sk_leech",
	"sk_splash",
	"sk_brim",
	"sk_fetters",
	"sk_madness",
	"sk_master",
	"sk_eternal",
	"summon_1",
	"summon_2",
	"summon_3",
	"summon_4",
	"summon_5",
	"summon_6",
	"summon_7",
	"summon_8",
	"summon_9",
	"summon_10",
	"summon_11",
	"summon_12",
	"summon_13",
	"summon_14",
	"summon_15",
]
const BAD_IDS := ["glasscannon", "frail", "weak", "sluggish", "anemia", "hex", "chaosdeal",
	"curse_hp1", "curse_hp2", "curse_hp3", "curse_hp4", "curse_hp5",
	"curse_mana1", "curse_mana2", "curse_mana3", "curse_mana4",
	"curse_hp6", "curse_hp7", "curse_hp8", "curse_hp9", "curse_hp10"]

## 生命类技能（各 10 种）
const HP_GOOD_IDS := ["vital10", "vital11", "vital12", "vital13", "vital14", "vital15", "vital16", "vital17", "vital18", "vital19"]
const HP_BAD_IDS := ["curse_hp1", "curse_hp2", "curse_hp3", "curse_hp4", "curse_hp5", "curse_hp6", "curse_hp7", "curse_hp8", "curse_hp9", "curse_hp10"]


func random_good() -> String:
	return str(GOOD_IDS[randi() % GOOD_IDS.size()])


func random_bad() -> String:
	return str(BAD_IDS[randi() % BAD_IDS.size()])


func name_of(id: String) -> String:
	if DEFS.has(id):
		return str(DEFS[id]["name"])
	return id


func desc_of(id: String) -> String:
	if DEFS.has(id):
		return str(DEFS[id]["desc"])
	return ""


func is_good(id: String) -> bool:
	if DEFS.has(id):
		return bool(DEFS[id]["good"])
	return true


func col_of(id: String) -> Color:
	if is_good(id):
		return Color(0.58, 1.00, 0.72)
	return Color(1.00, 0.48, 0.48)


var counts: Dictionary = {}
var order: Array = []


func clear() -> void:
	counts.clear()
	order.clear()


func has_any() -> bool:
	return order.size() > 0


func add(id: String) -> void:
	if not DEFS.has(id):
		return
	counts[id] = int(counts.get(id, 0)) + 1
	if not order.has(id):
		order.append(id)


func count_of(id: String) -> int:
	return int(counts.get(id, 0))


## 从存档恢复
func restore(d: Dictionary) -> void:
	clear()
	var keys: Array = d.keys()
	for i in range(keys.size()):
		var id: String = str(keys[i])
		if not DEFS.has(id):
			continue
		counts[id] = int(d[keys[i]])
		order.append(id)


## 倍率类技能（乘算，按层数幂）
func val(key: String) -> float:
	var v := 1.0
	var ids: Array = counts.keys()
	for i in range(ids.size()):
		var id: String = str(ids[i])
		var d: Dictionary = DEFS[id]
		if d.has(key):
			v *= pow(float(d[key]), float(int(counts[id])))
	return v


## 加值类技能（累加，按层数倍数）
func add_val(key: String) -> float:
	var v := 0.0
	var ids: Array = counts.keys()
	for i in range(ids.size()):
		var id: String = str(ids[i])
		var d: Dictionary = DEFS[id]
		if d.has(key):
			v += float(d[key]) * float(int(counts[id]))
	return v


func flag(key: String) -> bool:
	var ids: Array = counts.keys()
	for i in range(ids.size()):
		var id: String = str(ids[i])
		var d: Dictionary = DEFS[id]
		if d.has(key):
			return true
	return false


## HUD 用：{{id, name, good, desc, count}}
func list() -> Array:
	var out: Array = []
	for i in range(order.size()):
		var id: String = str(order[i])
		out.append({
			"id": id,
			"name": name_of(id),
			"good": is_good(id),
			"desc": desc_of(id),
			"count": count_of(id),
		})
	return out


## 技能提供的召唤物加成
func summon_extra() -> int:
	var n := 0
	for id in DEFS.keys():
		var sid: String = str(id)
		if DEFS[sid].has("summon_extra"):
			n += int(DEFS[sid]["summon_extra"]) * int(count_of(sid))
	return n


func summon_speed() -> float:
	var v := 1.0
	for id in DEFS.keys():
		var sid: String = str(id)
		if DEFS[sid].has("summon_speed"):
			v *= pow(float(DEFS[sid]["summon_speed"]), float(count_of(sid)))
	return v


func summon_life_bonus() -> float:
	var v := 0.0
	for id in DEFS.keys():
		var sid: String = str(id)
		if DEFS[sid].has("summon_life"):
			v += float(DEFS[sid]["summon_life"]) * float(count_of(sid))
	return v


func summon_ghost() -> bool:
	for id in DEFS.keys():
		var sid: String = str(id)
		if DEFS[sid].has("summon_ghost") and int(count_of(sid)) > 0:
			return true
	return false


func summon_splash() -> float:
	var v := 0.0
	for id in DEFS.keys():
		var sid: String = str(id)
		if DEFS[sid].has("summon_splash") and int(count_of(sid)) > 0:
			v = maxf(v, float(DEFS[sid]["summon_splash"]))
	return v


func summon_heal() -> float:
	var v := 0.0
	for id in DEFS.keys():
		var sid: String = str(id)
		if DEFS[sid].has("summon_heal"):
			v += float(DEFS[sid]["summon_heal"]) * int(count_of(sid))
	return v


func summon_status() -> String:
	for id in DEFS.keys():
		var sid: String = str(id)
		if DEFS[sid].has("summon_status") and int(count_of(sid)) > 0:
			return str(DEFS[sid]["summon_status"])
	return ""
