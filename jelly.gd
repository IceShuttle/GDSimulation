@tool
extends Sprite2D

@export var mass: float = 1
@export var spring_constant: float = 1;
var last_x_pos = Vector2(0, 0)
var last_speed = Vector2(0, 0)
var x = Vector2(0, 0)
var mul = 0
var bob_vel = Vector2(0, 0)

func _ready() -> void:
	last_x_pos = position
	mul = sqrt(2 * spring_constant * mass)


func _process(delta: float) -> void:
	#rotate(delta*2)
	var velocity = (position - last_x_pos) / delta
	last_x_pos = position
	last_speed = velocity
	#print(velocity)
	x -= velocity * delta
	bob_vel += -spring_constant * x / mass * delta
	x += bob_vel * delta
	#x.y += x.x*.1
	x = lerp(x, Vector2(0, 0), .05)
	self.material.set_shader_parameter("x_pos", x)
