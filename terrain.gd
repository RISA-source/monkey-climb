extends Node2D
## Endless hills, built in chunks ahead of the car and freed behind it.
## Also places pickups: keys (score) and lantern oil (fuel).

signal collected(kind: String)

const CHUNK_W := 800.0
const SEG := 20.0
const BASE_Y := 420.0
const ZONE_W := 8000.0      # each biome lasts 8000 px (160 m)
const BIOMES := [
	{"name": "grass",  "top": Color("#2c9e5a"), "fill": Color("#7b5a3a"), "props": ["tree", "bush1", "bush2"]},
	{"name": "forest", "top": Color("#0f8671"), "fill": Color("#3f6a5f"), "props": ["treePine", "bush1", "treePine"]},
	{"name": "fall",   "top": Color("#d9702a"), "fill": Color("#9c553a"), "props": ["treeOrange", "treePineOrange", "bushOrange1"]},
	{"name": "desert", "top": Color("#d8b978"), "fill": Color("#cfa866"), "props": ["cactus1", "cactus2", "treePalm"]},
]

var chunks := {}            # chunk index -> StaticBody2D
var taken := {}             # pickup id -> true (so they don't respawn)
var prop_cache := {}

static func biome_at(x: float) -> int:
	return posmod(int(floor(x / ZONE_W)), BIOMES.size())

static func ground_y(x: float) -> float:
	# Hills get taller the farther you go. Flat start so the car can settle.
	var ramp := clampf(x / 9000.0, 0.0, 1.0)
	var amp := lerpf(25.0, 115.0, ramp)
	var flat := clampf((x - 300.0) / 500.0, 0.0, 1.0)
	var h := sin(x * 0.0035) * amp + sin(x * 0.008 + 1.3) * amp * 0.4 + sin(x * 0.02) * amp * 0.1
	return BASE_Y - h * flat

func update(cam_x: float) -> void:
	var first := int(floor((cam_x - 1200.0) / CHUNK_W))
	var last := int(floor((cam_x + 2200.0) / CHUNK_W))
	for i in range(first, last + 1):
		if not chunks.has(i):
			_make_chunk(i)
	for i in chunks.keys():
		if i < first - 1 or i > last + 1:
			chunks[i].queue_free()
			chunks.erase(i)

func reset() -> void:
	for c in chunks.values():
		c.queue_free()
	chunks.clear()
	taken.clear()

func _make_chunk(idx: int) -> void:
	var body := StaticBody2D.new()
	var mat := PhysicsMaterial.new()
	mat.friction = 1.0
	mat.bounce = 0.0
	body.physics_material_override = mat
	add_child(body)
	chunks[idx] = body

	var x0 := idx * CHUNK_W
	var top := PackedVector2Array()
	var steps := int(CHUNK_W / SEG)
	for s in range(steps + 1):
		var x := x0 + s * SEG
		top.append(Vector2(x, ground_y(x)))

	# collision: a line of segments along the surface
	var segs := PackedVector2Array()
	for s in range(top.size() - 1):
		segs.append(top[s])
		segs.append(top[s + 1])
	var shape := ConcavePolygonShape2D.new()
	shape.segments = segs
	var col := CollisionShape2D.new()
	col.shape = shape
	body.add_child(col)

	# visuals: dirt fill + grass line (swap for Kenney tiles later if you like)
	var fill := PackedVector2Array(top)
	fill.append(Vector2(x0 + CHUNK_W, 1600))
	fill.append(Vector2(x0, 1600))
	var biome: Dictionary = BIOMES[biome_at(x0)]
	var poly := Polygon2D.new()
	poly.polygon = fill
	poly.color = biome["fill"]
	body.add_child(poly)
	_spawn_props(idx, biome, body)
	var grass := Line2D.new()
	grass.points = top
	grass.width = 16
	grass.default_color = biome["top"]
	grass.joint_mode = Line2D.LINE_JOINT_ROUND
	body.add_child(grass)

	if idx >= 1:
		_spawn_pickups(idx, body)

func _spawn_props(idx: int, biome: Dictionary, parent: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = idx * 104729 + 7
	var names: Array = biome["props"]
	var x0 := idx * CHUNK_W
	for i in range(4):
		var n: String = names[rng.randi() % names.size()]
		if not prop_cache.has(n):
			prop_cache[n] = load("res://assets/props/%s.png" % n)
		var tex: Texture2D = prop_cache[n]
		var x := x0 + rng.randf_range(20.0, CHUNK_W - 20.0)
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.centered = false
		var k := rng.randf_range(0.8, 1.15)
		sp.scale = Vector2(k, k)
		sp.position = Vector2(x - tex.get_width() * k / 2.0, ground_y(x) + 6.0 - tex.get_height() * k)
		sp.z_index = -1
		parent.add_child(sp)

func _spawn_pickups(idx: int, parent: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = idx * 7919 + 13
	var x0 := idx * CHUNK_W
	# a trail of 4 keys
	var kx := x0 + rng.randf_range(60.0, CHUNK_W - 260.0)
	for k in range(4):
		var x := kx + k * 45.0
		_add_pickup("key", "k%d_%d" % [idx, k], Vector2(x, ground_y(x) - 75.0), parent)
	# sometimes a jar of lantern oil
	if rng.randf() < 0.6:
		var ox := x0 + rng.randf_range(60.0, CHUNK_W - 60.0)
		_add_pickup("oil", "o%d" % idx, Vector2(ox, ground_y(ox) - 50.0), parent)

func _add_pickup(kind: String, id: String, pos: Vector2, parent: Node) -> void:
	if taken.has(id):
		return
	var p := Pickup.new()
	p.kind = kind
	p.position = pos
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 22.0
	cs.shape = c
	p.add_child(cs)
	p.body_entered.connect(func(b: Node) -> void:
		if b.is_in_group("car_part") and not taken.has(id):
			taken[id] = true
			collected.emit(kind)
			p.queue_free())
	parent.add_child(p)

class Pickup extends Area2D:
	var kind := "key"
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var bob := sin(t * 3.0 + position.x * 0.01) * 4.0
		draw_set_transform(Vector2(0, bob))
		if kind == "key":
			var gold := Color("#f2c230")
			draw_circle(Vector2(-7, 0), 7, gold)
			draw_circle(Vector2(-7, 0), 3, Color(0.3, 0.2, 0.05))
			draw_rect(Rect2(-1, -2, 17, 4), gold)
			draw_rect(Rect2(10, 2, 3, 6), gold)
			draw_rect(Rect2(5, 2, 3, 5), gold)
		else:
			draw_circle(Vector2.ZERO, 20, Color(1.0, 0.8, 0.3, 0.25))
			draw_rect(Rect2(-9, -9, 18, 20), Color("#c0562b"))
			draw_rect(Rect2(-6, -14, 12, 5), Color("#7a3416"))
			draw_circle(Vector2(0, 0), 4, Color("#ffd35a"))
