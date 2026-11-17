extends CharacterBody2D

signal derrotado

# [CODEX] Chefe com perseguição por rota e ataque exclusivo anunciado: Jato de Café.
enum EstadoAtaque { PERSEGUINDO, AVISANDO, RECUPERANDO }

const VIDA_MAXIMA := 10
const VELOCIDADE := 200.0
const ALCANCE_JATO := 760.0
const TEMPO_AVISO := 0.85
const TEMPO_RECUPERACAO := 0.55
const INTERVALO_JATO := 3.2
const PROJETIL_CAFE = preload("res://cafe_projetil.tscn")
var vida := VIDA_MAXIMA
var _morto := false
var estado_ataque := EstadoAtaque.PERSEGUINDO
var _tempo_estado := 0.0
var _recarga_jato := 1.8
var _direcao_jato := Vector2.RIGHT
@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var _navegacao: Node = get_parent().get_node_or_null("NavegacaoInimigos")


func _ready() -> void:
	%Slime.play_walk()
	%VidaBoss.value = vida


func _physics_process(delta: float) -> void:
	if _morto or not is_instance_valid(player):
		return
	_recarga_jato = maxf(0.0, _recarga_jato - delta)
	if estado_ataque == EstadoAtaque.AVISANDO:
		# [CODEX] A direção fica travada durante o aviso: o jogador pode sair do leque.
		velocity = Vector2.ZERO
		_tempo_estado -= delta
		# [CODEX] O cone parado fica em cache; redesenha apenas ao iniciar/encerrar o aviso.
		if _tempo_estado <= 0.0:
			_disparar_jato()
		return
	if estado_ataque == EstadoAtaque.RECUPERANDO:
		velocity = Vector2.ZERO
		_tempo_estado -= delta
		if _tempo_estado <= 0.0:
			estado_ataque = EstadoAtaque.PERSEGUINDO
		return

	var origem := _centro_corpo()
	var alvo := _centro_jogador()
	var distancia := origem.distance_to(alvo)
	if _recarga_jato <= 0.0 and distancia <= ALCANCE_JATO and distancia >= 100.0 and _tem_linha_de_tiro():
		_iniciar_aviso()
		return
	# [CODEX] A rota considera o corpo maior do chefe e contorna os móveis antes de atacar.
	if not is_instance_valid(_navegacao):
		_navegacao = get_parent().get_node_or_null("NavegacaoInimigos")
	var direcao := global_position.direction_to(player.global_position)
	if is_instance_valid(_navegacao):
		direcao = _navegacao.obter_direcao(self, player.global_position, delta)
	velocity = direcao * VELOCIDADE
	move_and_slide()


func _centro_corpo() -> Vector2:
	return $CollisionShape2D.global_position


func _centro_jogador() -> Vector2:
	var corpo: CollisionShape2D = player.get_node_or_null("CollisionShape2D")
	return corpo.global_position if corpo != null else player.global_position


func _tem_linha_de_tiro() -> bool:
	# [CODEX] Se o balcão ou outra parede estiver na frente, continua navegando em vez de atirar através.
	var consulta := PhysicsRayQueryParameters2D.create(_centro_corpo(), _centro_jogador(), 1)
	consulta.exclude = [get_rid()]
	var acerto := get_world_2d().direct_space_state.intersect_ray(consulta)
	return not acerto.is_empty() and acerto.collider == player


func _iniciar_aviso() -> void:
	estado_ataque = EstadoAtaque.AVISANDO
	_tempo_estado = TEMPO_AVISO
	_direcao_jato = _centro_corpo().direction_to(_centro_jogador())
	velocity = Vector2.ZERO
	%Slime.modulate = Color(1.0, 0.72, 0.32)
	$AvisoAtaque.visible = true
	queue_redraw()


func _disparar_jato() -> void:
	# [CODEX] Três gotas em leque; cada uma colide com o cenário e causa 10 de dano ao acertar.
	for angulo in [-0.18, 0.0, 0.18]:
		var direcao := _direcao_jato.rotated(angulo)
		var gota = PROJETIL_CAFE.instantiate()
		gota.direcao = direcao
		# [CODEX] Nasce no centro para varrer TODO o caminho, sem saltar um objeto fino ao lado do bico.
		# A mascara 1 da gota ignora o proprio chefe, que pertence a camada 2.
		gota.position = get_parent().to_local(_centro_corpo())
		get_parent().add_child(gota)
	estado_ataque = EstadoAtaque.RECUPERANDO
	_tempo_estado = TEMPO_RECUPERACAO
	_recarga_jato = INTERVALO_JATO
	%Slime.modulate = Color.WHITE
	$AvisoAtaque.visible = false
	queue_redraw()


func _draw() -> void:
	if estado_ataque != EstadoAtaque.AVISANDO or _morto:
		return
	# [CODEX] Cone no chão mostra a área do ataque antes de qualquer projétil nascer.
	var origem: Vector2 = $CollisionShape2D.position
	var lado_a := origem + _direcao_jato.rotated(-0.20) * ALCANCE_JATO
	var lado_b := origem + _direcao_jato.rotated(0.20) * ALCANCE_JATO
	draw_colored_polygon(PackedVector2Array([origem, lado_a, lado_b]), Color(1.0, 0.38, 0.08, 0.16))
	draw_line(origem, lado_a, Color(1.0, 0.58, 0.12, 0.9), 3.0)
	draw_line(origem, lado_b, Color(1.0, 0.58, 0.12, 0.9), 3.0)
	draw_line(origem, origem + _direcao_jato * ALCANCE_JATO, Color(1.0, 0.82, 0.3, 0.85), 2.0)


func take_damage() -> void:
	# [CODEX] A vida continua exigindo exatamente 10 acertos; a trava evita morte/sinal duplicado.
	if _morto:
		return
	vida -= 1
	%VidaBoss.value = vida
	%Slime.play_hurt()
	if vida <= 0:
		_morto = true
		# A cena principal recebe este sinal para mostrar "Fim de jogo" e pausar a rodada.
		derrotado.emit()
		queue_free()
