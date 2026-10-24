# Monk Key Climb (prototype v3)

A Hill-Climb-style driving game. Pick a vehicle and a driver in the Garage, then drive as far
as you can on one lantern of oil. Godot 4.3+ (GDScript). Fully offline.
Art: vehicles drawn in code; drivers, backgrounds and props from Kenney (CC0). See CREDITS.md.

## Run it
1. Install Godot 4.3 or newer (free, godotengine.org).
2. Project Manager -> Import -> select `project.godot`.
3. Press F5.

Controls: Right/D/Up = gas, Left/A/Down = brake (also tilts in the air).
On a phone, use the on-screen GAS and BRAKE buttons.

## What's in it
- `vehicles.gd`     vehicle + driver catalog (stats, costs, wheel/seat positions). Add new ones here.
- `vehicle_art.gd`  the drawn vehicles (back layer, driver, front layer, wheels). Add a new `_myCar()`
                    function and a `match` entry to create another vehicle.
- `car.gd`          builds a vehicle from the catalog: body collider + two sprung wheels + drive
- `terrain.gd`      endless hills (steeper with distance), four biomes every 160 m, props, pickups
- `main.gd`         game loop, fuel, game over, save file, HUD, Garage menu, biome backdrop

Fuel is lantern oil; oil jars refill it. Keys are your currency: unlock vehicles in the Garage.
Drivers are cosmetic and react (cheer on keys, wince on crash). Progress saves to `user://save.json`.

## Tuning knobs
- `vehicles.gd`: torque, speed, mass, drain, cost per vehicle
- `car.gd`: suspension stiffness/damping, AIR_TORQUE
- `terrain.gd`: ground_y() hills, ZONE_W (biome length), BIOMES colors and props
- `main.gd`: FUEL_DRAIN, FUEL_DRAIN_GAS, OIL_REFILL

## Next steps
1. Playtest and tune the driving feel.
2. Sound and music (Kenney audio packs are CC0).
3. Upgrade shop (engine, suspension, oil tank).
4. Rewarded ads: see the `_show_rewarded_ad()` stub in `main.gd`.
5. Android export: Godot docs -> "Exporting for Android".
