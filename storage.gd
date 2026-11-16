extends RefCounted
## 存档 / 设置 持久化（ConfigFile）
##   存档槽：user://save_1.cfg ~ user://save_3.cfg
##   设置  ：user://settings.cfg

const SLOT_COUNT := 3
const SETTINGS_PATH := "user://settings.cfg"


func slot_path(i: int) -> String:
	return "user://save_%d.cfg" % (i + 1)


func has_slot(i: int) -> bool:
	return FileAccess.file_exists(slot_path(i))


func save_slot(i: int, data: Dictionary) -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("run", "data", data)
	return cfg.save(slot_path(i)) == OK


func load_slot(i: int) -> Dictionary:
	if not has_slot(i):
		return {}
	var cfg := ConfigFile.new()
	if cfg.load(slot_path(i)) != OK:
		return {}
	var d = cfg.get_value("run", "data", {})
	if typeof(d) != TYPE_DICTIONARY:
		return {}
	return d


func delete_slot(i: int) -> void:
	if not has_slot(i):
		return
	var da := DirAccess.open("user://")
	if da != null:
		da.remove("save_%d.cfg" % (i + 1))


func save_settings(s: Dictionary) -> void:
	var cfg := ConfigFile.new()
	var keys: Array = s.keys()
	for k in keys:
		cfg.set_value("settings", str(k), s[k])
	cfg.save(SETTINGS_PATH)


## 键盘默认绑定（动作 → 键码）
func default_keys() -> Dictionary:
	return {
		"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT],
		"up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE, KEY_W], "sword": [KEY_J], "bow": [KEY_K],
		"shield": [KEY_L], "roll": [KEY_SHIFT], "heal": [KEY_Q], "reload": [KEY_R],
		"interact": [KEY_F],
	}


## 手柄默认绑定（Xbox 布局）
func default_pad() -> Dictionary:
	return {
		"left": [JOY_BUTTON_DPAD_LEFT], "right": [JOY_BUTTON_DPAD_RIGHT],
		"up": [JOY_BUTTON_DPAD_UP], "down": [JOY_BUTTON_DPAD_DOWN],
		"jump": [JOY_BUTTON_A], "sword": [JOY_BUTTON_X],
		"bow": [JOY_BUTTON_RIGHT_SHOULDER], "shield": [JOY_BUTTON_LEFT_SHOULDER],
		"roll": [JOY_BUTTON_B], "heal": [JOY_BUTTON_Y], "reload": [JOY_BUTTON_BACK],
		"interact": [JOY_BUTTON_Y],
	}


func load_settings() -> Dictionary:
	var out := {}
	out["volume"] = 0.8
	out["shake"] = 1.0
	out["fullscreen"] = false
	out["crosshair"] = true
	out["resolution"] = 0
	out["fps"] = 1
	out["show_fps"] = false
	out["quality"] = 1
	out["total_time"] = 0.0
	out["autoaim"] = false
	out["stickaim"] = true
	out["mouseaim"] = true
	out["customkeys"] = true
	out["wall_bg"] = false
	out["keys"] = default_keys()
	out["pad"] = default_pad()
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return out
	out["volume"] = clampf(float(cfg.get_value("settings", "volume", 0.8)), 0.0, 1.0)
	out["shake"] = clampf(float(cfg.get_value("settings", "shake", 1.0)), 0.0, 2.0)
	out["fullscreen"] = bool(cfg.get_value("settings", "fullscreen", false))
	out["crosshair"] = bool(cfg.get_value("settings", "crosshair", true))
	out["resolution"] = clampi(int(cfg.get_value("settings", "resolution", 0)), 0, 3)
	out["fps"] = clampi(int(cfg.get_value("settings", "fps", 1)), 0, 4)
	out["show_fps"] = bool(cfg.get_value("settings", "show_fps", false))
	out["quality"] = clampi(int(cfg.get_value("settings", "quality", 1)), 0, 2)
	out["total_time"] = maxf(0.0, float(cfg.get_value("settings", "total_time", 0.0)))
	# ---- 独立开关（之前漏读，导致每次启动都回到默认）----
	out["autoaim"] = bool(cfg.get_value("settings", "autoaim", false))
	out["stickaim"] = bool(cfg.get_value("settings", "stickaim", true))
	out["mouseaim"] = bool(cfg.get_value("settings", "mouseaim", true))
	out["customkeys"] = bool(cfg.get_value("settings", "customkeys", true))
	out["wall_bg"] = bool(cfg.get_value("settings", "wall_bg", false))
	# ---- 键位绑定（之前漏读，导致自定义按键重启后失效）----
	out["keys"] = _merge_binds(cfg.get_value("settings", "keys", {}), default_keys())
	out["pad"] = _merge_binds(cfg.get_value("settings", "pad", {}), default_pad())
	return out


## 把存档里的绑定合并到默认绑定上（缺哪个动作就用默认）
func _merge_binds(saved, defs: Dictionary) -> Dictionary:
	var out: Dictionary = defs.duplicate(true)
	if not (saved is Dictionary):
		return out
	var keys: Array = (saved as Dictionary).keys()
	for i in range(keys.size()):
		var k: String = str(keys[i])
		var v = (saved as Dictionary)[k]
		if v is Array and (v as Array).size() > 0:
			out[k] = (v as Array).duplicate()
	return out


## 把秒数格式化成 mm:ss 或 h:mm:ss
static func fmt_time(sec: float) -> String:
	var total: int = int(maxf(0.0, sec))
	var h: int = int(total / 3600)
	var m: int = int((total % 3600) / 60)
	var s: int = total % 60
	if h > 0:
		return "%d:%02d:%02d" % [h, m, s]
	return "%02d:%02d" % [m, s]
