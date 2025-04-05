extends CharacterBody3D

var mouse_sensitivity = 0.2

var accel = 10
var speed = 3
var direction = Vector3(0,0,0)

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var dweller: Dweller = $"../Dweller"
var holding_dweller = false
@onready var dweller_hold_pos: MeshInstance3D = $Camera3D/DwellerHoldPosition

@onready var camera: Camera3D = $Camera3D

var being_roped: bool = false
var rope_target: Vector3 = Vector3()
var rope_distance: float = 0
var roped_time: float = 0

@onready var debug_label: Label = $"../HUDCam/Label"


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta) -> void:
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
	
	if is_on_floor():
		if being_roped:
			camera.fov = lerp(camera.fov, 90.0, 10*delta)
		else:
			camera.fov = lerp(camera.fov, 75.0, 10*delta)
	
	if not holding_dweller and not dweller.thrown and not dweller.rope_ready and \
	(
		global_position.distance_squared_to(dweller.position) < 0.5 or \
		camera.global_position.distance_squared_to(dweller.position) < 0.5
	):
		print("picked up dweller")
		holding_dweller = true
		being_roped = false
	
	if Input.is_action_just_pressed("interact") and not being_roped:
		if not holding_dweller and not dweller.rope_ready:
			holding_dweller = true
			dweller.linear_velocity = Vector3()
		elif holding_dweller:
			dweller.linear_velocity = -camera.basis.z * 15 + Vector3(0, 2, 0)
			dweller.thrown = true
			holding_dweller = false
		elif dweller.rope_ready:
			being_roped = true
			dweller.rope_ready = false
			rope_target = dweller.position - camera.position / 2
			rope_distance = position.distance_to(rope_target)
	
	if being_roped:
		dweller.linear_velocity = Vector3()


func _physics_process(delta) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	direction = input_dir.normalized().rotated(-camera.rotation.y)
	direction = Vector3(direction.x, 0, direction.y)
	
	if not being_roped:
		move_and_slide()
		
		velocity.x = lerp(velocity.x, direction.x * speed, accel * delta)
		velocity.z = lerp(velocity.z, direction.z * speed, accel * delta)
		
		if not is_on_floor():
			velocity.y -= gravity * delta
	
	if being_roped:
		velocity = Vector3()
		position = position.lerp(
			rope_target,
			clamp(
				(1 - (position.distance_to(rope_target) / rope_distance)) / 10,
				0.01,
				0.09
			)
		)
		
	elif holding_dweller:
		dweller.position = lerp(dweller.position, dweller_hold_pos.global_position, 0.4)
		dweller.linear_velocity.y = 0


func _input(event) -> void:
	if event is InputEventMouseMotion:
		camera.rotation_degrees.y -= event.relative.x * mouse_sensitivity
		camera.rotation_degrees.x -= event.relative.y * mouse_sensitivity
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
