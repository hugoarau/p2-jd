# Diário de Desenvolvimento

## Organização por aula

**Nota sobre as datas:** esta seção organiza o trabalho pelos requisitos das aulas 08 a 12. O desenvolvimento documentado aconteceu em 15 e 16/11/2026, e não necessariamente nas datas originais das aulas. Os registros cronológicos completos estão preservados abaixo. Esta organização não substitui commits nem tags no GitHub.

### Aula 08 — Cenário, movimento e colisão

- **O que fiz:** desenvolvi o protótipo de horda seguindo o tutorial da GDQuest, com movimentação em quatro direções, cenário e personagem.
- **O que travou:** encontrei referências incorretas de nós, problemas nas colisões das paredes e dificuldades para configurar a câmera.
- **Como resolvi:** reorganizei os nós, ajustei as colisões e implementei o acompanhamento da câmera dentro do mapa.
- **Observação:** a arena atual é maior que uma tela; esse ponto ainda precisa ser conferido com o requisito do professor.

### Aula 09 — Vida, dano, ataque, vitória e derrota

- **O que fiz:** implementei vida, dano por contato, arma automática, projéteis e tela de derrota.
- **O que travou:** ocorreram erros nas referências dos nós e no funcionamento do dano durante os testes.
- **Como resolvi:** corrigi as referências, alinhei o sensor de dano e integrei as fontes de dano do jogador.
- **Objetivo do tipo Chefe:** implementei o temporizador de 60 segundos, o chefe com 10 pontos de vida, o ataque especial e o encerramento da partida ao derrotá-lo.

### Aula 10 — Comportamento e obstáculos

- **O que fiz:** implementei navegação compartilhada por A* para as xícaras encontrarem caminhos ao redor dos móveis e paredes.
- **O que travou:** inimigos podiam ficar bloqueados em obstáculos, passagens estreitas ou aglomerações.
- **Como resolvi:** adicionei rotas em cache, recálculo de caminhos e separação leve entre inimigos, com auxílio do Codex.
- **Verificação pendente:** confirmar se a máquina de estados do chefe e a navegação dos inimigos comuns atendem à exigência de estados de comportamento para o inimigo da Aula 10.

### Aula 11 — Tema e desempenho da horda

- **O que fiz:** adaptei o protótipo ao tema sorteado, Cafeteria com Xícaras Saltitantes, usando o cenário Corner Cafe, xícaras inimigas e uma xícara gigante.
- **O que travou:** ocorreram problemas de colisão, posicionamento de inimigos e desempenho na transição para o chefe.
- **Como resolvi:** adicionei colisões aos móveis, corrigi o nascimento dos inimigos e preparei antecipadamente as malhas de navegação.
- **Validação registrada:** testes automatizados e medições locais de desempenho foram documentados nas entradas originais abaixo.

### Aula 12 — Exportação e publicação

- **O que fiz:** organizei o README com a carta, instruções, captura de tela, origem no tutorial da GDQuest, créditos dos assets e uso de IA.
- **O que falta:** confirmar a exportação do jogo para executar fora da Godot.
- **O que falta:** publicar uma página do jogo e registrar o endereço no README.
- **Verificação pendente:** conferir os arquivos exportados, o funcionamento independente e as tags correspondentes no GitHub.

### Tutorial, recursos e inteligência artificial

O protótipo inicial foi desenvolvido com base no tutorial da GDQuest:
https://www.youtube.com/watch?v=GwCiGixlqiU

Inicialmente, foram utilizados HappyBoo, Slime, pistola, projéteis, árvores e efeitos do projeto-base. Posteriormente, o jogo foi adaptado ao tema obrigatório da cafeteria.

O OpenAI Codex auxiliou nas correções, na navegação dos inimigos, na implementação e revisão do chefe, nos testes e nas otimizações. Os registros marcados com [CODEX] e os comentários nos scripts documentam essa participação.

A documentação e as orientações técnicas também receberam apoio do ChatGPT.

### Pendências antes da entrega

- Testar uma partida completa, incluindo os 60 segundos, a luta contra o chefe, a vitória e a derrota.
- Confirmar o requisito da arena que cabe em uma tela e o uso de máquina de estados na IA.
- Confirmar os créditos e licenças de todos os recursos usados na versão final.
- Exportar, publicar e verificar o jogo fora do editor.
- Conferir os commits e as tags reais do repositório, sem alterar datas históricas.
- Conferir se todas as afirmações do registro original continuam correspondendo à versão final do jogo.

---

## Registros cronológicos originais (preservados)

## 16/11/2026 - [CODEX] Transicao para chefe e desempenho

- Na entrada do chefe, todas as xicaras comuns somem, param de processar e deixam de colidir imediatamente; sao liberadas sem efeitos de morte.
- Os nascimentos comuns continuam bloqueados durante o confronto com o chefe.
- As malhas da horda e do chefe sao preparadas antecipadamente, em lotes pelos frames da rodada. Nao ha mais construcao fria da malha no primeiro movimento do chefe.
- O cone de aviso do ataque usa os comandos de desenho em cache e so e redesenhado ao aparecer/desaparecer.
- Teste tests/test_transicao_chefe.gd confirmou limpeza completa da horda (30 inimigos na copia aberta), chefe unico e primeiro jato funcionando.
- Medicao local de CPU/headless: a construcao fria da malha do chefe custava cerca de 52 ms; com a malha pronta, a transicao custou 1,35 ms, a primeira IA 1,11 ms e o primeiro jato 0,09 ms. Tempos variam por computador.

## 16/11/2026 - [CODEX] IA das xicaras e Jato de Cafe do chefe

- [CODEX] Navegacao compartilhada por A* encontra rotas ao redor de sofas, mesas, balcao e paredes.
- Cada rota respeita o centro e a largura fisica da xicara. O chefe conserva a capsula manual de raio 101 e altura 224 e a velocidade 200.
- Rotas ficam em cache e sao recalculadas quando o jogador muda de lugar ou a xicara fica bloqueada. Passagens estreitas usam o ponto alcancavel mais proximo.
- Separacao leve entre xicaras reduz aglomeracoes, sem impedir o contato que causa dano.
- Ataque exclusivo do chefe: aviso visual de 0,85 segundo, mira travada, tres gotas de cafe em leque e recuperacao antes de voltar a perseguir.
- Cada gota causa 10 de dano uma vez. Movimento varrido impede atravessar moveis, paredes ou obstaculos finos, inclusive no trecho de saida do chefe.
- Contato e projeteis compartilham receber_dano no jogador. O chefe continua com 10 de vida, e a mensagem de vitoria editada manualmente foi preservada.
- Selo visual 'IA • CODEX' no HUD e comentarios [CODEX] identificam os trechos desta melhoria.
- Teste reproduzivel: godot --headless --path . --fixed-fps 60 --physics-fps 60 --script res://tests/test_ia.gd
- Validacao: 46 verificacoes de movimento real ao redor dos moveis, aproximacao em passagem estreita, aviso/mira/tiros, dano unico, cobertura e derrota no decimo acerto. Teste adicional confirmou bloqueio de gota lateral por obstaculo fino antes do antigo bico.

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
