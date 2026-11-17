extends SceneTree

# [CODEX] Regressao headless: observa corpos reais em ticks de fisica, sem trocar
# o movimento por simulacoes da rota. Qualquer falha termina com codigo 1.
# Executar: Godot --headless --path . --script res://tests/test_ia.gd
#           --fixed-fps 60 --quit-after 10000
const FPS := 60
const LIMITE_FRAMES := 9000
const LIMITE_REAL_MS := 120000

class JogadorTeste extends CharacterBody2D:
	var vida := 100.0
	var acertos := 0

	func receber_dano(quantidade: float) -> void:
		vida -= quantidade
		acertos += 1

var _jogo: Node2D
var _falhas: Array[String] = []
var _verificacoes := 0
var _inicio_ms := Time.get_ticks_msec()
var _terminado := false


func _initialize() -> void:
	seed(20261116)
	_executar.call_deferred()


func _process(_delta: float) -> bool:
	# [CODEX] O watchdog tambem cobre uma coroutine que deixou de progredir.
	if not _terminado and (Engine.get_physics_frames() > LIMITE_FRAMES or Time.get_ticks_msec() - _inicio_ms > LIMITE_REAL_MS):
		printerr("FAIL IA: tempo maximo excedido")
		_terminado = true
		quit(1)
	return false


func _executar() -> void:
	await _testar_perseguicao("xicara contorna sofa", "res://inimigo.tscn",
		Vector2(-350, 520), Vector2(330, 650), 900)
	await _testar_perseguicao("xicara contorna balcao", "res://inimigo.tscn",
		Vector2(1900, 810), Vector2(1900, 475), 1200)
	await _testar_perseguicao("chefe contorna mesa com capsula real", "res://boss.tscn",
		Vector2(-150, 800), Vector2(300, 800), 1200)
	await _testar_alvo_estreito()
	await _testar_jato_de_cafe()
	await _limpar_jogo()
	_terminado = true
	if _falhas.is_empty():
		print("PASS IA: %d verificacoes; perseguicao, largura do chefe, fallback e jato de cafe" % _verificacoes)
		quit(0)
	else:
		printerr("FAIL IA: %d falhas em %d verificacoes" % [_falhas.size(), _verificacoes])
		quit(1)


func _verificar(condicao: bool, mensagem: String) -> bool:
	_verificacoes += 1
	if not condicao:
		_falhas.append(mensagem)
		printerr("FAIL IA: " + mensagem)
	return condicao


func _ticks(quantidade: int) -> void:
	for _tick in quantidade:
		await physics_frame


func _limpar_jogo() -> void:
	paused = false
	if is_instance_valid(_jogo):
		_jogo.queue_free()
		await process_frame
		await process_frame
	_jogo = null


func _abrir_mapa() -> void:
	await _limpar_jogo()
	_jogo = load("res://jogodehorda.tscn").instantiate()
	root.add_child(_jogo)
	# [CODEX] A rodada e a arma ficam paradas para nenhum tiro/morte alterar o caso.
	_jogo.set_process(false)
	_jogo.get_node("Timer").stop()
	_jogo.get_node("TempoRodada").stop()
	var jogador: CharacterBody2D = _jogo.get_node("Player")
	jogador.set_physics_process(false)
	jogador.get_node("Arma").process_mode = Node.PROCESS_MODE_DISABLED
	jogador.get_node("Arma/Timer").stop()
	await _ticks(2)
	var navegacao := _jogo.get_node_or_null("NavegacaoInimigos")
	if _verificar(navegacao != null, "a cena principal deve criar NavegacaoInimigos"):
		navegacao.reconstruir()


func _centro(corpo: CharacterBody2D) -> Vector2:
	return corpo.get_node("CollisionShape2D").global_position


func _posicionar_centro(corpo: CharacterBody2D, ponto: Vector2) -> void:
	corpo.global_position += ponto - _centro(corpo)


func _livre_de_corpos(corpo: CharacterBody2D, apenas_estaticos: bool = false) -> bool:
	# [CODEX] Consulta a forma completa da cena, incluindo offset/escala; nao usa
	# o raio aproximado da navegacao para validar o proprio resultado dela.
	var forma: CollisionShape2D = corpo.get_node("CollisionShape2D")
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma.shape
	consulta.transform = forma.global_transform
	consulta.collision_mask = 3
	consulta.exclude = [corpo.get_rid()]
	for acerto in corpo.get_world_2d().direct_space_state.intersect_shape(consulta, 64):
		if not apenas_estaticos or acerto.collider is StaticBody2D:
			return false
	return true


func _criar_inimigo(cena: String, centro: Vector2) -> CharacterBody2D:
	var corpo: CharacterBody2D = load(cena).instantiate()
	var forma: CollisionShape2D = corpo.get_node("CollisionShape2D")
	corpo.position = _jogo.to_local(centro) - forma.position
	_jogo.add_child(corpo)
	corpo.set_physics_process(false)
	if corpo.get("_recarga_jato") != null:
		# [CODEX] Isola a locomocao; o ataque possui seu proprio caso abaixo.
		corpo.set("_recarga_jato", 999.0)
	return corpo


func _testar_perseguicao(rotulo: String, cena: String, origem: Vector2, alvo: Vector2, limite: int) -> void:
	var falhas_antes := _falhas.size()
	await _abrir_mapa()
	var jogador: CharacterBody2D = _jogo.get_node("Player")
	_posicionar_centro(jogador, alvo)
	var corpo := _criar_inimigo(cena, origem)
	await _ticks(2)
	if not _verificar(_livre_de_corpos(corpo) and _livre_de_corpos(jogador), rotulo + ": pontos iniciais livres"):
		return
	var navegacao := _jogo.get_node_or_null("NavegacaoInimigos")
	if navegacao == null:
		return
	var raio: float = navegacao.raio_do_corpo(corpo)
	_verificar(not navegacao.rota_livre(_centro(corpo), _centro(jogador), raio), rotulo + ": obstaculo interrompe a reta inicial")
	var caminho: PackedVector2Array = navegacao.caminho_para(corpo, jogador.global_position)
	if not _verificar(not caminho.is_empty(), rotulo + ": existe passagem para o corpo inteiro"):
		return
	if cena == "res://boss.tscn":
		_verificar_capsula_chefe(corpo)
	var alcance_contato := raio + 52.0 + 10.0
	var velocidade: float = corpo.get("VELOCIDADE")
	var anterior := _centro(corpo)
	var chegou := false
	var atravessou := false
	var teleportou := false
	corpo.set_physics_process(true)
	for _tick in limite:
		await physics_frame
		var atual := _centro(corpo)
		if not _livre_de_corpos(corpo, true):
			atravessou = true
			break
		if atual.distance_to(anterior) > velocidade / float(FPS) * 1.6 + 1.0:
			teleportou = true
			break
		anterior = atual
		if atual.distance_to(_centro(jogador)) <= alcance_contato:
			chegou = true
			break
	corpo.set_physics_process(false)
	_verificar(not atravessou, rotulo + ": nenhum tick sobrepoe um movel ou parede")
	_verificar(not teleportou, rotulo + ": deslocamento respeita a velocidade fisica")
	_verificar(chegou, "%s: chegou ao jogador dentro de %.1fs (centro final %s, alvo %s)" % [rotulo, limite / float(FPS), _centro(corpo), _centro(jogador)])
	if _falhas.size() == falhas_antes:
		print("PASS IA: " + rotulo)


func _verificar_capsula_chefe(chefe: CharacterBody2D) -> void:
	# [CODEX] Preserva os ajustes manuais do usuario: nao vale fazer o teste
	# passar reduzindo o corpo, mudando seu offset ou aumentando sua velocidade.
	var forma: CollisionShape2D = chefe.get_node("CollisionShape2D")
	if _verificar(forma.shape is CapsuleShape2D, "chefe conserva CapsuleShape2D"):
		_verificar(is_equal_approx(forma.shape.radius, 101.0) and is_equal_approx(forma.shape.height, 224.0), "capsula do chefe conserva raio 101 e altura 224")
	_verificar(forma.position.is_equal_approx(Vector2(1, 7)), "chefe conserva offset (1, 7)")
	_verificar(is_equal_approx(float(chefe.get("VELOCIDADE")), 200.0), "chefe conserva velocidade 200")
	_verificar(_jogo.get_node("NavegacaoInimigos").raio_do_corpo(chefe) >= 112.0, "rota considera a altura inteira da capsula")


func _testar_alvo_estreito() -> void:
	var falhas_antes := _falhas.size()
	await _abrir_mapa()
	var jogador: CharacterBody2D = _jogo.get_node("Player")
	_posicionar_centro(jogador, Vector2(1900, 475))
	var chefe := _criar_inimigo("res://boss.tscn", Vector2(1050, 600))
	await _ticks(2)
	if not _verificar(_livre_de_corpos(chefe) and _livre_de_corpos(jogador), "fallback: pontos iniciais livres"):
		return
	var navegacao := _jogo.get_node_or_null("NavegacaoInimigos")
	if navegacao == null:
		return
	var caminho: PackedVector2Array = navegacao.caminho_para(chefe, jogador.global_position)
	if not _verificar(not caminho.is_empty(), "fallback: alvo estreito ainda possui um destino alcancavel"):
		return
	var destino := caminho[caminho.size() - 1]
	var distancia_inicial := _centro(chefe).distance_to(_centro(jogador))
	_verificar(destino.distance_to(_centro(jogador)) > 180.0, "fallback: nao promete entrada numa passagem estreita para a capsula")
	_verificar(destino.distance_to(_centro(jogador)) < distancia_inicial - 100.0, "fallback: escolhe aproximacao util ao jogador")
	var livre := true
	var chegou := false
	chefe.set_physics_process(true)
	for _tick in 900:
		await physics_frame
		if not _livre_de_corpos(chefe, true):
			livre = false
			break
		if _centro(chefe).distance_to(destino) <= 24.0:
			chegou = true
			break
	var inicio_estabilidade := _centro(chefe)
	await _ticks(120)
	chefe.set_physics_process(false)
	_verificar(livre and _livre_de_corpos(chefe, true), "fallback: corpo permanece fora dos moveis")
	_verificar(chegou, "fallback: movimento real alcanca o destino alternativo sem ficar preso na quina")
	_verificar(_centro(chefe).distance_to(destino) <= 28.0 and _centro(chefe).distance_to(inicio_estabilidade) <= 28.0, "fallback: permanece estavel junto ao ponto alcancavel")
	if _falhas.size() == falhas_antes:
		print("PASS IA: chefe aproxima alvo estreito sem atravessar ou insistir na parede")


func _abrir_arena_de_ataque() -> JogadorTeste:
	await _limpar_jogo()
	_jogo = Node2D.new()
	_jogo.name = "Jogo"
	root.add_child(_jogo)
	var jogador := JogadorTeste.new()
	jogador.name = "Player"
	jogador.position = Vector2(500, 7)
	var colisao := CollisionShape2D.new()
	colisao.name = "CollisionShape2D"
	var forma := CircleShape2D.new()
	forma.radius = 20.0
	colisao.shape = forma
	jogador.add_child(colisao)
	_jogo.add_child(jogador)
	await _ticks(2)
	return jogador


func _testar_jato_de_cafe() -> void:
	var falhas_antes := _falhas.size()
	var jogador := await _abrir_arena_de_ataque()
	var chefe: CharacterBody2D = load("res://boss.tscn").instantiate()
	_jogo.add_child(chefe)
	chefe.set("_recarga_jato", 0.0)
	await _ticks(2)
	if not _verificar(int(chefe.get("estado_ataque")) == 1, "jato: inicia aviso antes de disparar"):
		chefe.set_physics_process(false)
		return
	_verificar(chefe.get_node("AvisoAtaque").visible, "jato: anuncio visivel durante preparacao")
	var mira: Vector2 = chefe.get("_direcao_jato")
	var posicao_aviso := chefe.global_position
	var inicio_aviso := Engine.get_physics_frames()
	# [CODEX] O jogador esquiva depois do aviso; a mira nao deve segui-lo.
	jogador.position = Vector2(500, 160)
	var disparou := false
	var mira_travada := true
	var parado_no_aviso := true
	for _tick in 90:
		await physics_frame
		if not Vector2(chefe.get("_direcao_jato")).is_equal_approx(mira):
			mira_travada = false
		if chefe.global_position.distance_to(posicao_aviso) > 0.1:
			parado_no_aviso = false
		if not get_nodes_in_group("projeteis_chefe").is_empty():
			disparou = true
			break
	chefe.set_physics_process(false)
	var frames_aviso := Engine.get_physics_frames() - inicio_aviso
	_verificar(disparou and frames_aviso >= 48, "jato: respeita o tempo de aviso antes de qualquer gota")
	_verificar(mira_travada and parado_no_aviso, "jato: chefe para e conserva a direcao anunciada para permitir esquiva")
	_verificar(get_nodes_in_group("projeteis_chefe").size() == 3, "jato: produz exatamente tres gotas")
	_verificar(int(chefe.get("estado_ataque")) == 2 and not chefe.get_node("AvisoAtaque").visible, "jato: entra em recuperacao e retira o aviso")
	for gota in get_nodes_in_group("projeteis_chefe"):
		gota.queue_free()
	await _ticks(2)
	await process_frame
	jogador.position = Vector2(500, 7)
	await _ticks(2)
	var gota: CharacterBody2D = load("res://cafe_projetil.tscn").instantiate()
	gota.position = Vector2(150, 7)
	_jogo.add_child(gota)
	await _ticks(75)
	_verificar(is_equal_approx(jogador.vida, 90.0) and jogador.acertos == 1, "jato: uma gota causa exatamente 10 de dano uma unica vez")
	# [CODEX] Frame longo forca a varredura a cruzar a parede inteira; um simples
	# teste de sobreposicao na posicao final deixaria a gota atravessar.
	var parede := StaticBody2D.new()
	parede.position = Vector2(300, 7)
	var colisao := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = Vector2(20, 200)
	colisao.shape = forma
	parede.add_child(colisao)
	_jogo.add_child(parede)
	await _ticks(2)
	gota = load("res://cafe_projetil.tscn").instantiate()
	gota.position = Vector2(150, 7)
	_jogo.add_child(gota)
	gota.set_physics_process(false)
	await _ticks(2)
	gota.call("_physics_process", 1.0)
	_verificar(gota.is_queued_for_deletion() and gota.position.x < 290.0, "jato: varredura bloqueia a gota na parede mesmo em frame de 1s")
	_verificar(is_equal_approx(jogador.vida, 90.0) and jogador.acertos == 1, "jato: a parede protege o jogador")
	await process_frame
	chefe.set("estado_ataque", 0)
	chefe.set("_recarga_jato", 0.0)
	chefe.call("_physics_process", 0.1)
	_verificar(int(chefe.get("estado_ataque")) == 0 and get_nodes_in_group("projeteis_chefe").is_empty(), "jato: chefe nao anuncia disparo atraves de um obstaculo")
	var mortes := [0]
	chefe.connect("derrotado", func(): mortes[0] += 1)
	for _acerto in 9:
		chefe.call("take_damage")
	_verificar(int(chefe.get("vida")) == 1 and not bool(chefe.get("_morto")), "chefe permanece vivo apos nove tiros")
	chefe.call("take_damage")
	chefe.call("take_damage")
	_verificar(int(chefe.get("vida")) == 0 and bool(chefe.get("_morto")) and mortes[0] == 1, "chefe morre no decimo tiro e emite derrota uma vez")
	if _falhas.size() == falhas_antes:
		print("PASS IA: jato anunciado, esquiva, dano unico, bloqueio do cenario e dez tiros no chefe")
