extends CharacterBody2D

@export var velocidade: float = 70.0
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	# Pega o vetor combinando as 4 direções (left, right, up, down)
	var direcao := Input.get_vector("left", "right", "up", "down")
	velocity = direcao * velocidade
	move_and_slide()

	# Se estiver parado animação para
	if direcao == Vector2.ZERO:
		anim.stop()
		return

	# # aqui peguei da IA vou estudar depois e ve se o prof postou algo parecido
	if abs(direcao.x) > abs(direcao.y):
		if direcao.x > 0:
			anim.play("direita")
		else:
			anim.play("esquerda")
	else:
		if direcao.y > 0:
			anim.play("baixo")
		else:
			anim.play("cima")
