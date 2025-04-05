class_name Dweller extends RigidBody3D

@onready var rope_timer: Timer = $RopeTimer
var thrown: bool = false
var rope_ready: bool = false

@onready var sprite: Sprite3D = $Sprite3D

@onready var debug_label: Label = $"../HUDCam/Label"


func _process(delta: float) -> void:
	sprite.shaded = not rope_ready
	
	#debug_label.text = str(linear_velocity)
	
	$Ouch.visible = not get_viewport().get_camera_3d().is_position_behind(global_position) and \
		rope_ready
	$Ouch.position = get_viewport().get_camera_3d().unproject_position(global_position) - Vector2(300,300)


func _on_body_entered(body: Node) -> void:
	print("Collided with ", body.name)
	
	if thrown:
		rope_timer.start()
		rope_ready = true
	
	thrown = false
	
	linear_velocity *= 0.5
	linear_velocity.y *= 0.5


func _on_rope_timer_timeout() -> void:
	rope_ready = false
