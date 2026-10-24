extends Node2D

const VehicleArtS := preload("res://vehicle_art.gd")
## A vehicle built from a Vehicles.DATA entry: drawn body + driver, two sprung wheels.

const AIR_TORQUE := 60000.0

var chassis: Chassis
var wheels: Array[Wheel] = []
var gas := false
var brake := false
var spec := {}
var art: VehicleArtS
var drive_torque := 90000.0
var max_spin := 20.0

static func spawn_height(sp: Dictionary) -> float:
	var w0: Vector2 = sp["wheels"][0]
	return w0.y + float(sp["r"])   # chassis center -> wheel bottom

func build(sp: Dictionary, spawn: Vector2, char_id: String) -> void:
	spec = sp
	var rad: float = float(sp["r"])
	var mass_k: float = float(sp["mass"]) / 2.0
	drive_torque = float(sp["torque"])
	max_spin = float(sp["speed"]) / rad

	chassis = Chassis.new()
	chassis.mass = float(sp["mass"])
	chassis.position = spawn
	chassis.add_to_group("car_part")
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = sp["body_size"]
	cs.shape = rs
	cs.position = sp["body_off"]
	chassis.add_child(cs)
	art = VehicleArtS.new()
	art.setup(sp["id"], char_id, false)
	chassis.add_child(art)
	add_child(chassis)

	for wp in sp["wheels"]:
		var off := wp as Vector2
		var w := Wheel.new()
		w.radius = rad
		w.mass = 1.0
		w.position = spawn + off
		w.add_to_group("car_part")
		w.contact_monitor = true
		w.max_contacts_reported = 4
		var m := PhysicsMaterial.new()
		m.friction = 1.4
		m.bounce = 0.0
		w.physics_material_override = m
		var wc := CollisionShape2D.new()
		var circ := CircleShape2D.new()
		circ.radius = rad
		wc.shape = circ
		w.add_child(wc)
		add_child(w)
		wheels.append(w)

		var base := spawn + off
		var groove := GrooveJoint2D.new()
		groove.position = base + Vector2(0, -12)
		groove.length = 26.0
		groove.initial_offset = 12.0
		groove.node_a = chassis.get_path()
		groove.node_b = w.get_path()
		add_child(groove)
		var spring := DampedSpringJoint2D.new()
		spring.position = base + Vector2(0, -12)
		spring.node_a = chassis.get_path()
		spring.node_b = w.get_path()
		spring.length = 12.0
		spring.rest_length = 5.0
		spring.stiffness = 300.0 * mass_k
		spring.damping = 16.0 * mass_k
		add_child(spring)

func _physics_process(_delta: float) -> void:
	if chassis == null:
		return
	var dir := 0.0
	if gas: dir += 1.0
	if brake: dir -= 1.0
	if dir != 0.0:
		for w in wheels:
			if absf(w.angular_velocity) < max_spin or signf(w.angular_velocity) != dir:
				w.apply_torque(dir * drive_torque)
		if not is_grounded():
			chassis.apply_torque(-dir * AIR_TORQUE * float(spec["mass"]) / 2.0)

func is_grounded() -> bool:
	for w in wheels:
		if w.get_colliding_bodies().size() > 0:
			return true
	return false

func is_flipped() -> bool:
	return absf(wrapf(chassis.rotation, -PI, PI)) > 2.0

func speed() -> float:
	return chassis.linear_velocity.length()

class Chassis extends RigidBody2D:
	pass

class Wheel extends RigidBody2D:
	var radius := 25.0
	func _process(_delta: float) -> void:
		queue_redraw()
	func _draw() -> void:
		VehicleArtS.paint_wheel(self, radius)
