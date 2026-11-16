extends Node2D


# Rodada adicionada: sobreviver por 60 s, enfrentar uma xícara gigante e encerrar.
# A fase também impede novos inimigos ou um segundo resultado depois do fim.
enum Fase { SOBREVIVENCIA, CHEFE, TERMINADO }

var fase := Fase.SOBREVIVENCIA
var boss: CharacterBody2D
var _tentativa_boss := 0.0


func _ready() -> void:
	# Força tela cheia ao jogar; testes sem janela continuam funcionando em headless.
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _unhandled_key_input(event: InputEvent) -> void:
	# Durante a partida, Escape volta para janela e F11 alterna a tela cheia.
	# Ignorar repetição evita alternar várias vezes ao segurar a tecla.
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if DisplayServer.get_name() == "headless":
		return
	if event.keycode == KEY_ESCAPE:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	elif event.keycode == KEY_F11:
		var modo := DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED
			if modo == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)


func _process(delta: float) -> void:
	# O HUD lê o Timer de 60 s da cena, em vez de manter outra contagem separada.
	if fase == Fase.SOBREVIVENCIA:
		%TempoLabel.text = "Chefe em: %02d s" % ceili($TempoRodada.time_left)
	elif fase == Fase.CHEFE and not is_instance_valid(boss):
		# Se o piso estiver ocupado, adia o nascimento sem prender o jogo num loop.
		_tentativa_boss -= delta
		if _tentativa_boss <= 0.0:
			_tentativa_boss = 0.5
			_tentar_spawn_boss()


func spawn_inimigo():
	if fase != Fase.SOBREVIVENCIA:
		return
	# Testa o corpo inteiro para nao criar inimigos dentro de paredes ou moveis.
	var novo_inimigo = preload("res://inimigo.tscn").instantiate()
	var colisao: CollisionShape2D = novo_inimigo.get_node("CollisionShape2D")
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = colisao.shape
	consulta.collision_mask = 3
	consulta.margin = 4.0
	var mapa: Sprite2D = $MapaCafe
	var area: Rect2 = mapa.get_rect()
	var espaco := get_world_2d().direct_space_state
	for tentativa in 24:
		%PathFollow2D.progress_ratio = randf()
		var ponto := mapa.to_local(%PathFollow2D.global_position)
		ponto.x = clampf(ponto.x, area.position.x + 24.0, area.end.x - 24.0)
		ponto.y = clampf(ponto.y, area.position.y + 82.0, area.end.y - 20.0)
		var posicao_spawn := mapa.to_global(ponto)
		consulta.transform = Transform2D(0.0, posicao_spawn) * colisao.transform
		if espaco.intersect_shape(consulta, 1).is_empty():
			novo_inimigo.position = to_local(posicao_spawn)
			add_child(novo_inimigo)
			return
	# Se todos os pontos estiverem ocupados, tenta novamente no proximo timer.
	novo_inimigo.free()


func _on_timer_timeout() -> void:
	spawn_inimigo()


func _on_player_vida_zerada() -> void:
	_terminar_jogo("Você morreu newba")


func _on_tempo_rodada_timeout() -> void:
	# Terminados os 60 s, a horda para de nascer e começa o confronto com o chefe.
	if fase != Fase.SOBREVIVENCIA:
		return
	fase = Fase.CHEFE
	$Timer.stop()
	$TempoRodada.stop()
	%TempoLabel.text = "Derrote a xícara gigante!"
	_tentar_spawn_boss()


func _tentar_spawn_boss() -> void:
	# O boss tem corpo maior: consulta sua própria colisão antes de colocá-lo no mapa.
	# A instância existente garante que só haja uma xícara gigante na rodada.
	if fase != Fase.CHEFE or is_instance_valid(boss):
		return
	var novo_boss = preload("res://boss.tscn").instantiate()
	var colisao: CollisionShape2D = novo_boss.get_node("CollisionShape2D")
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = colisao.shape
	consulta.collision_mask = 3
	consulta.margin = 8.0
	var mapa: Sprite2D = $MapaCafe
	var area: Rect2 = mapa.global_transform * mapa.get_rect()
	var espaco := get_world_2d().direct_space_state
	var jogador: CharacterBody2D = $Player
	var camera: Camera2D = jogador.get_node("Camera2D")
	var visivel := Rect2(camera.get_screen_center_position() - get_viewport_rect().size / camera.zoom / 2.0,
		get_viewport_rect().size / camera.zoom)
	var melhor_ponto := Vector2.INF
	var melhor_nota := INF
	# Varre o piso para o corpo grande nascer livre dos moveis e das paredes.
	for y in range(520, floori(area.end.y) - 110, 72):
		for x in range(ceili(area.position.x) + 160, floori(area.end.x) - 160, 96):
			var ponto := Vector2(x, y)
			var distancia := ponto.distance_to(jogador.global_position)
			if distancia < 300.0:
				continue
			consulta.transform = Transform2D(0.0, ponto) * colisao.transform
			if not espaco.intersect_shape(consulta, 1).is_empty():
				continue
			var nota := absf(distancia - 550.0)
			# Prefere uma posição visível e afastada, para o boss não surgir sobre o jogador.
			if not visivel.grow(-120).has_point(ponto):
				nota += 2000.0
			if nota < melhor_nota:
				melhor_nota = nota
				melhor_ponto = ponto
	if melhor_ponto == Vector2.INF:
		novo_boss.free()
		return
	boss = novo_boss
	boss.position = to_local(melhor_ponto)
	boss.derrotado.connect(_on_boss_derrotado)
	add_child(boss)


func _on_boss_derrotado() -> void:
	_terminar_jogo("Fim de jogo")


func _terminar_jogo(mensagem: String) -> void:
	# Vitória e derrota usam a mesma tela, com textos diferentes; o primeiro fim prevalece.
	# Parar os timers e pausar a árvore congela combate e contagem após o resultado.
	if fase == Fase.TERMINADO:
		return
	fase = Fase.TERMINADO
	$Timer.stop()
	$TempoRodada.stop()
	$FimDeJogo/ColorRect/Label.text = mensagem
	%FimDeJogo.visible = true
	get_tree().paused = true
