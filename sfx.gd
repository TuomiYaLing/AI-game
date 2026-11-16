extends Node
## 程序化音效：运行时合成 8-bit 风格音色，无需任何音频素材

const RATE := 22050
const TAU := 6.283185307179586

var players: Array = []
var streams: Dictionary = {}
var muted := false
var idx := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 12345
	for i in range(12):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		players.append(p)
	_build()


func _tone(dur: float, f0: float, f1: float, wave: int, noise_amt: float, vol: float) -> AudioStreamWAV:
	var n: int = int(float(RATE) * dur)
	if n < 16:
		n = 16
	var frames := PackedFloat32Array()
	frames.resize(n)
	var phase: float = 0.0
	for i in range(n):
		var tt: float = float(i) / float(RATE)
		var f: float = lerpf(f0, f1, clampf(tt / maxf(dur, 0.001), 0.0, 1.0))
		phase += TAU * f / float(RATE)
		if phase > TAU:
			phase -= TAU
		var s: float = 0.0
		if wave == 0:
			s = sin(phase)
		elif wave == 1:
			s = 1.0 if sin(phase) > 0.0 else -1.0
		else:
			s = (phase / PI) - 1.0
		if noise_amt > 0.0:
			s = lerpf(s, _rng.randf_range(-1.0, 1.0), noise_amt)
		var env: float = exp(-tt * (3.2 / maxf(dur, 0.02)))
		var attack: float = clampf(tt / 0.004, 0.0, 1.0)
		frames[i] = s * env * attack * vol
	return _wav_from(frames)


func _wav_from(frames: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(frames.size() * 2)
	for i in range(frames.size()):
		var v: int = int(clampf(frames[i], -1.0, 1.0) * 30000.0)
		if v < 0:
			v += 65536
		bytes[i * 2] = v & 0xFF
		bytes[i * 2 + 1] = (v >> 8) & 0xFF
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w


func _build() -> void:
	streams["slash"] = _tone(0.16, 1900.0, 420.0, 1, 0.42, 0.5)
	streams["hit"] = _tone(0.13, 240.0, 80.0, 1, 0.55, 0.55)
	streams["arrow_hit"] = _tone(0.10, 760.0, 300.0, 1, 0.35, 0.4)
	streams["kill"] = _tone(0.32, 180.0, 55.0, 1, 0.5, 0.55)
	streams["hurt"] = _tone(0.28, 340.0, 105.0, 2, 0.25, 0.6)
	streams["jump"] = _tone(0.13, 380.0, 660.0, 1, 0.04, 0.3)
	streams["step"] = _tone(0.06, 140.0, 90.0, 2, 0.55, 0.22)
	streams["roll"] = _tone(0.20, 720.0, 150.0, 2, 0.45, 0.35)
	streams["bow"] = _tone(0.16, 950.0, 320.0, 1, 0.28, 0.4)
	streams["parry"] = _tone(0.32, 2500.0, 1700.0, 1, 0.05, 0.5)
	streams["block"] = _tone(0.13, 980.0, 520.0, 1, 0.3, 0.4)
	streams["guard_up"] = _tone(0.09, 520.0, 720.0, 1, 0.08, 0.25)
	streams["heal"] = _tone(0.38, 480.0, 1050.0, 0, 0.0, 0.4)
	streams["flask"] = _tone(0.18, 280.0, 520.0, 0, 0.08, 0.3)
	streams["hop"] = _tone(0.12, 300.0, 540.0, 1, 0.08, 0.28)
	streams["groan"] = _tone(0.42, 150.0, 88.0, 2, 0.22, 0.32)
	streams["lunge"] = _tone(0.22, 250.0, 520.0, 2, 0.28, 0.36)
	streams["throw"] = _tone(0.12, 720.0, 1150.0, 1, 0.28, 0.28)
	streams["stun"] = _tone(0.26, 1250.0, 560.0, 1, 0.08, 0.4)
	streams["clink"] = _tone(0.09, 2700.0, 1500.0, 1, 0.08, 0.3)
	streams["coin"] = _tone(0.14, 1250.0, 1850.0, 0, 0.0, 0.28)
	streams["cell"] = _tone(0.22, 820.0, 1650.0, 0, 0.0, 0.3)
	streams["portal"] = _tone(0.55, 200.0, 950.0, 0, 0.16, 0.38)
	streams["dead"] = _tone(0.95, 320.0, 55.0, 2, 0.35, 0.55)
	streams["start"] = _tone(0.30, 380.0, 820.0, 0, 0.0, 0.32)
	streams["magic"] = _tone(0.24, 1400.0, 2600.0, 0, 0.10, 0.22)
	streams["pet"] = _tone(0.14, 900.0, 1500.0, 1, 0.20, 0.22)
	streams["stand"] = _tone(0.36, 200.0, 900.0, 1, 0.45, 0.42)
	streams["item"] = _tone(0.34, 620.0, 1240.0, 0, 0.0, 0.34)
	streams["gun"] = _tone(0.10, 900.0, 260.0, 1, 0.75, 0.42)
	streams["sniper"] = _tone(0.42, 520.0, 90.0, 2, 0.65, 0.55)
	streams["reload"] = _tone(0.14, 260.0, 180.0, 1, 0.55, 0.30)
	streams["reload_done"] = _tone(0.12, 520.0, 880.0, 1, 0.20, 0.30)
	streams["draw"] = _tone(0.16, 320.0, 520.0, 2, 0.30, 0.18)
	streams["chest"] = _tone(0.40, 380.0, 1100.0, 0, 0.10, 0.36)


func play(sound: String, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	if muted:
		return
	if not streams.has(sound):
		return
	if players.size() == 0:
		return
	var p: AudioStreamPlayer = players[idx]
	idx = (idx + 1) % players.size()
	p.stream = streams[sound]
	p.pitch_scale = clampf(pitch, 0.35, 2.6)
	p.volume_db = vol_db - 4.0
	p.play()


## 主音量（0~1），走 Master 总线，不影响单次播放的相对音量
func set_master_volume(v: float) -> void:
	var k: float = clampf(v, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, k)))
	AudioServer.set_bus_mute(0, k <= 0.001)


func set_muted(m: bool) -> void:
	muted = m
	AudioServer.set_bus_mute(0, m)
