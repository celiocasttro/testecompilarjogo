extends CharacterBody3D

signal health_changed(value: int)
signal ammo_changed(current: int, reserve: int)
signal enemy_hit

const SPEED := 5.4
const SPRINT_SPEED := 8.0
const MOUSE_SENSITIVITY := 0.0018
const MAGAZINE_SIZE := 30

var health := 100
var ammo := MAGAZINE_SIZE
var reserve_ammo := 90
var reloading := false
var fire_cooldown := 0.0
var gravity: float = 18.0
var camera: Camera3D
var weapon_pivot: Node3D
var muzzle_flash: OmniLight3D
var audio_player: AudioStreamPlayer3D
var mobile_look_touch := -1
var last_touch_position := Vector2.ZERO

func _ready() -> void:
	_build_player()
	ammo_changed.emit(ammo, reserve_ammo)

func _build_player() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.58, 0)
	camera.fov = 82
	add_child(camera)
	weapon_pivot = Node3D.new()
	weapon_pivot.position = Vector3(0.28, -0.25, -0.5)
	camera.add_child(weapon_pivot)
	_build_weapon_model()
	audio_player = AudioStreamPlayer3D.new()
	audio_player.max_distance = 55
	audio_player.volume_db = -4
	camera.add_child(audio_player)

func _build_weapon_model() -> void:
	var receiver := _weapon_box(Vector3(0.0, 0.0, -0.35), Vector3(0.15, 0.16, 0.58), Color(0.10, 0.12, 0.11))
	weapon_pivot.add_child(receiver)
	var barrel := _weapon_box(Vector3(0.0, 0.015, -0.72), Vector3(0.055, 0.055, 0.36), Color(0.07, 0.08, 0.075))
	weapon_pivot.add_child(barrel)
	var grip := _weapon_box(Vector3(0.0, -0.13, -0.22), Vector3(0.09, 0.2, 0.13), Color(0.16, 0.15, 0.12))
	weapon_pivot.add_child(grip)
	var handguard := _weapon_box(Vector3(0.0, 0.0, -0.57), Vector3(0.18, 0.13, 0.25), Color(0.14, 0.16, 0.14))
	weapon_pivot.add_child(handguard)
	var stock := _weapon_box(Vector3(0.0, 0.015, -0.08), Vector3(0.13, 0.12, 0.25), Color(0.12, 0.14, 0.12))
	weapon_pivot.add_child(stock)
	var magazine := _weapon_box(Vector3(0.0, -0.17, -0.43), Vector3(0.095, 0.19, 0.14), Color(0.065, 0.075, 0.067))
	magazine.rotation.x = deg_to_rad(-8)
	weapon_pivot.add_child(magazine)
	var top_rail := _weapon_box(Vector3(0.0, 0.105, -0.42), Vector3(0.07, 0.025, 0.39), Color(0.055, 0.065, 0.058))
	weapon_pivot.add_child(top_rail)
	var rear_sight := _weapon_box(Vector3(0.0, 0.14, -0.25), Vector3(0.06, 0.06, 0.045), Color(0.035, 0.04, 0.035))
	weapon_pivot.add_child(rear_sight)
	var front_sight := _weapon_box(Vector3(0.0, 0.09, -0.66), Vector3(0.035, 0.07, 0.035), Color(0.035, 0.04, 0.035))
	weapon_pivot.add_child(front_sight)
	muzzle_flash = OmniLight3D.new()
	muzzle_flash.light_color = Color(1.0, 0.55, 0.16)
	muzzle_flash.light_energy = 3.0
	muzzle_flash.omni_range = 3.0
	muzzle_flash.position = Vector3(0, 0.02, -0.92)
	muzzle_flash.visible = false
	weapon_pivot.add_child(muzzle_flash)

func _weapon_box(pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.65
	mat.roughness = 0.42
	mesh.material_override = mat
	return mesh

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-82), deg_to_rad(82))
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		reload_weapon()
	if Input.is_action_just_pressed("reload"):
		reload_weapon()
	if event is InputEventScreenTouch:
		if event.pressed:
			var screen_width := get_viewport().get_visible_rect().size.x
			if event.position.x > screen_width * 0.78:
				shoot()
			elif event.position.x > screen_width * 0.55:
				mobile_look_touch = event.index
				last_touch_position = event.position
		elif event.index == mobile_look_touch:
			mobile_look_touch = -1
	if event is InputEventScreenDrag and event.index == mobile_look_touch:
		var drag_event := event as InputEventScreenDrag
		var touch_delta: Vector2 = drag_event.position - last_touch_position
		rotate_y(-touch_delta.x * MOUSE_SENSITIVITY * 1.7)
		camera.rotate_x(-touch_delta.y * MOUSE_SENSITIVITY * 1.7)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-82), deg_to_rad(82))
		last_touch_position = event.position

func _physics_process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	var input_vec := Vector2.ZERO
	input_vec.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vec.y = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	var direction := (transform.basis * Vector3(input_vec.x, 0, input_vec.y)).normalized()
	var speed := SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else SPEED
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()
	if Input.is_action_pressed("fire"):
		shoot()

func shoot() -> void:
	if reloading or fire_cooldown > 0 or health <= 0:
		return
	if ammo <= 0:
		reload_weapon()
		return
	ammo -= 1
	fire_cooldown = 0.105
	ammo_changed.emit(ammo, reserve_ammo)
	_play_gunshot()
	muzzle_flash.visible = true
	weapon_pivot.position.z = -0.43
	var tween := create_tween()
	tween.tween_property(weapon_pivot, "position:z", -0.5, 0.07)
	await get_tree().create_timer(0.045).timeout
	if is_instance_valid(muzzle_flash):
		muzzle_flash.visible = false
	var origin := camera.global_position
	var end := origin + (-camera.global_transform.basis.z * 100.0)
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var target = hit.collider
		if target.has_method("take_damage"):
			target.take_damage(34)
			enemy_hit.emit()
		else:
			_make_impact(hit.position, hit.normal)

func _make_impact(pos: Vector3, normal: Vector3) -> void:
	var mark := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.055
	sphere.height = 0.11
	mark.mesh = sphere
	mark.global_position = pos + normal * 0.04
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.13, 0.08)
	mark.material_override = mat
	get_tree().current_scene.add_child(mark)
	get_tree().create_timer(4.0).timeout.connect(mark.queue_free)

func reload_weapon() -> void:
	if reloading or ammo == MAGAZINE_SIZE or reserve_ammo <= 0:
		return
	reloading = true
	weapon_pivot.rotation.x = deg_to_rad(12)
	await get_tree().create_timer(1.35).timeout
	var needed := MAGAZINE_SIZE - ammo
	var loaded: int = mini(needed, reserve_ammo)
	ammo += loaded
	reserve_ammo -= loaded
	weapon_pivot.rotation.x = 0
	reloading = false
	ammo_changed.emit(ammo, reserve_ammo)
	_play_reload()

func _play_gunshot() -> void:
	audio_player.stream = _make_noise(0.13, 0.8, 95.0, true)
	audio_player.play()

func _play_reload() -> void:
	audio_player.stream = _make_noise(0.22, 0.35, 800.0, false)
	audio_player.play()

func _make_noise(duration: float, volume: float, base_frequency: float, sharp: bool) -> AudioStreamWAV:
	var rate := 22050
	var count := int(duration * rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / rate
		var envelope := exp(-t * (34.0 if sharp else 9.0))
		var noise := randf_range(-1.0, 1.0)
		var tone := sin(TAU * base_frequency * t) * (0.5 if sharp else 0.15)
		var sample := clampf((noise * (0.85 if sharp else 0.25) + tone) * envelope * volume, -1.0, 1.0)
		var value := int(sample * 32767.0)
		bytes[i * 2] = value & 0xff
		bytes[i * 2 + 1] = (value >> 8) & 0xff
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	health_changed.emit(health)
