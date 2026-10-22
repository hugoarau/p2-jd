extends CharacterBody2D

@export var velocidade: float = 70.0
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	# Só sobe e desce: um eixo, sem andar para os lados.
	var eixo := Input.get_axis("up", "down")
	velocity = Vector2(0, eixo * velocidade)
	move_and_slide()

	if eixo == 0:
		anim.stop()
	elif eixo > 0:
		anim.play("baixo")
	else:
		anim.play("cima")
