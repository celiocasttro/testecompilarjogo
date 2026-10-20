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
