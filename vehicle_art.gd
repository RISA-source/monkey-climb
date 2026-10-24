extends Node2D

const VehiclesS := preload("res://vehicles.gd")
## Code-drawn vector vehicles with a visible driver. Local origin = chassis center,
## +x is forward (right), +y is down. Layers: back -> driver -> front (-> wheels in menu preview).

var vid := "buggy"
var driver: Sprite2D
var wheels_layer: Layer = null

static func P(a: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, a.size(), 2):
		out.append(Vector2(a[i], a[i + 1]))
	return out

static func poly(ci: CanvasItem, pts: Array, col: Color) -> void:
	ci.draw_colored_polygon(P(pts), col)

static func line(ci: CanvasItem, pts: Array, col: Color, w: float) -> void:
	ci.draw_polyline(P(pts), col, w, true)

static func paint_wheel(ci: CanvasItem, r: float) -> void:
	ci.draw_circle(Vector2.ZERO, r, Color("#2b2f3a"))
	ci.draw_circle(Vector2.ZERO, r * 0.64, Color("#cfd6e4"))
	ci.draw_circle(Vector2.ZERO, r * 0.5, Color("#aeb8cc"))
	for i in range(5):
		var a := i * TAU / 5.0
		ci.draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * r * 0.58, Color("#7e8aa3"), 3.0)
	ci.draw_circle(Vector2.ZERO, r * 0.2, Color("#2b2f3a"))

func setup(vehicle_id: String, char_id: String, with_wheels: bool) -> void:
	vid = vehicle_id
	var spec := VehiclesS.by_id(vid)
	var back := Layer.new()
	back.front = false
	back.art = self
	add_child(back)
	driver = Sprite2D.new()
	driver.texture = VehiclesS.portrait(char_id, "hold")
	driver.scale = Vector2.ONE * float(spec["driver_scale"])
	driver.position = spec["seat"]
	add_child(driver)
	var fr := Layer.new()
	fr.front = true
	fr.art = self
	add_child(fr)
	if with_wheels:
		wheels_layer = Layer.new()
		wheels_layer.wheels = true
		wheels_layer.art = self
		add_child(wheels_layer)

func set_pose(char_id: String, pose: String) -> void:
	driver.texture = VehiclesS.portrait(char_id, pose)

class Layer extends Node2D:
	var front := false
	var wheels := false
	var art: Node2D
	func _draw() -> void:
		if wheels:
			var spec := VehiclesS.by_id(art.vid)
			for w in spec["wheels"]:
				draw_set_transform(w as Vector2)
				art.paint_wheel(self, float(spec["r"]))
			draw_set_transform(Vector2.ZERO)
		else:
			art.paint(self, art.vid, front)

static func paint(ci: CanvasItem, id: String, front: bool) -> void:
	match id:
		"buggy": _buggy(ci, front)
		"suv_military": _jeep(ci, front)
		"van_small": _pickup(ci, front)
		"vintage": _roadster(ci, front)
		"sports_race": _racer(ci, front)

static func _buggy(ci: CanvasItem, front: bool) -> void:
	var tube := Color("#3d4452")
	if not front:
		line(ci, [-72, 14, -60, -56, 28, -56, 50, -8], tube, 6)
		line(ci, [-60, -56, -34, 10], tube, 5)
		poly(ci, [-44, -34, -24, -34, -24, 10, -44, 10], Color("#a3441a"))
	else:
		poly(ci, [-90, 24, -88, 0, -42, -8, 8, -10, 40, -2, 72, 6, 94, 12, 92, 26], Color("#f2762e"))
		poly(ci, [-88, 12, 92, 18, 92, 26, -90, 24], Color("#c9561b"))
		poly(ci, [-30, -8, 8, -10, 14, -4, -26, 0], Color("#ffa066"))
		poly(ci, [84, 8, 98, 10, 98, 26, 90, 26], Color("#3d4452"))
		ci.draw_circle(Vector2(82, 4), 6, Color("#ffe27a"))
		line(ci, [18, -10, 26, -30], Color("#3d4452"), 5)
		poly(ci, [30, -6, 38, -34, 44, -34, 40, -6], Color(0.75, 0.9, 0.97, 0.7))

static func _jeep(ci: CanvasItem, front: bool) -> void:
	var tube := Color("#3d4452")
	if not front:
		line(ci, [-80, -10, -76, -60, -20, -60], tube, 6)
		poly(ci, [-46, -30, -26, -30, -26, 8, -46, 8], Color("#3f5220"))
	else:
		poly(ci, [-92, 24, -94, -12, -34, -12, -30, -6, 36, -6, 40, -14, 48, -14, 52, -4, 94, 4, 94, 26], Color("#7a9a3e"))
		poly(ci, [-94, 12, 94, 14, 94, 26, -92, 24], Color("#5b7a2a"))
		poly(ci, [-90, -10, -36, -10, -36, -4, -90, -4], Color("#93b653"))
		poly(ci, [36, -8, 46, -42, 52, -42, 48, -8], Color(0.75, 0.9, 0.97, 0.75))
		line(ci, [36, -8, 46, -42], tube, 4)
		poly(ci, [92, 4, 100, 6, 100, 26, 92, 26], Color("#3d4452"))
		ci.draw_circle(Vector2(88, 2), 6, Color("#ffe27a"))
		ci.draw_circle(Vector2(-100, 4), 15, Color("#2b2f3a"))
		ci.draw_circle(Vector2(-100, 4), 8, Color("#aeb8cc"))

static func _pickup(ci: CanvasItem, front: bool) -> void:
	if not front:
		poly(ci, [-24, -10, -14, -46, 24, -46, 34, -10], Color("#2f4a63"))
		# the lantern riding in the bed
		ci.draw_circle(Vector2(-64, -26), 22, Color(1.0, 0.82, 0.35, 0.28))
		poly(ci, [-72, -14, -72, -34, -56, -34, -56, -14], Color("#d94f2b"))
		poly(ci, [-70, -38, -58, -38, -58, -34, -70, -34], Color("#7a3416"))
		ci.draw_circle(Vector2(-64, -24), 6, Color("#ffe27a"))
	else:
		poly(ci, [-98, 24, -98, -12, -30, -12, -30, 24], Color("#d94a3d"))
		poly(ci, [-98, 12, -30, 12, -30, 24, -98, 24], Color("#a8332a"))
		poly(ci, [-98, -12, -30, -12, -30, -6, -98, -6], Color("#ee6a5d"))
		poly(ci, [-30, 24, -30, -10, 36, -10, 70, -4, 96, 6, 98, 24], Color("#d94a3d"))
		poly(ci, [-30, 12, 98, 14, 98, 24, -30, 24], Color("#a8332a"))
		poly(ci, [-16, -52, 26, -52, 26, -46, -16, -46], Color("#d94a3d"))
		line(ci, [26, -48, 38, -10], Color("#a8332a"), 6)
		line(ci, [-16, -48, -28, -10], Color("#a8332a"), 6)
		ci.draw_circle(Vector2(92, 4), 6, Color("#ffe27a"))

static func _roadster(ci: CanvasItem, front: bool) -> void:
	if not front:
		poly(ci, [-46, -28, -26, -28, -26, 6, -46, 6], Color("#1f4a82"))
	else:
		poly(ci, [-98, 24, -98, 6, -72, -2, -30, -2, -24, -8, 8, -8, 14, -2, 62, 4, 100, 16, 100, 26], Color("#3a7bd5"))
		poly(ci, [-98, 14, 100, 18, 100, 26, -98, 24], Color("#2c5fa8"))
		line(ci, [-94, 10, -30, 2, 14, 2, 96, 14], Color("#f4efe0"), 4)
		poly(ci, [8, -8, 20, -34, 25, -34, 16, -6], Color(0.75, 0.9, 0.97, 0.75))
		ci.draw_circle(Vector2(90, 10), 8, Color("#f4efe0"))
		ci.draw_circle(Vector2(90, 10), 4, Color("#ffe27a"))
		poly(ci, [-100, 6, -92, 8, -92, 22, -100, 20], Color("#9aa7bd"))

static func _racer(ci: CanvasItem, front: bool) -> void:
	if not front:
		line(ci, [-92, -24, -90, 6], Color("#9a2a1c"), 5)
		line(ci, [-80, -24, -78, 2], Color("#9a2a1c"), 5)
		poly(ci, [-44, -18, -26, -18, -26, 6, -44, 6], Color("#8f6208"))
	else:
		poly(ci, [-98, 24, -100, 8, -72, 2, -30, -2, -10, -8, 12, -8, 42, 2, 100, 16, 102, 26], Color("#f4b92a"))
		poly(ci, [-98, 16, 102, 20, 102, 26, -98, 24], Color("#c98d10"))
		poly(ci, [-60, 8, 60, 10, 60, 15, -60, 13], Color("#fff6e0"))
		poly(ci, [-106, -30, -72, -30, -72, -24, -106, -24], Color("#e8412c"))
		poly(ci, [12, -8, 22, -22, 27, -22, 20, -6], Color(0.75, 0.9, 0.97, 0.75))
		ci.draw_circle(Vector2(94, 14), 5, Color("#ffe27a"))
