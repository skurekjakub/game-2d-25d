extends GdUnitTestSuite

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")


func _spawn_player() -> Player:
	var p: Player = auto_free(PLAYER_SCENE.instantiate())
	add_child(p)
	await get_tree().process_frame
	return p


func test_base_upgrade_effect_is_noop() -> void:
	var player := await _spawn_player()
	var hc: HealthComponent = player.get_node("HealthComponent") as HealthComponent
	var hp_before: float = hc.hp
	var speed_before: float = player.speed
	var effect := UpgradeEffect.new()
	effect.execute(player)
	assert_float(hc.hp).is_equal(hp_before)
	assert_float(player.speed).is_equal(speed_before)


func test_max_hp_bump_effect_raises_max_and_refills() -> void:
	var player := await _spawn_player()
	var hc: HealthComponent = player.get_node("HealthComponent") as HealthComponent
	hc.set_max_hp(100.0)
	hc.set_hp(30.0)
	var effect := MaxHpBumpEffect.new()
	effect.amount = 20.0
	effect.execute(player)
	assert_float(hc.max_hp).is_equal(120.0)
	assert_float(hc.hp).is_equal(120.0)


func test_speed_multiplier_effect_scales_player_speed() -> void:
	var player := await _spawn_player()
	player.speed = 200.0
	var effect := SpeedMultiplierEffect.new()
	effect.multiplier = 1.15
	effect.execute(player)
	assert_float(player.speed).is_equal_approx(230.0, 0.001)


func test_heal_to_full_effect_caps_at_max_hp() -> void:
	var player := await _spawn_player()
	var hc: HealthComponent = player.get_node("HealthComponent") as HealthComponent
	hc.set_max_hp(100.0)
	hc.set_hp(25.0)
	var effect := HealToFullEffect.new()
	effect.execute(player)
	assert_float(hc.hp).is_equal(100.0)


func test_weapon_acquire_effect_adds_weapon_to_host() -> void:
	var player := await _spawn_player()
	var weapon_count_before: int = player.weapon_host.weapons.size()
	var data := WeaponData.new()
	data.id = &"test_weapon"
	var effect := WeaponAcquireEffect.new()
	effect.weapon_data = data
	effect.execute(player)
	assert_int(player.weapon_host.weapons.size()).is_equal(weapon_count_before + 1)
	assert_str(String(player.weapon_host.weapons[-1].data.id)).is_equal("test_weapon")


func test_weapon_acquire_effect_noop_when_weapon_data_null() -> void:
	var player := await _spawn_player()
	var weapon_count_before: int = player.weapon_host.weapons.size()
	var effect := WeaponAcquireEffect.new()
	effect.execute(player)
	assert_int(player.weapon_host.weapons.size()).is_equal(weapon_count_before)


func test_noop_effect_inherits_base_noop() -> void:
	var player := await _spawn_player()
	var hc: HealthComponent = player.get_node("HealthComponent") as HealthComponent
	var hp_before: float = hc.hp
	var speed_before: float = player.speed
	var effect := NoopEffect.new()
	effect.execute(player)
	assert_float(hc.hp).is_equal(hp_before)
	assert_float(player.speed).is_equal(speed_before)
