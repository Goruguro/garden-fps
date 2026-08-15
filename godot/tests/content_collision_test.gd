extends SceneTree

const CollisionFactory := preload("res://scripts/physics/garden_collision_factory.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/rebuild/garden_world.tscn") as PackedScene
	assert(packed != null, "Dünya sahnesi yüklenemedi")
	var world := packed.instantiate() as RebuiltGardenWorld
	root.add_child(world)
	var session := GameSession.new()
	session.new_game()
	world.setup(session)
	await physics_frame
	await physics_frame

	var mira := world.get_node_or_null("Mira") as Node3D
	var lale := world.get_node_or_null("Lale") as Node3D
	var arda := world.get_node_or_null("Arda") as Node3D
	var yuzu := world.get_node_or_null("YuzuCompanion") as Node3D
	for character in [mira, lale, arda]:
		assert(character != null, "NPC sahnede bulunamadı")
		assert(character.get_node_or_null("CharacterHitbox") is AnimatableBody3D, "NPC hareketli hitbox taşımıyor")
		assert(CollisionFactory.count_valid_hitboxes(character.get_node("CharacterHitbox")) == 1, "NPC kapsül şekli eksik")
	assert(yuzu != null and yuzu.get_node_or_null("AnimalHitbox") is AnimatableBody3D, "Yuzu hitbox taşımıyor")

	assert(world.get_node_or_null("Cottage/CottageCollision") is StaticBody3D, "Ev katı değil")
	assert(world.get_node_or_null("Workshop/WorkshopCollision") is StaticBody3D, "Atölye katı değil")
	assert(world.kaykit_decorator.get_node_or_null("KayKit_well/WellHitbox") is StaticBody3D, "Kuyu katı değil")
	assert(world.kaykit_decorator.get_node_or_null("KayKit_bench/BenchHitbox") is StaticBody3D, "Bank katı değil")
	assert(world.foliage_scatter.tree_collision_count == world.foliage_scatter.source_tree_count, "Her LOD ağacının gövde hitbox'ı yok")

	var expected_minimum := world.foliage_scatter.tree_collision_count + 12
	var local_solids := 0
	for solid_node in get_nodes_in_group("solid_world_content"):
		var solid := solid_node as PhysicsBody3D
		if solid != null and world.is_ancestor_of(solid):
			local_solids += 1
			assert(solid.collision_layer & 1, "Katı içerik dünya çarpışma katmanında değil")
			assert(CollisionFactory.count_valid_hitboxes(solid) > 0, "Fizik gövdesinin şekli yok: %s" % solid.name)
	assert(local_solids >= expected_minimum, "Harita katı içerik sayısı yetersiz")

	world.player.set_controls_enabled(false)
	_assert_motion_hits(world.player, mira.global_position + Vector3(0.0, 0.22, 2.0), Vector3(0.0, 0.0, -4.0), mira.get_node("CharacterHitbox") as PhysicsBody3D)
	_assert_motion_hits(world.player, yuzu.global_position + Vector3(0.0, 0.16, 1.7), Vector3(0.0, 0.0, -3.4), yuzu.get_node("AnimalHitbox") as PhysicsBody3D)
	var cottage := world.get_node("Cottage") as Node3D
	_assert_motion_hits(world.player, cottage.global_position + Vector3(0.0, 0.22, 8.0), Vector3(0.0, 0.0, -12.0), cottage.get_node("CottageCollision") as PhysicsBody3D)
	var workshop := world.get_node("Workshop") as Node3D
	_assert_motion_hits(world.player, workshop.global_position + Vector3(0.0, 0.22, 7.0), Vector3(0.0, 0.0, -11.0), workshop.get_node("WorkshopCollision") as PhysicsBody3D)

	print("CONTENT_COLLISION_OK: solids=%d tree_hitboxes=%d npc=3 animals=1 buildings=2 decorator_props=true physical_blocking=true" % [local_solids, world.foliage_scatter.tree_collision_count])
	root.remove_child(world)
	world.free()
	await process_frame
	quit()


func _assert_motion_hits(player: CharacterBody3D, start: Vector3, motion: Vector3, expected_body: PhysicsBody3D) -> void:
	var player_collision := player.get_node("CollisionShape3D") as CollisionShape3D
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = player_collision.shape
	query.transform = Transform3D(player.global_basis, start + player_collision.position)
	query.motion = motion
	query.collision_mask = 1
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [player.get_rid()]
	var space_state := player.get_world_3d().direct_space_state
	var fractions := space_state.cast_motion(query)
	assert(not fractions.is_empty() and fractions[0] < 0.99, "%s oyuncuyu durdurmadı" % expected_body.name)
	query.transform.origin += motion * minf(float(fractions[0]) + 0.035, 1.0)
	query.motion = Vector3.ZERO
	var found_expected := false
	for hit: Dictionary in space_state.intersect_shape(query, 16):
		if hit.collider == expected_body:
			found_expected = true
			break
	assert(found_expected, "Süpürülmüş oyuncu şekli %s hitbox'ına ulaşmadı" % expected_body.name)
