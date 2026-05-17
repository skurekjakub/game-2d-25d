extends GdUnitTestSuite


func test_resolve_returns_empty_for_null() -> void:
	assert_str(String(DamageSourceResolver.resolve(null))).is_equal("")


func test_resolve_returns_weapon_id_field_when_present() -> void:
	var proj := preload("res://combat/weapons/projectiles/basic_projectile.tscn").instantiate()
	proj.weapon_id = &"blaster"
	add_child(auto_free(proj))
	assert_str(String(DamageSourceResolver.resolve(proj))).is_equal("blaster")


func test_resolve_aura_uses_instance_data_id() -> void:
	var aura := preload("res://combat/weapons/aura/aura_weapon.tscn").instantiate()
	add_child(auto_free(aura))
	var data := WeaponData.new()
	data.id = &"aura"
	aura.instance = WeaponInstance.new(data)
	assert_str(String(DamageSourceResolver.resolve(aura))).is_equal("aura")


func test_resolve_orbital_blade_walks_to_parent_weapon() -> void:
	var orbital := preload("res://combat/weapons/orbital/orbital_weapon.tscn").instantiate()
	var data := WeaponData.new()
	data.id = &"orbital"
	orbital.instance = WeaponInstance.new(data)
	add_child(auto_free(orbital))
	await get_tree().process_frame
	orbital._owned_tick(0.0)  # spawn the default 1 blade
	var blade: OrbitalBlade = null
	for child: Node in orbital.get_children():
		if child is OrbitalBlade:
			blade = child
			break
	assert_object(blade).is_not_null()
	assert_str(String(DamageSourceResolver.resolve(blade))).is_equal("orbital")
