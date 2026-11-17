extends CharacterBody2D

# [CODEX] Gota do Jato de Café: movimento varrido impede atravessar móveis em um frame rápido.
const VELOCIDADE := 520.0
const DANO := 10.0
const DISTANCIA_MAXIMA := 1400.0
var direcao := Vector2.RIGHT
var _distancia := 0.0
var _consumido := false


func _ready() -> void:
	add_to_group("projeteis_chefe")
	rotation = direcao.angle()


func _physics_process(delta: float) -> void:
	if _consumido:
		return
	var movimento := direcao * VELOCIDADE * delta
	var colisao := move_and_collide(movimento)
	_distancia += movimento.length()
	if colisao != null:
		_consumido = true
		var corpo := colisao.get_collider()
		# [CODEX] A camada 1 inclui jogador, móveis e paredes; só o jogador recebe dano.
		if is_instance_valid(corpo) and corpo.has_method("receber_dano"):
			corpo.receber_dano(DANO)
		queue_free()
	elif _distancia >= DISTANCIA_MAXIMA:
		queue_free()


func _draw() -> void:
	# [CODEX] Visual próprio em formas simples, sem depender de novas texturas.
	draw_circle(Vector2.ZERO, 11.0, Color(0.22, 0.08, 0.025))
	draw_circle(Vector2.ZERO, 7.5, Color(0.72, 0.33, 0.09))
	draw_circle(Vector2(2, -2), 3.0, Color(1.0, 0.82, 0.42))
	draw_line(Vector2(-12, 0), Vector2(-23, 0), Color(0.63, 0.29, 0.08, 0.7), 5.0)
