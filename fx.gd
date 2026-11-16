extends Node2D
## 特效层：粒子 / 血渍 / 挥砍弧光 / 冲击波 / 飘字

const Art = preload("res://scripts/art.gd")
const TAU := 6.283185307179586

var particles: Array = []
var texts: Array = []
var rings: Array = []
var slashes: Array = []
var whips: Array = []
var decals: Array = []
var t := 0.0
var quality := 1


## 画质设置：0 低 / 1 中 / 2 高（影响粒子数量与残留上限）
func set_quality(q: int) -> void:
	quality = clampi(q, 0, 2)
	var cap: int = 240
	if quality == 1:
		cap = 460
	elif quality == 2:
		cap = 700
	while particles.size() > cap:
		particles.pop_front()
	var dcap: int = 70
	if quality == 1:
		dcap = 240
	elif quality == 2:
		dcap = 420
	while decals.size() > dcap:
		decals.pop_front()


func _qmul() -> float:
	if quality == 0:
		return 0.45
	if quality == 2:
		return 1.65
	return 1.0


func _qn(n: int) -> int:
	return maxi(1, int(round(float(n) * _qmul())))


func clear_all() -> void:
	particles.clear()
	texts.clear()
	rings.clear()
	slashes.clear()
	whips.clear()
	decals.clear()


func _cap() -> void:
	if particles.size() > 460:
		particles.pop_front()


func blood_spawn(pos: Vector2, dir: Vector2, n: int, col: Color) -> void:
	if dir.length() < 0.01:
		dir = Vector2(0, -1)
	dir = dir.normalized()
	for i in range(_qn(n)):
		var spread: float = randf_range(-1.1, 1.1)
		var spd: float = randf_range(80.0, 330.0)
		var dv := dir.rotated(spread) * spd
		particles.append({
			"pos": pos + Vector2(randf_range(-4.0, 4.0), randf_range(-6.0, 6.0)),
			"vel": dv + Vector2(0.0, -randf_range(30.0, 150.0)),
			"life": randf_range(0.35, 0.9),
			"max": 0.9,
			"col": col,
			"size": randf_range(1.6, 3.6),
			"grav": 1500.0,
			"decal": true,
		})
	_cap()


func spark_spawn(pos: Vector2, dir: Vector2, n: int, col: Color) -> void:
	if dir.length() < 0.01:
		dir = Vector2(0, -1)
	dir = dir.normalized()
	for i in range(_qn(n)):
		var spread: float = randf_range(-1.5, 1.5)
		var spd: float = randf_range(120.0, 420.0)
		particles.append({
			"pos": pos,
			"vel": dir.rotated(spread) * spd,
			"life": randf_range(0.12, 0.34),
			"max": 0.34,
			"col": col,
			"size": randf_range(1.4, 2.6),
			"grav": 320.0,
			"decal": false,
		})
	_cap()


func dust_spawn(pos: Vector2, n: int, col: Color) -> void:
	for i in range(n):
		particles.append({
			"pos": pos + Vector2(randf_range(-10.0, 10.0), randf_range(-4.0, 2.0)),
			"vel": Vector2(randf_range(-40.0, 40.0), randf_range(-46.0, -10.0)),
			"life": randf_range(0.3, 0.7),
			"max": 0.7,
			"col": col,
			"size": randf_range(1.5, 3.0),
			"grav": -30.0,
			"decal": false,
		})
	_cap()


func ring_spawn(pos: Vector2, radius: float, col: Color) -> void:
	rings.append({"pos": pos, "r": 4.0, "target": radius, "life": 0.30, "max": 0.30, "col": col})


func slash_spawn(pos: Vector2, angle: float, radius: float, col: Color, face: float) -> void:
	slashes.append({
		"pos": pos,
		"angle": angle,
		"radius": radius,
		"life": 0.20,
		"max": 0.20,
		"col": col,
		"face": face,
	})


func text(pos: Vector2, s: String, col: Color, size: int = 18) -> void:
	texts.append({
		"pos": pos,
		"vel": Vector2(randf_range(-14.0, 14.0), -56.0),
		"life": 0.75,
		"max": 0.75,
		"text": s,
		"col": col,
		"size": size,
		"tilt": randf_range(-0.42, 0.42),
		"jit": randf_range(0.6, 1.8),
	})


func update(dt: float) -> void:
	t += dt
	var i: int = particles.size() - 1
	while i >= 0:
		var p: Dictionary = particles[i]
		var life: float = float(p["life"]) - dt
		p["life"] = life
		var pos: Vector2 = p["pos"]
		var vel: Vector2 = p["vel"]
		vel.y += float(p["grav"]) * dt
		pos += vel * dt
		p["pos"] = pos
		p["vel"] = vel
		if life <= 0.0:
			if bool(p["decal"]) and decals.size() < (70 if quality == 0 else (240 if quality == 1 else 420)):
				decals.append({"pos": pos, "r": float(p["size"]) * randf_range(1.4, 2.4), "col": p["col"]})
			particles.remove_at(i)
		i -= 1

	i = texts.size() - 1
	while i >= 0:
		var tt: Dictionary = texts[i]
		tt["life"] = float(tt["life"]) - dt
		var tp: Vector2 = tt["pos"] + Vector2(tt["vel"]) * dt
		tt["pos"] = tp
		var tv: Vector2 = tt["vel"]
		tv.y += 90.0 * dt
		tt["vel"] = tv
		if float(tt["life"]) <= 0.0:
			texts.remove_at(i)
		i -= 1

	i = rings.size() - 1
	while i >= 0:
		var rg: Dictionary = rings[i]
		rg["life"] = float(rg["life"]) - dt
		var f: float = 1.0 - float(rg["life"]) / float(rg["max"])
		rg["r"] = lerpf(4.0, float(rg["target"]), f)
		if float(rg["life"]) <= 0.0:
			rings.remove_at(i)
		i -= 1

	i = slashes.size() - 1
	while i >= 0:
		var sl: Dictionary = slashes[i]
		sl["life"] = float(sl["life"]) - dt
		if float(sl["life"]) <= 0.0:
			slashes.remove_at(i)
		i -= 1
	_update_whips(dt)
	queue_redraw()


func _draw() -> void:
	# 血渍
	for i in range(decals.size()):
		var d: Dictionary = decals[i]
		var dp: Vector2 = d["pos"]
		var dc: Color = d["col"]
		draw_rect(Rect2(dp.x - float(d["r"]), dp.y - float(d["r"]) * 0.45, float(d["r"]) * 2.0, float(d["r"]) * 0.9), Color(dc.r * 0.55, dc.g * 0.5, dc.b * 0.5, 0.55))

	# 挥砍弧光
	_draw_whips()
	for i in range(slashes.size()):
		var s: Dictionary = slashes[i]
		var f: float = 1.0 - float(s["life"]) / float(s["max"])
		var pos: Vector2 = s["pos"]
		var ang: float = s["angle"]
		var rad: float = s["radius"]
		var side: float = s["face"]
		var col: Color = s["col"]
		var sweep: float = 2.0
		var seg: int = 15
		for k in range(seg):
			var f2: float = float(k) / float(max(seg - 1, 1))
			var aa: float = ang - sweep * 0.5 * side + sweep * side * f2 * (0.45 + 0.55 * f)
			var rr: float = rad * (0.55 + 0.5 * f2) * (0.72 + 0.35 * f)
			var p2: Vector2 = pos + Vector2(cos(aa), sin(aa)) * rr
			var sz: float = 7.0 - 5.0 * f2
			var alpha: float = (1.0 - f) * (0.9 - 0.55 * f2)
			draw_rect(Rect2(p2.x - sz * 0.5, p2.y - sz * 0.5, sz, sz), Color(col.r, col.g, col.b, alpha))

	# 冲击波
	for i in range(rings.size()):
		var rg: Dictionary = rings[i]
		var rc: Color = rg["col"]
		var alpha2: float = float(rg["life"]) / float(rg["max"])
		draw_arc(rg["pos"], float(rg["r"]), 0.0, TAU, 26, Color(rc.r, rc.g, rc.b, alpha2 * 0.8), 2.5)

	# 粒子
	for i in range(particles.size()):
		var p: Dictionary = particles[i]
		var pc: Color = p["col"]
		var life_f: float = clampf(float(p["life"]) / maxf(0.01, float(p["max"])), 0.0, 1.0)
		var sz2: float = float(p["size"]) * (0.4 + 0.6 * life_f)
		var pp: Vector2 = p["pos"]
		draw_rect(Rect2(pp.x - sz2, pp.y - sz2, sz2 * 2.0, sz2 * 2.0), Color(pc.r, pc.g, pc.b, clampf(life_f * 1.4, 0.0, 1.0)))

	# 飘字
	var fnt: SystemFont = Art.make_font()
	for i in range(texts.size()):
		var tt: Dictionary = texts[i]
		var tc: Color = tt["col"]
		var lf: float = clampf(float(tt["life"]) / float(tt["max"]), 0.0, 1.0)
		var size2: int = int(tt["size"])
		var s2: String = tt["text"]
		var w: float = fnt.get_string_size(s2, HORIZONTAL_ALIGNMENT_LEFT, -1, size2).x
		var tpos: Vector2 = tt["pos"]
		var tilt: float = float(tt.get("tilt", 0.0))
		var jit: float = float(tt.get("jit", 1.0))
		# 抖动：高频小幅偏移
		var jx: float = sin(t * 42.0 * jit + tilt * 10.0) * 1.8
		var jy: float = cos(t * 37.0 * jit) * 1.2
		tpos += Vector2(jx, jy)
		draw_set_transform(tpos, tilt, Vector2.ONE)
		draw_string(fnt, Vector2(-w * 0.5, 0.0), s2, HORIZONTAL_ALIGNMENT_LEFT, -1, size2, Color(0.05, 0.05, 0.08, lf * 0.9))
		draw_string(fnt, Vector2(-w * 0.5, -2.0), s2, HORIZONTAL_ALIGNMENT_LEFT, -1, size2, Color(tc.r, tc.g, tc.b, lf))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 鞭影：一条从玩家手中甩出、快速伸直、再回缩的鞭子（带残影）
func whip_spawn(pos: Vector2, angle: float, reach: float, col: Color, face: float, dur: float = 0.34, host = null) -> void:
	whips.append({
		"host": host,
		"offset": (pos - host.position) if host != null and is_instance_valid(host) else Vector2.ZERO,
		"pos": pos,
		"angle": angle,
		"reach": reach,
		"col": col,
		"face": face,
		"life": dur,
		"max": dur,
		"seed": randf() * 6.283,
		"hist": [],
	})


func _update_whips(dt: float) -> void:
	var i: int = whips.size() - 1
	while i >= 0:
		var w: Dictionary = whips[i]
		w["life"] = float(w["life"]) - dt
		if float(w["life"]) <= 0.0:
			whips.remove_at(i)
		else:
			# 记录当前形状，作为后续帧的残影
			var hist: Array = w["hist"]
			hist.append(_whip_points(w))
			while hist.size() > 7:
				hist.remove_at(0)
		i -= 1


## 计算某一时刻鞭身的 13 个点
func _whip_points(w: Dictionary) -> PackedVector2Array:
	var f: float = 1.0 - float(w["life"]) / float(w["max"])
	var base: Vector2 = w["pos"]
	var host = w.get("host", null)
	if host != null and is_instance_valid(host):
		base = host.position + Vector2(0, -host.size.y * 0.52)
	var ang: float = w["angle"]
	var reach: float = w["reach"]
	var sd: float = w["seed"]
	var ext: float
	if f < 0.30:
		ext = pow(f / 0.30, 0.5)
	else:
		ext = 1.0 - (f - 0.30) / 0.70 * 0.45
	var pts: PackedVector2Array = PackedVector2Array()
	var seg: int = 12
	for k in range(seg + 1):
		var t01: float = float(k) / float(seg)
		var d: float = reach * ext * t01
		var curl: float = sin(t01 * 3.4 + sd) * (18.0 + 26.0 * t01) * t01
		pts.append(base + Vector2(cos(ang) * d - sin(ang) * curl, sin(ang) * d + cos(ang) * curl))
	return pts


func _draw_whips() -> void:
	for i in range(whips.size()):
		var w: Dictionary = whips[i]
		var f: float = 1.0 - float(w["life"]) / float(w["max"])
		var col: Color = w["col"]
		var hist: Array = w["hist"]
		# 1) 历史残影：由旧到新，越旧越淡越细
		for h in range(hist.size()):
			var age: float = float(hist.size() - h) / float(hist.size())
			var a_g: float = (1.0 - age) * 0.42 * (1.0 - f * 0.5)
			var hp: PackedVector2Array = hist[h]
			for k in range(hp.size() - 1):
				draw_line(hp[k], hp[k + 1], Color(col.r, col.g, col.b, a_g), 2.2)
		# 2) 当前鞭身
		var pts: PackedVector2Array = _whip_points(w)
		var alpha: float = clampf(1.0 - f * 0.6, 0.0, 1.0)
		for k in range(pts.size() - 1):
			draw_line(pts[k], pts[k + 1], Color(col.r, col.g, col.b, 0.17 * alpha), 7.0)
		for k in range(pts.size() - 1):
			draw_line(pts[k], pts[k + 1], Color(col.r, col.g, col.b, 0.95 * alpha), 2.8)
		for k in range(pts.size() - 1):
			draw_line(pts[k], pts[k + 1], Color(1.0, 1.0, 1.0, 0.55 * alpha), 0.9)
		# 3) 鞭梢亮点 + 拖尾光点
		if pts.size() > 0:
			var tip: Vector2 = pts[pts.size() - 1]
			draw_circle(tip, 5.0, Color(col.r, col.g, col.b, 0.30 * alpha))
			draw_circle(tip, 2.0, Color(1.0, 1.0, 1.0, 0.95 * alpha))
			for m in range(hist.size()):
				var hm: PackedVector2Array = hist[m]
				if hm.size() > 0:
					var ag2: float = float(m + 1) / float(hist.size() + 1)
					draw_circle(hm[hm.size() - 1], 2.4 * (1.0 - ag2 * 0.6), Color(col.r, col.g, col.b, 0.5 * (1.0 - ag2)))
