extends CharacterBody2D

# [CODEX] Perseguicao por rotas livres, com separacao leve para as xicaras nao formarem uma pilha.
const VELOCIDADE := 300.0
var vida = 3
var _morto := false

@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var _navegacao: Node = get_parent().get_node_or_null("NavegacaoInimigos")

func _ready():
	add_to_group("inimigos")
	%Slime.play_walk()


func _physics_process(delta: float) -> void:
	if _morto or not is_instance_valid(player):
		return
	# [CODEX] A rota considera a largura da xicara e passa pelos corredores ao redor dos moveis.
	var direction := Vector2.ZERO
	if is_instance_valid(_navegacao):
		direction = _navegacao.obter_direcao(self, player.global_position, delta)
	else:
		direction = global_position.direction_to(player.global_position)
	var separacao := _separacao_do_grupo()
	var desejada := (direction + separacao * 0.55).normalized() * VELOCIDADE
	# [CODEX] Se o desvio de outra xicara apontar para um movel, conserva a direcao da rota.
	if not separacao.is_zero_approx() and test_move(global_transform, desejada * delta):
		desejada = direction * VELOCIDADE
	velocity = desejada
	move_and_slide()


func _separacao_do_grupo() -> Vector2:
	# [CODEX] Perto do jogador a prioridade e encostar para causar dano, sem recuar em circulos.
	if global_position.distance_to(player.global_position) < 135.0:
		return Vector2.ZERO
	var afastamento := Vector2.ZERO
	for outro in get_tree().get_nodes_in_group("inimigos"):
		if outro == self or not is_instance_valid(outro):
			continue
		var diferenca: Vector2 = global_position - outro.global_position
		var distancia := diferenca.length()
		if distancia > 0.01 and distancia < 128.0:
			afastamento += diferenca / distancia * (1.0 - distancia / 128.0)
	return afastamento.limit_length(1.0)


func take_damage():
	# [CODEX] Impede que tiros simultaneos matem a mesma xicara mais de uma vez.
	if _morto:
		return
	vida -= 3
	%Slime.play_hurt()
	
	if vida <= 0:
		_morto = true
		queue_free()
		
		const CENA_FUMAÇA = preload("res://smoke_explosion/smoke_explosion.tscn")
		var fumaça = CENA_FUMAÇA.instantiate()
		get_parent().add_child(fumaça)
		fumaça.global_position = global_position
		
