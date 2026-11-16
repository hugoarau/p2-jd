extends CharacterBody2D


var _mapa: Sprite2D
@onready var _camera: Camera2D = $Camera2D


# A camera acompanha o jogador e recalcula o enquadramento quando a janela muda de tamanho.
func _ready() -> void:
	_mapa = get_parent().get_node_or_null("MapaCafe") as Sprite2D

	if _mapa == null:
		push_warning("MapaCafe nao encontrado!")
		return

	_camera.enabled = true
	_camera.limit_enabled = true
	_camera.limit_smoothed = false
	_camera.position_smoothing_enabled = false
	_camera.offset = Vector2.ZERO
	_camera.make_current()
	get_viewport().size_changed.connect(_atualizar_camera)
	_atualizar_camera()


func _atualizar_camera() -> void:
	# Usa as bordas da imagem no mundo, incluindo a escala do mapa.
	var area: Rect2 = _mapa.global_transform * _mapa.get_rect()
	_camera.limit_left = ceili(area.position.x) + 2
	_camera.limit_top = ceili(area.position.y) + 2
	_camera.limit_right = floori(area.end.x) - 2
	_camera.limit_bottom = floori(area.end.y) - 2

	# Os limites nao bastam se a tela enxergar uma area maior que o mapa.
	var tamanho_mapa := Vector2(
		_camera.limit_right - _camera.limit_left,
		_camera.limit_bottom - _camera.limit_top
	)
	var tamanho_tela := get_viewport_rect().size
	var zoom_minimo := maxf(
		1.0, maxf(tamanho_tela.x / tamanho_mapa.x, tamanho_tela.y / tamanho_mapa.y)
	)
	_camera.zoom = Vector2.ONE * zoom_minimo
	_camera.force_update_scroll()


signal vida_zerada

var vida = 100.0

# Impede novas emissoes de morte; passa a direcao para a animacao e preserva a orientacao parado.
func _physics_process(_delta):
	if vida <= 0.0:
		return
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * 600
	move_and_slide()
	
	if velocity.length()  > 0.0: #se a condição de velocidade for maior que 0, reproduz a animção de andar
		%HappyBoo.play_walk_animation(direction)
	else: #se a velocidade for igual a 0, ativa a função de parado (ocioso)
		%HappyBoo.play_idle_animation() #procura o nó HappyBoo, e depois executa a função de idle (parado) 
	
	# Sensor alinhado ao corpo com margem: contato na parede tambem causa dano.
	# Mascara 2 detecta inimigos e chefe, sem contar paredes ou moveis.
	const DANO_POR_SEGUNDO = 5.0
	var overlapping_inimigo = %Dano.get_overlapping_bodies()
	if overlapping_inimigo.size() > 0:
		vida = maxf(0.0, vida - DANO_POR_SEGUNDO * overlapping_inimigo.size() * _delta)
		%ProgressBar.value = vida 
		if vida <= 0.0:
			vida_zerada.emit()
