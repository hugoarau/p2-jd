# Cafeteria

Projeto do 2º bimestre de Jogos Digitais II (UNIGRAN, 2026/2). Jogo curto, de horda, vista de cima, feito na Godot 4.7.1 (Compatibility).

## A carta

- **Tema:** Cafeteria
- **Tipo de jogo:** _preencher com o tipo sorteado (Sobrevivência, Coleta, Defesa, Abate, Chefe, Fuga, Território ou Resgate)_
- **Modo:** Horda (arena vista de cima)

## Como jogar

Setas ou W/S sobem e descem com o personagem (nesta fase inicial ele só anda para cima e para baixo). Muro e mesas seguram o personagem.

## Estrutura

- `scenes/main.tscn`: cena principal, junta tudo (mapa + jogador). É ela que roda no F5.
- `scenes/cafeteria.tscn`: só o mapa (camadas `chao` e `objetos`). Para mexer no mapa, edite esta cena.
- `entities/jogador.tscn`: o personagem, com câmera e colisor.

## Estado atual (aula-08)

Cenário simples visto de cima, com muro e colisão, e personagem que anda para cima e para baixo com a câmera seguindo.

_Captura de tela: adicionar aqui._

## Créditos

- Arte: placeholders feitos para este projeto (sem arte de terceiros por enquanto). A arte do tema entra na Aula 11.
