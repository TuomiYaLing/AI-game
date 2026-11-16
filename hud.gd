extends Control
## HUD：血条 / 药瓶 / 金币 / 遗物 / 技能 / 武器弹药 / 小地图 / 商店 / 各种全屏界面

const Art = preload("res://scripts/art.gd")
const W = preload("res://scripts/weapons.gd")
const TAU := 6.283185307179586

var game = null
var fnt: SystemFont = null
var toasts: Array = []
var t := 0.0
var show_crosshair := true
var show_vignette := true
var show_fps := false

const C_BLOOD := Color(0.78, 0.16, 0.20)
const C_BLOOD_D := Color(0.35, 0.06, 0.09)
const C_GOLD := Color(0.95, 0.78, 0.32)
const C_ICE := Color(0.55, 0.90, 1.0)
const C_PAPER := Color(0.88, 0.86, 0.80)


func setup(p_game) -> void:
	game = p_game
	fnt = Art.make_font()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func msg(text: String, col: Color = Color(0.9, 0.9, 0.85), dur: float = 2.0) -> void:
	toasts.append({"text": text, "col": col, "life": dur, "max": dur})


func _process(dt: float) -> void:
	t += dt
	var vs: Vector2 = get_viewport_rect().size
	if size != vs:
		size = vs
		position = Vector2.ZERO
	var i: int = toasts.size() - 1
	while i >= 0:
		var tt: Dictionary = toasts[i]
		tt["life"] = float(tt["life"]) - dt
		if float(tt["life"]) <= 0.0:
			toasts.remove_at(i)
		i -= 1
	queue_redraw()


func txt(pos: Vector2, s: String, size: int, col: Color, align: int = 0) -> void:
	var w: float = fnt.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p: Vector2 = pos
	if align == 1:
		p.x -= w * 0.5
	elif align == 2:
		p.x -= w
	draw_string(fnt, p + Vector2(2, 2), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0.02, 0.02, 0.03, col.a * 0.85))
	draw_string(fnt, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func panel(rect: Rect2, alpha: float = 0.55) -> void:
	draw_rect(rect, Color(0.03, 0.03, 0.05, alpha))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2.0)), Color(0.45, 0.38, 0.30, 0.5))
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 2.0), Vector2(rect.size.x, 2.0)), Color(0.45, 0.38, 0.30, 0.35))


func _draw() -> void:
	if game == null:
		return
	var vs: Vector2 = get_viewport_rect().size
	if vs.x < 10.0:
		vs = size
	if show_vignette:
		var vg: GradientTexture2D = Art.vignette_tex()
		draw_texture_rect(vg, Rect2(0, 0, vs.x, vs.y), false, Color(1, 1, 1, 0.70))
		# 主题色分级：让每个关卡的氛围更明显
		if game.dungeon != null and is_instance_valid(game.dungeon):
			var th: Dictionary = game.dungeon.theme
			if th.has("glow"):
				var gc: Color = th["glow"]
				draw_rect(Rect2(0, 0, vs.x, 90.0), Color(gc.r, gc.g, gc.b, 0.030))
				var fg: Color = th["fog"]
				draw_rect(Rect2(0, vs.y - 130.0, vs.x, 130.0), Color(fg.r, fg.g, fg.b, 0.045))

	if game.state == "play" or game.state == "pause" or game.state == "shop" or game.state == "pickup":
		draw_rect(Rect2(0, vs.y - 130.0, vs.x, 130.0), Color(0.02, 0.02, 0.04, 0.36))
		draw_rect(Rect2(0, 0, vs.x, 200.0), Color(0.02, 0.02, 0.04, 0.32))
		_draw_stats(vs)
		_draw_mana(vs)
		_draw_items(vs)
		_draw_skills(vs)
		_draw_weapons(vs)
		_draw_minimap(vs)
		_draw_banner(vs)
		_draw_toasts(vs)
		_draw_combo(vs)
		_draw_pedestals(vs)
		var pl2 = game.player
		if pl2 != null:
			var fl2: float = float(pl2.flash)
			if fl2 > 0.01:
				draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.62, 0.02, 0.04, 0.26 * fl2))
		if game.state == "shop":
			_draw_shop(vs)
		elif game.state == "pickup":
			_draw_pickup(vs)
		else:
			if show_crosshair:
				_draw_crosshair()
		if show_fps:
			_draw_fps(vs)
	if game.state == "title":
		_draw_title(vs)
	elif game.state == "dead":
		_draw_death(vs)
	elif game.state == "pause":
		_draw_pause(vs)
	elif game.state == "codex":
		_draw_codex(vs)
	elif game.state == "saves":
		_draw_saves(vs)
	elif game.state == "settings":
		_draw_settings(vs)
	elif game.state == "train_cfg":
		_draw_train_cfg(vs)
	elif game.state == "tp_confirm":
		_draw_tp_confirm(vs)
	elif game.state == "keys":
		_draw_keys(vs)


func _draw_fps(vs: Vector2) -> void:
	var fps: int = int(Engine.get_frames_per_second())
	var col: Color = Color(0.65, 0.95, 0.7) if fps >= 55 else (Color(0.98, 0.85, 0.35) if fps >= 30 else Color(1.0, 0.45, 0.4))
	txt(Vector2(vs.x - 16.0, 22.0), "%d FPS" % fps, 15, col, 2)


# ---------------------------------------------------------------- 左上半区
func _draw_stats(vs: Vector2) -> void:
	var pl = game.player
	if pl == null:
		return
	var x: float = 26.0
	var y: float = 24.0
	var w: float = 296.0
	var h: float = 20.0
	draw_rect(Rect2(x - 3.0, y - 3.0, w + 6.0, h + 6.0), Color(0.03, 0.03, 0.05, 0.78))
	draw_rect(Rect2(x, y, w, h), C_BLOOD_D)
	var ratio: float = clampf(float(pl.hp) / maxf(1.0, float(pl.max_hp)), 0.0, 1.0)
	var fill: Color = C_BLOOD
	if float(pl.flash) > 0.3:
		fill = Color(1.0, 0.75, 0.75)
	draw_rect(Rect2(x, y, w * ratio, h), fill)
	draw_rect(Rect2(x, y, w * ratio, 4.0), Color(1.0, 0.45, 0.45, 0.5))
	for i in range(1, 10):
		draw_rect(Rect2(x + w * float(i) / 10.0, y, 1.0, h), Color(0.0, 0.0, 0.0, 0.35))
	draw_rect(Rect2(x - 3.0, y - 3.0, w + 6.0, 2.0), Color(0.55, 0.45, 0.35, 0.45))
	txt(Vector2(x + 6.0, y + h - 4.0), "%d / %d" % [int(pl.hp), int(pl.max_hp)], 13, Color(1, 0.92, 0.92, 0.85))

	# 药瓶（左下角，红白长条药丸）
	var vsp: Vector2 = get_viewport_rect().size
	var cap_w: float = 16.0
	var cap_h: float = 30.0
	var gap: float = 8.0
	var px0: float = 26.0
	var py0: float = vsp.y - 26.0 - cap_h * 0.5
	for i in range(pl.max_flasks):
		var cx0: float = px0 + float(i) * (cap_w + gap)
		var full: bool = i < pl.flasks
		draw_rect(Rect2(cx0 - 3.0, py0 - cap_h * 0.5 - 3.0, cap_w + 6.0, cap_h + 6.0), Color(0.04, 0.04, 0.07, 0.85))
		var c_white: Color = Color(0.94, 0.95, 0.98) if full else Color(0.26, 0.26, 0.30)
		var c_red: Color = Color(0.92, 0.22, 0.30) if full else Color(0.22, 0.14, 0.16)
		var top_y: float = py0 - cap_h * 0.5
		draw_rect(Rect2(cx0, top_y, cap_w, cap_h * 0.5), c_white)
		draw_rect(Rect2(cx0, py0, cap_w, cap_h * 0.5), c_red)
		draw_circle(Vector2(cx0 + cap_w * 0.5, top_y), cap_w * 0.5, c_white)
		draw_circle(Vector2(cx0 + cap_w * 0.5, py0 + cap_h * 0.5), cap_w * 0.5, c_red)
		draw_rect(Rect2(cx0 - 1.0, py0 - 1.0, cap_w + 2.0, 2.0), Color(0.10, 0.10, 0.14, 0.9))
		draw_rect(Rect2(cx0 + 2.5, top_y + 3.0, 2.6, cap_h - 6.0), Color(1, 1, 1, 0.30 if full else 0.10))
		if full:
			draw_rect(Rect2(cx0 - 4.0, top_y - 4.0, cap_w + 8.0, cap_h + 8.0), Color(1.0, 0.35, 0.40, 0.10))

	# 金币
	var cy: float = y + h + 46.0
	draw_circle(Vector2(x + 8.0, cy - 4.0), 7.0, Color(0.95, 0.78, 0.30, 0.95))
	draw_circle(Vector2(x + 8.0, cy - 4.0), 4.0, Color(1.0, 0.92, 0.6, 1.0))
	txt(Vector2(x + 22.0, cy), str(int(game.coins)), 18, C_GOLD)

	# 魔法保护次数
	if game.items != null and is_instance_valid(game.items) and game.items.guard_charges > 0:
		var gx: float = x + 120.0
		draw_circle(Vector2(gx + 8.0, cy - 5.0), 8.0, Color(0.45, 0.75, 1.0, 0.30))
		draw_arc(Vector2(gx + 8.0, cy - 5.0), 8.0, 0.0, TAU, 16, Color(0.75, 0.95, 1.0, 0.9), 2.0)
		txt(Vector2(gx + 22.0, cy), "×" + str(game.items.guard_charges), 17, Color(0.82, 0.95, 1.0))

	# 右上：楼层 / 时间 / 击杀 / 传送门
	var rx: float = vs.x - 26.0
	var flabel: String = "训练场 ∞" if game.training_mode else ("第 %d 层 · %s" % [game.floor_index, game.theme_name()])
	txt(Vector2(rx, 44.0), flabel, 22, C_PAPER, 2)
	txt(Vector2(rx, 66.0), game.theme_sub() + "   怪物强度 ×" + _fmt_mult(game.stat_mult()), 12, Color(0.65, 0.60, 0.55, 0.85), 2)
	txt(Vector2(rx, 92.0), "%s   ·   击杀 %d" % [_fmt_time(game.run_time), int(game.kills)], 15, Color(0.80, 0.78, 0.72), 2)
	var seal_col: Color = C_ICE if game.kills >= game.kills_required else Color(0.72, 0.66, 0.60)
	txt(Vector2(rx, 112.0), "传送门封印: %d / %d" % [int(game.kills), int(game.kills_required)], 14, seal_col, 2)
	if game.kills >= game.kills_required:
		txt(Vector2(rx, 130.0), "封印已解除 —— 前往出口", 14, Color(0.6, 1.0, 0.7), 2)


func _fmt_mult(m: float) -> String:
	if m < 100.0:
		return "%d" % int(m)
	return "%d" % int(m)


func _fmt_time(t: float) -> String:
	var total: int = int(t)
	var m: int = int(total / 60)
	var s: int = total % 60
	return "%02d:%02d" % [m, s]


func _draw_items(vs: Vector2) -> void:
	if game.items == null or not is_instance_valid(game.items):
		return
	var order: Array = game.items.order
	if order.size() == 0:
		return
	var x: float = 26.0
	var y: float = 110.0
	txt(Vector2(x, y - 4.0), "遗物", 11, Color(0.62, 0.58, 0.52, 0.9))
	for i in range(order.size()):
		var id: String = str(order[i])
		var n: int = game.items.count_of(id)
		var col: Color = game.items.item_col(id)
		var bx: float = x + float(i) * 32.0
		draw_rect(Rect2(bx, y, 28.0, 28.0), Color(0.03, 0.03, 0.05, 0.70))
		draw_rect(Rect2(bx, y, 28.0, 2.0), Color(col.r, col.g, col.b, 0.85))
		_draw_item_icon(Vector2(bx + 14.0, y + 15.0), id, col)
		if n > 1:
			txt(Vector2(bx + 27.0, y + 27.0), "x" + str(n), 11, Color(1.0, 0.96, 0.88, 0.95), 2)


func _draw_item_icon(c: Vector2, id: String, col: Color) -> void:
	if id == "pet_skull":
		draw_circle(c, 7.0, Color(0.90, 0.88, 0.80))
		draw_rect(Rect2(c.x - 4.0, c.y + 1.0, 8.0, 4.0), Color(0.90, 0.88, 0.80))
		draw_rect(Rect2(c.x - 3.5, c.y - 2.5, 2.6, 3.0), Color(0.10, 0.10, 0.12))
		draw_rect(Rect2(c.x + 1.0, c.y - 2.5, 2.6, 3.0), Color(0.10, 0.10, 0.12))
		return
	if id.begins_with("pet_"):
		draw_rect(Rect2(c.x - 6.0, c.y - 4.0, 12.0, 10.0), Color(col.r, col.g, col.b, 0.9))
		draw_rect(Rect2(c.x - 5.0, c.y - 8.0, 3.0, 4.0), Color(col.r * 0.7, col.g * 0.7, col.b * 0.7, 0.9))
		draw_rect(Rect2(c.x + 2.0, c.y - 8.0, 3.0, 4.0), Color(col.r * 0.7, col.g * 0.7, col.b * 0.7, 0.9))
		draw_rect(Rect2(c.x - 4.0, c.y - 1.0, 3.0, 3.0), Color(1.0, 0.96, 0.7))
		draw_rect(Rect2(c.x + 1.0, c.y - 1.0, 3.0, 3.0), Color(1.0, 0.96, 0.7))
		return
	if id.begins_with("stand_"):
		draw_rect(Rect2(c.x - 5.0, c.y - 9.0, 10.0, 8.0), Color(col.r, col.g, col.b, 0.9))
		draw_rect(Rect2(c.x - 6.0, c.y - 1.0, 12.0, 9.0), Color(col.r, col.g, col.b, 0.75))
		draw_rect(Rect2(c.x - 3.0, c.y - 6.0, 2.0, 2.0), Color(1.0, 0.96, 0.75))
		draw_rect(Rect2(c.x + 1.0, c.y - 6.0, 2.0, 2.0), Color(1.0, 0.96, 0.75))
		return
	match id:
		"sword":
			draw_rect(Rect2(c.x - 1.5, c.y - 9.0, 3.0, 14.0), Color(0.88, 0.94, 1.0))
			draw_rect(Rect2(c.x - 6.0, c.y + 4.0, 12.0, 2.4), Color(0.64, 0.47, 0.28))
			draw_rect(Rect2(c.x - 1.2, c.y + 6.0, 2.4, 5.0), Color(0.45, 0.32, 0.20))
		"laser":
			draw_circle(c, 8.0, Color(col.r, col.g, col.b, 0.20))
			draw_arc(c, 7.0, 0.0, TAU, 16, Color(col.r, col.g, col.b, 0.95), 1.8)
			draw_circle(c, 2.8, Color(1.0, 0.98, 0.82))
		"thunder":
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(2.0, -9.0), c + Vector2(-4.0, 0.0), c + Vector2(0.5, 0.0),
				c + Vector2(-2.0, 9.0), c + Vector2(5.0, -2.0), c + Vector2(0.5, -2.0),
			]), Color(col.r, col.g, col.b, 0.95))
		"frost":
			for k in range(3):
				var a4: float = float(k) * TAU / 3.0
				var d4: Vector2 = Vector2(cos(a4), sin(a4)) * 7.5
				draw_line(c - d4, c + d4, Color(col.r, col.g, col.b, 0.95), 1.6)
		"thorn":
			draw_arc(c, 8.0, 0.0, TAU, 16, Color(col.r, col.g, col.b, 0.9), 1.6)
			for k in range(4):
				var a5: float = float(k) * TAU / 4.0
				var d5: Vector2 = Vector2(cos(a5), sin(a5))
				draw_line(c + d5 * 6.0, c + d5 * 11.0, Color(col.r, col.g, col.b, 0.85), 1.6)
		"crown":
			draw_rect(Rect2(c.x - 8.0, c.y - 1.0, 16.0, 4.0), Color(1.0, 0.84, 0.36))
			for k in range(3):
				var kx: float = -6.0 + float(k) * 6.0
				draw_colored_polygon(PackedVector2Array([
					c + Vector2(kx - 2.0, -1.0), c + Vector2(kx, -8.0), c + Vector2(kx + 2.0, -1.0),
				]), Color(1.0, 0.92, 0.5))
		"magnet":
			draw_arc(c, 7.0, -1.1, 1.1, 12, Color(0.86, 0.62, 0.46), 2.4)
			draw_rect(Rect2(c.x - 8.0, c.y - 3.0, 3.0, 6.0), Color(0.9, 0.35, 0.32))
			draw_rect(Rect2(c.x + 5.0, c.y - 3.0, 3.0, 6.0), Color(0.9, 0.35, 0.32))
		"phoenix":
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(0.0, -10.0), c + Vector2(6.0, 2.0), c + Vector2(0.0, 9.0), c + Vector2(-6.0, 2.0),
			]), Color(1.0, 0.62, 0.28, 0.9))
			draw_circle(c, 2.4, Color(1.0, 0.94, 0.66))
		"summon_drake", "summon_seadrake":
			var wc3: Color = Color(0.72, 0.28, 0.20) if id == "summon_drake" else Color(0.24, 0.52, 0.80)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-9.0, 2.0), c + Vector2(-2.0, -8.0), c + Vector2(4.0, 2.0)]), Color(wc3.r, wc3.g, wc3.b, 0.9))
			draw_rect(Rect2(c.x - 5.0, c.y - 2.0, 12.0, 5.0), wc3)
			draw_circle(c + Vector2(7.0, -2.0), 1.6, Color(1.0, 0.9, 0.5))
		"summon_slime":
			draw_rect(Rect2(c.x - 9.0, c.y - 6.0, 18.0, 12.0), Color(0.40, 0.82, 0.40))
			draw_rect(Rect2(c.x - 4.0, c.y - 3.0, 3.0, 4.0), Color(0.05, 0.12, 0.08))
			draw_rect(Rect2(c.x + 2.0, c.y - 3.0, 3.0, 4.0), Color(0.05, 0.12, 0.08))
		"mana_gem", "mana_crystal", "mana_orb", "mana_spring", "mana_leech", "mana_font", "mana_sage", "mana_pearl", "mana_core", "mana_star":
			# 法力类遗物：棱形水晶 + 内芯
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(0.0, -10.0), c + Vector2(7.0, -1.0), c + Vector2(0.0, 10.0), c + Vector2(-7.0, -1.0),
			]), Color(col.r, col.g, col.b, 0.9))
			draw_circle(c + Vector2(0.0, -1.0), 3.0, Color(0.90, 0.97, 1.0, 0.95))
		"pet_skull":
			draw_circle(c, 7.0, Color(0.90, 0.88, 0.80))
			draw_rect(Rect2(c.x - 4.0, c.y + 1.0, 8.0, 4.0), Color(0.90, 0.88, 0.80))
			draw_rect(Rect2(c.x - 3.5, c.y - 2.5, 2.6, 3.0), Color(0.10, 0.10, 0.12))
			draw_rect(Rect2(c.x + 1.0, c.y - 2.5, 2.6, 3.0), Color(0.10, 0.10, 0.12))
		"wing_angel", "wing_demon":
			var wc: Color = Color(0.98, 0.97, 0.90) if id == "wing_angel" else Color(0.80, 0.22, 0.28)
			var wc2: Color = Color(0.86, 0.90, 1.0) if id == "wing_angel" else Color(0.52, 0.12, 0.18)
			for s in range(2):
				var dx: float = -1.0 if s == 0 else 1.0
				draw_colored_polygon(PackedVector2Array([
					c + Vector2(dx * 1.5, -1.0),
					c + Vector2(dx * 9.5, -8.0),
					c + Vector2(dx * 7.0, 3.0),
				]), wc)
				draw_colored_polygon(PackedVector2Array([
					c + Vector2(dx * 1.5, 1.0),
					c + Vector2(dx * 7.0, 3.0),
					c + Vector2(dx * 4.0, 7.5),
				]), wc2)
		"halo":
			draw_arc(c, 8.0, 0.0, TAU, 18, Color(col.r, col.g, col.b, 0.85), 2.0)
			draw_circle(c + Vector2(0.0, -8.0), 2.4, Color(1.0, 0.96, 0.80))
			draw_circle(c + Vector2(7.0, 4.0), 2.2, Color(1.0, 0.90, 0.60))
			draw_circle(c + Vector2(-7.0, 4.0), 2.2, Color(1.0, 0.90, 0.60))
		"book":
			draw_rect(Rect2(c.x - 9.0, c.y - 7.0, 18.0, 14.0), Color(0.28, 0.20, 0.34))
			draw_rect(Rect2(c.x - 7.5, c.y - 5.5, 7.0, 11.0), Color(0.88, 0.93, 1.0, 0.95))
			draw_rect(Rect2(c.x + 0.5, c.y - 5.5, 7.0, 11.0), Color(0.92, 0.96, 1.0, 0.95))
			draw_rect(Rect2(c.x - 0.8, c.y - 7.0, 1.6, 14.0), Color(0.18, 0.12, 0.22))
		"guard":
			draw_arc(c, 8.0, 0.0, TAU, 18, Color(0.78, 0.94, 1.0, 0.9), 2.2)
			draw_rect(Rect2(c.x - 1.0, c.y - 5.0, 2.0, 10.0), Color(0.85, 0.96, 1.0, 0.9))
		_:
			draw_circle(c, 7.0, Color(col.r, col.g, col.b, 0.8))


func _draw_mana(vs: Vector2) -> void:
	var pl = game.player
	if pl == null:
		return
	var ratio: float = 0.0
	if float(pl.max_mana) > 0.0:
		ratio = clampf(float(pl.mana) / float(pl.max_mana), 0.0, 1.0)
	draw_rect(Rect2(24.0, 56.0, 250.0, 8.0), Color(0.04, 0.05, 0.09, 0.9))
	draw_rect(Rect2(24.0, 56.0, 250.0 * ratio, 8.0), Color(0.32, 0.62, 1.0, 0.95))
	txt(Vector2(280.0, 64.0), "%d/%d" % [int(pl.mana), int(pl.max_mana)], 11, Color(0.62, 0.82, 1.0), 0)


func _draw_skills(vs: Vector2) -> void:
	if game.skills == null:
		return
	var list: Array = game.skills.list()
	if list.size() == 0:
		return
	var x: float = 26.0
	var y: float = 152.0
	for i in range(list.size()):
		var s: Dictionary = list[i]
		var label: String = ("+" if bool(s["good"]) else "−") + str(s["name"])
		if int(s["count"]) > 1:
			label += "×" + str(int(s["count"]))
		var col: Color = Color(0.6, 1.0, 0.72) if bool(s["good"]) else Color(1.0, 0.5, 0.5)
		var w: float = fnt.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 12.0
		if x + w > 660.0:
			x = 26.0
			y += 20.0
		draw_rect(Rect2(x, y - 12.0, w, 18.0), Color(0.03, 0.03, 0.05, 0.55))
		draw_rect(Rect2(x, y - 12.0, w, 1.6), Color(col.r, col.g, col.b, 0.7))
		txt(Vector2(x + 6.0, y + 1.0), label, 12, col)
		x += w + 6.0


func _draw_weapons(vs: Vector2) -> void:
	var pl = game.player
	if pl == null:
		return
	var bw: float = 104.0
	var bh: float = 78.0
	var gap: float = 12.0
	var total_w: float = bw * 3.0 + gap * 2.0
	var x0: float = vs.x * 0.5 - total_w * 0.5
	var y: float = vs.y - bh - 20.0
	var names: Array = [
		W.sword_name(pl.sword_id),
		W.gun_name(pl.ranged_id),
		W.shield_name(pl.shield_id),
	]
	var keys: Array = ["左键 / J", "右键 / K", "中键 / L"]
	var wids: Array = [pl.sword_id, pl.ranged_id, pl.shield_id]
	var sword_def: Dictionary = W.sword(pl.sword_id)
	var gun_def: Dictionary = W.gun(pl.ranged_id)
	var shield_def: Dictionary = W.shield(pl.shield_id)
	var cols: Array = [
		sword_def["col"],
		gun_def["col"],
		shield_def["col"],
	]
	var active: Array = [
		float(pl.atk_time) > 0.0,
		bool(pl.bow_active) or float(pl.muzzle_flash) > 0.0,
		float(pl.guard) > 0.0,
	]
	for i in range(3):
		var bx: float = x0 + float(i) * (bw + gap)
		var rect := Rect2(bx, y, bw, bh)
		var is_on: bool = bool(active[i])
		panel(rect, 0.66 if is_on else 0.44)
		var accent: Color = cols[i]
		draw_rect(Rect2(bx, y, bw, 3.0), Color(accent.r, accent.g, accent.b, 0.9 if is_on else 0.5))
		var cx: float = bx + bw * 0.5
		# 三张武器卡片统一使用"每把武器独立模型"的图标
		_draw_weapon_icon(Vector2(cx, y + 30.0), str(wids[i]))
		txt(Vector2(cx, y + 58.0), str(names[i]), 15, Color(0.90, 0.88, 0.82), 1)
		txt(Vector2(cx, y + 71.0), str(keys[i]), 10, Color(0.62, 0.58, 0.52), 1)

	# 弹药 / 蓄力条（远程卡片上）
	var gb: float = x0 + bw + gap
	var gmax: int = int(gun_def["ammo"])
	if gmax > 0:
		txt(Vector2(gb + bw * 0.5, y + 14.0), "%d / %d" % [int(pl.ammo), gmax], 13, Color(0.92, 0.92, 1.0), 1)
		if float(pl.reloading) > 0.0:
			var rr: float = float(pl.reload_ratio())
			draw_rect(Rect2(gb + 8.0, y + bh + 4.0, bw - 16.0, 5.0), Color(0.06, 0.06, 0.09, 0.9))
			draw_rect(Rect2(gb + 8.0, y + bh + 4.0, (bw - 16.0) * rr, 5.0), Color(1.0, 0.62, 0.35))
			txt(Vector2(gb + bw * 0.5, y + bh + 20.0), "换弹中", 11, Color(1.0, 0.72, 0.45), 1)
	else:
		txt(Vector2(gb + bw * 0.5, y + 14.0), "∞", 16, Color(0.85, 0.92, 1.0), 1)

	if pl.bow_active and float(pl.bow_charge) > 0.02:
		var cbx: float = gb + 10.0
		var cby: float = y - 12.0
		draw_rect(Rect2(cbx, cby, bw - 20.0, 5.0), Color(0.08, 0.08, 0.10, 0.85))
		draw_rect(Rect2(cbx, cby, (bw - 20.0) * clampf(float(pl.bow_charge), 0.0, 1.0), 5.0), C_ICE)


func _draw_minimap(vs: Vector2) -> void:
	if game.dungeon == null:
		return
	var rooms: Array = game.dungeon.rooms
	if rooms.size() == 0:
		return
	var box := Rect2(vs.x - 240.0, vs.y - 150.0, 214.0, 96.0)
	panel(box, 0.5)
	var lw: int = int(game.dungeon.width_tiles)
	var lh: int = int(game.dungeon.height_tiles)
	var sc: float = minf((box.size.x - 20.0) / float(max(lw, 1)), (box.size.y - 20.0) / float(max(lh, 1)))
	var ox: float = box.position.x + 10.0
	var oy: float = box.position.y + 10.0
	var vis: Array = game.dungeon.visited
	for i in range(rooms.size()):
		if i >= vis.size() or not bool(vis[i]):
			continue
		var rc: Rect2i = rooms[i]["rect"]
		var r := Rect2(ox + float(rc.position.x) * sc, oy + float(rc.position.y) * sc, float(rc.size.x) * sc, maxf(2.0, float(rc.size.y) * sc))
		draw_rect(r, Color(0.34, 0.40, 0.52, 0.75))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 1.0)), Color(0.55, 0.62, 0.75, 0.6))
	# 宝箱
	for i in range(game.dungeon.chests.size()):
		var ch: Dictionary = game.dungeon.chests[i]
		if bool(ch["opened"]):
			continue
		var cp: Vector2 = ch["pos"]
		if not _room_visited_at(cp):
			continue
		draw_rect(Rect2(ox + cp.x / 32.0 * sc - 1.5, oy + cp.y / 32.0 * sc - 1.5, 3.0, 3.0), Color(0.95, 0.78, 0.3))
	if bool(game.dungeon.portal_open) and _room_visited_at(game.dungeon.portal_point):
		var pp: Vector2 = game.dungeon.portal_point
		draw_circle(Vector2(ox + pp.x / 32.0 * sc, oy + pp.y / 32.0 * sc), 3.0, Color(0.55, 1.0, 0.65))
	if game.player != null:
		var plp: Vector2 = game.player.position
		draw_circle(Vector2(ox + plp.x / 32.0 * sc, oy + plp.y / 32.0 * sc), 3.2, Color(0.85, 0.98, 1.0))
		draw_circle(Vector2(ox + plp.x / 32.0 * sc, oy + plp.y / 32.0 * sc), 6.0, Color(0.6, 0.95, 1.0, 0.22))


## 某个世界坐标是否位于「已探索」的房间内
func _room_visited_at(world_pos: Vector2) -> bool:
	if game.dungeon == null:
		return false
	var tx: int = int(world_pos.x / 32.0)
	var ty: int = int(world_pos.y / 32.0)
	var rooms: Array = game.dungeon.rooms
	var vis: Array = game.dungeon.visited
	for i in range(rooms.size()):
		var rc: Rect2i = rooms[i]["rect"]
		var fy: int = int(rooms[i]["floor"])
		if tx >= rc.position.x - 1 and tx <= rc.position.x + rc.size.x and ty >= rc.position.y - 1 and ty <= fy + 1:
			return i < vis.size() and bool(vis[i])
	return false


## 传送确认面板
func _draw_tp_confirm(vs: Vector2) -> void:
	var lbl: String = str(game.pending_tp.get("label", "传送点"))
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.02, 0.02, 0.04, 0.55))
	var pw: float = 560.0
	var ph: float = 200.0
	var px: float = vs.x * 0.5 - pw * 0.5
	var py: float = vs.y * 0.5 - ph * 0.5
	panel(Rect2(px, py, pw, ph), 0.94)
	draw_rect(Rect2(px, py, pw, 3.0), Color(0.55, 0.90, 1.0, 0.9))
	txt(Vector2(vs.x * 0.5, py + 46.0), "传送门", 26, Color(0.92, 0.96, 1.0), 1)
	txt(Vector2(vs.x * 0.5, py + 84.0), "是否传送到「%s」？" % lbl, 18, Color(0.86, 0.90, 0.96), 1)
	var blink: float = 0.7 + 0.3 * sin(t * 5.0)
	txt(Vector2(vs.x * 0.5, py + 132.0), "Enter / F / 手柄 A = 确认传送", 17, Color(0.7, 1.0, 0.8, blink), 1)
	txt(Vector2(vs.x * 0.5, py + 160.0), "Esc / Q / 手柄 B = 取消（留在本房间继续探索）", 15, Color(0.92, 0.86, 0.7), 1)


## 传送门交互提示（普通模式 / 训练房通用）
func _draw_tp_prompt(vs: Vector2) -> void:
	if game.dungeon == null or not is_instance_valid(game.dungeon) or game.player == null:
		return
	var cam: Vector2 = game.cam.get_screen_center_position() if game.cam != null else Vector2.ZERO
	# 楼层传送门（开启后常驻提示，按 F / 回车 进入下一关）
	if bool(game.dungeon.portal_open) and _room_visited_at(game.dungeon.portal_point):
		var pp0: Vector2 = game.dungeon.portal_point
		if pp0.distance_to(game.player.position + Vector2(0, -20.0)) <= 96.0:
			var ps0: Vector2 = pp0 - cam + vs * 0.5
			txt(Vector2(ps0.x, ps0.y - 80.0), "按 F / 回车（手柄 Y）进入下一关", 14, Color(0.65, 1.0, 0.78), 1)
	for i in range(game.dungeon.teleporters.size()):
		var tp: Dictionary = game.dungeon.teleporters[i]
		var tpw: Vector2 = tp["pos"]
		if tpw.distance_to(game.player.position + Vector2(0, -20.0)) > 62.0:
			continue
		var tsc: Vector2 = tpw - cam + vs * 0.5
		txt(Vector2(tsc.x, tsc.y - 70.0), "按 F（手柄 Y）传送 · " + str(tp["label"]), 13, Color(0.75, 0.95, 1.0), 1)


## 训练房：走廊展示台的名字与 T 拾取提示
func _draw_pedestals(vs: Vector2) -> void:
	if not game.training_mode:
		return
	if game.dungeon == null or not is_instance_valid(game.dungeon):
		return
	# 自愈：如果展示台没生成（例如读档/热重载后），就地补一次
	if game.dungeon.train_pedestals.size() == 0:
		game.fill_train_pedestals()
	var peds: Array = game.dungeon.train_pedestals
	if peds.size() == 0:
		return
	var cam: Vector2 = game.cam.get_screen_center_position() if game.cam != null else Vector2.ZERO
	for i in range(peds.size()):
		var pd: Dictionary = peds[i]
		var pos: Vector2 = pd["pos"]
		var scr: Vector2 = pos - cam + vs * 0.5
		if scr.x < -260.0 or scr.x > vs.x + 260.0 or scr.y < -200.0 or scr.y > vs.y + 200.0:
			continue
		var nm: String = str(pd["id"])
		var kind: String = str(pd["kind"])
		if kind == "weapon":
			var cat: int = int(pd.get("cat", 0))
			if cat == 0:
				nm = W.sword_name(str(pd["id"]))
			elif cat == 1:
				nm = W.gun_name(str(pd["id"]))
			else:
				nm = W.shield_name(str(pd["id"]))
		elif kind == "item":
			if game.items != null:
				nm = game.items.item_name(str(pd["id"]))
		elif kind == "skill":
			if game.skills != null:
				nm = game.skills.name_of(str(pd["id"]))
		var col: Color = pd["col"]
		var taken: bool = bool(pd["taken"])
		var label: String = "已拾取" if taken else nm
		var lw: float = fnt.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 12.0
		var ly: float = scr.y - 46.0
		# 名牌底衬，保证在亮背景上也看得清
		draw_rect(Rect2(scr.x - lw * 0.5, ly - 12.0, lw, 18.0), Color(0.03, 0.04, 0.07, 0.72))
		draw_rect(Rect2(scr.x - lw * 0.5, ly - 12.0, lw, 1.6), Color(col.r, col.g, col.b, 0.85))
		var tc: Color = Color(0.55, 0.55, 0.60) if taken else Color(col.r, col.g, col.b, 1.0)
		txt(Vector2(scr.x, ly + 1.0), label, 12, tc, 1)
		if i == int(game.near_pedestal):
			txt(Vector2(scr.x, ly - 22.0), "按 T 拾取", 12, Color(1.0, 0.94, 0.62), 1)
	# 传送门交互提示（走近才显示）
	var tps: Array = game.dungeon.teleporters
	for i in range(tps.size()):
		var tp: Dictionary = tps[i]
		var tpw: Vector2 = tp["pos"]
		var tsc: Vector2 = tpw - cam + vs * 0.5
		if tpw.distance_to(game.player.position + Vector2(0, -20.0)) <= 62.0:
			txt(Vector2(tsc.x, tsc.y - 70.0), "按 F 传送 · " + str(tp["label"]), 13, Color(0.75, 0.95, 1.0), 1)

func _draw_combo(vs: Vector2) -> void:
	var txt1: String = "累计伤害 %d" % int(game.total_damage)
	txt(Vector2(vs.x - 240.0, vs.y - 168.0), txt1, 13, Color(0.86, 0.86, 0.92), 0)
	if int(game.combo) > 1:
		var a: float = clampf(float(game.combo_timer) / 2.6, 0.0, 1.0)
		var sz: int = 18 + mini(int(game.combo) / 4, 14)
		txt(Vector2(vs.x - 240.0, vs.y - 186.0), "连击 %d" % int(game.combo), sz, Color(1.0, 0.86, 0.4, 0.5 + 0.5 * a), 0)


func _draw_banner(vs: Vector2) -> void:
	if game.banner_time <= 0.0:
		return
	var a: float = clampf(game.banner_time, 0.0, 1.0)
	if game.banner_time > 2.0:
		a = clampf(2.6 - game.banner_time, 0.0, 1.0)
	var y: float = vs.y * 0.28
	txt(Vector2(vs.x * 0.5, y), game.theme_name(), 50, Color(0.92, 0.88, 0.80, a), 1)
	txt(Vector2(vs.x * 0.5, y + 30.0), "第 %d 层 · %s" % [game.floor_index, game.theme_sub()], 15, Color(0.62, 0.85, 0.95, a * 0.9), 1)
	draw_rect(Rect2(vs.x * 0.5 - 120.0, y + 44.0, 240.0, 1.0), Color(0.85, 0.80, 0.68, a * 0.5))


func _draw_toasts(vs: Vector2) -> void:
	var y: float = vs.y - 136.0
	for i in range(toasts.size()):
		var tt: Dictionary = toasts[i]
		var lf: float = clampf(float(tt["life"]) / maxf(0.01, float(tt["max"])), 0.0, 1.0)
		var col: Color = tt["col"]
		var alpha: float = clampf(lf * 2.0, 0.0, 1.0)
		txt(Vector2(vs.x * 0.5, y - float(i) * 24.0), tt["text"], 18, Color(col.r, col.g, col.b, alpha), 1)


func _draw_crosshair() -> void:
	# 实时读取设置：关掉「显示准星」立刻隐藏（不再依赖缓存）
	if not bool(game.settings.get("crosshair", true)):
		return
	var mp: Vector2 = game.mouse_pos
	# 使用右摇杆时，准星跟随摇杆方向（世界 → 屏幕）
	if game.stick_aim and game.player != null and game.cam != null:
		var cc: Vector2 = game.cam.get_screen_center_position()
		mp = game.crosshair_world - cc + get_viewport_rect().size * 0.5
	var col := Color(0.75, 0.95, 1.0, 0.85)
	draw_arc(mp, 9.0, 0.0, TAU, 20, Color(col.r, col.g, col.b, 0.55), 1.5)
	draw_line(mp + Vector2(-14, 0), mp + Vector2(-5, 0), col, 1.5)
	draw_line(mp + Vector2(5, 0), mp + Vector2(14, 0), col, 1.5)
	draw_line(mp + Vector2(0, -14), mp + Vector2(0, -5), col, 1.5)
	draw_line(mp + Vector2(0, 5), mp + Vector2(0, 14), col, 1.5)
	draw_rect(Rect2(mp.x - 1.0, mp.y - 1.0, 2.0, 2.0), Color(1, 1, 1, 0.9))


# ---------------------------------------------------------------- 商店
## 商店升级行的点击区域（绘制与鼠标命中共用）
func shop_row_rect(i: int, vs: Vector2) -> Rect2:
	var w: float = 760.0
	var h: float = 430.0
	var bx: float = vs.x * 0.5 - w * 0.5
	var by: float = vs.y * 0.5 - h * 0.5
	return Rect2(bx + 40.0, by + 132.0 + float(i) * 50.0, w - 80.0, 42.0)


## 暂停菜单选项的点击区域（绘制与鼠标命中共用）
func pause_opt_rect(i: int, vs: Vector2) -> Rect2:
	var ry: float = vs.y * 0.38 + float(i) * 52.0
	return Rect2(vs.x * 0.5 - 170.0, ry - 26.0, 340.0, 44.0)


func _draw_shop(vs: Vector2) -> void:
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.01, 0.01, 0.03, 0.66))
	var w: float = 760.0
	var h: float = 430.0
	var bx: float = vs.x * 0.5 - w * 0.5
	var by: float = vs.y * 0.5 - h * 0.5
	panel(Rect2(bx, by, w, h), 0.86)
	txt(Vector2(vs.x * 0.5, by + 44.0), "金 币 商 店 · 强 化", 30, Color(0.94, 0.90, 0.82), 1)
	txt(Vector2(vs.x * 0.5, by + 70.0), "第 %d 层已通过 · 下一层怪物强度 ×%s" % [game.floor_index, _fmt_mult(game.stat_mult() * 2.0)], 14, Color(0.72, 0.68, 0.62), 1)

	# 金币
	draw_circle(Vector2(vs.x * 0.5 - 44.0, by + 102.0), 8.0, Color(0.95, 0.78, 0.30))
	draw_circle(Vector2(vs.x * 0.5 - 44.0, by + 102.0), 4.5, Color(1.0, 0.92, 0.6))
	txt(Vector2(vs.x * 0.5 - 28.0, by + 108.0), str(int(game.coins)), 22, C_GOLD)

	var kinds: Array = ["phys", "magic", "def", "hp", "mana"]
	var labels: Array = ["物理等级", "魔法等级", "防御等级", "生命等级", "法力等级"]
	for i in range(kinds.size()):
		var kind: String = str(kinds[i])
		var row_r: Rect2 = shop_row_rect(i, vs)
		var ry: float = row_r.position.y
		var hover: bool = row_r.has_point(game.mouse_pos)
		var cost: int = game.upgrade_cost(kind)
		var afford: bool = int(game.coins) >= cost
		var sel_row: bool = i == int(game.shop_sel) or hover
		draw_rect(row_r, Color(0.16, 0.22, 0.34, 0.95) if sel_row else Color(0.06, 0.07, 0.11, 0.75 if afford else 0.45))
		if i == int(game.shop_sel):
			draw_rect(Rect2(bx + 40.0, ry, w - 80.0, 2.5), Color(0.55, 0.88, 1.0, 0.95))
		elif hover:
			draw_rect(Rect2(bx + 40.0, ry, w - 80.0, 2.0), Color(0.55, 0.88, 1.0, 0.55))
		draw_rect(Rect2(bx + 40.0, ry, 3.0, 42.0), Color(0.5, 0.85, 1.0, 0.85) if afford else Color(0.4, 0.4, 0.4, 0.5))
		txt(Vector2(bx + 58.0, ry + 18.0), "[%d]  %s" % [i + 1, str(labels[i])], 17, Color(0.90, 0.88, 0.82) if afford else Color(0.55, 0.53, 0.5))
		txt(Vector2(bx + 58.0, ry + 35.0), "Lv.%d    %s" % [int(game.level_of(kind)), game.upgrade_desc(kind)], 12, Color(0.66, 0.72, 0.80))
		txt(Vector2(bx + w - 60.0, ry + 26.0), "%d 金币" % cost, 15, C_GOLD if afford else Color(0.55, 0.45, 0.35), 2)

	if game.shop_msg != "":
		txt(Vector2(vs.x * 0.5, by + h - 52.0), game.shop_msg, 15, Color(0.85, 0.92, 1.0), 1)
	var blink: float = 0.6 + 0.4 * sin(t * 4.0)
	txt(Vector2(vs.x * 0.5, by + h - 44.0), "↑↓ 选择    F 确认升级（或 1~5 直购）    回车 / 空格 下潜到第 %d 层" % (int(game.floor_index) + 1), 17, Color(0.95, 0.86, 0.62, blink), 1)
	txt(Vector2(vs.x * 0.5, by + h - 20.0), "手柄：十字键 ↑↓ 选择    → / X 确认升级    A 下潜    B 返回战斗", 13, Color(0.66, 0.86, 1.0), 1)


# ---------------------------------------------------------------- 全屏界面
func _draw_title(vs: Vector2) -> void:
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.02, 0.02, 0.04, 0.62))
	draw_rect(Rect2(0, vs.y * 0.5 - 130.0, vs.x, 260.0), Color(0.01, 0.01, 0.02, 0.35))
	var pulse: float = 0.85 + 0.15 * sin(t * 2.0)
	txt(Vector2(vs.x * 0.5, vs.y * 0.30), "逃 离 恶 魔 城", 66, Color(0.92, 0.90, 0.86, 0.96 * pulse), 1)
	txt(Vector2(vs.x * 0.5, vs.y * 0.355), "E S C A P E   F R O M   T H E   D E M O N   C A S T L E", 15, Color(0.62, 0.86, 0.98, 0.85), 1)
	txt(Vector2(vs.x * 0.5, vs.y * 0.39), "无 限 地 牢  ·  逃 出 去", 14, Color(0.95, 0.72, 0.62, 0.85), 1)
	draw_rect(Rect2(vs.x * 0.5 - 200.0, vs.y * 0.415, 400.0, 1.0), Color(0.8, 0.75, 0.65, 0.35))

	var lines: Array = [
		"移动 A/D 或 ←/→    跳跃 空格/W（角色自带二段跳）    下蹲 S    翻滚 Shift    喝药 Q    换弹 R",
		"长剑 左键/J    远程 右键/K（按住）    盾牌 中键/L（举盾瞬间命中＝弹反）    暂停 Esc    静音 N",
		"武器：短剑 / 长剑 / 唐刀 / 武士刀    弓 / 冲锋枪 / 步枪 / 加特林 / 狙击枪    铁盾 / 反伤盾 / 闪避盾",
		"遗物：飞剑 · 光环 · 魔导书 · 三种宠物 · 三种替身 · 魔法保护    宝箱与怪物都可能掉落",
		"Tab 图鉴        F4 存档界面        O 设置        T 训练房（游戏中先按 Esc 暂停）",
		"手柄：左摇杆 移动    右摇杆 瞄准    A 跳跃    B 翻滚    X 近战    RB 远程    LB 举盾    Y 交互/喝药",
		"手柄（在主界面和暂停时）：Y 训练场    X 存档    START 设置    A 开始游戏    十字键 ← 训练场 / → 开始",
	]
	for i in range(lines.size()):
		txt(Vector2(vs.x * 0.5, vs.y * 0.47 + float(i) * 24.0), lines[i], 13, Color(0.80, 0.78, 0.72, 0.9), 1)

	txt(Vector2(vs.x * 0.5, vs.y * 0.72), "每次死亡，地牢都会重新构筑。", 17, Color(0.88, 0.72, 0.72, 0.9), 1)
	if fmod(t, 1.4) < 0.85:
		txt(Vector2(vs.x * 0.5, vs.y * 0.80), "按 任 意 键 开 始 新 冒 险", 26, Color(1.0, 0.92, 0.75, 0.95), 1)
	txt(Vector2(vs.x * 0.5, vs.y - 48.0), "最深记录：第 %d 层        累计游玩：%s" % [int(game.best_floor), _fmt_clock(game.total_playtime)], 13, Color(0.6, 0.85, 0.65, 0.75), 1)
	if game.storage != null:
		var cnt: int = 0
		for i in range(game.slot_cache.size()):
			var dd: Dictionary = game.slot_cache[i]
			if not dd.is_empty():
				cnt += 1
		txt(Vector2(vs.x * 0.5, vs.y - 26.0), "可用存档：%d / 3 个（按 F4 打开存档界面）" % cnt, 13, Color(0.62, 0.72, 0.88, 0.8), 1)

	# 右下角按钮（鼠标可点）
	var mrect: Rect2 = title_menu_rect(vs)
	var qrect: Rect2 = title_quit_rect(vs)
	_draw_button(mrect, "存 档 / 读 档", Color(0.45, 0.82, 1.0), mrect.has_point(game.mouse_pos))
	var qlabel: String = "再 按 一 次 确 认" if game.quit_armed else "退  出  游  戏"
	_draw_button(qrect, qlabel, Color(1.0, 0.45, 0.42), qrect.has_point(game.mouse_pos))

	if show_crosshair:
		_draw_crosshair()


func _build_summary() -> Array:
	var out: Array = []
	if game.items != null and is_instance_valid(game.items):
		var s1: String = ""
		for i in range(game.items.order.size()):
			var iid: String = str(game.items.order[i])
			if s1 != "":
				s1 += "   "
			s1 += game.items.item_name(iid) + "×" + str(game.items.count_of(iid))
		if s1 != "":
			out.append("遗物：" + s1)
	if game.skills != null:
		var s2: String = ""
		for i in range(game.skills.order.size()):
			var sid: String = str(game.skills.order[i])
			if s2 != "":
				s2 += "   "
			s2 += ("+" if game.skills.is_good(sid) else "−") + game.skills.name_of(sid)
			if game.skills.count_of(sid) > 1:
				s2 += "×" + str(game.skills.count_of(sid))
		if s2 != "":
			out.append("技能：" + s2)
	if game.player != null and is_instance_valid(game.player):
		out.append("武器：%s · %s · %s" % [W.sword_name(game.player.sword_id), W.gun_name(game.player.ranged_id), W.shield_name(game.player.shield_id)])
	out.append("商店等级：物理 %d · 魔法 %d · 防御 %d · 生命 %d" % [int(game.phys_level), int(game.magic_level), int(game.defense_level), int(game.hp_level)])
	return out


func _draw_death(vs: Vector2) -> void:
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.12, 0.01, 0.02, 0.62))
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.0, 0.0, 0.0, 0.25))
	txt(Vector2(vs.x * 0.5, vs.y * 0.22), "你 死 了", 72, Color(0.85, 0.16, 0.18), 1)
	txt(Vector2(vs.x * 0.5, vs.y * 0.28), "YOU DIED", 17, Color(0.62, 0.24, 0.24), 1)
	var lines: Array = [
		"抵达楼层：第 %d 层 · %s" % [int(game.floor_index), game.theme_name()],
		"击杀敌人：%d        生存时间：%s" % [int(game.kills), _fmt_time(game.run_time)],
		"金币：%d      最深记录：第 %d 层" % [int(game.coins), int(game.best_floor)],
	]
	for i in range(lines.size()):
		txt(Vector2(vs.x * 0.5, vs.y * 0.37 + float(i) * 26.0), lines[i], 17, Color(0.82, 0.78, 0.72), 1)
	var summary: Array = _build_summary()
	for i in range(summary.size()):
		txt(Vector2(vs.x * 0.5, vs.y * 0.54 + float(i) * 22.0), str(summary[i]), 13, Color(0.72, 0.70, 0.80), 1)
	if fmod(t, 1.4) < 0.9:
		txt(Vector2(vs.x * 0.5, vs.y * 0.84), "按 R 重 生   （ 地 图 将 重 新 构 筑 ）", 23, Color(0.95, 0.85, 0.6), 1)
	txt(Vector2(vs.x * 0.5, vs.y * 0.90), "按 Tab 查看图鉴（收录永久保存）", 14, Color(0.66, 0.72, 0.86), 1)


func _draw_pause(vs: Vector2) -> void:
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.01, 0.01, 0.03, 0.72))
	txt(Vector2(vs.x * 0.5, vs.y * 0.24), "暂 停", 52, Color(0.9, 0.88, 0.82), 1)
	var opts: Array = ["继续游戏", "设置", "退回主界面", "存档界面", "退出游戏"]
	for i in range(opts.size()):
		var r: Rect2 = pause_opt_rect(i, vs)
		var hover: bool = r.has_point(game.mouse_pos)
		var sel: bool = i == int(game.pause_sel) or hover
		var tint: Color = Color(1.0, 0.45, 0.42) if i == opts.size() - 1 else Color(0.55, 0.88, 1.0)
		_draw_button(r, str(opts[i]), tint, sel)
	txt(Vector2(vs.x - 210.0, vs.y * 0.38), "↑↓ / 鼠标 选择", 14, Color(0.72, 0.72, 0.78), 1)
	txt(Vector2(vs.x - 210.0, vs.y * 0.38 + 26.0), "Enter / 点击 确认", 14, Color(0.72, 0.72, 0.78), 1)
	txt(Vector2(vs.x - 210.0, vs.y * 0.38 + 52.0), "Esc 继续", 14, Color(0.72, 0.72, 0.78), 1)
	txt(Vector2(vs.x - 210.0, vs.y * 0.38 + 96.0), "手柄：十字键 / A / B", 13, Color(0.60, 0.66, 0.80), 1)


func pause_quit_rect(vs: Vector2) -> Rect2:
	return Rect2(vs.x * 0.5 - 130.0, vs.y * 0.58, 260.0, 46.0)


func _fmt_clock(sec: float) -> String:
	var total: int = int(maxf(0.0, sec))
	var h: int = int(total / 3600)
	var m: int = int((total % 3600) / 60)
	var s: int = total % 60
	if h > 0:
		return "%d:%02d:%02d" % [h, m, s]
	return "%02d:%02d" % [m, s]


# ---------------------------------------------------------------- 单件遗物询问
func _draw_pickup_item(vs: Vector2) -> void:
	var iid: String = str(game.pending_weapon.get("id", ""))
	if iid == "" or game.items == null:
		return
	var nm: String = game.items.item_name(iid)
	var ds: String = game.items.item_desc(iid)
	var col: Color = game.items.item_col(iid)
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.02, 0.02, 0.04, 0.70))
	var pw: float = 660.0
	var ph: float = 260.0
	var px: float = vs.x * 0.5 - pw * 0.5
	var py: float = vs.y * 0.5 - ph * 0.5
	panel(Rect2(px, py, pw, ph), 0.94)
	draw_rect(Rect2(px, py, pw, 3.0), Color(col.r, col.g, col.b, 0.9))
	txt(Vector2(px + 28.0, py + 42.0), "发现遗物", 24, Color(0.94, 0.92, 0.86))
	_draw_item_icon(Vector2(px + 60.0, py + 106.0), iid, col)
	txt(Vector2(px + 96.0, py + 100.0), nm, 24, Color(col.r, col.g, col.b, 0.98))
	_draw_wrapped(Vector2(px + 30.0, py + 150.0), ds, pw - 60.0, 15, Color(0.80, 0.78, 0.74))
	var blink: float = 0.7 + 0.3 * sin(t * 5.0)
	txt(Vector2(vs.x * 0.5, py + ph - 34.0), "E / 回车 = 拾取        Q / Esc = 放弃", 18, Color(0.95, 0.90, 0.72, blink), 1)


# ---------------------------------------------------------------- 翅膀遗物替换询问
func _draw_pickup_relic(vs: Vector2) -> void:
	var nid: String = str(game.pending_weapon.get("id", ""))
	var oid: String = str(game.pending_weapon.get("old", ""))
	if nid == "":
		return
	var items = game.items
	var nm: String = items.item_name(nid)
	var om: String = items.item_name(oid)
	var nc: Color = items.item_col(nid)
	var oc: Color = items.item_col(oid)
	var nd: String = items.item_desc(nid)
	var od: String = items.item_desc(oid)

	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.02, 0.02, 0.04, 0.72))
	var pw: float = 760.0
	var ph: float = 400.0
	var px: float = vs.x * 0.5 - pw * 0.5
	var py: float = vs.y * 0.5 - ph * 0.5
	panel(Rect2(px, py, pw, ph), 0.94)
	draw_rect(Rect2(px, py, pw, 3.0), Color(1.0, 0.92, 0.62, 0.9))

	txt(Vector2(px + 30.0, py + 42.0), "发 现 新 遗 物", 26, Color(0.94, 0.92, 0.86))
	txt(Vector2(px + 30.0, py + 68.0), "你已经有另一种翅膀了（飞行类遗物互斥），是否替换？", 13, Color(0.66, 0.70, 0.78))

	# 左：新  右：当前
	draw_rect(Rect2(px + 24.0, py + 90.0, 340.0, 150.0), Color(0.07, 0.08, 0.12, 0.85))
	_draw_item_icon(Vector2(px + 60.0, py + 128.0), nid, nc)
	txt(Vector2(px + 90.0, py + 124.0), "新：" + nm, 19, Color(0.96, 0.94, 0.86))
	txt(Vector2(px + 90.0, py + 150.0), "按键 E / 回车 换上", 13, Color(0.62, 0.72, 0.85))
	_draw_wrap_chars_center(Vector2(px + 194.0, py + 176.0), nd, 5, 13, Color(0.80, 0.78, 0.74), 4)

	draw_rect(Rect2(px + 396.0, py + 90.0, 340.0, 150.0), Color(0.05, 0.06, 0.09, 0.85))
	_draw_item_icon(Vector2(px + 432.0, py + 128.0), oid, oc)
	txt(Vector2(px + 462.0, py + 124.0), "当前：" + om, 19, Color(0.86, 0.84, 0.78))
	txt(Vector2(px + 462.0, py + 150.0), "按键 Q / Esc 保留", 13, Color(0.72, 0.72, 0.78))
	_draw_wrap_chars_center(Vector2(px + 566.0, py + 176.0), od, 5, 13, Color(0.72, 0.72, 0.76), 4)

	var blink: float = 0.7 + 0.3 * sin(t * 5.0)
	txt(Vector2(vs.x * 0.5, py + ph - 70.0), "两种翅膀都能飞行：按住跳跃持续上升", 14, Color(0.66, 0.85, 0.95), 1)
	txt(Vector2(vs.x * 0.5, py + ph - 40.0), "E / 回车 = 替换        Q / Esc = 保留当前", 18, Color(0.95, 0.90, 0.72, blink), 1)

# ---------------------------------------------------------------- 训练房配置
func _draw_train_cfg(vs: Vector2) -> void:
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.02, 0.02, 0.04, 0.94))
	txt(Vector2(vs.x * 0.5, 46.0), "训 练 房 间", 32, Color(0.94, 0.90, 0.82), 1)
	txt(Vector2(vs.x * 0.5, 70.0), "木桩血量无限 · 自由搭配装备 / 技能 / 遗物", 12, Color(0.58, 0.62, 0.70), 1)

	var tabs: Array = ["装备", "技能", "遗物", "木桩", "等级"]
	var tw: float = 118.0
	var tx0: float = vs.x * 0.5 - tw * 2.5
	for i in range(tabs.size()):
		var bx: float = tx0 + float(i) * tw
		var on: bool = i == int(game.train_tab)
		draw_rect(Rect2(bx + 4.0, 84.0, tw - 8.0, 32.0), Color(0.10, 0.13, 0.19, 0.95) if on else Color(0.04, 0.04, 0.06, 0.85))
		draw_rect(Rect2(bx + 4.0, 84.0, tw - 8.0, 2.0), Color(0.55, 0.88, 1.0, 0.95) if on else Color(0.30, 0.30, 0.36, 0.6))
		txt(Vector2(bx + tw * 0.5, 105.0), "[%d] %s" % [i + 1, str(tabs[i])], 16 if on else 14,
			Color(0.95, 0.93, 0.86) if on else Color(0.60, 0.60, 0.63), 1)

	var list: Array = game.train_entries()
	var rows: int = 13
	var start: int = 0
	if int(game.train_idx) >= rows:
		start = int(game.train_idx) - rows + 1
	var lx: float = 60.0
	var ly: float = 146.0
	draw_rect(Rect2(lx - 10.0, ly - 22.0, 470.0, float(rows) * 30.0 + 30.0), Color(0.03, 0.03, 0.05, 0.75))
	for r in range(rows):
		var k: int = start + r
		if k >= list.size():
			break
		var e: Dictionary = list[k]
		var sel: bool = k == int(game.train_idx)
		var ry: float = ly + float(r) * 30.0
		if sel:
			draw_rect(Rect2(lx - 8.0, ry - 18.0, 466.0, 27.0), Color(0.12, 0.16, 0.24, 0.95))
			draw_rect(Rect2(lx - 8.0, ry - 18.0, 3.0, 27.0), Color(0.55, 0.88, 1.0))
		var mult: int = int(e.get("count", 1)) if bool(e["on"]) else 0
		var mark: String = ("●×%d" % mult) if mult > 1 else ("●" if bool(e["on"]) else "○")
		txt(Vector2(lx, ry), mark, 13, Color(0.55, 1.0, 0.65) if bool(e["on"]) else Color(0.42, 0.42, 0.48), 0)
		var cc: Color = e["col"]
		draw_rect(Rect2(lx + 46.0, ry - 11.0, 10.0, 10.0), Color(cc.r, cc.g, cc.b, 0.9))
		txt(Vector2(lx + 66.0, ry), str(e["name"]), 15, Color(0.92, 0.90, 0.84) if bool(e["on"]) else Color(0.78, 0.78, 0.80), 0)
		if str(e.get("kind", "")) == "level":
			txt(Vector2(lx + 430.0, ry), "当前 %d 级    ← → 调整" % int(e.get("count", 0)), 12, Color(0.66, 0.86, 1.0), 2)

	# 右侧详情
	var dx: float = 570.0
	var dw: float = vs.x - dx - 50.0
	draw_rect(Rect2(dx, ly - 22.0, dw, float(rows) * 30.0 + 30.0), Color(0.03, 0.03, 0.05, 0.78))
	if list.size() > 0:
		var cur: Dictionary = list[clampi(int(game.train_idx), 0, list.size() - 1)]
		txt(Vector2(dx + 24.0, ly + 14.0), str(cur["name"]), 24, Color(0.95, 0.92, 0.84), 0)
		var kind_txt: String = "武器"
		if str(cur["kind"]) == "skill":
			kind_txt = "技能"
		elif str(cur["kind"]) == "item":
			kind_txt = "遗物"
		elif str(cur["kind"]) == "dummy":
			kind_txt = "木桩"
		txt(Vector2(dx + 24.0, ly + 40.0), kind_txt + ("  · 已选择" if bool(cur["on"]) else "  · 未选择"), 13, Color(0.62, 0.76, 0.9), 0)
		_draw_wrapped(Vector2(dx + 24.0, ly + 76.0), str(cur["desc"]), dw - 48.0, 15, Color(0.80, 0.78, 0.74))

	# 当前搭配
	var loadout: String = "当前：%s / %s / %s　技能 %d 个　遗物 %d 个　木桩：%s" % [
		W.sword_name(str(game.train_sword)), W.gun_name(str(game.train_ranged)),
		W.shield_name(str(game.train_shield)), game.train_skills.size(), game.train_items.size(), str(game.train_dummy)]
	txt(Vector2(vs.x * 0.5, vs.y - 78.0), loadout, 13, Color(0.72, 0.86, 1.0), 1)
	txt(Vector2(vs.x * 0.5, vs.y - 30.0), "手柄：十字键选择    LB/RB 翻页    LT/RT 调数量    ← 开始    A 选择    B 返回", 13, Color(0.66, 0.84, 1.0), 1)

# ---------------------------------------------------------------- 存档界面
func _draw_saves(vs: Vector2) -> void:
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.02, 0.02, 0.04, 0.90))
	txt(Vector2(vs.x * 0.5, 62.0), "存  档", 36, Color(0.94, 0.90, 0.82), 1)
	txt(Vector2(vs.x * 0.5, 88.0), "共 3 个槽位 · 存档记录楼层 / 金币 / 装备 / 遗物 / 游玩时间", 12, Color(0.58, 0.60, 0.68), 1)
	txt(Vector2(vs.x * 0.5, 110.0), "累计游玩时间 " + _fmt_clock(game.total_playtime), 14, Color(0.72, 0.85, 0.95), 1)

	var px: float = vs.x * 0.5 - 450.0
	for i in range(3):
		var sr: Rect2 = slot_rect(i, vs)
		var sy: float = sr.position.y
		var sel: bool = i == int(game.menu_index)
		var d: Dictionary = {}
		if i < game.slot_cache.size():
			d = game.slot_cache[i]
		var has: bool = not d.is_empty()
		draw_rect(sr, Color(0.10, 0.13, 0.20, 0.95) if sel else Color(0.05, 0.06, 0.09, 0.9))
		draw_rect(Rect2(sr.position.x, sr.position.y, 4.0, sr.size.y), Color(0.55, 0.88, 1.0) if sel else Color(0.30, 0.32, 0.40))
		txt(Vector2(px + 22.0, sy + 34.0), "存档 %d" % (i + 1), 22, Color(0.94, 0.92, 0.86) if has else Color(0.55, 0.55, 0.60))
		if not has:
			txt(Vector2(px + 150.0, sy + 34.0), "—— 空槽位 ——", 16, Color(0.45, 0.45, 0.52))
			continue
		var fl: int = int(d.get("floor", 1))
		var tm: float = float(d.get("run_time", 0.0))
		var cn: int = int(d.get("coins", 0))
		var sw: String = str(d.get("sword", "long"))
		var rg: String = str(d.get("ranged", "bow"))
		var sh: String = str(d.get("shield", "iron"))
		var played: float = float(d.get("playtime", 0.0))
		txt(Vector2(px + 150.0, sy + 32.0), "第 %d 层" % fl, 20, Color(0.85, 0.95, 1.0))
		txt(Vector2(px + 260.0, sy + 32.0), "游玩 " + _fmt_clock(tm), 17, Color(0.88, 0.86, 0.78))
		txt(Vector2(px + 430.0, sy + 32.0), "金币 %d" % cn, 17, C_GOLD)
		txt(Vector2(px + 22.0, sy + 62.0), "装备：%s / %s / %s" % [W.sword_name(sw), W.gun_name(rg), W.shield_name(sh)], 15, Color(0.74, 0.80, 0.90))
		txt(Vector2(px + 22.0, sy + 84.0), "保存于 %s    累计游玩 %s" % [str(d.get("saved_at", "-")), _fmt_clock(played)], 12, Color(0.52, 0.54, 0.60))

	txt(Vector2(vs.x * 0.5, vs.y - 92.0), "↑↓ 选择槽位      Enter 读取      S / F5 保存到该槽      Del 删除      Esc 返回", 15, Color(0.86, 0.86, 0.90), 1)
	txt(Vector2(vs.x * 0.5, vs.y - 66.0), "手柄：十字键选择    A 读取    Y 保存    B 返回", 13, Color(0.62, 0.80, 0.95), 1)
	if game.menu_msg != "":
		txt(Vector2(vs.x * 0.5, vs.y - 62.0), str(game.menu_msg), 15, Color(0.85, 0.95, 1.0), 1)
	if not game.run_active:
		txt(Vector2(vs.x * 0.5, vs.y - 36.0), "（当前没有进行中的冒险：只能读取存档）", 13, Color(0.80, 0.66, 0.55), 1)


# ---------------------------------------------------------------- 设置界面
func settings_row_rect(i: int, vs: Vector2) -> Rect2:
	var pw: float = 760.0
	var px: float = vs.x * 0.5 - pw * 0.5
	return Rect2(px, 130.0 + float(i) * 52.0, pw, 46.0)


func slot_rect(i: int, vs: Vector2) -> Rect2:
	var pw: float = 900.0
	var px: float = vs.x * 0.5 - pw * 0.5
	return Rect2(px, 140.0 + float(i) * 116.0, pw, 100.0)


func title_quit_rect(vs: Vector2) -> Rect2:
	return Rect2(vs.x - 224.0, vs.y - 56.0, 186.0, 38.0)


func title_menu_rect(vs: Vector2) -> Rect2:
	return Rect2(vs.x - 224.0, vs.y - 102.0, 186.0, 38.0)


func _draw_button(r: Rect2, label: String, tint: Color, hover: bool) -> void:
	draw_rect(r, Color(tint.r, tint.g, tint.b, 0.30 if hover else 0.16))
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 2.0), Color(tint.r, tint.g, tint.b, 0.95 if hover else 0.6))
	txt(Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.5 + 6.0), label, 16,
		Color(0.96, 0.94, 0.90) if hover else Color(0.82, 0.82, 0.86), 1)


func _draw_settings(vs: Vector2) -> void:
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.02, 0.02, 0.04, 0.93))
	txt(Vector2(vs.x * 0.5, 54.0), "设  置", 34, Color(0.94, 0.90, 0.82), 1)
	txt(Vector2(vs.x * 0.5, 78.0), "改动立即生效并自动保存 · F11 快速切换全屏", 12, Color(0.58, 0.60, 0.68), 1)

	var labels: Array = ["音效音量", "屏幕震动", "全屏显示", "分辨率", "帧率上限", "显示帧数", "画面质量", "显示准星", "按键 / 手柄设置", "自动瞄准", "摇杆瞄准", "准星瞄准", "自定义按键", "退出游戏"]
	var s: Dictionary = game.settings
	for i in range(labels.size()):
		var r: Rect2 = settings_row_rect(i, vs)
		var sel: bool = i == int(game.settings_index)
		var quit_row: bool = i == 13
		var bg: Color = Color(0.10, 0.13, 0.20, 0.95) if sel else Color(0.05, 0.06, 0.09, 0.9)
		if quit_row:
			bg = Color(0.32, 0.09, 0.11, 0.95) if sel else Color(0.17, 0.06, 0.08, 0.9)
		draw_rect(r, bg)
		var accent: Color = Color(1.0, 0.45, 0.42) if quit_row else Color(0.55, 0.88, 1.0)
		draw_rect(Rect2(r.position.x, r.position.y, 4.0, r.size.y), accent if sel else Color(0.30, 0.32, 0.40))
		if quit_row:
			var qtxt: String = "再 按 一 次 确 认 退 出" if game.quit_armed else "退   出   游   戏"
			txt(Vector2(r.position.x + r.size.x * 0.5, r.position.y + 30.0), qtxt, 19, Color(1.0, 0.64, 0.60), 1)
			continue
		txt(Vector2(r.position.x + 24.0, r.position.y + 30.0), str(labels[i]), 19, Color(0.92, 0.90, 0.84))
		var val: String = ""
		if i == 0:
			val = "%d%%" % int(round(float(s.get("volume", 0.8)) * 100.0))
		elif i == 1:
			val = "%d%%" % int(round(float(s.get("shake", 1.0)) * 100.0))
		elif i == 2:
			val = "全屏" if bool(s.get("fullscreen", false)) else "窗口"
		elif i == 3:
			val = game.res_name()
		elif i == 4:
			val = game.fps_name()
			if int(s.get("fps", 1)) < 4:
				val += " FPS"
		elif i == 5:
			val = "开" if bool(s.get("show_fps", false)) else "关"
		elif i == 6:
			val = game.quality_name()
		elif i == 7:
			val = "开" if bool(s.get("crosshair", true)) else "关"
		elif i == 8:
			val = "按 9 进入"
		elif i == 9:
			val = "开" if bool(s.get("autoaim", false)) else "关"
		elif i == 10:
			val = "开" if bool(s.get("stickaim", true)) else "关"
		elif i == 11:
			val = "开" if bool(s.get("mouseaim", true)) else "关"
		elif i == 12:
			val = "开" if bool(s.get("customkeys", true)) else "关"
		else:
			val = ""
		txt(Vector2(r.position.x + r.size.x - 24.0, r.position.y + 30.0), val, 19, Color(0.78, 0.95, 1.0), 2)
		if i == 0 or i == 1:
			var v: float = clampf(float(s.get("volume", 0.8)), 0.0, 1.0)
			if i == 1:
				v = clampf(float(s.get("shake", 1.0)) / 2.0, 0.0, 1.0)
			var bx: float = r.position.x + r.size.x * 0.30
			var bw: float = r.size.x * 0.5
			draw_rect(Rect2(bx, r.position.y + 19.0, bw, 8.0), Color(0.03, 0.04, 0.06, 0.9))
			draw_rect(Rect2(bx, r.position.y + 19.0, bw * v, 8.0), Color(0.45, 0.82, 1.0, 0.85))
			draw_rect(Rect2(bx + bw * v - 2.0, r.position.y + 16.0, 4.0, 14.0), Color(0.92, 0.97, 1.0))


	# 右侧：按键提示（竖排，避开中间设置行）
	var hint_x: float = vs.x - 176.0
	var hint_y: float = vs.y * 0.5 - 70.0
	var hints: Array = ["↑↓  选择", "←→  调整", "Enter 确认/切换", "Esc  返回"]
	for hi2 in range(hints.size()):
		txt(Vector2(hint_x, hint_y + float(hi2) * 26.0), str(hints[hi2]), 13, Color(0.72, 0.80, 0.92), 0)
	# 左侧：画质 / 分辨率总结（竖排，位于设置行左外侧）
	var sum_x: float = 30.0
	var sum_y: float = vs.y * 0.5 - 70.0
	var sums: Array = ["画质：" + game.quality_name(), "分辨率：" + game.res_name(), "帧率：" + game.fps_name()]
	for si2 in range(sums.size()):
		txt(Vector2(sum_x, sum_y + float(si2) * 24.0), str(sums[si2]), 13, Color(0.66, 0.86, 1.0), 0)
	if game.menu_msg != "":
		txt(Vector2(vs.x * 0.5, vs.y - 28.0), str(game.menu_msg), 15, Color(0.95, 0.82, 0.55), 1)


# ---------------------------------------------------------------- 武器拾取询问
func _weapon_rows(cat: int, id: String) -> Array:
	var rows: Array = []
	if cat == 0:
		var d: Dictionary = W.sword(id)
		var dm: Array = d["dmg"]
		var du: Array = d["dur"]
		rows.append({"label": "伤害", "val": "%d / %d / %d" % [int(dm[0]), int(dm[1]), int(dm[2])], "num": float(dm[0]) + float(dm[1]) + float(dm[2])})
		rows.append({"label": "范围", "val": str(int(d["reach"])), "num": float(d["reach"])})
		rows.append({"label": "出手耗时", "val": "%.2f 秒" % float(du[0]), "num": 1.0 / maxf(0.05, float(du[0]))})
	elif cat == 1:
		var g: Dictionary = W.gun(id)
		var gd: Array = g["dmg"]
		var am: int = int(g["ammo"])
		var rl: float = float(g["reload"])
		rows.append({"label": "单发伤害", "val": str(int(gd[1])) if str(g["mode"]) == "charge" else str(int(gd[0])), "num": (float(gd[1]) if str(g["mode"]) == "charge" else float(gd[0]))})
		rows.append({"label": "弹药", "val": ("无限" if am <= 0 else str(am)), "num": (9999.0 if am <= 0 else float(am))})
		rows.append({"label": "换弹", "val": ("—" if rl <= 0.0 else "%.1f 秒" % rl), "num": (0.0 if rl <= 0.0 else 1.0 / rl)})
	else:
		var s: Dictionary = W.shield(id)
		rows.append({"label": "效果", "val": str(s["desc"]), "num": 0.0})
	return rows


func _draw_pickup(vs: Vector2) -> void:
	var pk: String = str(game.pending_weapon.get("kind", "weapon"))
	if pk == "relic":
		_draw_pickup_relic(vs)
		return
	if pk == "item":
		_draw_pickup_item(vs)
		return
	var cat: int = int(game.pending_weapon.get("cat", 0))
	var nid: String = str(game.pending_weapon.get("id", ""))
	var pl = game.player
	if pl == null or nid == "":
		return
	var cid: String = pl.sword_id
	var cname: String = W.sword_name(cid)
	var nname: String = W.sword_name(nid)
	var cat_name: String = "剑"
	if cat == 1:
		cid = pl.ranged_id
		cname = W.gun_name(cid)
		nname = W.gun_name(nid)
		cat_name = "远程"
	elif cat == 2:
		cid = pl.shield_id
		cname = W.shield_name(cid)
		nname = W.shield_name(nid)
		cat_name = "盾牌"

	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.02, 0.02, 0.04, 0.72))
	var pw: float = 720.0
	var ph: float = 400.0
	var px: float = vs.x * 0.5 - pw * 0.5
	var py: float = vs.y * 0.5 - ph * 0.5
	panel(Rect2(px, py, pw, ph), 0.94)
	draw_rect(Rect2(px, py, pw, 3.0), Color(0.55, 0.88, 1.0, 0.9))

	txt(Vector2(px + 30.0, py + 42.0), "发 现 新 武 器", 26, Color(0.94, 0.92, 0.86))
	txt(Vector2(px + 30.0, py + 70.0), "类别：" + cat_name + "        是否替换当前装备？", 14, Color(0.66, 0.70, 0.78))

	draw_rect(Rect2(px + 30.0, py + 92.0, 92.0, 92.0), Color(0.06, 0.07, 0.10, 0.95))
	_draw_weapon_icon(Vector2(px + 76.0, py + 130.0), nid)
	txt(Vector2(px + 136.0, py + 124.0), nname, 26, Color(0.92, 0.96, 1.0))
	txt(Vector2(px + 136.0, py + 156.0), "当前：" + cname, 15, Color(0.78, 0.76, 0.70))

	# 属性对比
	if cat != 2:
		var cur_rows: Array = _weapon_rows(cat, cid)
		var new_rows: Array = _weapon_rows(cat, nid)
		var hy: float = py + 206.0
		txt(Vector2(px + 130.0, hy), "属性", 14, Color(0.60, 0.64, 0.72))
		txt(Vector2(px + 380.0, hy), "当前", 14, Color(0.60, 0.64, 0.72), 1)
		txt(Vector2(px + 540.0, hy), "新", 14, Color(0.60, 0.64, 0.72), 1)
		for i in range(new_rows.size()):
			var ry: float = hy + 30.0 + float(i) * 34.0
			var nr: Dictionary = new_rows[i]
			var cr: Dictionary = cur_rows[i]
			draw_rect(Rect2(px + 24.0, ry - 22.0, pw - 48.0, 30.0), Color(0.07, 0.08, 0.12, 0.75) if i % 2 == 0 else Color(0.05, 0.06, 0.09, 0.6))
			txt(Vector2(px + 34.0, ry), str(nr["label"]), 16, Color(0.80, 0.80, 0.84))
			txt(Vector2(px + 380.0, ry), str(cr["val"]), 16, Color(0.74, 0.76, 0.82), 1)
			txt(Vector2(px + 540.0, ry), str(nr["val"]), 16, Color(0.92, 0.96, 1.0), 1)
			var cn2: float = float(cr["num"])
			var nn2: float = float(nr["num"])
			if cn2 > 0.0 and nn2 > 0.0 and absf(nn2 - cn2) > 0.001:
				if nn2 > cn2:
					txt(Vector2(px + 620.0, ry), "↑ 提升", 15, Color(0.55, 1.0, 0.65))
				else:
					txt(Vector2(px + 620.0, ry), "↓ 降低", 15, Color(1.0, 0.55, 0.55))

	# 盾牌 / 护甲：描述按 5 字换行并居中
	# 盾牌 / 护甲：介绍文字按 5 字换行并居中（与属性区分离，避免重叠）
	if cat == 2:
		var ndesc: String = str(W.shield(nid).get("desc", ""))
		var odesc: String = str(W.shield(cid).get("desc", ""))
		txt(Vector2(px + 200.0, py + 218.0), "新：" + nname, 15, Color(0.90, 0.93, 1.0), 1)
		txt(Vector2(px + 540.0, py + 218.0), "当前：" + cname, 15, Color(0.78, 0.80, 0.86), 1)
		_draw_wrap_chars_center(Vector2(px + 200.0, py + 246.0), ndesc, 5, 14, Color(0.90, 0.92, 0.98), 4)
		_draw_wrap_chars_center(Vector2(px + 540.0, py + 246.0), odesc, 5, 14, Color(0.74, 0.76, 0.82), 4)
	var blink: float = 0.7 + 0.3 * sin(t * 5.0)
	txt(Vector2(vs.x * 0.5, py + ph - 40.0), "E / 回车 = 替换装备        Q / Esc = 保留当前", 18, Color(0.95, 0.90, 0.72, blink), 1)


# ---------------------------------------------------------------- 按键设置
func _draw_keys(vs: Vector2) -> void:
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.01, 0.01, 0.03, 0.96))
	txt(Vector2(vs.x * 0.5, 46.0), "按 键 设 置", 32, Color(0.94, 0.90, 0.82), 1)

	# 两个标签页：键盘 / 手柄
	var tab_names: Array = ["键盘", "手柄（Xbox）"]
	for i in range(2):
		var on: bool = i == int(game.keys_tab)
		var bx: float = vs.x * 0.5 - 210.0 + float(i) * 220.0
		draw_rect(Rect2(bx, 70.0, 200.0, 34.0), Color(0.10, 0.13, 0.19, 0.95) if on else Color(0.04, 0.05, 0.08, 0.85))
		draw_rect(Rect2(bx, 70.0, 200.0, 2.5), Color(0.55, 0.88, 1.0) if on else Color(0.25, 0.27, 0.34))
		txt(Vector2(bx + 100.0, 92.0), str(tab_names[i]), 17, Color(0.95, 0.93, 0.86) if on else Color(0.60, 0.62, 0.66), 1)

	txt(Vector2(vs.x * 0.5, 124.0), "← → 切换页面     ↑↓ 选择动作     Enter 重新绑定（按新键）     Backspace 恢复默认     Esc 返回", 13, Color(0.62, 0.66, 0.76), 1)

	var acts: Array = game.actions()
	var row_h: float = 34.0
	var top: float = 152.0
	for i in range(acts.size()):
		var a: String = str(acts[i])
		var ry: float = top + float(i) * row_h
		var sel: bool = i == int(game.keys_index)
		draw_rect(Rect2(vs.x * 0.5 - 340.0, ry - 22.0, 680.0, row_h - 4.0),
			Color(0.10, 0.13, 0.19, 0.95) if sel else Color(0.04, 0.05, 0.08, 0.85))
		draw_rect(Rect2(vs.x * 0.5 - 340.0, ry - 22.0, 4.0, row_h - 4.0),
			Color(0.55, 0.88, 1.0) if sel else Color(0.25, 0.27, 0.34))
		txt(Vector2(vs.x * 0.5 - 316.0, ry), game.action_name(a), 17, Color(0.90, 0.89, 0.84))
		var txtv: String = "—"
		if int(game.keys_tab) == 0:
			var ks: Array = game.keys_cfg.get(a, [])
			if ks.size() > 0:
				txtv = game.key_name(int(ks[0]))
			if sel and game.capturing:
				txtv = "请按下键盘按键…"
		else:
			var bs: Array = game.pad_cfg.get(a, [])
			if bs.size() > 0:
				txtv = game.pad_name(int(bs[0]))
			if sel and game.capturing:
				txtv = "请按下手柄按键…"
		txt(Vector2(vs.x * 0.5 + 150.0, ry), txtv, 17,
			Color(1.0, 0.92, 0.62) if (sel and game.capturing) else Color(0.82, 0.92, 1.0), 1)

	var tip: String = "手柄布局按 Xbox：A 跳 / X 近战 / RB 远程 / LB 举盾 / B 翻滚 / Y 喝药 / BACK 换弹 / 十字键或左摇杆移动"
	txt(Vector2(vs.x * 0.5, vs.y - 34.0), tip, 13, Color(0.66, 0.72, 0.86), 1)
# ---------------------------------------------------------------- 图鉴
func _draw_codex(vs: Vector2) -> void:
	if game.codex == null:
		return
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color(0.01, 0.01, 0.03, 0.94))
	txt(Vector2(vs.x * 0.5, 50.0), "图  鉴", 34, Color(0.94, 0.90, 0.82), 1)
	txt(Vector2(vs.x * 0.5, 74.0), "遇到过 / 拿到过就会自动收录，记录保存在本地", 12, Color(0.58, 0.60, 0.68), 1)

	var n_cats: int = game.codex.cat_count()
	var tab_w: float = 158.0
	var tx0: float = vs.x * 0.5 - tab_w * float(n_cats) * 0.5
	for i in range(n_cats):
		var bx: float = tx0 + float(i) * tab_w
		var on: bool = i == int(game.codex_tab)
		var cat: String = game.codex.cat_id(i)
		var sc: int = game.codex.seen_count(cat)
		var tc: int = game.codex.total_count(cat)
		draw_rect(Rect2(bx + 4.0, 94.0, tab_w - 8.0, 34.0),
			Color(0.10, 0.13, 0.19, 0.95) if on else Color(0.04, 0.04, 0.06, 0.85))
		draw_rect(Rect2(bx + 4.0, 94.0, tab_w - 8.0, 2.0),
			Color(0.55, 0.88, 1.0, 0.95) if on else Color(0.30, 0.30, 0.36, 0.6))
		txt(Vector2(bx + tab_w * 0.5, 116.0),
			"[%d] %s  %d/%d" % [i + 1, game.codex.cat_name(i), sc, tc], 15,
			Color(0.95, 0.93, 0.86) if on else Color(0.60, 0.60, 0.63), 1)

	var cat2: String = game.codex.cat_id(int(game.codex_tab))
	var list: Array = game.codex.entries(cat2)
	var rows: int = 12
	var idx: int = clampi(int(game.codex_index), 0, maxi(0, list.size() - 1))
	var start: int = 0
	if idx >= rows:
		start = idx - rows + 1
	var lx: float = 70.0
	var ly: float = 158.0
	draw_rect(Rect2(lx - 10.0, ly - 20.0, 396.0, float(rows) * 32.0 + 28.0), Color(0.03, 0.03, 0.05, 0.75))
	for r in range(rows):
		var k: int = start + r
		if k >= list.size():
			break
		var e: Dictionary = list[k]
		var known: bool = game.codex.is_seen(cat2, str(e["id"]))
		var sel: bool = k == idx
		var ry: float = ly + float(r) * 32.0
		if sel:
			draw_rect(Rect2(lx - 8.0, ry - 19.0, 392.0, 30.0), Color(0.12, 0.16, 0.24, 0.95))
			draw_rect(Rect2(lx - 8.0, ry - 19.0, 3.0, 30.0), Color(0.55, 0.88, 1.0))
		var label: String = str(e["name"]) if known else "？？？"
		txt(Vector2(lx + 6.0, ry), label, 16, Color(0.92, 0.90, 0.84) if known else Color(0.42, 0.42, 0.48), 0)

	var dx: float = 500.0
	var dw: float = vs.x - dx - 66.0
	draw_rect(Rect2(dx, ly - 20.0, dw, float(rows) * 32.0 + 28.0), Color(0.03, 0.03, 0.05, 0.78))
	if list.size() > 0:
		var e2: Dictionary = list[idx]
		var known2: bool = game.codex.is_seen(cat2, str(e2["id"]))
		draw_rect(Rect2(dx + 26.0, ly + 10.0, 96.0, 96.0), Color(0.06, 0.07, 0.10, 0.92))
		draw_rect(Rect2(dx + 26.0, ly + 10.0, 96.0, 2.0), Color(0.45, 0.55, 0.7, 0.6))
		_draw_codex_icon(Vector2(dx + 74.0, ly + 58.0), cat2, str(e2["id"]), e2["col"], known2)
		txt(Vector2(dx + 142.0, ly + 44.0), str(e2["name"]) if known2 else "？？？", 26,
			Color(0.95, 0.92, 0.84) if known2 else Color(0.45, 0.45, 0.50), 0)
		txt(Vector2(dx + 142.0, ly + 72.0), str(e2["extra"]) if known2 else "未收录", 13, Color(0.62, 0.72, 0.85), 0)
		var desc: String = str(e2["desc"]) if known2 else "尚未遇到或获得，遇到后会自动记录。"
		_draw_wrapped(Vector2(dx + 30.0, ly + 140.0), desc, dw - 60.0, 16, Color(0.80, 0.78, 0.74) if known2 else Color(0.50, 0.50, 0.56))

	txt(Vector2(vs.x * 0.5, vs.y - 30.0), "↑↓ 选择     1~4 或 ←→ 切换分类     Tab / Esc 关闭", 15, Color(0.86, 0.86, 0.90), 1)


## 中文按固定字数换行 + 居中（护甲/盾牌替换界面）
func _draw_wrap_chars_center(pos: Vector2, s: String, per_line: int, size_px: int, col: Color, max_rows: int = 6) -> void:
	if per_line < 1:
		per_line = 5
	var lh: float = float(size_px) + 5.0
	var i: int = 0
	var row: int = 0
	while i < s.length() and row < max_rows:
		var n: int = mini(per_line, s.length() - i)
		var line: String = s.substr(i, n)
		var w: float = fnt.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
		txt(Vector2(pos.x - w * 0.5, pos.y + float(row) * lh), line, size_px, col, 0)
		i += n
		row += 1


## 中文按固定字数换行（装备替换界面用小字竖排风格）
func _draw_wrap_chars(pos: Vector2, s: String, per_line: int, size_px: int, col: Color, line_h: float = 0.0) -> void:
	if per_line < 1:
		per_line = 5
	var lh: float = line_h if line_h > 0.0 else float(size_px) + 5.0
	var i: int = 0
	var row: int = 0
	while i < s.length() and row < 5:
		var n: int = mini(per_line, s.length() - i)
		txt(Vector2(pos.x, pos.y + float(row) * lh), s.substr(i, n), size_px, col, 0)
		i += n
		row += 1


## 简易自动换行文字
func _draw_wrapped(pos: Vector2, s: String, width: float, size: int, col: Color) -> void:
	var line: String = ""
	var y: float = pos.y
	for i in range(s.length()):
		var ch: String = s.substr(i, 1)
		var test: String = line + ch
		if fnt.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
			txt(Vector2(pos.x, y), line, size, col)
			y += float(size) + 6.0
			line = ch
		else:
			line = test
		if y > pos.y + 220.0:
			return
	if line != "":
		txt(Vector2(pos.x, y), line, size, col)


## 每把武器都有独立图标（图鉴 / 拾取对比共用）
func _draw_weapon_icon(p: Vector2, id: String) -> void:
	if W.SWORDS.has(id):
		var d: Dictionary = W.sword(id)
		var scol: Color = d["col"]
		var magic: bool = bool(d.get("magic", false))
		var lord: bool = W.is_boss_only(id)
		var ln: float = 13.0 + float(int(d["tier"])) * 1.7
		# 鞭类：细长鞭身 + 短柄
		if str(id).begins_with("whip_"):
			draw_rect(Rect2(p.x - 1.6, p.y + 4.0, 3.2, 7.0), Color(0.46, 0.32, 0.22))
			draw_rect(Rect2(p.x - 5.0, p.y + 2.4, 10.0, 2.2), scol.darkened(0.25))
			var pw2: PackedVector2Array = PackedVector2Array()
			for k in range(7):
				var fy: float = 2.4 - float(k) * 3.4
				var fx: float = sin(float(k) * 0.9) * 3.2
				pw2.append(p + Vector2(fx, fy))
			for k in range(pw2.size() - 1):
				draw_line(pw2[k], pw2[k + 1], scol, 2.0)
			draw_circle(p + Vector2(sin(5.4) * 3.2, 2.4 - 6.0 * 3.4), 2.0, Color(1, 1, 1, 0.8))
			return
		if magic:
			draw_circle(p + Vector2(0.0, -ln * 0.2), ln * 0.62, Color(scol.r, scol.g, scol.b, 0.16))
		# 剑身
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(-2.4, ln * 0.3), p + Vector2(0.0, -ln * 0.62), p + Vector2(2.4, ln * 0.3),
		]), scol)
		draw_rect(Rect2(p.x - 2.2, p.y - ln * 0.2, 4.4, ln * 0.55), scol)
		# 护手 / 剑柄
		draw_rect(Rect2(p.x - 7.0, p.y + ln * 0.3, 14.0, 2.6), Color(0.58, 0.46, 0.32) if not magic else Color(scol.r * 0.7, scol.g * 0.7, scol.b * 0.7))
		draw_rect(Rect2(p.x - 1.8, p.y + ln * 0.3 + 2.6, 3.6, 6.0), Color(0.42, 0.30, 0.20))
		if lord:
			draw_circle(p + Vector2(0.0, -ln * 0.5), 3.0, Color(1.0, 0.90, 0.45))
		return
	if W.has_gun(id):
		var g: Dictionary = W.gun(id)
		var gcol: Color = g["col"]
		var mode: String = str(g.get("mode", "auto"))
		var bullet: String = str(g.get("bullet", "bullet"))
		if mode == "magic" or mode == "summon":
			# 魔杖 / 法典
			if bullet == "element":
				draw_rect(Rect2(p.x - 2.0, p.y - 4.0, 4.0, 26.0), Color(0.56, 0.42, 0.28))
				draw_circle(p + Vector2(0.0, -9.0), 9.0, Color(gcol.r, gcol.g, gcol.b, 0.20))
				draw_circle(p + Vector2(0.0, -9.0), 5.0, Color(gcol.r, gcol.g, gcol.b, 0.85))
				draw_circle(p + Vector2(-1.4, -10.6), 1.8, Color(1.0, 1.0, 1.0, 0.9))
			else:
				draw_rect(Rect2(p.x - 11.0, p.y - 10.0, 22.0, 20.0), Color(0.26, 0.18, 0.32))
				draw_rect(Rect2(p.x - 9.0, p.y - 8.0, 8.0, 16.0), Color(0.90, 0.94, 1.0, 0.95))
				draw_rect(Rect2(p.x + 1.0, p.y - 8.0, 8.0, 16.0), Color(0.94, 0.97, 1.0, 0.95))
		elif bullet == "arrow" or mode == "charge":
			# 弓
			draw_arc(p + Vector2(4.0, 0.0), 13.0, -1.35, 1.35, 16, Color(0.70, 0.56, 0.38), 3.0)
			draw_line(p + Vector2(6.0, -12.0), p + Vector2(-6.0, 0.0), Color(0.86, 0.88, 0.94), 1.4)
			draw_line(p + Vector2(6.0, 12.0), p + Vector2(-6.0, 0.0), Color(0.86, 0.88, 0.94), 1.4)
			draw_colored_polygon(PackedVector2Array([
				p + Vector2(-14.0, 0.0), p + Vector2(-4.0, -3.0), p + Vector2(-4.0, 3.0),
			]), gcol)
		else:
			# 枪械：长度/口径按配置区分
			var glen: float = 18.0
			var ghigh: float = 6.0
			if id == "smg":
				glen = 15.0
				ghigh = 5.0
			elif id == "rifle":
				glen = 21.0
				ghigh = 5.5
			elif id == "gatling":
				glen = 24.0
				ghigh = 8.5
			elif id == "sniper":
				glen = 26.0
				ghigh = 4.5
			draw_rect(Rect2(p.x - glen * 0.5, p.y - ghigh * 0.5, glen, ghigh), Color(0.60, 0.64, 0.72))
			draw_rect(Rect2(p.x - glen * 0.28, p.y + ghigh * 0.5, 7.0, 8.0), Color(0.44, 0.34, 0.24))
			draw_rect(Rect2(p.x + glen * 0.42, p.y - ghigh * 0.5 - 1.0, 6.0, ghigh * 0.7), gcol)
		return
	# 盾
	var sh: Dictionary = W.shield(id)
	var shc: Color = sh["col"]
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-14.0, -16.0), p + Vector2(14.0, -16.0), p + Vector2(14.0, 4.0),
		p + Vector2(0.0, 20.0), p + Vector2(-14.0, 4.0),
	]), shc)
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-9.0, -11.0), p + Vector2(9.0, -11.0), p + Vector2(9.0, 2.0),
		p + Vector2(0.0, 13.0), p + Vector2(-9.0, 2.0),
	]), Color(0.80, 0.84, 0.92))
	if id == "thorns":
		for k in range(4):
			var a6: float = -2.4 + float(k) * 1.6
			draw_line(p + Vector2(cos(a6), sin(a6)) * 12.0, p + Vector2(cos(a6), sin(a6)) * 19.0, Color(1.0, 0.55, 0.35), 2.0)
	elif id == "dodge":
		draw_rect(Rect2(p.x - 2.0, p.y - 8.0, 4.0, 16.0), Color(0.60, 1.0, 0.80))
	elif id == "arcane" or W.is_boss_only(id):
		draw_circle(p + Vector2(0.0, -2.0), 7.0, Color(shc.r, shc.g, shc.b, 0.55))
		draw_circle(p + Vector2(0.0, -2.0), 3.0, Color(1.0, 1.0, 1.0, 0.85))

func _draw_codex_icon(p: Vector2, cat: String, id: String, col: Color, known: bool) -> void:
	if not known:
		draw_rect(Rect2(p.x - 26.0, p.y - 26.0, 52.0, 52.0), Color(0.09, 0.09, 0.12, 0.95))
		txt(Vector2(p.x, p.y + 12.0), "?", 34, Color(0.34, 0.34, 0.40), 1)
		return
	if cat == "items":
		_draw_item_icon(p, id, col)
		return
	if cat == "monsters":
		if id.begins_with("seadrake"):
			# 海龙：贴地爬行的蛇形
			var bk2: float = 1.35 if id.contains("king") else (1.0 if id.contains("large") else 0.75)
			for k3 in range(5):
				var f3: float = float(k3) / 5.0
				draw_circle(Vector2(p.x + (14.0 - f3 * 34.0) * bk2, p.y + 4.0 - f3 * 3.0), (9.0 - f3 * 4.0) * bk2, Color(0.22, 0.50, 0.78))
			draw_colored_polygon(PackedVector2Array([
				p + Vector2(12.0 * bk2, 0.0), p + Vector2(26.0 * bk2, -9.0 * bk2), p + Vector2(30.0 * bk2, 4.0 * bk2), p + Vector2(14.0 * bk2, 8.0 * bk2),
			]), Color(0.22, 0.50, 0.78))
			draw_colored_polygon(PackedVector2Array([
				p + Vector2(14.0 * bk2, -8.0 * bk2), p + Vector2(6.0 * bk2, -20.0 * bk2), p + Vector2(20.0 * bk2, -9.0 * bk2),
			]), Color(0.55, 0.92, 1.0, 0.8))
			draw_circle(p + Vector2(24.0 * bk2, -3.0 * bk2), 2.4 * bk2, Color(1.0, 0.95, 0.55))
			if id.contains("king"):
				draw_rect(Rect2(p.x + 16.0 * bk2, p.y - 16.0 * bk2, 14.0 * bk2, 3.0 * bk2), Color(0.95, 0.99, 1.0))
			return
		if id.begins_with("drake"):
			var big: bool = id.contains("king")
			var k: float = 1.35 if big else (0.8 if id.contains("large") else 0.6)
			var wc4: Color = Color(0.72, 0.28, 0.20)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-26.0 * k, 6.0 * k), p + Vector2(-6.0 * k, -22.0 * k), p + Vector2(4.0 * k, 8.0 * k)]), Color(wc4.r, wc4.g, wc4.b, 0.85))
			draw_colored_polygon(PackedVector2Array([p + Vector2(2.0 * k, 4.0 * k), p + Vector2(16.0 * k, -18.0 * k), p + Vector2(24.0 * k, 8.0 * k)]), Color(wc4.r, wc4.g, wc4.b, 0.7))
			draw_rect(Rect2(p.x - 10.0 * k, p.y - 2.0 * k, 26.0 * k, 9.0 * k), wc4)
			draw_rect(Rect2(p.x + 10.0 * k, p.y - 6.0 * k, 11.0 * k, 8.0 * k), wc4.darkened(0.2))
			draw_circle(p + Vector2(17.0 * k, -2.0 * k), 2.0 * k, Color(1.0, 0.9, 0.5))
			if big:
				draw_rect(Rect2(p.x - 2.0 * k, p.y - 16.0 * k, 22.0 * k, 3.0 * k), Color(1.0, 0.86, 0.36))
			return
		if id == "skeleton":
			draw_rect(Rect2(p.x - 9.0, p.y - 30.0, 18.0, 6.0), Color(0.88, 0.86, 0.78))
			draw_rect(Rect2(p.x - 6.0, p.y - 24.0, 12.0, 26.0), Color(0.80, 0.78, 0.70))
			draw_rect(Rect2(p.x - 3.5, p.y - 20.0, 3.0, 4.0), Color(0.35, 0.95, 1.0))
			draw_rect(Rect2(p.x + 1.0, p.y - 20.0, 3.0, 4.0), Color(0.35, 0.95, 1.0))
			draw_rect(Rect2(p.x - 10.0, p.y - 18.0, 20.0, 3.0), Color(0.62, 0.60, 0.52))
			return
		if id == "flesh":
			draw_rect(Rect2(p.x - 16.0, p.y - 22.0, 32.0, 30.0), Color(0.62, 0.26, 0.26))
			draw_rect(Rect2(p.x - 16.0, p.y - 8.0, 32.0, 3.0), Color(0.38, 0.14, 0.16))
			draw_circle(Vector2(p.x - 6.0, p.y - 24.0), 4.0, Color(1.0, 0.92, 0.5))
			draw_circle(Vector2(p.x + 7.0, p.y - 24.0), 4.0, Color(0.15, 0.05, 0.05))
			draw_circle(Vector2(p.x - 6.0, p.y - 24.0), 2.0, Color(1.0, 0.92, 0.5))
			draw_circle(Vector2(p.x + 7.0, p.y - 24.0), 2.0, Color(1.0, 0.92, 0.5))
			return
		if id.begins_with("slime"):
			var scol: Color = Color(0.24, 0.58, 0.28)
			if id == "slime_blue":
				scol = Color(0.30, 0.60, 0.94)
			elif id == "slime_red":
				scol = Color(0.92, 0.34, 0.26)
			elif id == "slime_metal":
				scol = Color(0.84, 0.84, 0.78)
			elif id == "slime_wood":
				scol = Color(0.40, 0.80, 0.42)
			elif id == "slime_earth":
				scol = Color(0.74, 0.60, 0.34)
			elif id == "slime_king":
				scol = Color(0.70, 0.56, 0.30)
			elif id == "slime_queen":
				scol = Color(0.66, 0.40, 0.90)
			var kk: float = 26.0 if id.contains("king") or id.contains("queen") else (17.0 if id == "slime_mini" else 22.0)
			draw_rect(Rect2(p.x - kk, p.y - kk * 0.62, kk * 2.0, kk * 1.25), scol)
			draw_rect(Rect2(p.x - kk * 0.5, p.y - kk * 0.45, 5.0, 6.0), Color(0.05, 0.09, 0.08))
			draw_rect(Rect2(p.x + 2.0, p.y - kk * 0.45, 5.0, 6.0), Color(0.05, 0.09, 0.08))
			if id == "slime_king" or id == "slime_queen":
				draw_rect(Rect2(p.x - 12.0, p.y - kk * 0.62 - 6.0, 24.0, 4.0), Color(1.0, 0.86, 0.36))
				for k2 in range(3):
					var kx2: float = -9.0 + float(k2) * 9.0
					draw_colored_polygon(PackedVector2Array([
						p + Vector2(kx2 - 3.0, -kk * 0.62 - 6.0), p + Vector2(kx2, -kk * 0.62 - 13.0), p + Vector2(kx2 + 3.0, -kk * 0.62 - 6.0),
					]), Color(1.0, 0.92, 0.48))
			return
		if id == "slime" or id == "slime_mini":
			var k: float = 24.0 if id == "slime" else 17.0
			draw_rect(Rect2(p.x - k, p.y - k * 0.65, k * 2.0, k * 1.3), Color(0.24, 0.58, 0.28))
			draw_rect(Rect2(p.x - k * 0.55, p.y - k * 0.45, 6.0, 7.0), Color(0.05, 0.09, 0.08))
			draw_rect(Rect2(p.x + 2.0, p.y - k * 0.45, 6.0, 7.0), Color(0.05, 0.09, 0.08))
		elif id == "zombie" or id == "elite":
			draw_rect(Rect2(p.x - 13.0, p.y - 28.0, 26.0, 54.0), Color(0.42, 0.52, 0.36))
			draw_rect(Rect2(p.x - 10.0, p.y - 22.0, 7.0, 7.0), Color(1.0, 0.25, 0.16))
			draw_rect(Rect2(p.x + 3.0, p.y - 22.0, 7.0, 7.0), Color(1.0, 0.25, 0.16))
			if id == "elite":
				draw_arc(p, 32.0, 0.0, TAU, 26, Color(0.80, 0.50, 1.0, 0.85), 3.0)
		else:
			draw_rect(Rect2(p.x - 15.0, p.y - 12.0, 30.0, 26.0), Color(0.36, 0.56, 0.24))
			draw_rect(Rect2(p.x - 9.0, p.y - 17.0, 18.0, 6.0), Color(0.36, 0.56, 0.24))
			draw_rect(Rect2(p.x - 10.0, p.y - 6.0, 8.0, 8.0), Color(1.0, 0.86, 0.25))
			draw_rect(Rect2(p.x + 2.0, p.y - 6.0, 8.0, 8.0), Color(1.0, 0.86, 0.25))
		return
	if cat == "weapons":
		_draw_weapon_icon(p, id)
		return
	draw_circle(p, 25.0, Color(col.r, col.g, col.b, 0.18))
	draw_arc(p, 23.0, 0.0, TAU, 26, Color(col.r, col.g, col.b, 0.90), 2.5)
	draw_rect(Rect2(p.x - 2.0, p.y - 12.0, 4.0, 24.0), Color(col.r, col.g, col.b, 0.95))
	draw_rect(Rect2(p.x - 12.0, p.y - 2.0, 24.0, 4.0), Color(col.r, col.g, col.b, 0.95))
