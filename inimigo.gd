extends CharacterBody2D

var vida = 3

@onready var player = get_node("/root/Jogo/Player")

func _ready():
	%Slime.play_walk()


func _physics_process(_delta):
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * 300.0
	move_and_slide()
	
func take_damage():
	vida -= 1
	%Slime.play_hurt()
	
	if vida == 0:
		queue_free()
		
		const CENA_FUMAÇA = preload("res://smoke_explosion/smoke_explosion.tscn")
		var fumaça = CENA_FUMAÇA.instantiate()
		get_parent().add_child(fumaça)
		fumaça.global_position = global_position
		
