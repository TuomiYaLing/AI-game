extends RefCounted
## 血月恶魔城 · 像素美术库
## 全部美术都是"程序化"绘制：没有外部图片资源，靠矩形/多边形拼出像素角色与场景。
## 所有坐标单位是"美术像素"(默认 2 屏幕像素)，因此天然是粗颗粒像素画风格。

const TILE := 32
const U := 2.0
const TAU := 6.283185307179586

# 瓦片类型
const AIR := 0
const ROCK := 1
const PLAT := 2
const SPIKE := 3
const DOOR := 4

# ---------------------------------------------------------------- 主题（生物群系）
static var THEMES: Array = [
	{
		"name": "亡者墓窖", "sub": "CRYPT OF THE FALLEN",
		"sky_top": Color(0.055, 0.065, 0.105), "sky_bot": Color(0.020, 0.024, 0.038),
		"stone": Color(0.16, 0.18, 0.24), "stone_dark": Color(0.075, 0.085, 0.125),
		"stone_hi": Color(0.30, 0.34, 0.44),
		"glow": Color(1.0, 0.62, 0.28), "accent": Color(0.45, 0.88, 1.0),
		"brick": Color(0.20, 0.22, 0.29), "fog": Color(0.24, 0.32, 0.46), "deco": 0, "layout": "hall",
	},
	{
		"name": "幽绿沼窟", "sub": "VERDANT MIRE",
		"sky_top": Color(0.045, 0.085, 0.075), "sky_bot": Color(0.015, 0.032, 0.028),
		"stone": Color(0.13, 0.19, 0.16), "stone_dark": Color(0.055, 0.085, 0.072),
		"stone_hi": Color(0.26, 0.36, 0.29),
		"glow": Color(0.55, 1.0, 0.45), "accent": Color(0.62, 1.0, 0.55),
		"brick": Color(0.16, 0.26, 0.22), "fog": Color(0.20, 0.36, 0.26), "deco": 1, "layout": "cave",
	},
	{
		"name": "赤月长廊", "sub": "CRIMSON GALLERY",
		"sky_top": Color(0.105, 0.045, 0.055), "sky_bot": Color(0.032, 0.014, 0.020),
		"stone": Color(0.22, 0.13, 0.15), "stone_dark": Color(0.10, 0.055, 0.065),
		"stone_hi": Color(0.38, 0.24, 0.26),
		"glow": Color(1.0, 0.40, 0.32), "accent": Color(1.0, 0.48, 0.42),
		"brick": Color(0.30, 0.16, 0.18), "fog": Color(0.40, 0.14, 0.16), "deco": 2, "layout": "snake",
	},
	{
		"name": "霜息冰窟", "sub": "FROSTBITE HOLLOW",
		"sky_top": Color(0.045, 0.070, 0.105), "sky_bot": Color(0.014, 0.022, 0.036),
		"stone": Color(0.17, 0.21, 0.28), "stone_dark": Color(0.075, 0.10, 0.14),
		"stone_hi": Color(0.36, 0.44, 0.55),
		"glow": Color(0.55, 0.85, 1.0), "accent": Color(0.72, 0.92, 1.0),
		"brick": Color(0.24, 0.28, 0.34), "fog": Color(0.26, 0.36, 0.52), "deco": 3, "layout": "tower",
	},
	{
		"name": "熔铁王座", "sub": "MOLTEN THRONE",
		"sky_top": Color(0.120, 0.050, 0.030), "sky_bot": Color(0.030, 0.012, 0.010),
		"stone": Color(0.20, 0.14, 0.12), "stone_dark": Color(0.085, 0.050, 0.045),
		"stone_hi": Color(0.42, 0.26, 0.18),
		"glow": Color(1.0, 0.48, 0.16), "accent": Color(1.0, 0.66, 0.30),
		"brick": Color(0.30, 0.20, 0.14), "fog": Color(0.42, 0.18, 0.08), "deco": 4, "layout": "hall",
	},
	{
		"name": "残响钟楼", "sub": "ECHO BELFRY",
		"sky_top": Color(0.070, 0.070, 0.095), "sky_bot": Color(0.022, 0.022, 0.034),
		"stone": Color(0.19, 0.19, 0.23), "stone_dark": Color(0.085, 0.085, 0.11),
		"stone_hi": Color(0.40, 0.40, 0.48),
		"glow": Color(0.95, 0.85, 0.45), "accent": Color(1.0, 0.92, 0.62),
		"brick": Color(0.22, 0.20, 0.26), "fog": Color(0.30, 0.30, 0.40), "deco": 5, "layout": "tower",
	},
	{
		"name": "浮空神殿", "sub": "SKYBORNE TEMPLE",
		"sky_top": Color(0.100, 0.130, 0.190), "sky_bot": Color(0.180, 0.150, 0.130),
		"stone": Color(0.30, 0.30, 0.34), "stone_dark": Color(0.14, 0.14, 0.17),
		"stone_hi": Color(0.52, 0.52, 0.58),
		"glow": Color(0.85, 0.92, 1.0), "accent": Color(1.0, 0.95, 0.80),
		"brick": Color(0.26, 0.26, 0.36), "fog": Color(0.55, 0.62, 0.75), "deco": 6, "layout": "open",
	},
	{
		"name": "荆棘圣堂", "sub": "THORN CATHEDRAL",
		"sky_top": Color(0.060, 0.085, 0.070), "sky_bot": Color(0.018, 0.028, 0.022),
		"stone": Color(0.18, 0.24, 0.19), "stone_dark": Color(0.075, 0.11, 0.085),
		"stone_hi": Color(0.34, 0.46, 0.34),
		"glow": Color(0.72, 1.0, 0.62), "accent": Color(0.95, 1.0, 0.70),
		"brick": Color(0.28, 0.24, 0.20), "fog": Color(0.22, 0.40, 0.28), "deco": 7, "layout": "hall",
	},
	{
		"name": "水晶深渊", "sub": "CRYSTAL ABYSS",
		"sky_top": Color(0.070, 0.040, 0.100), "sky_bot": Color(0.020, 0.010, 0.030),
		"stone": Color(0.20, 0.16, 0.28), "stone_dark": Color(0.080, 0.060, 0.120),
		"stone_hi": Color(0.46, 0.36, 0.62),
		"glow": Color(0.85, 0.50, 1.0), "accent": Color(0.92, 0.62, 1.0),
		"brick": Color(0.18, 0.22, 0.32), "fog": Color(0.32, 0.18, 0.46), "deco": 8, "layout": "cave",
	},
]

# ---------------------------------------------------------------- 角色调色板
static var PAL: Dictionary = {
	"player": {
		"cloth": Color(0.15, 0.17, 0.25), "cloth2": Color(0.085, 0.095, 0.14),
		"hi": Color(0.34, 0.40, 0.54), "leather": Color(0.30, 0.20, 0.14),
		"metal": Color(0.66, 0.73, 0.83), "metal_d": Color(0.30, 0.35, 0.45),
		"cape": Color(0.66, 0.14, 0.22), "cape2": Color(0.34, 0.06, 0.12),
		"flame": Color(0.42, 0.94, 1.00), "flame2": Color(0.14, 0.52, 0.85),
		"eye": Color(0.82, 1.0, 1.0), "skin": Color(0.72, 0.58, 0.45),
	},
	"slime": {
		"body": Color(0.24, 0.58, 0.28), "body_d": Color(0.10, 0.28, 0.16),
		"hi": Color(0.58, 0.92, 0.52), "core": Color(0.80, 1.00, 0.55),
		"eye": Color(0.06, 0.09, 0.08), "stain": Color(0.18, 0.40, 0.22),
	},
	"zombie": {
		"skin": Color(0.42, 0.52, 0.36), "skin_d": Color(0.24, 0.31, 0.21),
		"rag": Color(0.20, 0.18, 0.20), "rag2": Color(0.10, 0.09, 0.11),
		"bone": Color(0.70, 0.68, 0.56), "eye": Color(1.0, 0.24, 0.16),
		"blood": Color(0.46, 0.06, 0.10),
	},
	"goblin": {
		"skin": Color(0.36, 0.56, 0.24), "skin_d": Color(0.20, 0.33, 0.13),
		"cloth": Color(0.34, 0.24, 0.14), "cloth2": Color(0.19, 0.13, 0.08),
		"eye": Color(1.0, 0.86, 0.25), "metal": Color(0.62, 0.66, 0.72),
		"tooth": Color(0.90, 0.88, 0.75),
	},
}

static var _tex_cache: Dictionary = {}
static var _glow: GradientTexture2D = null
static var _vig: GradientTexture2D = null
static var _font: SystemFont = null


static func theme(index: int) -> Dictionary:
	var n: int = THEMES.size()
	var i: int = (index - 1) % n
	if i < 0:
		i += n
	return THEMES[i]


static func pal(name: String) -> Dictionary:
	return PAL[name]


# ---------------------------------------------------------------- 绘制基础工具
static func r(ci: CanvasItem, x: float, y: float, w: float, h: float, col: Color, u: float = U) -> void:
	var rx: float = roundf(x * u)
	var ry: float = roundf(y * u)
	var rw: float = roundf(w * u)
	var rh: float = roundf(h * u)
	if rw < 1.0:
		rw = 1.0
	if rh < 1.0:
		rh = 1.0
	ci.draw_rect(Rect2(rx, ry, rw, rh), col)


static func pline(ci: CanvasItem, a: Vector2, b: Vector2, thick: float, col: Color, u: float = U) -> void:
	var d: Vector2 = b - a
	var steps: int = int(ceil(maxf(absf(d.x), absf(d.y))))
	if steps < 1:
		steps = 1
	if steps > 40:
		steps = 40
	for i in range(steps + 1):
		var p: Vector2 = a.lerp(b, float(i) / float(steps))
		r(ci, p.x - thick * 0.5, p.y - thick * 0.5, thick, thick, col, u)


static func tw(c: Color, f: float) -> Color:
	return c.lerp(Color(1.0, 1.0, 1.0, 1.0), clampf(f, 0.0, 1.0) * 0.85)


static func make_font() -> SystemFont:
	if _font != null:
		return _font
	var f := SystemFont.new()
	f.font_names = PackedStringArray([
		"Microsoft YaHei UI", "Microsoft YaHei", "SimHei", "Noto Sans CJK SC",
		"Source Han Sans SC", "PingFang SC", "WenQuanYi Micro Hei", "sans-serif"
	])
	_font = f
	return f


static func glow_tex() -> GradientTexture2D:
	if _glow != null:
		return _glow
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.30, Color(1, 1, 1, 0.55))
	g.add_point(0.62, Color(1, 1, 1, 0.14))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 128
	t.height = 128
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	_glow = t
	return t


static func vignette_tex() -> GradientTexture2D:
	if _vig != null:
		return _vig
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0, 0, 0, 0.92))
	g.add_point(0.55, Color(0, 0, 0, 0.10))
	g.add_point(0.82, Color(0, 0, 0, 0.55))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 256
	t.height = 256
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	_vig = t
	return t


## 创建一个发光精灵（叠加混合），用于火把 / 角色辉光 / 传送门
static func make_glow(col: Color, radius: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = glow_tex()
	s.modulate = col
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = m
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	s.scale = Vector2(radius / 64.0, radius / 64.0)
	s.z_index = 40
	return s


# ---------------------------------------------------------------- 程序化砖块贴图
static func _kind_code(kind: String) -> int:
	match kind:
		"top":
			return 1
		"body":
			return 2
		_:
			return 3


static func stone_tex(theme_idx: int, kind: String, variant: int) -> Texture2D:
	var key: String = "%d|%s|%d" % [theme_idx, kind, variant]
	if _tex_cache.has(key):
		return _tex_cache[key]
	var th: Dictionary = theme(theme_idx)
	var base: Color = th["stone"]
	var dark: Color = th["stone_dark"]
	var hi: Color = th["stone_hi"]
	var rng := RandomNumberGenerator.new()
	rng.seed = variant * 7919 + theme_idx * 104729 + _kind_code(kind) * 17
	var img := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	var row_h: int = 16
	if kind == "wall":
		row_h = 8
	for y in range(TILE):
		for x in range(TILE):
			var n: float = rng.randf_range(-0.030, 0.030)
			var c := Color(base.r + n, base.g + n, base.b + n, 1.0)
			var by: int = y % row_h
			var row: int = int(y / row_h)
			var seam: int = (x + row * 9) % (TILE / 2)
			if by == 0:
				c = dark
			elif by == 1:
				c = Color(hi.r * 0.62, hi.g * 0.62, hi.b * 0.62, 1.0)
			if seam == 0 and by > 1:
				c = dark
			# 碎石斑点
			if rng.randf() < 0.05:
				c = dark.lerp(base, 0.35)
			img.set_pixel(x, y, c)
	if kind == "top":
		for x in range(TILE):
			var hgt: int = 2 + int(rng.randf_range(0.0, 2.4))
			for y in range(hgt):
				var f: float = float(y) / float(max(hgt, 1))
				var c2: Color = hi.lerp(base, f)
				if th["deco"] == 1:
					c2 = c2.lerp(Color(0.22, 0.42, 0.24), 0.45 * (1.0 - f))
				img.set_pixel(x, y, c2)
		# 边缘磨损
		for x in range(TILE):
			if rng.randf() < 0.10:
				img.set_pixel(x, 0, dark)
	if kind == "wall":
		for y in range(TILE):
			for x in range(3):
				var f2: float = 1.0 - float(x) / 3.0
				img.set_pixel(x, y, base.lerp(dark, 0.55 * f2))
	var tex: Texture2D = ImageTexture.create_from_image(img)
	_tex_cache[key] = tex
	return tex


# ---------------------------------------------------------------- 远景视差背景
static func draw_backdrop(ci: CanvasItem, cam: Vector2, view: Vector2, th: Dictionary, t: float) -> void:
	var o: Vector2 = cam - view * 0.5
	var sky_top: Color = th["sky_top"]
	var sky_bot: Color = th["sky_bot"]
	var glow: Color = th["glow"]
	var fogc: Color = th["fog"]

	var bands: int = 10
	for i in range(bands):
		var f: float = float(i) / float(bands)
		var c: Color = sky_top.lerp(sky_bot, f)
		ci.draw_rect(Rect2(o.x - 8.0, o.y + view.y * f - 1.0, view.x + 16.0, view.y / float(bands) + 2.0), c)

	# 血月 / 月亮
	var moon: Vector2 = o + Vector2(view.x * 0.76, view.y * 0.19)
	ci.draw_circle(moon, 78.0, Color(glow.r, glow.g, glow.b, 0.045))
	ci.draw_circle(moon, 52.0, Color(glow.r, glow.g, glow.b, 0.075))
	ci.draw_circle(moon, 30.0, Color(0.90, 0.88, 0.82, 0.22))
	ci.draw_circle(moon, 22.0, Color(0.95, 0.93, 0.86, 0.45))

	# 远景尖塔（慢速视差）
	var far_col: Color = sky_top.lerp(Color(0.09, 0.11, 0.17), 0.9)
	var far_off: float = -fposmod(cam.x * 0.16, 360.0)
	var fy: float = o.y + view.y * 0.74
	for k in range(-1, 5):
		var bx: float = o.x + far_off + float(k) * 360.0
		_tower(ci, bx + 10.0, fy, 52.0, 250.0, far_col, th)
		_tower(ci, bx + 138.0, fy, 34.0, 168.0, far_col.darkened(0.18), th)
		_tower(ci, bx + 236.0, fy, 44.0, 210.0, far_col.darkened(0.08), th)

	# 中景拱廊
	var mid_col: Color = sky_top.lerp(Color(0.055, 0.065, 0.10), 0.72)
	var mid_off: float = -fposmod(cam.x * 0.40, 440.0)
	var my: float = o.y + view.y * 0.92
	for k in range(-1, 4):
		var bx2: float = o.x + mid_off + float(k) * 440.0
		_arcade(ci, bx2, my, mid_col, th)

	# 星辰（远景，闪烁）
	var star_col: Color = glow.lerp(Color(1, 1, 1), 0.55)
	for i in range(46):
		var sd: float = float(i) * 1.618
		var sx2: float = o.x + fposmod(sd * 197.0 - cam.x * 0.05, view.x + 40.0) - 20.0
		var sy2: float = o.y + fposmod(sd * 113.0, view.y * 0.55)
		var tw: float = 0.35 + 0.65 * absf(sin(t * (0.6 + fposmod(sd, 1.4)) + sd))
		var ss: float = 1.1 + fposmod(sd * 0.7, 1.6)
		ci.draw_rect(Rect2(sx2, sy2, ss, ss), Color(star_col.r, star_col.g, star_col.b, 0.42 * tw))

	# 月华光束（斜向光柱）
	for i in range(3):
		var rl: float = sin(t * 0.10 + float(i) * 2.1) * 0.5 + 0.5
		var rw2: float = 26.0 + float(i) * 20.0
		var rx: float = moon.x - 60.0 + float(i) * 44.0
		ci.draw_colored_polygon(PackedVector2Array([
			Vector2(rx, moon.y),
			Vector2(rx + rw2, moon.y),
			Vector2(rx + rw2 + 150.0 + rl * 40.0, o.y + view.y),
			Vector2(rx + 90.0 + rl * 40.0, o.y + view.y),
		]), Color(glow.r, glow.g, glow.b, 0.016 + 0.010 * rl))

	# 近景剪影（最快的视差层）
	var near_col: Color = sky_top.lerp(Color(0.02, 0.02, 0.03), 0.92)
	var near_off: float = -fposmod(cam.x * 0.72, 520.0)
	var ny: float = o.y + view.y * 1.02
	for k in range(-1, 3):
		var nx: float = o.x + near_off + float(k) * 520.0
		ci.draw_rect(Rect2(nx, ny - 300.0, 46.0, 300.0), near_col)
		ci.draw_rect(Rect2(nx - 8.0, ny - 316.0, 62.0, 16.0), near_col)
		ci.draw_rect(Rect2(nx + 300.0, ny - 210.0, 30.0, 210.0), near_col)

	# 雾带
	for i in range(3):
		var yy: float = o.y + view.y * (0.48 + 0.20 * float(i)) + sin(t * 0.22 + float(i) * 1.7) * 10.0
		var a: float = 0.045 + 0.018 * sin(t * 0.35 + float(i))
		ci.draw_rect(Rect2(o.x - 8.0, yy, view.x + 16.0, view.y * 0.26), Color(fogc.r, fogc.g, fogc.b, a))

	# 顶部光柱
	var shaft_x: float = o.x + view.x * 0.30 + sin(t * 0.12) * 24.0
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(shaft_x, o.y),
		Vector2(shaft_x + 120.0, o.y),
		Vector2(shaft_x + 260.0, o.y + view.y),
		Vector2(shaft_x + 40.0, o.y + view.y),
	]), Color(glow.r, glow.g, glow.b, 0.022))


static func _tower(ci: CanvasItem, x: float, base_y: float, w: float, h: float, col: Color, th: Dictionary) -> void:
	ci.draw_rect(Rect2(x, base_y - h, w, h), col)
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(x - 7.0, base_y - h),
		Vector2(x + w * 0.5, base_y - h - w * 1.25),
		Vector2(x + w + 7.0, base_y - h),
	]), col.darkened(0.10))
	var glow: Color = th["glow"]
	var rows: int = int(h / 52.0)
	for i in range(rows):
		var wy: float = base_y - h + 34.0 + float(i) * 52.0
		if wy > base_y - 16.0:
			break
		ci.draw_rect(Rect2(x + w * 0.5 - 3.0, wy, 6.0, 11.0), Color(glow.r, glow.g, glow.b, 0.10))
		ci.draw_rect(Rect2(x + w * 0.5 - 1.0, wy + 2.0, 2.0, 6.0), Color(glow.r, glow.g, glow.b, 0.16))


static func _arcade(ci: CanvasItem, x: float, base_y: float, col: Color, th: Dictionary) -> void:
	var pw: float = 34.0
	var h: float = 380.0
	for k in range(3):
		var px: float = x + float(k) * 148.0
		ci.draw_rect(Rect2(px, base_y - h, pw, h), col)
		ci.draw_rect(Rect2(px - 7.0, base_y - h - 16.0, pw + 14.0, 16.0), col.darkened(0.20))
		ci.draw_rect(Rect2(px - 7.0, base_y - h + 120.0, pw + 14.0, 8.0), col.darkened(0.12))
	ci.draw_circle(Vector2(x + 74.0, base_y - h + 26.0), 84.0, col.darkened(0.06))
	ci.draw_circle(Vector2(x + 74.0, base_y - h + 26.0), 70.0, col.darkened(0.28))


# ---------------------------------------------------------------- 玩家
static func draw_player(ci: CanvasItem, a: Dictionary) -> void:
	var P: Dictionary = PAL["player"]
	var cloth: Color = P["cloth"]
	var cloth2: Color = P["cloth2"]
	var hi: Color = P["hi"]
	var metal: Color = P["metal"]
	var leather: Color = P["leather"]
	var cape: Color = P["cape"]
	var cape2: Color = P["cape2"]
	var flame: Color = P["flame"]

	var face: float = a.get("face", 1.0)
	if face >= 0.0:
		face = 1.0
	else:
		face = -1.0
	var st: String = a.get("state", "idle")
	var t: float = a.get("t", 0.0)
	var ph: float = a.get("run", 0.0)
	var cr: float = clampf(a.get("crouch", 0.0), 0.0, 1.0)
	var flash: float = clampf(a.get("flash", 0.0), 0.0, 1.0)
	var aim: float = a.get("aim", 0.0)
	var atk: float = a.get("atk", -1.0)
	var roll: float = a.get("roll", 0.0)
	var guard: float = a.get("guard", 0.0)
	var bowd: float = a.get("bow", 0.0)
	var charge: float = a.get("charge", 0.0)
	var gund: float = a.get("gun", 0.0)
	var muzzle: float = clampf(a.get("muzzle", 0.0), 0.0, 1.0)
	var blade_col: Color = metal
	if a.has("sword_col"):
		blade_col = a["sword_col"]
	var wings: int = int(a.get("wings", 0))

	if st == "dead":
		_draw_player_dead(ci, face, cloth, cloth2, leather, cape2)
		return
	if st == "roll":
		_draw_player_roll(ci, face, roll, cloth, cloth2, cape, cape2, leather, metal)
		return

	# ---- 姿态参数
	var bob: float = 0.0
	var lean: float = 0.0
	var lfx: float = 2.2
	var rfx: float = -2.2
	var lfy: float = 0.0
	var rfy: float = 0.0
	if st == "run":
		var s: float = sin(ph * TAU)
		lfx = 2.8 * s
		rfx = -2.8 * s
		lfy = maxf(0.0, s) * 1.9
		rfy = maxf(0.0, -s) * 1.9
		bob = -absf(sin(ph * TAU * 2.0)) * 0.7
		lean = 1.1
	elif st == "jump":
		lfx = 2.2
		rfx = -1.4
		lfy = 2.2
		rfy = 1.0
		lean = 0.7
	elif st == "fall":
		lfx = 2.4
		rfx = -2.4
		lfy = 0.7
		rfy = 0.3
		lean = -0.6
	elif st == "hurt":
		lean = -2.6

	if cr > 0.01:
		lfx += 1.8 * cr
		rfx -= 1.8 * cr

	var hip: float = -9.0 + bob + cr * 3.4
	var sh: float = -18.0 + bob + cr * 4.6
	var hd: float = -22.4 + bob + cr * 5.0
	var bw: float = 6.0 - cr * 0.5
	var body_x: float = lean * 0.45

	# ---- 翅膀（最靠后）
	if wings > 0:
		_draw_wings(ci, wings, t, face, body_x, sh, ph)

	# ---- 披风（在身后）
	var sway: float = sin(t * 2.5) * 0.5 + sin(ph * TAU) * 0.9
	for i in range(5):
		var f: float = float(i) / 4.0
		var cy: float = sh + f * (7.0 + (-hip) * 0.15)
		var back: float = -face * (2.4 + f * 1.9 + sway * (0.35 + f * 0.9))
		var cw: float = 4.6 - f * 1.5
		r(ci, body_x + back - cw * 0.5, cy, cw, 2.3, cape2.lerp(cape, 0.85 - f * 0.5))

	# ---- 后手
	pline(ci, Vector2(body_x - face * 2.0, sh + 1.8), Vector2(body_x - face * 3.3, sh + 6.2), 1.7, cloth2)

	# ---- 腿
	pline(ci, Vector2(body_x - 1.2, hip), Vector2(rfx, -rfy), 1.9, cloth2)
	pline(ci, Vector2(body_x + 1.2, hip), Vector2(lfx, -lfy), 1.9, cloth2)
	r(ci, rfx - 1.4, -rfy - 1.9, 2.9, 1.9, leather)
	r(ci, lfx - 1.4, -lfy - 1.9, 2.9, 1.9, leather)

	# ---- 躯干
	r(ci, body_x - bw * 0.5, sh, bw, hip - sh + 1.2, cloth)
	r(ci, body_x - bw * 0.5, sh, bw, 1.3, hi)
	r(ci, body_x - bw * 0.5, sh + 1.3, 1.1, hip - sh - 1.0, cloth2)
	r(ci, body_x - bw * 0.5, hip - 1.7, bw, 1.3, leather)
	r(ci, body_x - 0.9, sh + 4.6, 1.8, 1.8, P["flame2"])

	# ---- 前臂 / 武器
	var hand := Vector2(body_x + face * 3.0, sh + 4.2)
	if atk >= 0.0:
		var sweep: float = lerpf(-1.35, 1.15, clampf(atk, 0.0, 1.0))
		var ang: float = aim + sweep * face
		var blade: float = 9.4
		var tip: Vector2 = hand + Vector2(cos(ang), sin(ang)) * blade
		pline(ci, Vector2(body_x + face * 1.6, sh + 1.8), hand, 1.7, cloth)
		r(ci, hand.x - 1.1, hand.y - 0.7, 2.2, 1.4, leather)
		pline(ci, hand, tip, 1.3, blade_col)
		pline(ci, hand.lerp(tip, 0.6), tip, 0.8, Color(1, 1, 1, 0.55))
	elif gund > 0.0:
		# 枪械
		var gdir := Vector2(cos(aim), sin(aim))
		var gperp := Vector2(-gdir.y, gdir.x)
		var gx: Vector2 = hand + gdir * 2.0
		pline(ci, Vector2(body_x + face * 1.6, sh + 1.8), hand, 1.7, cloth)
		for i in range(4):
			var gp: Vector2 = gx + gdir * (float(i) * 3.2)
			r(ci, gp.x - 1.7, gp.y - 1.7, 3.4, 3.4, P["metal_d"])
		r(ci, gx.x - 2.4, gx.y - 2.4, 4.8, 4.8, metal)
		var magp: Vector2 = gx + gperp * 2.8 + gdir * 2.0
		r(ci, magp.x - 1.3, magp.y - 1.3, 2.6, 4.2, leather)
		if muzzle > 0.05:
			var tipm: Vector2 = gx + gdir * 15.0
			r(ci, tipm.x - 2.6, tipm.y - 2.6, 5.2, 5.2, Color(1.0, 0.82, 0.38, muzzle * 0.85))
			r(ci, tipm.x - 1.2, tipm.y - 1.2, 2.4, 2.4, Color(1.0, 1.0, 0.86, muzzle))
	elif bowd > 0.0:
		var ang2: float = aim
		var dirv := Vector2(cos(ang2), sin(ang2))
		var perpv := Vector2(-dirv.y, dirv.x)
		var bc: Vector2 = hand + dirv * 1.6
		pline(ci, Vector2(body_x + face * 1.6, sh + 1.8), hand, 1.7, cloth)
		# 弓身
		var seg: int = 5
		var prev: Vector2 = bc - perpv * 4.2
		for i in range(1, seg + 1):
			var f2: float = float(i) / float(seg)
			var p2: Vector2 = bc - perpv * 4.2 + perpv * 8.4 * f2 + dirv * sin(f2 * PI) * 1.4
			pline(ci, prev, p2, 1.0, leather)
			prev = p2
		# 弓弦
		var top: Vector2 = bc - perpv * 4.2
		var bot: Vector2 = bc + perpv * 4.2
		var pull: float = 1.6 + charge * 2.6
		var mid: Vector2 = bc - dirv * pull
		pline(ci, top, mid, 0.6, Color(0.85, 0.85, 0.90, 0.75))
		pline(ci, mid, bot, 0.6, Color(0.85, 0.85, 0.90, 0.75))
		if charge > 0.05:
			pline(ci, mid, mid + dirv * 5.0, 0.7, Color(0.95, 0.95, 0.85, 0.9))
	elif guard > 0.0:
		pline(ci, Vector2(body_x + face * 1.6, sh + 1.8), hand, 1.7, cloth)
		var sx: float = body_x + face * 3.4
		r(ci, sx - 1.6, sh + 0.6, 3.6, 9.0, P["metal_d"])
		r(ci, sx - 0.9, sh + 1.2, 2.4, 7.8, metal)
		r(ci, sx - 0.3, sh + 3.6, 1.4, 2.6, P["flame2"])
	else:
		pline(ci, Vector2(body_x + face * 1.6, sh + 1.8), hand, 1.7, cloth)
		# 收剑：斜挂身侧
		pline(ci, hand, hand + Vector2(face * 2.0, 8.4), 1.2, blade_col)
		r(ci, hand.x - 1.0, hand.y - 0.6, 2.0, 1.6, leather)

	# ---- 兜帽 / 头部
	var hx: float = body_x + lean * 0.6
	r(ci, hx - 3.0, hd - 3.4, 6.0, 6.8, cloth2)
	r(ci, hx - 2.6, hd - 4.2, 5.2, 1.4, cloth2)
	r(ci, hx - 3.0, hd - 3.4, 6.0, 0.8, hi)
	r(ci, hx - 2.0, hd - 1.5, 4.0, 3.7, Color(0.015, 0.015, 0.03))
	# 发光眼睛
	if st != "dead":
		var eg: float = 0.75 + 0.25 * sin(t * 8.0)
		var col_eye := Color(P["flame"].r, P["flame"].g, P["flame"].b, eg)
		r(ci, hx - 1.7, hd - 0.9, 1.1, 1.1, col_eye)
		r(ci, hx + 0.6, hd - 0.9, 1.1, 1.1, col_eye)
	# 头顶火焰
	var fl: float = sin(t * 13.0) * 0.6 + sin(t * 7.7) * 0.4
	r(ci, hx - 1.1 + fl * 0.5, hd - 6.6, 2.2, 2.6, flame)
	r(ci, hx - 0.4 - fl * 0.7, hd - 8.6, 1.2, 2.2, Color(0.80, 1.0, 1.0, 0.95))

	# ---- 受击闪白
	if flash > 0.04:
		var fc := Color(1, 1, 1, 0.45 * flash)
		r(ci, hx - 3.0, hd - 4.2, 6.0, 7.6, fc)
		r(ci, body_x - bw * 0.5, sh, bw, hip - sh + 1.2, fc)
		r(ci, -3.2, hip, 6.4, -hip, fc)


static func _draw_player_roll(ci: CanvasItem, face: float, roll: float, cloth: Color, cloth2: Color, cape: Color, cape2: Color, leather: Color, metal: Color) -> void:
	var spin: float = roll * TAU * 1.7 * face
	var cy: float = -6.0
	# 拖尾披风
	for i in range(3):
		var f: float = float(i) / 2.0
		r(ci, -face * (4.0 + f * 3.5), cy - 2.0 + f * 2.0, 3.2 - f * 0.8, 3.0, cape2.lerp(cape, 0.6 - f * 0.4))
	# 团身
	for i in range(7):
		var ang: float = spin + float(i) * TAU / 7.0
		var p: Vector2 = Vector2(0, cy) + Vector2(cos(ang), sin(ang)) * 2.1
		r(ci, p.x - 2.3, p.y - 2.3, 4.6, 4.6, cloth)
	r(ci, -2.2, cy - 2.2, 4.4, 4.4, cloth2)
	r(ci, -1.2, cy - 1.0, 2.4, 2.0, Color(0.55, 0.95, 1.0, 0.85))
	r(ci, -3.0, -2.2, 6.0, 2.2, leather)


static func _draw_player_dead(ci: CanvasItem, face: float, cloth: Color, cloth2: Color, leather: Color, cape2: Color) -> void:
	r(ci, -7.0, -3.4, 13.0, 3.4, cloth)
	r(ci, -7.0, -3.4, 13.0, 1.0, cloth2)
	r(ci, -9.6, -4.6, 3.6, 3.4, cloth2)
	r(ci, -15.0 * face, -2.4, 6.0, 2.4, cape2)
	r(ci, 6.0 * face - 1.0, -1.6, 3.0, 1.6, leather)


# ---------------------------------------------------------------- 翅膀
## kind: 1 = 天使之翼（羽翼，暖白），2 = 恶魔之翼（蝠翼，暗红）
static func _draw_wings(ci: CanvasItem, kind: int, t: float, face: float, bx: float, sy: float, ph: float) -> void:
	var flap: float = sin(t * 4.2 + ph * 2.0) * 0.5 + 0.5
	var spread: float = 7.0 + flap * 5.5
	var root := Vector2(bx - face * 1.0, sy + 2.0)
	if kind == 1:
		var feather: Color = Color(0.98, 0.97, 0.90)
		var feather2: Color = Color(0.88, 0.90, 0.98)
		var glowc: Color = Color(1.0, 0.96, 0.72, 0.22)
		ci.draw_circle(root + Vector2(-face * 6.0, -3.0), spread * 0.9, glowc)
		for s in range(2):
			var dirn: float = -1.0 if s == 0 else 1.0
			var base_x: float = root.x + dirn * 2.0
			# 三层羽毛
			for k in range(3):
				var len_k: float = spread * (1.0 - float(k) * 0.26)
				var tip := Vector2(base_x + dirn * len_k * 0.85, root.y - 2.0 - len_k * 0.55 + float(k) * 2.6)
				var b0 := Vector2(base_x, root.y + float(k) * 2.4)
				var b1 := Vector2(base_x + dirn * 1.6, root.y + 3.4 + float(k) * 2.2)
				ci.draw_colored_polygon(PackedVector2Array([b0, tip, b1]), feather if k != 1 else feather2)
				ci.draw_line(b0, tip, Color(0.72, 0.74, 0.82, 0.55), 0.7)
	else:
		var skin: Color = Color(0.52, 0.10, 0.16)
		var skin2: Color = Color(0.78, 0.20, 0.26)
		var bone: Color = Color(0.86, 0.70, 0.66)
		var glowc2: Color = Color(0.95, 0.25, 0.30, 0.20)
		ci.draw_circle(root + Vector2(-face * 6.0, -3.0), spread * 0.95, glowc2)
		for s in range(2):
			var dirn2: float = -1.0 if s == 0 else 1.0
			var bx2: float = root.x + dirn2 * 1.5
			# 蝠翼：两根指骨 + 三层膜
			var tipA := Vector2(bx2 + dirn2 * spread * 0.95, root.y - 8.0 - flap * 2.5)
			var tipB := Vector2(bx2 + dirn2 * spread * 0.70, root.y + 3.0)
			var tipC := Vector2(bx2 + dirn2 * spread * 0.40, root.y + 9.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(bx2, root.y), tipA, tipB]), skin)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(bx2, root.y + 1.0), tipB, tipC]), skin2)
			ci.draw_line(Vector2(bx2, root.y), tipA, bone, 0.9)
			ci.draw_line(Vector2(bx2, root.y + 1.0), tipC, bone, 0.8)

# ---------------------------------------------------------------- 飞龙 / 海龙
## fire=true 为赤色飞龙，false 为蓝色海龙
static func draw_drake(ci: CanvasItem, a: Dictionary, fire: bool) -> void:
	var t: float = a.get("t", 0.0)
	var face: float = a.get("face", 1.0)
	var flash: float = clampf(a.get("flash", 0.0), 0.0, 1.0)
	var sk: float = a.get("scale", 1.0)
	var skin: Color = Color(0.72, 0.28, 0.20) if fire else Color(0.24, 0.52, 0.80)
	var skin2: Color = Color(0.46, 0.14, 0.12) if fire else Color(0.12, 0.30, 0.52)
	var belly: Color = Color(1.0, 0.76, 0.42) if fire else Color(0.62, 0.90, 1.0)
	var wing: Color = Color(0.86, 0.42, 0.22, 0.88) if fire else Color(0.42, 0.72, 0.95, 0.88)
	var flap: float = sin(t * 5.0) * 0.5 + 0.5
	var gy: float = -18.0 * sk
	# 尾巴
	ci.draw_line(Vector2(-10.0 * sk * face, gy), Vector2(-30.0 * sk * face, gy + 6.0 * sk + flap * 4.0), skin2, 3.0 * sk)
	# 翅膀（后）
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(-2.0 * sk, gy - 2.0 * sk),
		Vector2(-26.0 * sk * face, gy - 20.0 * sk - flap * 6.0),
		Vector2(-20.0 * sk * face, gy + 4.0 * sk),
	]), wing)
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(2.0 * sk, gy - 2.0 * sk),
		Vector2(22.0 * sk * face, gy - 22.0 * sk - flap * 6.0),
		Vector2(18.0 * sk * face, gy + 3.0 * sk),
	]), wing.darkened(0.12))
	# 身体
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(-14.0 * sk * face, gy),
		Vector2(10.0 * sk * face, gy - 6.0 * sk),
		Vector2(16.0 * sk * face, gy + 4.0 * sk),
		Vector2(-8.0 * sk * face, gy + 7.0 * sk),
	]), skin)
	# 腹部
	ci.draw_rect(Rect2(-6.0 * sk * face if face > 0.0 else -12.0 * sk, gy - 1.0 * sk, 14.0 * sk, 5.0 * sk), belly)
	# 头 + 角
	var hx: float = 18.0 * sk * face
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(hx, gy - 4.0 * sk),
		Vector2(hx + 14.0 * sk * face, gy - 1.0 * sk),
		Vector2(hx + 13.0 * sk * face, gy + 5.0 * sk),
		Vector2(hx, gy + 5.0 * sk),
	]), skin)
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(hx + 4.0 * sk * face, gy - 4.0 * sk),
		Vector2(hx + 1.0 * sk * face, gy - 12.0 * sk),
		Vector2(hx + 8.0 * sk * face, gy - 5.0 * sk),
	]), skin2)
	# 眼睛（发光）
	ci.draw_circle(Vector2(hx + 8.0 * sk * face, gy), 2.2 * sk, Color(1.0, 0.86, 0.35) if fire else Color(0.55, 1.0, 1.0))
	# 腿
	ci.draw_line(Vector2(-4.0 * sk, gy + 7.0 * sk), Vector2(-6.0 * sk, gy + 18.0 * sk), skin2, 2.4 * sk)
	ci.draw_line(Vector2(8.0 * sk * face, gy + 6.0 * sk), Vector2(10.0 * sk * face, gy + 17.0 * sk), skin2, 2.4 * sk)
	if flash > 0.04:
		ci.draw_rect(Rect2(-30.0 * sk, gy - 26.0 * sk, 60.0 * sk, 48.0 * sk), Color(1, 1, 1, 0.35 * flash))


# ---------------------------------------------------------------- 飞龙王（王级专属模型）
static func draw_drake_king(ci: CanvasItem, a: Dictionary) -> void:
	var t: float = a.get("t", 0.0)
	var face: float = a.get("face", 1.0)
	var flash: float = clampf(a.get("flash", 0.0), 0.0, 1.0)
	var flap: float = sin(t * 3.4) * 0.5 + 0.5
	var body: Color = Color(0.62, 0.16, 0.14)
	var body_d: Color = Color(0.34, 0.08, 0.08)
	var belly: Color = Color(1.0, 0.74, 0.36)
	var wing: Color = Color(0.86, 0.32, 0.16, 0.9)
	var glow: Color = Color(1.0, 0.55, 0.20, 0.16)
	var gy: float = -40.0
	# 火焰气场
	ci.draw_circle(Vector2(0, gy), 74.0, glow)
	ci.draw_circle(Vector2(0, gy), 52.0, Color(1.0, 0.70, 0.30, 0.10))
	# 巨大双翼（先画，在身后）
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(-6.0 * face, gy - 6.0),
		Vector2(-84.0 * face, gy - 52.0 - flap * 16.0),
		Vector2(-62.0 * face, gy + 6.0),
		Vector2(-30.0 * face, gy + 22.0),
	]), wing)
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(6.0 * face, gy - 6.0),
		Vector2(78.0 * face, gy - 56.0 - flap * 16.0),
		Vector2(58.0 * face, gy + 4.0),
		Vector2(26.0 * face, gy + 20.0),
	]), wing.darkened(0.12))
	# 翼骨
	ci.draw_line(Vector2(-6.0 * face, gy - 6.0), Vector2(-80.0 * face, gy - 52.0 - flap * 16.0), body_d, 3.0)
	ci.draw_line(Vector2(6.0 * face, gy - 6.0), Vector2(74.0 * face, gy - 56.0 - flap * 16.0), body_d, 3.0)
	# 尾巴
	for k in range(5):
		var f2: float = float(k) / 5.0
		ci.draw_circle(Vector2(-34.0 * face - f2 * 44.0 * face, gy + 14.0 + f2 * 16.0 + sin(t * 3.0 + f2 * 3.0) * 4.0), 9.0 - f2 * 5.0, body)
	# 躯干
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(-44.0 * face, gy + 6.0),
		Vector2(-14.0 * face, gy - 18.0),
		Vector2(28.0 * face, gy - 16.0),
		Vector2(44.0 * face, gy + 10.0),
		Vector2(-20.0 * face, gy + 26.0),
	]), body)
	# 腹甲
	ci.draw_rect(Rect2(-18.0 * face if face > 0.0 else -30.0, gy + 2.0, 44.0, 14.0), belly)
	for k in range(4):
		ci.draw_rect(Rect2((-12.0 + float(k) * 10.0) * face if face > 0.0 else (-26.0 + float(k) * 10.0) * face, gy + 2.0, 6.0, 14.0), Color(0.86, 0.58, 0.28))
	# 背刺
	for k in range(5):
		var sx3: float = -30.0 + float(k) * 15.0
		ci.draw_colored_polygon(PackedVector2Array([
			Vector2(sx3 * face, gy - 12.0), Vector2((sx3 + 5.0) * face, gy - 28.0), Vector2((sx3 + 10.0) * face, gy - 12.0),
		]), Color(1.0, 0.62, 0.26))
	# 头
	var hx: float = 46.0 * face
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(hx, gy - 18.0),
		Vector2(hx + 34.0 * face, gy - 8.0),
		Vector2(hx + 36.0 * face, gy + 8.0),
		Vector2(hx + 6.0 * face, gy + 12.0),
	]), body)
	# 下颚
	ci.draw_rect(Rect2(hx + 8.0 * face if face > 0.0 else hx + 8.0 * face, gy + 8.0, 26.0, 6.0), body_d)
	# 双角
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(hx + 4.0 * face, gy - 18.0), Vector2(hx - 10.0 * face, gy - 46.0), Vector2(hx + 14.0 * face, gy - 20.0),
	]), Color(1.0, 0.86, 0.62))
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(hx + 22.0 * face, gy - 14.0), Vector2(hx + 16.0 * face, gy - 38.0), Vector2(hx + 30.0 * face, gy - 12.0),
	]), Color(1.0, 0.86, 0.62))
	# 眼
	ci.draw_circle(Vector2(hx + 18.0 * face, gy - 6.0), 4.6, Color(1.0, 0.90, 0.40))
	ci.draw_circle(Vector2(hx + 18.0 * face, gy - 6.0), 2.0, Color(0.15, 0.05, 0.05))
	# 王冠
	var cy3: float = gy - 30.0
	ci.draw_rect(Rect2(-14.0 * face if face > 0.0 else -14.0, cy3, 30.0, 6.0), Color(1.0, 0.84, 0.32))
	for k in range(3):
		var kx3: float = (-10.0 + float(k) * 11.0)
		ci.draw_colored_polygon(PackedVector2Array([
			Vector2(kx3, cy3), Vector2(kx3 + 5.0, cy3 - 13.0), Vector2(kx3 + 10.0, cy3),
		]), Color(1.0, 0.92, 0.52))
	# 利爪
	ci.draw_line(Vector2(-16.0 * face, gy + 24.0), Vector2(-20.0 * face, gy + 44.0), body_d, 5.0)
	ci.draw_line(Vector2(18.0 * face, gy + 24.0), Vector2(22.0 * face, gy + 44.0), body_d, 5.0)
	if flash > 0.04:
		ci.draw_rect(Rect2(-90.0, gy - 70.0, 180.0, 120.0), Color(1, 1, 1, 0.35 * flash))


# ---------------------------------------------------------------- 海龙（地面蛇形）
static func draw_seadragon(ci: CanvasItem, a: Dictionary, is_king: bool) -> void:
	var t: float = a.get("t", 0.0)
	var face: float = a.get("face", 1.0)
	var ph: float = a.get("run", 0.0)
	var flash: float = clampf(a.get("flash", 0.0), 0.0, 1.0)
	var skin: Color = Color(0.22, 0.50, 0.78)
	var skin_d: Color = Color(0.12, 0.28, 0.50)
	var fin: Color = Color(0.55, 0.92, 1.0)
	var belly: Color = Color(0.72, 0.94, 1.0)
	# 蛇形躯干（贴地爬行）
	var segs: int = 7 if is_king else 5
	for k in range(segs):
		var f: float = float(k) / float(segs)
		var sx4: float = (18.0 - f * 52.0) * face
		var sy4: float = -8.0 - sin(ph * TAU * 2.0 + f * 3.4) * 2.4 - f * 2.0
		var rr: float = (13.0 - f * 6.0) * (1.35 if is_king else 1.0)
		ci.draw_circle(Vector2(sx4, sy4), rr, skin if k % 2 == 0 else skin_d.lerp(skin, 0.45))
	# 背鳍
	for k in range(segs - 1):
		var f2: float = float(k) / float(segs)
		var sx5: float = (18.0 - f2 * 52.0) * face
		var sy5: float = -20.0 - sin(ph * TAU * 2.0 + f2 * 3.4) * 2.4
		ci.draw_colored_polygon(PackedVector2Array([
			Vector2(sx5 - 5.0, sy5 + 6.0), Vector2(sx5, sy5 - 10.0), Vector2(sx5 + 5.0, sy5 + 6.0),
		]), Color(fin.r, fin.g, fin.b, 0.85))
	# 头
	var hx: float = 30.0 * face
	var hk: float = 1.35 if is_king else 1.0
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(hx - 10.0 * hk * face, -4.0 * hk),
		Vector2(hx + 18.0 * hk * face, -14.0 * hk),
		Vector2(hx + 24.0 * hk * face, 2.0 * hk),
		Vector2(hx + 2.0 * hk * face, 8.0 * hk),
	]), skin)
	# 下颚 / 牙
	ci.draw_rect(Rect2(hx + 2.0 * hk * face if face > 0.0 else hx - 18.0 * hk, 2.0 * hk, 20.0 * hk, 5.0 * hk), skin_d)
	for k in range(4):
		ci.draw_colored_polygon(PackedVector2Array([
			Vector2((hx + 4.0 * hk + float(k) * 5.0 * hk) * face, 2.0 * hk),
			Vector2((hx + 6.0 * hk + float(k) * 5.0 * hk) * face, 7.0 * hk),
			Vector2((hx + 8.0 * hk + float(k) * 5.0 * hk) * face, 2.0 * hk),
		]), Color(0.95, 0.98, 1.0))
	# 头鳍
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(hx, -12.0 * hk), Vector2(hx - 16.0 * hk * face, -30.0 * hk), Vector2(hx + 6.0 * hk * face, -14.0 * hk),
	]), Color(fin.r, fin.g, fin.b, 0.75))
	# 眼
	ci.draw_circle(Vector2(hx + 10.0 * hk * face, -6.0 * hk), 3.4 * hk, Color(1.0, 0.95, 0.55))
	ci.draw_circle(Vector2(hx + 10.0 * hk * face, -6.0 * hk), 1.6 * hk, Color(0.08, 0.10, 0.16))
	# 腹甲
	ci.draw_rect(Rect2(-6.0, -4.0, 26.0, 6.0), belly)
	if is_king:
		# 王冠
		ci.draw_rect(Rect2(hx - 6.0 * hk, -22.0 * hk, 26.0 * hk, 5.0 * hk), Color(0.92, 0.96, 1.0))
		for k in range(3):
			var kx4: float = hx - 4.0 * hk + float(k) * 9.0 * hk
			ci.draw_colored_polygon(PackedVector2Array([
				Vector2(kx4, -22.0 * hk), Vector2(kx4 + 4.0 * hk, -32.0 * hk), Vector2(kx4 + 8.0 * hk, -22.0 * hk),
			]), Color(0.95, 0.99, 1.0))
	if flash > 0.04:
		ci.draw_rect(Rect2(-50.0, -40.0, 100.0, 54.0), Color(1, 1, 1, 0.4 * flash))

# ---------------------------------------------------------------- 骷髅
static func draw_skeleton(ci: CanvasItem, a: Dictionary) -> void:
	var t: float = a.get("t", 0.0)
	var face: float = a.get("face", 1.0)
	var ph: float = a.get("run", 0.0)
	var flash: float = clampf(a.get("flash", 0.0), 0.0, 1.0)
	var bone: Color = Color(0.90, 0.88, 0.78)
	var bone_d: Color = Color(0.60, 0.58, 0.50)
	var sw: float = sin(ph * TAU) * 3.0
	# 腿
	r(ci, -4.0 + sw * 0.4, -14.0, 3.0, 14.0, bone_d)
	r(ci, 1.0 - sw * 0.4, -14.0, 3.0, 14.0, bone_d)
	# 骨盆 / 脊椎
	r(ci, -5.0, -20.0, 10.0, 7.0, bone)
	r(ci, -1.2, -34.0, 2.4, 15.0, bone_d)
	# 肋骨
	for k in range(4):
		r(ci, -6.0, -33.0 + float(k) * 3.4, 12.0, 2.0, bone if k % 2 == 0 else bone_d)
	# 肩 / 手臂
	r(ci, -9.0, -36.0, 18.0, 3.0, bone)
	r(ci, -11.0 * face, -35.0, 3.0, 13.0, bone_d)
	# 头骨
	r(ci, -6.0, -47.0, 12.0, 11.0, bone)
	r(ci, -4.5, -51.0, 9.0, 4.0, bone)
	# 眼窝（发光）
	ci.draw_circle(Vector2(-3.0, -43.0), 2.0, Color(0.35, 0.95, 1.0))
	ci.draw_circle(Vector2(3.0, -43.0), 2.0, Color(0.35, 0.95, 1.0))
	ci.draw_circle(Vector2(-3.0, -43.0), 3.4, Color(0.35, 0.95, 1.0, 0.22))
	ci.draw_circle(Vector2(3.0, -43.0), 3.4, Color(0.35, 0.95, 1.0, 0.22))
	# 牙齿
	for k in range(4):
		r(ci, -4.0 + float(k) * 2.2, -38.5, 1.4, 2.0, bone_d)
	if flash > 0.04:
		r(ci, -12.0, -52.0, 24.0, 40.0, Color(1, 1, 1, 0.45 * flash))


# ---------------------------------------------------------------- 腐肉怪
static func draw_flesh(ci: CanvasItem, a: Dictionary) -> void:
	var t: float = a.get("t", 0.0)
	var ph: float = a.get("run", 0.0)
	var flash: float = clampf(a.get("flash", 0.0), 0.0, 1.0)
	var flesh: Color = Color(0.62, 0.26, 0.26)
	var flesh_d: Color = Color(0.38, 0.14, 0.16)
	var pus: Color = Color(0.86, 0.82, 0.42)
	var squish: float = sin(t * 3.0 + ph * 4.0) * 1.6
	# 身体（巨大的肉块）
	r(ci, -15.0 - squish * 0.5, -34.0, 30.0 + squish, 34.0, flesh)
	r(ci, -12.0, -38.0, 24.0, 6.0, flesh)
	r(ci, -15.0, -8.0, 7.0, 8.0, flesh_d)
	r(ci, 8.0, -8.0, 7.0, 8.0, flesh_d)
	# 缝合线
	for k in range(3):
		r(ci, -10.0 + float(k) * 8.0, -30.0, 1.6, 22.0, flesh_d)
	for k in range(4):
		r(ci, -9.0, -30.0 + float(k) * 6.0, 20.0, 1.4, flesh_d)
	# 脓包
	ci.draw_circle(Vector2(-6.0, -22.0), 3.6, pus)
	ci.draw_circle(Vector2(7.0, -16.0), 2.8, pus)
	ci.draw_circle(Vector2(2.0, -28.0), 2.4, pus)
	# 眼睛
	ci.draw_circle(Vector2(-5.0, -33.0), 3.0, Color(1.0, 0.92, 0.5))
	ci.draw_circle(Vector2(6.0, -33.0), 3.0, Color(1.0, 0.92, 0.5))
	ci.draw_circle(Vector2(-5.0, -33.0), 1.4, Color(0.15, 0.05, 0.05))
	ci.draw_circle(Vector2(6.0, -33.0), 1.4, Color(0.15, 0.05, 0.05))
	# 嘴
	r(ci, -7.0, -26.0, 14.0, 3.0, Color(0.20, 0.06, 0.08))
	if flash > 0.04:
		r(ci, -18.0, -40.0, 36.0, 40.0, Color(1, 1, 1, 0.45 * flash))

# ---------------------------------------------------------------- 史莱姆
static func draw_slime(ci: CanvasItem, a: Dictionary) -> void:
	var P: Dictionary = PAL["slime"]
	var body: Color = P["body"]
	var body_d: Color = P["body_d"]
	var hi: Color = P["hi"]
	if a.has("col"):
		body = a["col"]
		body_d = body.darkened(0.45)
		hi = body.lerp(Color(1, 1, 1), 0.55)
	var core: Color = P["core"]
	var t: float = a.get("t", 0.0)
	var sq: float = a.get("squash", 0.0)
	var face: float = a.get("face", 1.0)
	var flash: float = clampf(a.get("flash", 0.0), 0.0, 1.0)
	var scale_k: float = a.get("scale", 1.0)

	var wob: float = sin(t * 3.4) * 0.5
	var hgt: float = (8.0 - sq * 3.4) * scale_k
	var wid: float = (7.4 + sq * 2.4) * scale_k
	if hgt < 2.0:
		hgt = 2.0
	# 水滴形：底部宽、顶部窄（之前画反了，变成了上宽下窄）
	var rows: int = int(hgt / 1.4) + 1
	for i in range(rows):
		var f: float = float(i) / float(max(rows - 1, 1))
		var from_bottom: float = 1.0 - f
		var w: float = wid * sqrt(max(0.06, 1.0 - from_bottom * from_bottom)) + wob * 0.4
		var y: float = -hgt + f * hgt
		var col: Color = body.lerp(body_d, 1.0 - f)
		r(ci, -w, y, w * 2.0, 1.5, col)
	# 底部加宽的一层，让软泥稳稳趴在地上
	r(ci, -wid, -1.8, wid * 2.0, 1.8, body_d)
	# 高光（顶部偏左）
	r(ci, -wid * 0.38, -hgt * 0.70, wid * 0.34, 1.6, hi)
	# 内核
	r(ci, -wid * 0.28, -hgt * 0.52, wid * 0.56, hgt * 0.36, Color(core.r, core.g, core.b, 0.32))
	# 眼睛
	var ey: float = -hgt * 0.68
	r(ci, -wid * 0.42, ey, 1.5, 1.9, P["eye"])
	r(ci, wid * 0.12, ey, 1.5, 1.9, P["eye"])
	r(ci, -wid * 0.34, ey + 0.5, 0.7, 0.8, Color(1, 1, 1, 0.9))
	r(ci, wid * 0.20, ey + 0.5, 0.7, 0.8, Color(1, 1, 1, 0.9))
	if a.has("crown"):
		# 王冠
		var cy2: float = -hgt - 3.0
		r(ci, -wid * 0.55, cy2, wid * 1.1, 2.2, Color(1.0, 0.86, 0.34))
		for k in range(3):
			var kx: float = -wid * 0.42 + float(k) * wid * 0.42
			ci.draw_colored_polygon(PackedVector2Array([
				Vector2(kx - 1.8, cy2), Vector2(kx, cy2 - 3.4), Vector2(kx + 1.8, cy2),
			]), Color(1.0, 0.92, 0.48))
	if flash > 0.04:
		r(ci, -wid, -hgt, wid * 2.0, hgt, Color(1, 1, 1, 0.5 * flash))


# ---------------------------------------------------------------- 僵尸
static func draw_zombie(ci: CanvasItem, a: Dictionary) -> void:
	var P: Dictionary = PAL["zombie"]
	var skin: Color = P["skin"]
	var skin_d: Color = P["skin_d"]
	var rag: Color = P["rag"]
	var rag2: Color = P["rag2"]
	var bone: Color = P["bone"]
	var face: float = a.get("face", 1.0)
	if face >= 0.0:
		face = 1.0
	else:
		face = -1.0
	var t: float = a.get("t", 0.0)
	var ph: float = a.get("run", 0.0)
	var st: String = a.get("state", "walk")
	var flash: float = clampf(a.get("flash", 0.0), 0.0, 1.0)
	var atk: float = a.get("atk", -1.0)

	var s: float = sin(ph * TAU)
	var lfx: float = 2.2 * s + 0.8
	var rfx: float = -2.2 * s - 0.8
	var lfy: float = maxf(0.0, s) * 1.4
	var rfy: float = maxf(0.0, -s) * 1.4
	var hip: float = -8.4
	var sh: float = -16.6
	var hd: float = -20.4
	var lean: float = 1.4
	if st == "lunge":
		lean = 3.2
		lfx = 3.4
		rfx = -2.6
	if st == "stun":
		lean = -1.2

	# 破烂披风
	for i in range(3):
		var f: float = float(i) / 2.0
		r(ci, -face * (2.2 + f * 1.4), sh + f * 5.0, 3.0 - f * 0.6, 2.6, rag2)
	# 腿
	pline(ci, Vector2(-1.0, hip), Vector2(rfx, -rfy), 1.8, skin_d)
	pline(ci, Vector2(1.0, hip), Vector2(lfx, -lfy), 1.8, skin_d)
	r(ci, rfx - 1.3, -rfy - 1.6, 2.7, 1.6, Color(0.16, 0.13, 0.12))
	r(ci, lfx - 1.3, -lfy - 1.6, 2.7, 1.6, Color(0.16, 0.13, 0.12))
	# 躯干（前倾）
	var bx: float = lean * 0.5 * face
	r(ci, bx - 2.8, sh, 5.6, hip - sh + 1.0, rag)
	r(ci, bx - 2.8, sh + 2.0, 5.6, 1.2, rag2)
	# 露出肋骨
	r(ci, bx - 1.6, sh + 4.0, 3.2, 0.8, bone)
	r(ci, bx - 1.6, sh + 6.0, 3.2, 0.8, bone)
	r(ci, bx - 0.8, sh + 3.6, 0.8, 3.4, skin_d)
	# 手臂前伸
	var arm_y: float = sh + 3.2
	var reach: float = 5.2
	if atk >= 0.0:
		reach = 7.4
		arm_y = sh + 4.2
	pline(ci, Vector2(bx + face * 2.0, sh + 2.0), Vector2(bx + face * reach, arm_y), 1.8, skin)
	pline(ci, Vector2(bx + face * 2.0, sh + 3.2), Vector2(bx + face * (reach - 0.6), arm_y + 1.6), 1.7, skin_d)
	# 手爪
	r(ci, bx + face * reach - 1.0, arm_y - 1.4, 2.0, 2.0, skin_d)
	# 头
	r(ci, bx - 2.6 + face * 0.6, hd - 2.8, 5.2, 5.6, skin)
	r(ci, bx - 2.6 + face * 0.6, hd - 2.8, 5.2, 1.0, skin_d)
	r(ci, bx - 1.4 + face * 0.6, hd + 1.0, 3.6, 1.6, skin_d)
	# 发光红眼
	var eg: float = 0.7 + 0.3 * sin(t * 5.0 + 1.0)
	r(ci, bx - 1.8 + face * 0.8, hd - 1.4, 1.1, 1.0, Color(1.0, 0.22, 0.16, eg))
	r(ci, bx + 0.5 + face * 0.8, hd - 1.4, 1.1, 1.0, Color(1.0, 0.22, 0.16, eg))
	# 牙齿
	r(ci, bx - 1.0 + face * 0.6, hd + 1.2, 0.7, 1.0, bone)
	r(ci, bx + 0.4 + face * 0.6, hd + 1.2, 0.7, 1.0, bone)
	if flash > 0.04:
		var fc := Color(1, 1, 1, 0.45 * flash)
		r(ci, bx - 2.8, sh, 5.6, hip - sh + 1.0, fc)
		r(ci, bx - 2.6 + face * 0.6, hd - 2.8, 5.2, 5.6, fc)


# ---------------------------------------------------------------- 哥布林
static func draw_goblin(ci: CanvasItem, a: Dictionary) -> void:
	var P: Dictionary = PAL["goblin"]
	var skin: Color = P["skin"]
	var skin_d: Color = P["skin_d"]
	var cloth: Color = P["cloth"]
	var cloth2: Color = P["cloth2"]
	var face: float = a.get("face", 1.0)
	if face >= 0.0:
		face = 1.0
	else:
		face = -1.0
	var t: float = a.get("t", 0.0)
	var ph: float = a.get("run", 0.0)
	var st: String = a.get("state", "walk")
	var flash: float = clampf(a.get("flash", 0.0), 0.0, 1.0)
	var atk: float = a.get("atk", -1.0)

	var s: float = sin(ph * TAU)
	var lfx: float = 1.8 * s
	var rfx: float = -1.8 * s
	var lfy: float = maxf(0.0, s) * 1.6
	var rfy: float = maxf(0.0, -s) * 1.6
	var hip: float = -6.4
	var sh: float = -12.4
	var hd: float = -15.6
	if st == "throw":
		lfx = 2.4
		rfx = -2.4

	# 腿
	pline(ci, Vector2(-0.8, hip), Vector2(rfx, -rfy), 1.6, skin_d)
	pline(ci, Vector2(0.8, hip), Vector2(lfx, -lfy), 1.6, skin_d)
	r(ci, rfx - 1.2, -rfy - 1.4, 2.4, 1.4, cloth2)
	r(ci, lfx - 1.2, -lfy - 1.4, 2.4, 1.4, cloth2)
	# 身体
	r(ci, -2.4, sh, 4.8, hip - sh + 1.0, skin)
	r(ci, -2.4, sh + 3.0, 4.8, 2.0, cloth)
	r(ci, -2.4, hip - 1.6, 4.8, 1.6, cloth2)
	# 手臂
	var reach: float = 4.4
	if atk >= 0.0:
		reach = 6.4
	pline(ci, Vector2(face * 1.6, sh + 2.0), Vector2(face * reach, sh + 4.2), 1.5, skin)
	pline(ci, Vector2(-face * 1.4, sh + 2.0), Vector2(-face * 2.6, sh + 5.0), 1.4, skin_d)
	# 匕首
	if atk >= 0.0:
		pline(ci, Vector2(face * reach, sh + 4.2), Vector2(face * (reach + 3.2), sh + 3.4), 0.9, P["metal"])
	else:
		pline(ci, Vector2(face * reach, sh + 4.2), Vector2(face * (reach + 2.2), sh + 5.6), 0.9, P["metal"])
	# 大脑袋
	r(ci, -2.8, hd - 3.0, 5.6, 5.4, skin)
	r(ci, -2.8, hd - 3.0, 5.6, 1.0, skin_d)
	# 尖耳朵
	pline(ci, Vector2(-2.8, hd - 1.6), Vector2(-5.0, hd - 3.4), 1.0, skin_d)
	pline(ci, Vector2(2.8, hd - 1.6), Vector2(5.0, hd - 3.4), 1.0, skin_d)
	# 大眼睛
	var eg: float = 0.75 + 0.25 * sin(t * 6.0)
	r(ci, -1.9, hd - 1.6, 1.5, 1.5, P["eye"])
	r(ci, 0.4, hd - 1.6, 1.5, 1.5, P["eye"])
	r(ci, -1.5 + face * 0.3, hd - 1.2, 0.6, 0.8, Color(0.05, 0.05, 0.05, eg))
	r(ci, 0.8 + face * 0.3, hd - 1.2, 0.6, 0.8, Color(0.05, 0.05, 0.05, eg))
	# 牙
	r(ci, -0.8, hd + 1.4, 0.7, 0.9, P["tooth"])
	r(ci, 0.3, hd + 1.4, 0.7, 0.9, P["tooth"])
	if flash > 0.04:
		var fc := Color(1, 1, 1, 0.45 * flash)
		r(ci, -2.4, sh, 4.8, hip - sh + 1.0, fc)
		r(ci, -2.8, hd - 3.0, 5.6, 5.4, fc)


# ---------------------------------------------------------------- 场景装饰
static func draw_torch(ci: CanvasItem, pos: Vector2, t: float, th: Dictionary) -> void:
	var glow: Color = th["glow"]
	# 铁架
	ci.draw_rect(Rect2(pos.x - 2.0, pos.y - 6.0, 4.0, 18.0), Color(0.13, 0.12, 0.14))
	ci.draw_rect(Rect2(pos.x - 5.0, pos.y - 10.0, 10.0, 5.0), Color(0.20, 0.18, 0.20))
	# 火焰
	var f1: float = sin(t * 11.0 + pos.x * 0.05) * 0.8 + sin(t * 6.3) * 0.5
	var f2: float = cos(t * 9.0 + pos.y * 0.03) * 0.7
	ci.draw_rect(Rect2(pos.x - 4.0 + f1, pos.y - 17.0, 8.0, 8.0), Color(glow.r, glow.g, glow.b, 0.55))
	ci.draw_rect(Rect2(pos.x - 3.0 + f2, pos.y - 21.0, 6.0, 7.0), Color(glow.r, glow.g * 0.9, glow.b * 0.7, 0.85))
	ci.draw_rect(Rect2(pos.x - 1.5 + f1 * 1.4, pos.y - 25.0, 3.0, 6.0), Color(1.0, 0.98, 0.86, 0.95))


static func draw_prop(ci: CanvasItem, p: Dictionary, t: float, th: Dictionary) -> void:
	var type: String = p.get("type", "bone")
	var pos: Vector2 = p.get("pos", Vector2.ZERO)
	var sd: float = p.get("seed", 0.0)
	match type:
		"bone":
			var a: float = 0.4 + sd * 0.7
			var p2: Vector2 = pos + Vector2(cos(a), sin(a)) * 6.0
			ci.draw_line(pos, p2, Color(0.52, 0.50, 0.44), 2.0)
			ci.draw_circle(pos, 1.8, Color(0.58, 0.56, 0.48))
			ci.draw_circle(p2, 1.8, Color(0.58, 0.56, 0.48))
		"skull":
			ci.draw_rect(Rect2(pos.x - 4.0, pos.y - 6.0, 8.0, 6.0), Color(0.60, 0.58, 0.50))
			ci.draw_rect(Rect2(pos.x - 2.0, pos.y - 3.0, 4.0, 2.0), Color(0.10, 0.09, 0.09))
			ci.draw_rect(Rect2(pos.x - 3.0, pos.y - 6.0, 2.0, 2.0), Color(0.10, 0.09, 0.09))
			ci.draw_rect(Rect2(pos.x + 1.0, pos.y - 6.0, 2.0, 2.0), Color(0.10, 0.09, 0.09))
		"chain":
			var links: int = int(p.get("len", 6.0))
			for i in range(links):
				var yy: float = pos.y + float(i) * 9.0
				ci.draw_rect(Rect2(pos.x - 2.0, yy, 4.0, 6.0), Color(0.18, 0.18, 0.20))
				ci.draw_rect(Rect2(pos.x - 2.0, yy + 3.0, 4.0, 2.0), Color(0.28, 0.28, 0.32))
		"banner":
			var col: Color = th["accent"]
			var sw: float = sin(t * 1.2 + sd * 4.0) * 1.5
			ci.draw_rect(Rect2(pos.x - 9.0, pos.y, 18.0, 4.0), Color(0.22, 0.20, 0.22))
			for i in range(7):
				var f: float = float(i) / 6.0
				var w: float = 16.0 - f * 3.0
				ci.draw_rect(Rect2(pos.x - w * 0.5 + sw * f, pos.y + 4.0 + f * 22.0, w, 3.4), Color(col.r * 0.55, col.g * 0.30, col.b * 0.30, 0.9))
			ci.draw_rect(Rect2(pos.x - 3.0, pos.y + 10.0, 6.0, 6.0), Color(0.75, 0.68, 0.35, 0.75))
		"mushroom":
			ci.draw_rect(Rect2(pos.x - 1.5, pos.y - 5.0, 3.0, 5.0), Color(0.55, 0.52, 0.45))
			ci.draw_rect(Rect2(pos.x - 5.0, pos.y - 8.0, 10.0, 4.0), Color(0.35, 0.62, 0.38))
			ci.draw_rect(Rect2(pos.x - 3.0, pos.y - 9.0, 6.0, 2.0), Color(0.45, 0.78, 0.46))
			ci.draw_rect(Rect2(pos.x - 2.0, pos.y - 7.0, 1.5, 1.5), Color(0.85, 0.95, 0.70))
		"crate":
			ci.draw_rect(Rect2(pos.x - 9.0, pos.y - 18.0, 18.0, 18.0), Color(0.28, 0.22, 0.15))
			ci.draw_rect(Rect2(pos.x - 9.0, pos.y - 18.0, 18.0, 2.0), Color(0.40, 0.32, 0.20))
			ci.draw_line(pos + Vector2(-8.0, -16.0), pos + Vector2(8.0, -2.0), Color(0.20, 0.15, 0.10), 2.0)
			ci.draw_line(pos + Vector2(8.0, -16.0), pos + Vector2(-8.0, -2.0), Color(0.20, 0.15, 0.10), 2.0)
		"grass":
			for i in range(4):
				var off: float = float(i) * 3.0 - 4.5
				var hh: float = 4.0 + sd * 4.0 + float(i)
				ci.draw_line(pos + Vector2(off, 0), pos + Vector2(off + 1.5, -hh), Color(0.24, 0.36, 0.24), 1.4)
		_:
			pass


static func draw_portal(ci: CanvasItem, pos: Vector2, t: float, open: bool, th: Dictionary) -> void:
	var col: Color = th["accent"]
	var pulse: float = 0.5 + 0.5 * sin(t * 3.0)
	# 石制拱门
	ci.draw_rect(Rect2(pos.x - 26.0, pos.y - 62.0, 10.0, 62.0), Color(0.20, 0.19, 0.23))
	ci.draw_rect(Rect2(pos.x + 16.0, pos.y - 62.0, 10.0, 62.0), Color(0.20, 0.19, 0.23))
	ci.draw_rect(Rect2(pos.x - 30.0, pos.y - 70.0, 60.0, 9.0), Color(0.24, 0.22, 0.27))
	# 漩涡
	for i in range(5):
		var f: float = float(i) / 4.0
		var rr: float = 24.0 * (1.0 - f * 0.75)
		var a: float = (0.10 + 0.12 * pulse) * (1.0 - f * 0.4)
		if not open:
			a *= 0.35
		ci.draw_circle(Vector2(pos.x, pos.y - 30.0), rr, Color(col.r, col.g, col.b, a))
	for i in range(6):
		var ang: float = t * 2.0 + float(i) * TAU / 6.0
		var rpos: Vector2 = Vector2(pos.x, pos.y - 30.0) + Vector2(cos(ang), sin(ang) * 1.3) * 20.0
		var aa: float = 0.35 + 0.35 * pulse
		if not open:
			aa *= 0.4
		ci.draw_circle(rpos, 2.2, Color(col.r, col.g, col.b, aa))
	if open:
		ci.draw_rect(Rect2(pos.x - 2.0, pos.y - 100.0, 4.0, 34.0), Color(col.r, col.g, col.b, 0.16 + 0.10 * pulse))



## 场景砖墙（屏幕固定，不随镜头移动；在天空之后绘制才不会盖住）
## 生成/复用砖墙贴图（整张地牢只用一次绘制）
static var _wall_tex: ImageTexture = null
static var _wall_key: String = ""
static var _bg_tex: ImageTexture = null
static var _bg_key: String = ""


static func wall_texture(th: Dictionary) -> ImageTexture:
	var name: String = str(th.get("name", "x"))
	var key: String = name
	if _wall_tex != null and _wall_key == key:
		return _wall_tex
	var w: int = 128
	var h: int = 104
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var base: Color = th.get("brick", Color(0.20, 0.22, 0.29))
	var stone: Color = th.get("stone", base)
	var c1: Color = base.lerp(stone, 0.55)
	var bw: float = 64.0
	var bh: float = 26.0
	for r in range(4):
		var y0: float = float(r) * bh
		var off: float = 32.0 if (r % 2 == 1) else 0.0
		for c in range(3):
			var x0: float = float(c) * bw + off - 32.0
			var sh: float = 0.90 + 0.16 * sin(float(r) * 1.7 + float(c) * 2.3)
			var col := Color(c1.r * sh, c1.g * sh, c1.b * sh, 1.0)
			for yy in range(int(y0), mini(int(y0 + bh - 2.6), h)):
				for xx in range(maxi(int(x0), 0), mini(int(x0 + bw - 2.6), w)):
					img.set_pixel(xx, yy, col)
			# 顶面高光
			for yy in range(int(y0), mini(int(y0 + 3.0), h)):
				for xx in range(maxi(int(x0), 0), mini(int(x0 + bw - 2.6), w)):
					img.set_pixel(xx, yy, Color(minf(c1.r * 1.8, 1.0), minf(c1.g * 1.8, 1.0), minf(c1.b * 1.8, 1.0), 0.55).blend(img.get_pixel(xx, yy)))
			# 底部暗边
			for yy in range(maxi(int(y0 + bh - 4.6), 0), mini(int(y0 + bh - 2.6), h)):
				for xx in range(maxi(int(x0), 0), mini(int(x0 + bw - 2.6), w)):
					img.set_pixel(xx, yy, Color(0, 0, 0, 0.40).blend(img.get_pixel(xx, yy)))
	_wall_tex = ImageTexture.create_from_image(img)
	_wall_key = key
	return _wall_tex


static func draw_walls(ci: CanvasItem, cam: Vector2, view: Vector2, th: Dictionary) -> void:
	var tex: ImageTexture = wall_texture(th)
	# 固定在屏幕上的墙壁：位置永远 = 视口左上角，不随镜头滚动
	var left: float = cam.x - view.x * 0.5
	var top: float = cam.y - view.y * 0.5
	ci.draw_texture_rect(tex, Rect2(left, top, view.x, view.y), false, Color(1, 1, 1, 1))




## 屏幕固定墙壁：在屏幕坐标 (0,0) 平铺，不跟随镜头
static func draw_walls_screen(ci: CanvasItem, cam: Vector2, view: Vector2, th: Dictionary) -> void:
	var tex: ImageTexture = wall_texture(th)
	if tex == null:
		return
	# 起点永远是屏幕左上角（世界坐标 cam - view/2），tile=true 让图案从屏幕角开始重复
	# → 视觉上固定不动，且铺满整屏
	var origin: Vector2 = cam - view * 0.5
	ci.draw_texture_rect(tex, Rect2(origin, view), true, Color(1, 1, 1, 1))
