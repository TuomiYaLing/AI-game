extends RefCounted
## 武器数据表：剑（短剑/长剑/唐刀/武士刀）· 远程（弓/冲锋枪/步枪/加特林/狙击枪）· 盾（铁盾/反伤盾/闪避盾）

const SWORDS := {
	"short": {
		"name": "短剑", "tier": 1,
		"dmg": [9.0, 10.5, 17.0], "reach": 50.0, "dur": [0.19, 0.18, 0.25],
		"col": Color(0.82, 0.90, 1.00),
		"desc": "出手最快，范围最近",
	},
	"long": {
		"name": "长剑", "tier": 2,
		"dmg": [13.0, 15.0, 26.0], "reach": 64.0, "dur": [0.26, 0.24, 0.34],
		"col": Color(0.86, 0.93, 1.00),
		"desc": "均衡之选",
	},
	"whip_iron": {
		"name": "铁链鞭", "tier": 3,
		"dmg": [14.0, 16.0, 27.0], "reach": 340.0, "dur": [0.17, 0.16, 0.21],
		"col": Color(0.82, 0.84, 0.90),
		"status": "slow",
		"desc": "长距离鞭击 · 命中使目标减速",
	},
	"whip_flame": {
		"name": "火焰鞭", "tier": 4,
		"dmg": [15.0, 17.0, 30.0], "reach": 356.0, "dur": [0.18, 0.17, 0.22],
		"col": Color(1.00, 0.62, 0.30),
		"status": "burn",
		"desc": "长距离鞭击 · 命中附加持续灼烧",
	},
	"whip_frost": {
		"name": "霜冻鞭", "tier": 4,
		"dmg": [13.0, 15.0, 26.0], "reach": 372.0, "dur": [0.17, 0.16, 0.21],
		"col": Color(0.66, 0.90, 1.00),
		"status": "slow", "status2": "root",
		"desc": "最长鞭 · 命中减速并概率定身",
	},
	"whip_viper": {
		"name": "毒蛇鞭", "tier": 4,
		"dmg": [12.0, 14.0, 24.0], "reach": 344.0, "dur": [0.13, 0.12, 0.17],
		"col": Color(0.56, 0.94, 0.52),
		"status": "devour",
		"desc": "快速鞭击 · 命中附加毒蚀持续掉血",
	},
	"whip_thorn": {
		"name": "荆棘鞭", "tier": 5,
		"dmg": [18.0, 20.0, 34.0], "reach": 384.0, "dur": [0.20, 0.19, 0.24],
		"col": Color(0.86, 0.52, 0.72),
		"status": "burn",
		"desc": "最远最重的一鞭 · 灼烧并强力击退",
	},
	"whip_blood": {
		"name": "血契鞭", "tier": 5,
		"dmg": [16.0, 18.0, 31.0], "reach": 352.0, "dur": [0.16, 0.15, 0.20],
		"col": Color(0.92, 0.32, 0.42),
		"status": "confuse",
		"desc": "鞭击命中使目标混乱，失去攻击目标",
	},
	"dao": {
		"name": "唐刀", "tier": 3,
		"dmg": [15.0, 17.0, 29.0], "reach": 70.0, "dur": [0.27, 0.25, 0.36],
		"col": Color(1.00, 0.86, 0.55),
		"desc": "范围更远、伤害更高",
	},
	"katana": {
		"name": "武士刀", "tier": 4,
		"dmg": [17.0, 19.0, 33.0], "reach": 77.0, "dur": [0.29, 0.27, 0.40],
		"col": Color(1.00, 0.72, 0.82),
		"desc": "伤害与范围最强，出手最慢",
	},
	"wisp": {
		"name": "灵刃", "tier": 3, "magic": true,
		"dmg": [12.0, 14.0, 24.0], "reach": 68.0, "dur": [0.22, 0.20, 0.30],
		"col": Color(0.68, 0.90, 1.00),
		"desc": "魔法剑：伤害按「魔法等级」计算，挥砍会溅出灵光",
	},
	"rune": {
		"name": "符文巨剑", "tier": 5, "magic": true,
		"dmg": [17.0, 19.0, 33.0], "reach": 82.0, "dur": [0.30, 0.28, 0.42],
		"col": Color(0.88, 0.70, 1.00),
		"desc": "魔法剑：最重的一击，命中释放奥术冲击波",
	},
	"king_drake_sword": {
		"name": "飞龙王剑", "tier": 6, "magic": true, "status": "burn",
		"dmg": [19.0, 22.0, 38.0], "reach": 84.0, "dur": [0.28, 0.26, 0.40],
		"col": Color(1.00, 0.46, 0.22),
		"desc": "王级：命中附加【灼烧】每秒 6 点，持续 5 秒",
	},
	"king_sea_sword": {
		"name": "海龙王剑", "tier": 6, "magic": true, "status": "slow",
		"dmg": [18.0, 21.0, 36.0], "reach": 82.0, "dur": [0.27, 0.25, 0.38],
		"col": Color(0.42, 0.78, 1.00),
		"desc": "王级：命中附加【缓速】移速 -20%，持续 5 秒",
	},
	"king_slime_sword": {
		"name": "史莱姆王剑", "tier": 6, "status": "devour", "status2": "slow",
		"dmg": [16.0, 19.0, 34.0], "reach": 80.0, "dur": [0.26, 0.24, 0.38],
		"col": Color(0.66, 0.94, 0.44),
		"desc": "王级：命中附加【吞噬】每秒 3 点 + 【缓速】，持续 5 秒",
	},
	"queen_slime_sword": {
		"name": "史莱姆王后剑", "tier": 6, "magic": true, "status": "confuse",
		"dmg": [15.0, 18.0, 32.0], "reach": 80.0, "dur": [0.24, 0.22, 0.36],
		"col": Color(0.86, 0.62, 1.00),
		"desc": "王级：命中附加【混乱】，持续 5 秒",
	},
	"error_sword": {
		"name": "错误剑", "tier": 9,
		"dmg": [999999.0, 999999.0, 999999.0], "reach": 96.0, "dur": [0.18, 0.18, 0.18],
		"col": Color(1.00, 0.24, 0.88),
		"desc": "错误剑 · 挥剑即闪现斩杀最近的怪物（冷却 1 秒）",
	},
}

const GUNS := {
	"bow": {
		"name": "弓箭", "mode": "charge", "tier": 1,
		"ammo": 0, "reload": 0.0, "charge": 0.42,
		"dmg": [8.0, 28.0], "speed": [780.0, 1500.0], "delay": 0.0,
		"spread": 0.0, "bullet": "arrow",
		"col": Color(0.70, 0.85, 1.00),
		"desc": "无限箭矢，按住蓄力，射速慢但无弹药",
	},
	"smg": {
		"name": "冲锋枪", "mode": "auto", "tier": 2,
		"ammo": 30, "reload": 1.2, "charge": 0.0,
		"dmg": [5.5, 5.5], "speed": [1250.0, 1250.0], "delay": 0.085,
		"spread": 0.085, "bullet": "bullet",
		"col": Color(0.85, 0.85, 0.92),
		"desc": "30 发 · 换弹 1.2 秒 · 射速极快",
	},
	"rifle": {
		"name": "步枪", "mode": "auto", "tier": 3,
		"ammo": 50, "reload": 0.9, "charge": 0.0,
		"dmg": [11.0, 11.0], "speed": [1500.0, 1500.0], "delay": 0.14,
		"spread": 0.03, "bullet": "bullet",
		"col": Color(0.92, 0.92, 0.96),
		"desc": "50 发 · 换弹最快 · 精准",
	},
	"gatling": {
		"name": "加特林", "mode": "auto", "tier": 4,
		"ammo": 150, "reload": 5.0, "charge": 0.0,
		"dmg": [4.5, 4.5], "speed": [1200.0, 1200.0], "delay": 0.055,
		"spread": 0.13, "bullet": "bullet",
		"col": Color(1.00, 0.80, 0.42),
		"desc": "150 发 · 换弹 5 秒 · 弹雨覆盖",
	},
	"sniper": {
		"name": "狙击枪", "mode": "charge", "tier": 5,
		"ammo": 5, "reload": 3.5, "charge": 0.75,
		"dmg": [70.0, 70.0], "speed": [2600.0, 2600.0], "delay": 0.0,
		"spread": 0.0, "bullet": "sniper",
		"col": Color(0.72, 0.92, 1.00),
		"desc": "5 发 · 蓄力 0.75 秒 · 换弹 3.5 秒 · 单发最高伤害",
	},
}

const SHIELDS := {
	"iron": {"name": "铁盾", "tier": 1, "col": Color(0.76, 0.82, 0.92), "desc": "格挡减伤，举盾瞬间命中＝弹反"},
	"thorns": {"name": "反伤盾", "tier": 2, "col": Color(1.00, 0.55, 0.35), "desc": "格挡时把 50% 伤害反弹给攻击者"},
	"dodge": {"name": "闪避盾", "tier": 3, "col": Color(0.60, 1.00, 0.80), "desc": "被击中瞬间自动闪避（间隔 2 秒）"},
	"arcane": {"name": "秘法盾", "tier": 4, "col": Color(0.78, 0.62, 1.00), "desc": "格挡或弹反时释放奥术冲击，伤害周围敌人"},
	"king_drake_shield": {"name": "飞龙盾", "tier": 5, "col": Color(1.00, 0.48, 0.24), "status": "burn", "desc": "王级：格挡时对周围怪物附加【灼烧】5 秒"},
	"king_sea_shield": {"name": "海龙盾", "tier": 5, "col": Color(0.44, 0.80, 1.00), "status": "slow", "desc": "王级：格挡时对周围怪物附加【缓速】5 秒"},
	"king_slime_shield": {"name": "史莱姆王盾", "tier": 5, "col": Color(0.66, 0.94, 0.44), "status": "devour", "status2": "slow", "desc": "王级：格挡时附加【吞噬】+【缓速】5 秒"},
	"queen_slime_shield": {"name": "史莱姆王后盾", "tier": 5, "col": Color(0.88, 0.64, 1.00), "status": "confuse", "desc": "王级：格挡时对周围怪物附加【混乱】5 秒"},
	"armor_iron": {"name": "重甲", "tier": 4, "armor": true, "def_mult": 20.0, "col": Color(0.72, 0.76, 0.86), "desc": "盔甲：防御力 ×20"},
	"armor_fire": {"name": "炎甲", "tier": 5, "armor": true, "def_mult": 20.0, "status": "burn", "col": Color(1.00, 0.58, 0.30), "desc": "盔甲：防御 ×20，格挡时附加【灼烧】"},
	"armor_ice": {"name": "霜甲", "tier": 5, "armor": true, "def_mult": 20.0, "status": "slow", "col": Color(0.62, 0.90, 1.00), "desc": "盔甲：防御 ×20，格挡时附加【缓速】"},
	"armor_thorn": {"name": "荆棘甲", "tier": 5, "armor": true, "def_mult": 20.0, "reflect": 0.8, "col": Color(0.86, 0.52, 0.72), "desc": "盔甲：防御 ×20，反弹 80% 伤害"},
	"armor_void": {"name": "虚空甲", "tier": 6, "armor": true, "def_mult": 20.0, "status": "confuse", "col": Color(0.72, 0.56, 1.00), "desc": "盔甲：防御 ×20，格挡时附加【混乱】"},
	"armor_storm": {"name": "雷甲", "tier": 6, "armor": true, "def_mult": 20.0, "status": "shock", "col": Color(0.86, 0.94, 1.00), "desc": "盔甲：防御 ×20，格挡时附加【电击】"},
	"armor_saint": {"name": "圣甲", "tier": 7, "armor": true, "def_mult": 20.0, "status2": "root", "col": Color(1.00, 0.94, 0.68), "desc": "盔甲：防御 ×20，格挡时附加【定身】"},
	"armor_error": {"name": "错误之甲", "tier": 8, "armor": true, "def_mult": 20.0, "status": "shock", "status2": "confuse", "col": Color(1.00, 0.24, 0.88), "desc": "免疫所有伤害 100 秒，之后冷却 50 秒（防御 ×20）"},
}

const SWORD_IDS := ["short", "long", "dao", "katana", "error_sword", "whip_iron", "whip_flame", "whip_frost", "whip_viper", "whip_thorn", "whip_blood", "wisp", "rune", "king_drake_sword", "king_sea_sword", "king_slime_sword", "queen_slime_sword"]
const GUN_IDS := ["bow", "smg", "rifle", "gatling", "sniper", "wand_metal", "wand_wood", "wand_water", "wand_fire", "wand_earth", "wand_shock", "staff_imp", "staff_bat", "staff_skull", "staff_wisp", "staff_void", "staff_tide", "staff_prism", "tome", "king_drake_wand", "king_sea_wand", "king_slime_wand", "queen_slime_wand"]
const SHIELD_IDS := ["iron", "thorns", "dodge", "arcane", "armor_iron", "armor_fire", "armor_ice", "armor_thorn", "armor_void", "armor_storm", "armor_saint", "armor_error", "king_drake_shield", "king_sea_shield", "king_slime_shield", "queen_slime_shield"]

## 五行魔法杖 / 魔法书（无限弹，伤害吃「魔法等级」）
const MAGIC_WANDS := {
	"wand_metal": {
		"name": "金·金锋杖", "mode": "magic", "tier": 3, "elem": "metal",
		"ammo": 0, "reload": 0.0, "charge": 0.0,
		"dmg": [14.0, 14.0], "speed": [1200.0, 1200.0], "delay": 0.34,
		"spread": 0.0, "bullet": "element", "pierce": 2, "knock": 140.0,
		"col": Color(1.00, 0.92, 0.52),
		"desc": "金属性 · 高速锋刃，可穿透 3 个敌人",
	},
	"wand_wood": {
		"name": "木·藤蔓杖", "mode": "magic", "tier": 2, "elem": "wood",
		"ammo": 0, "reload": 0.0, "charge": 0.0,
		"dmg": [8.0, 8.0], "speed": [640.0, 640.0], "delay": 0.28,
		"spread": 0.0, "bullet": "element", "pierce": 0, "knock": 90.0, "homing": true,
		"col": Color(0.55, 0.95, 0.55),
		"desc": "木属性 · 追踪藤蔓，单发伤害低但必定命中",
	},
	"wand_water": {
		"name": "水·涌泉杖", "mode": "magic", "tier": 3, "elem": "water",
		"ammo": 0, "reload": 0.0, "charge": 0.0,
		"dmg": [10.0, 10.0], "speed": [920.0, 920.0], "delay": 0.30,
		"spread": 0.04, "bullet": "element", "pierce": 0, "knock": 150.0, "splash": 3,
		"col": Color(0.48, 0.82, 1.00),
		"desc": "水属性 · 命中炸成 3 颗水滴，攻击多个敌人",
	},
	"wand_fire": {
		"name": "火·炽炎杖", "mode": "magic", "tier": 4, "elem": "fire",
		"ammo": 0, "reload": 0.0, "charge": 0.0,
		"dmg": [13.0, 13.0], "speed": [860.0, 860.0], "delay": 0.38,
		"spread": 0.0, "bullet": "element", "pierce": 0, "knock": 180.0, "blast": 52.0,
		"col": Color(1.00, 0.52, 0.24),
		"desc": "火属性 · 命中在 52 像素范围内爆炸",
	},
	"wand_earth": {
		"name": "土·岩生杖", "mode": "magic", "tier": 5, "elem": "earth",
		"ammo": 0, "reload": 0.0, "charge": 0.0,
		"dmg": [34.0, 34.0], "speed": [680.0, 680.0], "delay": 0.52,
		"spread": 0.0, "bullet": "element", "pierce": 0, "knock": 420.0,
		"col": Color(0.86, 0.66, 0.38),
		"desc": "土属性 · 巨石，爆发伤害与击退最高",
	},
	"wand_shock": {
		"name": "雷·雷击杖", "mode": "magic", "tier": 4, "elem": "shock",
		"ammo": 0, "reload": 0.0, "charge": 0.0,
		"dmg": [15.0, 15.0], "speed": [1000.0, 1000.0], "delay": 0.34,
		"spread": 0.0, "bullet": "element", "pierce": 0, "knock": 200.0,
		"col": Color(0.86, 0.94, 1.00),
		"desc": "雷属性 · 命中造成【电击】持续 5 秒",
	},
	"staff_imp": {
		"name": "恶魔召唤杖", "mode": "summon", "tier": 3, "elem": "fire",
		"summon": "imp", "count": 1, "summon_dmg": 10.0, "summon_life": 15.0,
		"mana": 20.0, "ammo": 0, "reload": 0.0, "charge": 0.0,
		"dmg": [0.0, 0.0], "speed": [0.0, 0.0], "delay": 1.0, "spread": 0.0, "bullet": "summon",
		"col": Color(1.00, 0.55, 0.32),
		"desc": "挥杖召唤小恶魔（20 秒）；命中附加【灼烧】，本身无伤害",
	},
	"staff_bat": {
		"name": "蝙蝠召唤杖", "mode": "summon", "tier": 4, "elem": "",
		"summon": "bat", "count": 1, "summon_dmg": 10.0, "summon_life": 15.0, "summon_ghost": true,
		"mana": 20.0, "ammo": 0, "reload": 0.0, "charge": 0.0,
		"dmg": [0.0, 0.0], "speed": [0.0, 0.0], "delay": 1.0, "spread": 0.0, "bullet": "summon",
		"col": Color(0.62, 0.52, 0.80),
		"desc": "召唤可穿墙的蝙蝠：命中时吸血（给你回血）",
	},
	"staff_skull": {
		"name": "骷髅召唤杖", "mode": "summon", "tier": 4, "elem": "",
		"summon": "skull", "count": 1, "summon_dmg": 10.0, "summon_life": 15.0,
		"mana": 20.0, "ammo": 0, "reload": 0.0, "charge": 0.0,
		"dmg": [0.0, 0.0], "speed": [0.0, 0.0], "delay": 1.0, "spread": 0.0, "bullet": "summon",
		"col": Color(0.88, 0.88, 0.80),
		"desc": "召唤骷髅仆从：重击强击退，可撞开怪群",
	},
	"staff_wisp": {
		"name": "精灵召唤杖", "mode": "summon", "tier": 5, "elem": "",
		"summon": "wisp", "count": 1, "summon_dmg": 10.0, "summon_life": 15.0, "summon_support": true,
		"mana": 20.0, "ammo": 0, "reload": 0.0, "charge": 0.0,
		"dmg": [0.0, 0.0], "speed": [0.0, 0.0], "delay": 1.0, "spread": 0.0, "bullet": "summon",
		"col": Color(0.72, 1.00, 0.72),
		"desc": "召唤精灵：命中时治疗你并回复 4 点法力",
	},
	"staff_void": {
		"name": "虚空召唤杖", "mode": "summon", "tier": 5, "elem": "shock",
		"summon": "void", "count": 1, "summon_dmg": 10.0, "summon_life": 15.0, "summon_ghost": true,
		"mana": 20.0, "ammo": 0, "reload": 0.0, "charge": 0.0,
		"dmg": [0.0, 0.0], "speed": [0.0, 0.0], "delay": 1.0, "spread": 0.0, "bullet": "summon",
		"col": Color(0.80, 0.55, 1.00),
		"desc": "召唤穿墙虚空体：命中【电击】并溅射周围敌人",
	},
	"staff_tide": {
		"name": "潮汐召唤杖", "mode": "summon", "tier": 4, "elem": "water",
		"summon": "tide", "count": 1, "summon_dmg": 10.0, "summon_life": 15.0, "summon_support": true,
		"mana": 20.0, "ammo": 0, "reload": 0.0, "charge": 0.0,
		"dmg": [0.0, 0.0], "speed": [0.0, 0.0], "delay": 1.0, "spread": 0.0, "bullet": "summon",
		"col": Color(0.42, 0.82, 1.00),
		"desc": "召唤潮汐元素：命中【缓速】并小额治疗你；本身无伤害",
	},
	"staff_prism": {
		"name": "泰拉棱镜", "mode": "summon", "tier": 6, "elem": "",
		"summon": "prism", "count": 1, "summon_dmg": 14.0, "summon_life": 15.0, "summon_ghost": true,
		"mana": 20.0, "ammo": 0, "reload": 0.0, "charge": 0.0,
		"dmg": [0.0, 0.0], "speed": [0.0, 0.0], "delay": 1.0, "spread": 0.0, "bullet": "summon",
		"col": Color(0.80, 0.95, 1.00),
		"desc": "泰拉棱镜 · 可穿墙的炫彩之剑，极速瞬移横斩（每击 14）",
	},
	"tome": {
		"name": "魔导法典", "mode": "magic", "tier": 4, "elem": "arcane",
		"ammo": 0, "reload": 0.0, "charge": 0.0,
		"dmg": [9.0, 9.0], "speed": [720.0, 720.0], "delay": 0.46,
		"spread": 0.0, "bullet": "element", "pierce": 0, "knock": 120.0, "homing": true, "fan": 3,
		"col": Color(0.80, 0.66, 1.00),
		"desc": "魔法书 · 一次扇射 3 枚追踪奥术弹",
	},
	"king_drake_wand": {
		"name": "飞龙王法杖", "mode": "magic", "tier": 6, "elem": "fire", "status": "burn",
		"ammo": 0, "reload": 0.0, "charge": 0.0,
		"dmg": [15.0, 15.0], "speed": [900.0, 900.0], "delay": 0.34,
		"spread": 0.0, "bullet": "element", "pierce": 0, "knock": 200.0, "blast": 60.0,
		"col": Color(1.00, 0.48, 0.22),
		"desc": "王级法杖 · 火焰爆炸 + 【灼烧】5 秒",
	},
	"king_sea_wand": {
		"name": "海龙王法杖", "mode": "magic", "tier": 6, "elem": "water", "status": "slow",
		"ammo": 0, "reload": 0.0, "charge": 0.0,
		"dmg": [13.0, 13.0], "speed": [980.0, 980.0], "delay": 0.30,
		"spread": 0.0, "bullet": "element", "pierce": 0, "knock": 260.0, "splash": 3,
		"col": Color(0.44, 0.80, 1.00),
		"desc": "王级法杖 · 水枪溅射 + 【缓速】5 秒",
	},
	"king_slime_wand": {
		"name": "史莱姆王法杖", "mode": "magic", "tier": 6, "elem": "wood", "status": "devour", "status2": "slow",
		"ammo": 0, "reload": 0.0, "charge": 0.0,
		"dmg": [11.0, 11.0], "speed": [760.0, 760.0], "delay": 0.30,
		"spread": 0.0, "bullet": "element", "pierce": 0, "knock": 140.0, "homing": true,
		"col": Color(0.66, 0.94, 0.44),
		"desc": "王级法杖 · 追踪黏液 + 【吞噬】【缓速】5 秒",
	},
	"queen_slime_wand": {
		"name": "史莱姆王后法杖", "mode": "magic", "tier": 6, "elem": "arcane", "status": "confuse",
		"ammo": 0, "reload": 0.0, "charge": 0.0,
		"dmg": [12.0, 12.0], "speed": [800.0, 800.0], "delay": 0.32,
		"spread": 0.0, "bullet": "element", "pierce": 0, "knock": 150.0, "homing": true, "fan": 2,
		"col": Color(0.88, 0.64, 1.00),
		"desc": "王级法杖 · 双重追踪弹 + 【混乱】5 秒",
	},
}


static func sword(id: String) -> Dictionary:
	if SWORDS.has(id):
		return SWORDS[id]
	return SWORDS["long"]


static func gun(id: String) -> Dictionary:
	if GUNS.has(id):
		return GUNS[id]
	if MAGIC_WANDS.has(id):
		return MAGIC_WANDS[id]
	return GUNS["bow"]


static func has_gun(id: String) -> bool:
	return GUNS.has(id) or MAGIC_WANDS.has(id)


static func shield(id: String) -> Dictionary:
	if SHIELDS.has(id):
		return SHIELDS[id]
	return SHIELDS["iron"]


static func sword_name(id: String) -> String:
	return str(sword(id)["name"])


static func gun_name(id: String) -> String:
	return str(gun(id)["name"])


static func shield_name(id: String) -> String:
	return str(shield(id)["name"])


## 王级（king_ / queen_）武器只由 BOSS 掉落，不进宝箱与普通随机池
static func is_boss_only(id: String) -> bool:
	return id.begins_with("king_") or id.begins_with("queen_")


static func _normal_ids(ids: Array) -> Array:
	var out: Array = []
	for i in range(ids.size()):
		var id: String = str(ids[i])
		if is_boss_only(id):
			continue
		# 泰拉棱镜 / 错误剑为特殊获取，不进常规掉落池
		if id == "staff_prism" or id == "error_sword" or id == "armor_error":
			continue
		out.append(id)
	return out


static func random_sword() -> String:
	var pool: Array = _normal_ids(SWORD_IDS)
	return str(pool[randi() % pool.size()])


static func random_gun() -> String:
	var pool: Array = _normal_ids(GUN_IDS)
	return str(pool[randi() % pool.size()])


## 召唤类武器池（泰拉棱镜为特殊获取，不在此列）
static func summon_ids() -> Array:
	var out: Array = []
	for i in range(GUN_IDS.size()):
		var id: String = str(GUN_IDS[i])
		if id.begins_with("staff_") and id != "staff_prism":
			out.append(id)
	return out


static func random_summon() -> String:
	var pool: Array = summon_ids()
	if pool.size() == 0:
		return "bow"
	return str(pool[randi() % pool.size()])


static func is_summon(id: String) -> bool:
	if not has_gun(id):
		return false
	return str(gun(id).get("mode", "")) == "summon"


static func random_shield() -> String:
	var pool: Array = _normal_ids(SHIELD_IDS)
	return str(pool[randi() % pool.size()])
