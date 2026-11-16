extends CharacterBody2D

signal vida_zerada

var vida = 100.0

func _physics_process(_delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * 600
	move_and_slide()
	
	if velocity.length()  > 0.0: #se a condição de velocidade for maior que 0, reproduz a animção de andar
		%HappyBoo.play_walk_animation() #procura o nó HappyBoo, e depois executa a função de andar (walk) 
	else: #se a velocidade for igual a 0, ativa a função de parado (ocioso)
		%HappyBoo.play_idle_animation() #procura o nó HappyBoo, e depois executa a função de idle (parado) 
	
	const DANO_POR_SEGUNDO = 5.0
	var overlapping_inimigo = %Dano.get_overlapping_bodies()
	if overlapping_inimigo.size() > 0:
		vida -= DANO_POR_SEGUNDO * overlapping_inimigo.size() * _delta
		%ProgressBar.value = vida 
		if vida <= 0.0:
			vida_zerada.emit()
