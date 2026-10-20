extends Node3D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCRIPT := preload("res://scripts/enemy.gd")

var player: CharacterBody3D
var hud: CanvasLayer
var status_label: Label
var health_label: Label
var ammo_label: Label
var crosshair: Label
var enemies_left := 0
var mission_over := false

func _ready() -> void:
	_build_world()
	_build_hud()
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.position = Vector3(0, 1.2, 7)
	player.health_changed.connect(_on_health_changed)
	player.ammo_changed.connect(_on_ammo_changed)
	player.enemy_hit.connect(_on_enemy_hit)
	_spawn_enemies(6)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.61, 0.67)
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)

	_make_box("Ground", Vector3(0, -0.35, 0), Vector3(44, 0.7, 44), Color(0.19, 0.23, 0.20))
	# Ruined training compound walls and cover.
	_make_box("North wall", Vector3(0, 1.4, -17), Vector3(36, 2.8, 0.7), Color(0.31, 0.32, 0.29))
	_make_box("South wall", Vector3(0, 1.4, 17), Vector3(36, 2.8, 0.7), Color(0.29, 0.30, 0.27))
	_make_box("West wall", Vector3(-17, 1.4, 0), Vector3(0.7, 2.8, 34), Color(0.31, 0.32, 0.29))
	_make_box("East wall", Vector3(17, 1.4, 0), Vector3(0.7, 2.8, 34), Color(0.31, 0.32, 0.29))
	for i in range(9):
		var x := -12.0 + float(i) * 3.0
		_make_box("Concrete cover", Vector3(x, 0.55, -3.5 if i % 2 == 0 else 2.0), Vector3(1.7, 1.1, 1.0), Color(0.36, 0.37, 0.34))
	_make_box("Barracks", Vector3(-8, 1.8, -10), Vector3(7, 3.6, 5), Color(0.27, 0.30, 0.28))
	_make_box("Barracks roof", Vector3(-8, 3.8, -10), Vector3(7.4, 0.35, 5.4), Color(0.17, 0.20, 0.19))
	_make_box("Supply container", Vector3(9, 1.2, -8), Vector3(4.0, 2.4, 2.2), Color(0.22, 0.31, 0.25))
	_make_box("Sandbag cover", Vector3(8, 0.65, 5), Vector3(5, 1.3, 1.1), Color(0.43, 0.39, 0.29))
	for i in range(18):
		var px := randf_range(-15, 15)
		var pz := randf_range(-15, 15)
		if abs(px) < 3 and pz > 3:
			continue
		_make_box("Debris", Vector3(px, 0.18, pz), Vector3(randf_range(0.25, 0.8), 0.35, randf_range(0.25, 0.7)), Color(0.30, 0.31, 0.28))

func _make_box(label: String, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	mesh.material_override = mat
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)
	return body

func _spawn_enemies(amount: int) -> void:
	for i in range(amount):
		var enemy := CharacterBody3D.new()
		enemy.set_script(ENEMY_SCRIPT)
		add_child(enemy)
		var positions := [Vector3(-11, 0.1, -5), Vector3(10, 0.1, -13), Vector3(12, 0.1, 9), Vector3(-5, 0.1, -14), Vector3(2, 0.1, -8), Vector3(-12, 0.1, 10)]
		enemy.position = positions[i % positions.size()]
		enemy.died.connect(_on_enemy_died)
	enemies_left = amount
	status_label.text = "OBJETIVO: ELIMINE TODOS OS HOSTIS"

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var panel := ColorRect.new()
	panel.position = Vector2(18, 18)
	panel.size = Vector2(330, 112)
	panel.color = Color(0.025, 0.04, 0.045, 0.78)
	hud.add_child(panel)
	var title := Label.new()
	title.text = "OPERAÇÃO FÊNIX  //  ZONA 04"
	title.position = Vector2(32, 24)
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.77, 0.85, 0.72))
	hud.add_child(title)
	status_label = Label.new()
	status_label.text = "Preparando missão..."
	status_label.position = Vector2(32, 53)
	status_label.add_theme_font_size_override("font_size", 15)
	hud.add_child(status_label)
	health_label = Label.new()
	health_label.text = "VIDA 100"
	health_label.position = Vector2(32, 80)
	health_label.add_theme_color_override("font_color", Color(0.52, 0.9, 0.58))
	hud.add_child(health_label)
	ammo_label = Label.new()
	ammo_label.text = "MUNIÇÃO 30 / 90"
	ammo_label.position = Vector2(0, 0)
	ammo_label.anchor_left = 1
	ammo_label.anchor_right = 1
	ammo_label.offset_left = -250
	ammo_label.offset_right = -24
	ammo_label.offset_top = 24
	ammo_label.offset_bottom = 60
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_label.add_theme_font_size_override("font_size", 20)
	hud.add_child(ammo_label)
	crosshair = Label.new()
	crosshair.text = "+"
	crosshair.anchor_left = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -12
	crosshair.offset_right = 12
	crosshair.offset_top = -18
	crosshair.offset_bottom = 18
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.add_theme_font_size_override("font_size", 32)
	crosshair.add_theme_color_override("font_color", Color(0.85, 0.95, 0.78))
	hud.add_child(crosshair)
	var help := Label.new()
	help.text = "WASD mover  •  Mouse mirar  •  Clique atirar  •  R recarregar  •  ESC liberar mouse"
	help.anchor_top = 1
	help.anchor_bottom = 1
	help.offset_left = 18
	help.offset_right = -18
	help.offset_top = -36
	help.offset_bottom = -10
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 14)
	hud.add_child(help)

func _on_health_changed(value: int) -> void:
	health_label.text = "VIDA %d" % value
	if value <= 0:
		mission_over = true
		status_label.text = "MISSÃO FALHOU — pressione ENTER"
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_ammo_changed(current: int, reserve: int) -> void:
	ammo_label.text = "MUNIÇÃO %02d / %02d" % [current, reserve]

func _on_enemy_hit() -> void:
	crosshair.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25))
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(crosshair):
		crosshair.add_theme_color_override("font_color", Color(0.85, 0.95, 0.78))

func _on_enemy_died() -> void:
	enemies_left -= 1
	if enemies_left <= 0:
		status_label.text = "ÁREA SEGURA — MISSÃO CONCLUÍDA"
	else:
		status_label.text = "HOSTIS RESTANTES: %d" % enemies_left

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not mission_over:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER and mission_over:
		get_tree().reload_current_scene()
