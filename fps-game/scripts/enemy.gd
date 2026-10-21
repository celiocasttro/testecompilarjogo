extends CharacterBody3D

signal died

var health := 100
var speed := 1.8
var attack_timer := 0.0
var think_timer := 0.0
var target: Node3D
var body_mesh: MeshInstance3D
var health_bar: MeshInstance3D
var alive := true
var home_position := Vector3.ZERO

func _ready() -> void:
	home_position = position
	_build_enemy()
	target = get_tree().get_first_node_in_group("player")
	if target == null:
		target = get_tree().current_scene.find_child("Player", true, false)

func _build_enemy() -> void:
	var capsule := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.7
	capsule.shape = shape
	capsule.position.y = 0.85
	add_child(capsule)
	body_mesh = MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.36
	body.height = 1.65
	body_mesh.mesh = body
	body_mesh.position.y = 0.85
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.20, 0.25, 0.19)
	mat.roughness = 0.95
	body_mesh.material_override = mat
	add_child(body_mesh)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	head.mesh = sphere
	head.position.y = 1.78
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.45, 0.36, 0.27)
	head.material_override = head_mat
	add_child(head)
	var vest := MeshInstance3D.new()
	var vest_box := BoxMesh.new()
	vest_box.size = Vector3(0.57, 0.52, 0.28)
	vest.mesh = vest_box
	vest.position = Vector3(0, 0.92, -0.02)
	var vest_mat := StandardMaterial3D.new()
	vest_mat.albedo_color = Color(0.12, 0.15, 0.12)
	vest.material_override = vest_mat
	add_child(vest)

	# Helmet, shoulder armor, limbs and a compact rifle improve the hostile silhouette.
	var helmet := MeshInstance3D.new()
	var helmet_mesh := SphereMesh.new()
	helmet_mesh.radius = 0.245
	helmet_mesh.height = 0.30
	helmet.mesh = helmet_mesh
	helmet.position = Vector3(0, 1.98, 0)
	var helmet_mat := StandardMaterial3D.new()
	helmet_mat.albedo_color = Color(0.12, 0.16, 0.12)
	helmet_mat.metallic = 0.18
	helmet_mat.roughness = 0.72
	helmet.material_override = helmet_mat
	add_child(helmet)

	var visor := MeshInstance3D.new()
	var visor_mesh := BoxMesh.new()
	visor_mesh.size = Vector3(0.29, 0.075, 0.055)
	visor.mesh = visor_mesh
	visor.position = Vector3(0, 1.80, -0.19)
	var visor_mat := StandardMaterial3D.new()
	visor_mat.albedo_color = Color(0.07, 0.10, 0.09)
	visor_mat.metallic = 0.3
	visor_mat.roughness = 0.28
	visor.material_override = visor_mat
	add_child(visor)

	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		var arm_mesh := CapsuleMesh.new()
		arm_mesh.radius = 0.13
		arm_mesh.height = 0.62
		arm.mesh = arm_mesh
		arm.position = Vector3(side * 0.43, 0.96, -0.015)
		arm.rotation.z = deg_to_rad(side * -9.0)
		arm.material_override = mat
		add_child(arm)

		var leg := MeshInstance3D.new()
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.145
		leg_mesh.height = 0.72
		leg.mesh = leg_mesh
		leg.position = Vector3(side * 0.17, 0.36, 0.015)
		leg.material_override = mat
		add_child(leg)

	var rifle := MeshInstance3D.new()
	var rifle_mesh := BoxMesh.new()
	rifle_mesh.size = Vector3(0.09, 0.10, 0.72)
	rifle.mesh = rifle_mesh
	rifle.position = Vector3(0.28, 1.10, -0.30)
	var rifle_mat := StandardMaterial3D.new()
	rifle_mat.albedo_color = Color(0.055, 0.065, 0.058)
	rifle_mat.metallic = 0.52
	rifle_mat.roughness = 0.48
	rifle.material_override = rifle_mat
	add_child(rifle)

func _physics_process(delta: float) -> void:
	if not alive:
		return
	attack_timer = maxf(0.0, attack_timer - delta)
	think_timer -= delta
	if target == null or not is_instance_valid(target):
		target = get_tree().current_scene.find_child("Player", true, false)
		return
	var distance := global_position.distance_to(target.global_position)
	if distance < 17.0:
		var flat_target := Vector3(target.global_position.x, global_position.y, target.global_position.z)
		look_at(flat_target, Vector3.UP)
		if distance > 5.0:
			var dir := (flat_target - global_position).normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
		else:
			velocity.x = 0
			velocity.z = 0
			if attack_timer <= 0.0 and target.has_method("take_damage"):
				target.take_damage(8)
				attack_timer = 1.25
	else:
		velocity.x = 0
		velocity.z = 0
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	move_and_slide()

func take_damage(amount: int) -> void:
	if not alive:
		return
	health -= amount
	if health <= 0:
		alive = false
		died.emit()
		queue_free()
	else:
		body_mesh.material_override.albedo_color = Color(0.45, 0.12, 0.10)
		await get_tree().create_timer(0.12).timeout
		if is_instance_valid(body_mesh) and alive:
			body_mesh.material_override.albedo_color = Color(0.20, 0.25, 0.19)
