extends CharacterBody2D

signal derrotado

# Cada projétil chama take_damage uma vez: o chefe exige 10 acertos para morrer.
const VIDA_MAXIMA := 10
var vida := VIDA_MAXIMA
var _morto := false
@onready var player: CharacterBody2D = get_parent().get_node("Player")


func _ready() -> void:
	%Slime.play_walk()
	%VidaBoss.value = vida


func _physics_process(_delta: float) -> void:
	# Reutiliza a perseguição simples das xícaras, com velocidade menor para o chefe.
	if _morto or not is_instance_valid(player):
		return
	velocity = global_position.direction_to(player.global_position) * 180.0
	move_and_slide()


func take_damage() -> void:
	# A trava impede morte/sinal duplicados se mais de uma bala acertar no mesmo frame.
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
