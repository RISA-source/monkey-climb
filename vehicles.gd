extends RefCounted
## Vehicle + driver catalog. Art is drawn in vehicle_art.gd (same ids).
## Coordinates are pixels, origin = chassis center, +y down.

const DATA := [
	{"id": "buggy", "name": "Buggy", "cost": 0,
	 "wheels": [Vector2(-62, 30), Vector2(64, 30)], "r": 27.0,
	 "body_size": Vector2(150, 34), "body_off": Vector2(0, -6),
	 "seat": Vector2(-8, -26), "driver_scale": 0.46,
	 "mass": 2.0, "torque": 92000.0, "speed": 560.0, "drain": 1.0,
	 "desc": "Light and nimble. A good first ride."},
	{"id": "vintage", "name": "Roadster", "cost": 60,
	 "wheels": [Vector2(-64, 30), Vector2(64, 30)], "r": 24.0,
	 "body_size": Vector2(170, 30), "body_off": Vector2(0, -2),
	 "seat": Vector2(-4, -29), "driver_scale": 0.44,
	 "mass": 2.4, "torque": 100000.0, "speed": 580.0, "drain": 0.8,
	 "desc": "Long and thrifty. Sips lantern oil."},
	{"id": "van_small", "name": "Pickup", "cost": 120,
	 "wheels": [Vector2(-62, 30), Vector2(64, 30)], "r": 25.0,
	 "body_size": Vector2(170, 36), "body_off": Vector2(0, -4),
	 "seat": Vector2(4, -22), "driver_scale": 0.42,
	 "mass": 3.2, "torque": 150000.0, "speed": 520.0, "drain": 1.0,
	 "desc": "Heavy and stable. Carries the lantern in back."},
	{"id": "suv_military", "name": "Field Jeep", "cost": 220,
	 "wheels": [Vector2(-58, 30), Vector2(60, 30)], "r": 26.0,
	 "body_size": Vector2(160, 34), "body_off": Vector2(0, -6),
	 "seat": Vector2(-4, -26), "driver_scale": 0.46,
	 "mass": 3.0, "torque": 150000.0, "speed": 580.0, "drain": 1.15,
	 "desc": "Grips the steepest hills."},
	{"id": "sports_race", "name": "Racer", "cost": 350,
	 "wheels": [Vector2(-64, 30), Vector2(64, 30)], "r": 22.0,
	 "body_size": Vector2(170, 28), "body_off": Vector2(0, -2),
	 "seat": Vector2(-14, -22), "driver_scale": 0.42,
	 "mass": 2.0, "torque": 100000.0, "speed": 740.0, "drain": 1.3,
	 "desc": "Very fast, very thirsty, a bit twitchy."},
]

const CHARACTERS := [
	{"id": "male_adv", "name": "Rowan"},
	{"id": "female_adv", "name": "Sage"},
	{"id": "male_person", "name": "Marcus"},
	{"id": "female_person", "name": "Amara"},
	{"id": "robot", "name": "Bolt"},
	{"id": "zombie", "name": "Moss"},
]

static func by_id(id: String) -> Dictionary:
	for v in DATA:
		if v["id"] == id:
			return v
	return DATA[0]

static func portrait(char_id: String, pose: String) -> Texture2D:
	return load("res://assets/characters/%s_%s.png" % [char_id, pose])
