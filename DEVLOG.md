# Diário de Desenvolvimento

## 16/11/2026 - Camera, colisoes, animacoes e rodada com chefe

Alteracoes implementadas nesta sessao com auxilio do Codex:

- Camera acompanha o jogador sem ultrapassar a imagem do mapa, inclusive ao redimensionar.
- Tela cheia nativa e proporcao expand eliminam a moldura da previa e barras pretas fora de 16:9.
- Seis arvores removidas da cena; 24 colisoes adicionadas aos moveis e objetos do piso. O tapete continua transitavel.
- Sensor de dano alinhado ao corpo com margem corrige a falta de dano parado contra paredes.
- Geracao de inimigos verifica o corpo inteiro e evita nascer dentro de paredes, moveis ou jogador.
- Animacoes para esquerda, direita, cima e baixo, com perfil lateral, costas ao subir e direcao preservada ao parar.
- Contador visivel de 60 segundos; depois param os nascimentos comuns e surge uma xicara gigante com 10 de vida.
- O decimo acerto derrota o chefe e exibe 'Fim de jogo'. A morte exibe 'Voce morreu newba'. Ambos pausam a partida.
- Escape sai da tela cheia e F11 alterna o modo durante a partida.
- Comentarios nos scripts, cenas e configuracoes explicam os blocos alterados e os motivos das correcoes.

Validacao realizada na Godot 4.7.1:

- Dano parado nas quatro direcoes: 5 HP/s por inimigo; inimigo distante nao causa dano.
- Colisoes dos 24 moveis, bloqueio no sofa/balcao/banco e 90 nascimentos sem sobreposicao com obstaculos.
- Camera contida no mapa em diferentes proporcoes; tela cheia confirmada em monitor de 1680x1050.
- Entradas de movimento acionam as quatro animacoes; idle preserva a orientacao e virar nao reinicia a passada.
- Timer real de 60 segundos validado com simulacao acelerada: sem chefe aos 55 segundos e chefe apos o prazo.
- Chefe sobrevive a nove acertos e morre no decimo; finais e protecao contra callbacks duplicados verificados.

## 15/11/2026 - Desenvolvimento do protótipo

O que fiz:
- Configurei a movimentação e as animações do personagem.
- Implementei inimigos perseguidores.
- Adicionei disparos, colisões e sistema de dano.
- Implementei vida e geração periódica de inimigos.
- Trabalhei na organização das cenas e scripts.

Problemas encontrados:
- Referências incorretas entre nós.
- Scripts associados a nós incompatíveis.
- Problemas com nomes únicos e colisões.
- Erros durante a implementação de dano.

Como resolvi:
- Corrigi caminhos e referências de nós.
- Revisei a organização das cenas.
- Ajustei os scripts e as colisões durante os testes.

Próxima atualização:
- Implementar o chefe final.
- Implementar a condição de vitória ao derrotar o chefe.

Observação:
A temática atual é provisória e será adaptada posteriormente para Cafeteria com xícaras saltitantes.
