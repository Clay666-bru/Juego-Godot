extends Node

enum WeaponType { PISTOL, MACHINEGUN, SPREAD, LASER }

var current_weapon: WeaponType = WeaponType.PISTOL

var weapon_data := {
	WeaponType.PISTOL: {
		fire_rate = 0.3,
		speed = 600.0,
		damage = 1,
		spread_degrees = 0,
		bullet_count = 1,
		bullet_scene = preload("res://scenes/weapons/bullet.tscn"),
	},
	WeaponType.MACHINEGUN: {
		fire_rate = 0.08,
		speed = 700.0,
		damage = 1,
		spread_degrees = 3.0,
		bullet_count = 1,
		bullet_scene = preload("res://scenes/weapons/bullet.tscn"),
	},
	WeaponType.SPREAD: {
		fire_rate = 0.25,
		speed = 550.0,
		damage = 1,
		spread_degrees = 12.0,
		bullet_count = 3,
		bullet_scene = preload("res://scenes/weapons/bullet.tscn"),
	},
	WeaponType.LASER: {
		fire_rate = 0.15,
		speed = 800.0,
		damage = 2,
		spread_degrees = 0,
		bullet_count = 1,
		bullet_scene = preload("res://scenes/weapons/bullet.tscn"),
	},
}


func get_current_data() -> Dictionary:
	return weapon_data[current_weapon]


func switch_to(weapon: WeaponType) -> void:
	current_weapon = weapon
