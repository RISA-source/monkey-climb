extends Node2D

const VehiclesS := preload("res://vehicles.gd")
const VehicleArtS := preload("res://vehicle_art.gd")
const CarS := preload("res://car.gd")
const TerrainS := preload("res://terrain.gd")
## Monk Key Climb: drive the lantern vehicle as far as you can.
## Oil jars refill the lantern, keys are your currency (unlock new vehicles).

const GROUND_Y := 420.0
const SPAWN_X := 150.0
const SAVE_PATH := "user://save.json"
const FUEL_DRAIN := 2.4
const FUEL_DRAIN_GAS := 2.0
const OIL_REFILL := 35.0

var car: CarS
var terrain: TerrainS
var cam: Camera2D
var fuel := 100.0
var keys := 0
var best := 0.0
var total_keys := 0
var distance := 0.0
var state := "menu"              # menu | play | over
var flip_time := 0.0
var stall_time := 0.0
var react_t := 0.0
var ui_gas := false
var ui_brake := false
var unlocked: Array = ["buggy"]
var sel_vehicle := "buggy"
var sel_char := "male_adv"
var spec := {}
var v_idx := 0
var c_idx := 0
var pose := ""

var lbl_dist: Label
var lbl_keys: Label
var lbl_best: Label
var bar: ProgressBar
var hud_layer: CanvasLayer
var panel: PanelContainer
var lbl_over: Label
var btn_refuel: Button
var menu: Control
var m_art: VehicleArtS
var m_stage: Node2D
var m_vname: Label
var m_vdesc: Label
var m_vstats: Label
var m_vbtn: Button
var m_ctex: TextureRect
var m_cname: Label
var m_keys: Label

func _ready() -> void:
	_load_save()
	_build_backdrop()
	terrain = TerrainS.new()
	terrain.collected.connect(_on_collected)
	add_child(terrain)
	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	add_child(cam)
	_build_hud()
	_build_menu()
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--char="): sel_char = a.substr(7)
		if a.begins_with("--vehicle="): sel_vehicle = a.substr(10)
	for i in VehiclesS.DATA.size():
		if VehiclesS.DATA[i]["id"] == sel_vehicle: v_idx = i
	for i in VehiclesS.CHARACTERS.size():
		if VehiclesS.CHARACTERS[i]["id"] == sel_char: c_idx = i
	if "--selftest" in args:
		for a in args:
			if a.begins_with("--vehicle="):
				sel_vehicle = a.substr(10)
			if a.begins_with("--char="):
				sel_char = a.substr(7)
		if "--menu" in args:
			_open_menu()
		else:
			_start_run()
		_run_test(args)
	else:
		_open_menu()

# ---------- run lifecycle ----------
func _start_run() -> void:
	spec = VehiclesS.by_id(sel_vehicle)
	if car != null:
		remove_child(car)
		car.queue_free()
	terrain.reset()
	car = CarS.new()
	add_child(car)
	var spawn := Vector2(SPAWN_X, GROUND_Y - CarS.spawn_height(spec) - 8.0)
	car.build(spec, spawn, sel_char)
	terrain.update(SPAWN_X)
	fuel = 100.0
	keys = 0
	distance = 0.0
	flip_time = 0.0
	stall_time = 0.0
	state = "play"
	panel.visible = false
	menu.visible = false
	hud_layer.visible = true
	cam.global_position = spawn + Vector2(300, -110)
	cam.reset_smoothing()

func _physics_process(delta: float) -> void:
	if state != "play":
		return
	var gas := ui_gas or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_UP)
	var brk := ui_brake or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_DOWN)
	car.gas = gas and fuel > 0.0
	car.brake = brk and fuel > 0.0
	var k: float = float(spec["drain"])
	fuel -= FUEL_DRAIN * k * delta
	if gas:
		fuel -= FUEL_DRAIN_GAS * k * delta
	fuel = maxf(fuel, 0.0)
	var x := car.chassis.global_position.x
	distance = maxf(distance, (x - SPAWN_X) / 50.0)
	terrain.update(x)
	if car.is_flipped():
		flip_time += delta
		if flip_time > 1.2:
			_game_over("Tipped over!")
	else:
		flip_time = 0.0
	if fuel <= 0.0 and car.speed() < 20.0:
		stall_time += delta
		if stall_time > 1.0:
			_game_over("The lantern went out.")
	else:
		stall_time = 0.0
	if car.chassis.global_position.y > 2000.0:
		_game_over("Fell off the mountain!")

func _process(delta: float) -> void:
	if car != null and car.chassis != null and state != "menu":
		cam.global_position = car.chassis.global_position + Vector2(300, -110)
	lbl_dist.text = "%d m" % int(distance)
	lbl_keys.text = "Keys: %d" % keys
	lbl_best.text = "Best: %d m" % int(best)
	bar.value = fuel
	react_t = maxf(0.0, react_t - delta)
	var want := "hold"
	if state == "over":
		want = "hurt"
	elif react_t > 0.0:
		want = "cheer"
	if want != pose:
		pose = want
		if car != null and car.art != null:
			car.art.set_pose(sel_char, pose)

func _on_collected(kind: String) -> void:
	if kind == "key":
		keys += 1
		react_t = 0.6
	else:
		fuel = minf(100.0, fuel + OIL_REFILL)

func _game_over(reason: String) -> void:
	state = "over"
	car.gas = false
	car.brake = false
	total_keys += keys
	var new_best := distance > best
	if new_best:
		best = distance
	_save()
	var extra := "\nNew best!" if new_best else ""
	lbl_over.text = "%s\n\nDistance: %d m   Keys: +%d\nBest: %d m   Total keys: %d%s" % [reason, int(distance), keys, int(best), total_keys, extra]
	btn_refuel.visible = fuel <= 0.0
	panel.visible = true

func _on_refuel() -> void:
	# PLACEHOLDER for a rewarded ad: call your AdMob plugin here and run
	# _grant_refuel() from its "reward earned" callback.
	_show_rewarded_ad(_grant_refuel)

func _show_rewarded_ad(on_reward: Callable) -> void:
	on_reward.call()

func _grant_refuel() -> void:
	fuel = 60.0
	stall_time = 0.0
	flip_time = 0.0
	car.chassis.rotation = 0.0
	car.chassis.angular_velocity = 0.0
	car.chassis.global_position += Vector2(0, -80)
	state = "play"
	panel.visible = false
	pose = ""

# ---------- save / load ----------
func _load_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var d = JSON.parse_string(f.get_as_text())
		if typeof(d) == TYPE_DICTIONARY:
			best = float(d.get("best", 0.0))
			total_keys = int(d.get("total_keys", 0))
			unlocked = d.get("unlocked", ["buggy"])
			sel_vehicle = str(d.get("vehicle", "buggy"))
			sel_char = str(d.get("character", "male_adv"))

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"best": best, "total_keys": total_keys, "unlocked": unlocked,
		"vehicle": sel_vehicle, "character": sel_char}))

# ---------- menu ----------
func _open_menu() -> void:
	state = "menu"
	panel.visible = false
	hud_layer.visible = false
	menu.visible = true
	_refresh_menu()

func _refresh_menu() -> void:
	var v: Dictionary = VehiclesS.DATA[v_idx]
	if m_art != null:
		m_stage.remove_child(m_art)
		m_art.queue_free()
	m_art = VehicleArtS.new()
	m_art.setup(v["id"], sel_char, true)
	m_stage.add_child(m_art)
	m_vname.text = v["name"]
	m_vdesc.text = v["desc"]
	m_vstats.text = "Top speed %d   Oil use %d%%   Weight %.1f" % [int(float(v["speed"]) / 10.0), int(float(v["drain"]) * 100.0), float(v["mass"])]
	var owned: bool = v["id"] in unlocked
	if owned:
		m_vbtn.text = "DRIVE"
		m_vbtn.disabled = false
	else:
		m_vbtn.text = "Unlock for %d keys" % int(v["cost"])
		m_vbtn.disabled = total_keys < int(v["cost"])
	var c: Dictionary = VehiclesS.CHARACTERS[c_idx]
	m_ctex.texture = VehiclesS.portrait(c["id"], "idle")
	m_cname.text = c["name"]
	m_keys.text = "Keys: %d    Best: %d m" % [total_keys, int(best)]

func _vehicle_step(d: int) -> void:
	v_idx = posmod(v_idx + d, VehiclesS.DATA.size())
	_refresh_menu()

func _char_step(d: int) -> void:
	c_idx = posmod(c_idx + d, VehiclesS.CHARACTERS.size())
	sel_char = VehiclesS.CHARACTERS[c_idx]["id"]
	pose = ""
	_save()
	_refresh_menu()

func _vehicle_action() -> void:
	var v: Dictionary = VehiclesS.DATA[v_idx]
	if v["id"] in unlocked:
		sel_vehicle = v["id"]
		_save()
		_start_run()
	elif total_keys >= int(v["cost"]):
		total_keys -= int(v["cost"])
		unlocked.append(v["id"])
		_save()
		_refresh_menu()

func _build_menu() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	menu = Control.new()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(menu)
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.12, 0.2, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(dim)
	_text(menu, "MONK KEY CLIMB", Vector2(0, 28), Vector2(1280, 60), 46, true)
	m_keys = _text(menu, "", Vector2(0, 92), Vector2(1280, 30), 22, true)
	# vehicle picker (left)
	_text(menu, "Vehicle", Vector2(120, 150), Vector2(520, 30), 22, true)
	menu.add_child(_btn("<", Vector2(110, 270), Vector2(70, 90), func() -> void: _vehicle_step(-1)))
	m_stage = Node2D.new()
	m_stage.position = Vector2(320, 350)
	m_stage.scale = Vector2(1.25, 1.25)
	menu.add_child(m_stage)
	menu.add_child(_btn(">", Vector2(460, 270), Vector2(70, 90), func() -> void: _vehicle_step(1)))
	m_vname = _text(menu, "", Vector2(110, 430), Vector2(420, 40), 30, true)
	m_vdesc = _text(menu, "", Vector2(110, 472), Vector2(420, 30), 18, true)
	m_vstats = _text(menu, "", Vector2(110, 504), Vector2(420, 30), 18, true)
	# character picker (right)
	_text(menu, "Driver", Vector2(700, 150), Vector2(460, 30), 22, true)
	menu.add_child(_btn("<", Vector2(700, 270), Vector2(70, 90), func() -> void: _char_step(-1)))
	m_ctex = _tex(menu, Vector2(790, 190), Vector2(180, 240))
	menu.add_child(_btn(">", Vector2(990, 270), Vector2(70, 90), func() -> void: _char_step(1)))
	m_cname = _text(menu, "", Vector2(700, 440), Vector2(360, 40), 30, true)
	m_vbtn = _btn("DRIVE", Vector2(420, 580), Vector2(440, 84), _vehicle_action)
	m_vbtn.add_theme_font_size_override("font_size", 34)
	menu.add_child(m_vbtn)

func _text(parent: Node, t: String, pos: Vector2, sz: Vector2, fs: int, center: bool) -> Label:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.size = sz
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", Color.WHITE)
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	return l

func _tex(parent: Node, pos: Vector2, sz: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.position = pos
	t.size = sz
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(t)
	return t

func _btn(t: String, pos: Vector2, sz: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.position = pos
	b.size = sz
	b.custom_minimum_size = sz
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 30)
	b.pressed.connect(cb)
	return b

# ---------- HUD ----------
func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	var top := HBoxContainer.new()
	top.position = Vector2(24, 16)
	top.add_theme_constant_override("separation", 28)
	hud_layer.add_child(top)
	lbl_dist = _hud_label(top, 34)
	lbl_keys = _hud_label(top, 26)
	lbl_best = _hud_label(top, 22)
	var fl := Label.new()
	fl.text = "Lantern oil"
	fl.position = Vector2(24, 64)
	fl.add_theme_font_size_override("font_size", 16)
	hud_layer.add_child(fl)
	bar = ProgressBar.new()
	bar.position = Vector2(24, 90)
	bar.size = Vector2(260, 22)
	bar.max_value = 100
	bar.show_percentage = false
	hud_layer.add_child(bar)
	var brake_btn := _touch_button("BRAKE", Vector2(30, 560))
	brake_btn.button_down.connect(func() -> void: ui_brake = true)
	brake_btn.button_up.connect(func() -> void: ui_brake = false)
	hud_layer.add_child(brake_btn)
	var gas_btn := _touch_button("GAS", Vector2(1280 - 30 - 230, 560))
	gas_btn.button_down.connect(func() -> void: ui_gas = true)
	gas_btn.button_up.connect(func() -> void: ui_gas = false)
	hud_layer.add_child(gas_btn)
	var over_layer := CanvasLayer.new()
	over_layer.layer = 4
	add_child(over_layer)
	panel = PanelContainer.new()
	panel.position = Vector2(390, 150)
	panel.custom_minimum_size = Vector2(500, 380)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)
	lbl_over = Label.new()
	lbl_over.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_over.add_theme_font_size_override("font_size", 24)
	vb.add_child(lbl_over)
	var retry := Button.new()
	retry.text = "Try again"
	retry.custom_minimum_size = Vector2(0, 56)
	retry.pressed.connect(_start_run)
	vb.add_child(retry)
	btn_refuel = Button.new()
	btn_refuel.text = "Refill lantern (watch ad)"
	btn_refuel.custom_minimum_size = Vector2(0, 56)
	btn_refuel.pressed.connect(_on_refuel)
	vb.add_child(btn_refuel)
	var to_menu := Button.new()
	to_menu.text = "Garage (change vehicle / driver)"
	to_menu.custom_minimum_size = Vector2(0, 56)
	to_menu.pressed.connect(_open_menu)
	vb.add_child(to_menu)
	over_layer.add_child(panel)
	panel.visible = false

func _hud_label(parent: Node, size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("outline_size", 6)
	parent.add_child(l)
	return l

func _touch_button(text: String, pos: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(230, 120)
	b.custom_minimum_size = Vector2(230, 120)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 32)
	b.modulate = Color(1, 1, 1, 0.75)
	return b

func _build_backdrop() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	var hills := Backdrop.new()
	hills.main = self
	layer.add_child(hills)
	hills.build()

class Backdrop extends Node2D:
	## Four biome backgrounds (Kenney Background Elements, CC0), tiled with parallax
	## and cross-faded as you drive from one biome zone into the next.
	const TILE := 922.0   # 1024 px image drawn at 0.9 scale
	var main: Node2D
	var groups: Array = []   # per biome: Array of Sprite2D tiles
	func build() -> void:
		for name in ["grass", "forest", "fall", "desert"]:
			var tex: Texture2D = load("res://assets/backgrounds/%s.png" % name)
			var tiles: Array = []
			for i in range(3):
				var sp := Sprite2D.new()
				sp.texture = tex
				sp.centered = false
				sp.scale = Vector2(0.9, 0.9)
				sp.position = Vector2(i * TILE, -190)
				add_child(sp)
				tiles.append(sp)
			groups.append(tiles)
	func _process(_d: float) -> void:
		var cx := 0.0
		if main != null and main.cam != null:
			cx = main.cam.global_position.x
		var f: float = (cx + 640.0) / TerrainS.ZONE_W
		var cur := posmod(int(floor(f)), 4)
		var nxt := (cur + 1) % 4
		var frac: float = f - floor(f)
		var a := clampf((frac - 0.9) / 0.1, 0.0, 1.0)
		var off := -fposmod(cx * 0.12, TILE)
		for b in range(groups.size()):
			var tiles: Array = groups[b]
			var vis: bool = (b == cur) or (b == nxt and a > 0.0)
			for i in range(tiles.size()):
				var sp: Sprite2D = tiles[i]
				sp.visible = vis
				sp.position.x = off + i * TILE
				sp.z_index = 1 if b == nxt else 0
				sp.modulate.a = a if b == nxt else 1.0

# ---------- headless self-test ----------
func _run_test(args: PackedStringArray) -> void:
	ui_gas = not ("--idle" in args)
	var secs := 12.0
	for a in args:
		if a.begins_with("--secs="):
			secs = float(a.substr(7))
	var t := 0.0
	while t < secs:
		await get_tree().create_timer(3.0).timeout
		t += 3.0
		if car == null:
			continue
		print("  t=", int(t), " x=", int(car.chassis.global_position.x), " y=", int(car.chassis.global_position.y), " vx=", int(car.chassis.linear_velocity.x), " spin=", snappedf(car.wheels[0].angular_velocity, 0.1), " rot=", snappedf(car.chassis.rotation, 0.01), " grounded=", car.is_grounded())
	for a in args:
		if a.begins_with("--shot="):
			get_viewport().get_texture().get_image().save_png(a.substr(7))
	if car == null:
		get_tree().quit()
		return
	print("TEST ", sel_vehicle, " x=", int(car.chassis.global_position.x), " dist=", int(distance), " fuel=", int(fuel), " keys=", keys, " state=", state, " rot=", snappedf(car.chassis.rotation, 0.01))
	get_tree().quit()
