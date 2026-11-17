extends SceneTree

# [CODEX] Regressao: malhas prontas antes do chefe e horda inteira removida na transicao.
func _initialize() -> void:
	_executar.call_deferred()


func exigir(condicao: bool, mensagem: String) -> bool:
	if not condicao:
		push_error(mensagem)
		quit(1)
	return condicao


func _executar() -> void:
	var game = load("res://jogodehorda.tscn").instantiate()
	root.add_child(game)
	game.get_node("Timer").stop()
	game.get_node("TempoRodada").stop()
	game.get_node("Player").set_physics_process(false)
	game.get_node("Player/Arma").process_mode = Node.PROCESS_MODE_DISABLED
	var nav: Node = game.get_node("NavegacaoInimigos")
	# [CODEX] Aceita os tamanhos editados no Godot, sem fixar o raio das xicaras no teste.
	var raios: Array[int] = []
	for cena in [load("res://inimigo.tscn"), load("res://boss.tscn")]:
		var modelo: CharacterBody2D = cena.instantiate()
		raios.append(ceili(nav.raio_do_corpo(modelo)))
		modelo.free()
	var maior_frame := 0
	for frame in 360:
		var inicio := Time.get_ticks_usec()
		await process_frame
		maior_frame = maxi(maior_frame, Time.get_ticks_usec() - inicio)
		if nav._grades.has(raios[0]) and nav._grades.has(raios[1]):
			break
	if not exigir(nav._grades.has(raios[0]) and nav._grades.has(raios[1]), "Malhas nao foram preparadas durante a rodada"):
		return
	print("PASS malhas prontas antecipadamente; maior frame de preparo(ms)=", maior_frame / 1000.0)
	var horda: Array[Node] = []
	for tentativa in 35:
		var antes: int = game.get_child_count()
		game.spawn_inimigo()
		if game.get_child_count() > antes:
			var inimigo: Node = game.get_child(-1)
			inimigo.set_physics_process(false)
			horda.append(inimigo)
		await physics_frame
	if not exigir(horda.size() >= 8, "Cenario de teste precisa de uma horda presente"):
		return
	var inicio := Time.get_ticks_usec()
	game._on_tempo_rodada_timeout()
	print("TRANSICAO_MS=", (Time.get_ticks_usec() - inicio) / 1000.0, " XICARAS_REMOVIDAS=", horda.size())
	if not exigir(is_instance_valid(game.boss), "Chefe nao surgiu"):
		return
	game.boss.set_physics_process(false)
	for inimigo in horda:
		if not exigir(inimigo.is_queued_for_deletion() and not inimigo.visible and inimigo.collision_layer == 0,
			"Xicara permaneceu visivel ou colidindo na entrada do chefe"):
			return
	if not exigir(get_nodes_in_group("inimigos").is_empty() and game.get_node("Timer").is_stopped(), "Horda continuou ativa"):
		return
	game.spawn_inimigo()
	await process_frame
	await process_frame
	for inimigo in horda:
		if not exigir(not is_instance_valid(inimigo), "Xicara nao foi liberada"):
			return
	if not exigir(get_nodes_in_group("inimigos").is_empty(), "Novo inimigo surgiu durante o chefe"):
		return
	print("PASS horda some por completo, sem colisoes residuais nem novos nascimentos")
	inicio = Time.get_ticks_usec()
	game.boss._physics_process(1.0 / 60.0)
	print("PRIMEIRA_IA_CHEFE_MS=", (Time.get_ticks_usec() - inicio) / 1000.0)
	inicio = Time.get_ticks_usec()
	game.boss._iniciar_aviso()
	game.boss._physics_process(0.9)
	print("PRIMEIRO_JATO_MS=", (Time.get_ticks_usec() - inicio) / 1000.0)
	if not exigir(get_nodes_in_group("projeteis_chefe").size() == 3, "Ataque nao criou tres gotas"):
		return
	print("PASS primeiro ataque preservado com apenas o chefe em combate")
	quit()
