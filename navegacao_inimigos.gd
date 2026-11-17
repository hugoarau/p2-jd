extends Node2D

# [CODEX] Navegacao compartilhada: as xicaras procuram passagens em torno dos moveis,
# em vez de insistir numa linha reta atraves das paredes. Cada tamanho tem sua grade.
const CELULA := 16.0
const FOLGA_GRADE := 4.0
const VIZINHOS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN,
	Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(1, 1)]

var _limites := Rect2()
var _obstaculos: Array[Rect2] = []
var _grades: Dictionary = {}
var _rotas: Dictionary = {}
var _pronto := false


func preparar_grades(raios: Array[int]) -> void:
	# [CODEX] Distribui a preparacao pelos frames, com orcamento aproximado de 2 ms.
	# A publicacao so ocorre com a grade completa; consultas existentes continuam seguras.
	if not _pronto:
		reconstruir()
	for raio in raios:
		if _grades.has(raio):
			continue
		var grade := _nova_grade()
		var livres: Array[Vector2i] = []
		var componentes: Dictionary = {}
		var inicio_lote := Time.get_ticks_usec()
		for y in grade.region.size.y:
			for x in grade.region.size.x:
				var id := Vector2i(x, y)
				var bloqueado := _ponto_bloqueado(grade.get_point_position(id), raio)
				grade.set_point_solid(id, bloqueado)
				if not bloqueado:
					livres.append(id)
				if Time.get_ticks_usec() - inicio_lote >= 2000:
					await get_tree().process_frame
					# Uma consulta pode ter preparado esta grade enquanto o lote aguardava.
					if _grades.has(raio):
						break
					inicio_lote = Time.get_ticks_usec()
			if _grades.has(raio):
				break
		if _grades.has(raio):
			continue
		var numero := 0
		for id in livres:
			if componentes.has(id):
				continue
			var fila: Array[Vector2i] = [id]
			componentes[id] = numero
			var frente := 0
			while frente < fila.size():
				var atual := fila[frente]
				frente += 1
				for passo in VIZINHOS:
					var vizinho: Vector2i = atual + passo
					if grade.region.has_point(vizinho) and not grade.is_point_solid(vizinho) and not componentes.has(vizinho):
						componentes[vizinho] = numero
						fila.append(vizinho)
				if Time.get_ticks_usec() - inicio_lote >= 2000:
					await get_tree().process_frame
					inicio_lote = Time.get_ticks_usec()
			numero += 1
		if not _grades.has(raio):
			_grades[raio] = {"grade": grade, "livres": livres, "componentes": componentes}


func _nova_grade() -> AStarGrid2D:
	var grade := AStarGrid2D.new()
	grade.region = Rect2i(Vector2i.ZERO, Vector2i(ceili(_limites.size.x / CELULA), ceili(_limites.size.y / CELULA)))
	grade.cell_size = Vector2.ONE * CELULA
	grade.offset = _limites.position + Vector2.ONE * CELULA / 2.0
	grade.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	grade.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grade.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grade.update()
	return grade


func _ponto_bloqueado(ponto: Vector2, raio: int) -> bool:
	if not _limites.grow(-float(raio) - FOLGA_GRADE).has_point(ponto):
		return true
	var distancia_minima := float(raio) + FOLGA_GRADE
	for obstaculo in _obstaculos:
		if _distancia_retangulo_quadrada(ponto, obstaculo) < distancia_minima * distancia_minima:
			return true
	return false


func reconstruir() -> void:
	# [CODEX] So corpos estaticos entram no mapa de obstaculos. Jogador e outras
	# xicaras sao dinamicos e nao podem deixar corredores permanentemente fechados.
	_grades.clear()
	_rotas.clear()
	_obstaculos.clear()
	var mapa: Sprite2D = get_parent().get_node_or_null("MapaCafe") as Sprite2D
	if mapa == null:
		_pronto = false
		return
	_limites = mapa.global_transform * mapa.get_rect()
	_coletar_obstaculos(get_parent())
	_pronto = true


func _coletar_obstaculos(no: Node) -> void:
	if no is StaticBody2D and (no.collision_layer & 1) != 0:
		for filho in no.get_children():
			if filho is CollisionShape2D and not filho.disabled and filho.shape != null:
				_obstaculos.append(filho.global_transform * filho.shape.get_rect())
	for filho in no.get_children():
		_coletar_obstaculos(filho)


func centro_do_corpo(corpo: CharacterBody2D) -> Vector2:
	var colisao: CollisionShape2D = corpo.get_node_or_null("CollisionShape2D") as CollisionShape2D
	return colisao.global_position if colisao != null else corpo.global_position


func raio_do_corpo(corpo: CharacterBody2D) -> float:
	var colisao: CollisionShape2D = corpo.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if colisao != null and colisao.shape != null:
		# [CODEX] Tambem respeita o tamanho de capsulas editadas no editor, sem
		# reduzir a colisao do chefe: usa um circulo que cobre sua maior dimensao.
		var tamanho: Vector2 = colisao.shape.get_rect().size * colisao.global_scale.abs()
		return maxf(tamanho.x, tamanho.y) / 2.0
	return 56.0


func _centro_do_alvo(alvo: Vector2) -> Vector2:
	var jogador: CharacterBody2D = get_parent().get_node_or_null("Player") as CharacterBody2D
	if jogador != null and jogador.global_position.distance_squared_to(alvo) < 1.0:
		return centro_do_corpo(jogador)
	return alvo


func obter_direcao(corpo: CharacterBody2D, alvo: Vector2, delta: float) -> Vector2:
	if not _pronto:
		reconstruir()
	if not _pronto:
		return Vector2.ZERO
	var origem := centro_do_corpo(corpo)
	var destino := _centro_do_alvo(alvo)
	var raio := raio_do_corpo(corpo)
	# [CODEX] O teste usa o volume do corpo, nao apenas um raio fino: atalhos so
	# sao aceitos quando a xicara inteira passa sem raspar em sofas e quinas.
	if rota_livre(origem, destino, raio):
		return origem.direction_to(destino)
	var chave := corpo.get_instance_id()
	if not _rotas.has(chave):
		_rotas[chave] = {"pontos": PackedVector2Array(), "indice": 0, "tempo": 0.0,
			"alvo": Vector2.INF, "anterior": origem, "parado": 0.0}
		corpo.tree_exited.connect(_remover_rota.bind(chave), CONNECT_ONE_SHOT)
	var estado: Dictionary = _rotas[chave]
	estado.tempo -= delta
	estado.parado = estado.parado + delta if origem.distance_squared_to(estado.anterior) < 0.2 else 0.0
	estado.anterior = origem
	# [CODEX] Replaneja em intervalos curtos, quando o alvo muda ou quando uma
	# aglomeracao impede o movimento; nao executa uma busca A* em todo frame.
	if estado.tempo <= 0.0 or destino.distance_squared_to(estado.alvo) > 2304.0 or estado.parado > 0.8:
		estado.pontos = caminho_para(corpo, alvo)
		estado.indice = 0
		estado.alvo = destino
		estado.tempo = 0.35 + float(chave % 7) * 0.02
		estado.parado = 0.0
	var pontos: PackedVector2Array = estado.pontos
	while estado.indice < pontos.size() and origem.distance_to(pontos[estado.indice]) < 12.0:
		estado.indice += 1
	if estado.indice >= pontos.size():
		return Vector2.ZERO
	# Pula curvas ja visiveis, mantendo a margem de seguranca do corpo inteiro.
	for indice in range(mini(estado.indice + 3, pontos.size() - 1), estado.indice, -1):
		if rota_livre(origem, pontos[indice], raio):
			estado.indice = indice
			break
	return origem.direction_to(pontos[estado.indice])


func _remover_rota(chave: int) -> void:
	_rotas.erase(chave)


func caminho_para(corpo: CharacterBody2D, alvo: Vector2) -> PackedVector2Array:
	if not _pronto:
		reconstruir()
	if not _pronto:
		return PackedVector2Array()
	var origem := centro_do_corpo(corpo)
	var destino := _centro_do_alvo(alvo)
	var raio := raio_do_corpo(corpo)
	if rota_livre(origem, destino, raio):
		return PackedVector2Array([destino])
	var dados := _obter_grade(ceili(raio))
	var inicio := _celula_proxima(origem, dados)
	if inicio == Vector2i(-1, -1):
		return PackedVector2Array()
	var componente: int = dados.componentes[inicio]
	# [CODEX] Um alvo junto a parede pode ocupar um lugar estreito demais para
	# o chefe. Escolhe a posicao alcancavel mais proxima, sem atravessar o movel.
	var fim := _celula_proxima(destino, dados, componente)
	if fim == Vector2i(-1, -1):
		return PackedVector2Array()
	var grade: AStarGrid2D = dados.grade
	var bruto: PackedVector2Array = grade.get_point_path(inicio, fim)
	var caminho := PackedVector2Array()
	var atual := origem
	var indice := 0
	while indice < bruto.size():
		var escolhido := indice
		for candidato in range(bruto.size() - 1, indice - 1, -1):
			if rota_livre(atual, bruto[candidato], raio):
				escolhido = candidato
				break
		caminho.append(bruto[escolhido])
		atual = bruto[escolhido]
		indice = escolhido + 1
	if rota_livre(atual, destino, raio):
		caminho.append(destino)
	return caminho


func _obter_grade(raio: int) -> Dictionary:
	if _grades.has(raio):
		return _grades[raio]
	var grade := _nova_grade()
	var livres: Array[Vector2i] = []
	for y in grade.region.size.y:
		for x in grade.region.size.x:
			var id := Vector2i(x, y)
			var bloqueado := _ponto_bloqueado(grade.get_point_position(id), raio)
			grade.set_point_solid(id, bloqueado)
			if not bloqueado:
				livres.append(id)
	var componentes: Dictionary = {}
	var numero := 0
	for id in livres:
		if componentes.has(id):
			continue
		var fila: Array[Vector2i] = [id]
		componentes[id] = numero
		var frente := 0
		while frente < fila.size():
			var atual := fila[frente]
			frente += 1
			for passo in VIZINHOS:
				var vizinho: Vector2i = atual + passo
				if grade.region.has_point(vizinho) and not grade.is_point_solid(vizinho) and not componentes.has(vizinho):
					componentes[vizinho] = numero
					fila.append(vizinho)
		numero += 1
	var dados := {"grade": grade, "livres": livres, "componentes": componentes}
	_grades[raio] = dados
	return dados


func _celula_proxima(ponto: Vector2, dados: Dictionary, componente: int = -1) -> Vector2i:
	var grade: AStarGrid2D = dados.grade
	var aproximada := Vector2i(((ponto - grade.offset) / CELULA).round())
	if grade.region.has_point(aproximada) and dados.componentes.has(aproximada):
		if componente < 0 or dados.componentes[aproximada] == componente:
			return aproximada
	var melhor := Vector2i(-1, -1)
	var distancia := INF
	for id in dados.livres:
		if componente >= 0 and dados.componentes[id] != componente:
			continue
		var atual: float = ponto.distance_squared_to(grade.get_point_position(id))
		if atual < distancia:
			distancia = atual
			melhor = id
	return melhor


func rota_livre(origem: Vector2, destino: Vector2, raio: float, _exclude: Array[RID] = []) -> bool:
	if not _pronto:
		reconstruir()
	if not _pronto:
		return false
	# [CODEX] Teste geometrico so contra obstaculos estaticos, reutilizado pelo
	# chefe para nao preparar uma investida atraves de paredes ou do balcao.
	var folga := raio + 2.0
	var area := _limites.grow(-folga)
	if not area.has_point(origem) or not area.has_point(destino):
		return false
	for obstaculo in _obstaculos:
		if _distancia_segmento_retangulo_quadrada(origem, destino, obstaculo) < folga * folga:
			return false
	return true


func _distancia_retangulo_quadrada(ponto: Vector2, area: Rect2) -> float:
	var proximo := ponto.clamp(area.position, area.end)
	return ponto.distance_squared_to(proximo)


func _distancia_segmento_retangulo_quadrada(origem: Vector2, destino: Vector2, area: Rect2) -> float:
	# [CODEX] Distancia circular exata nas quinas: inflar apenas a AABB criaria
	# paredes invisiveis e fecharia passagens diagonais que o corpo realmente cabe.
	if _segmento_no_retangulo(origem, destino, area):
		return 0.0
	var distancia := minf(_distancia_retangulo_quadrada(origem, area), _distancia_retangulo_quadrada(destino, area))
	for canto in [area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)]:
		var proximo := Geometry2D.get_closest_point_to_segment(canto, origem, destino)
		distancia = minf(distancia, canto.distance_squared_to(proximo))
	return distancia


func _segmento_no_retangulo(origem: Vector2, destino: Vector2, area: Rect2) -> bool:
	var direcao := destino - origem
	var entrada := 0.0
	var saida := 1.0
	for eixo in 2:
		if absf(direcao[eixo]) < 0.00001:
			if origem[eixo] < area.position[eixo] or origem[eixo] > area.end[eixo]:
				return false
			continue
		var minimo: float = (area.position[eixo] - origem[eixo]) / direcao[eixo]
		var maximo: float = (area.end[eixo] - origem[eixo]) / direcao[eixo]
		if minimo > maximo:
			var troca := minimo
			minimo = maximo
			maximo = troca
		entrada = maxf(entrada, minimo)
		saida = minf(saida, maximo)
		if entrada > saida:
			return false
	return true
