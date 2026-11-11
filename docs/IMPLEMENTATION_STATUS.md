# Estado da implementação · Mundo Vivo 4.1

| Estado | Significado |
| --- | --- |
| IMPLEMENTADO | O fluxo descrito funciona no projeto Godot. |
| TESTADO | A implementação tem cobertura automatizada executada nesta versão. |
| PARCIAL | Há um fluxo jogável com escopo limitado em relação ao documento de design. |
| PENDENTE | O comportamento ainda requer implementação. |
| BLOQUEADO | A entrega exige uma dependência ou acesso indisponível. |

| Etapa e módulo | Estado | Evidência e escopo |
| --- | --- | --- |
| A · Vale, câmera, personagem, oito classes e obra da ponte | TESTADO | As 119 verificações da 4.0 cobrem criação, economia, clima, construção e simulação da vila. O spritesheet e a renderização HD-2D continuam em uso. |
| A · Partidas, identidade e persistência | TESTADO | Menu de novo jogo, carregamento de partidas individuais, identificador persistente e recuperação explícita da cópia anterior. Esquema 4 com SHA-256, substituição por arquivo temporário e leitura de 1 a 3. |
| B · Construção e reforma | TESTADO | Prévia, rotação, instalação, movimentação de bancos e vasos, remoção sem devolução de materiais, dependências entre fundação, piso e mobília, permissão e persistência. |
| B · Agricultura e vida econômica | PARCIAL | Plantio e criação do galinheiro existentes, crescimento sensível à temperatura e adubação que consome um ovo e aumenta a produção. Fertilidade contínua, estufas, estábulos e animais de propriedade particular pendentes. |
| B · Inventário e profissões | PARCIAL | Peso, pilhas, baú, transferências unitárias, fabricação exclusiva, uso e durabilidade testados. Faltam interface de separação de quantidades, especializações e aprimoramentos. |
| C · Ruína da Serra | TESTADO | Entrada no portal existente, duas câmaras, patrulha, perseguição, ataques, bloqueio físico, chefe, recompensa de ferro e progresso persistente. O modificador de força vem do dia da primeira visita. |
| C · Combate e exploração ampliados | PARCIAL | Guerreiro, arqueiro e mago atacam os inimigos. Curandeiro recupera o aliado NPC. Faltam outras masmorras, chefes com fases avançadas, passivas e balanceamento de expedições. Posições de inimigos e projéteis da ruína reiniciam ao carregar, enquanto vida, dia da expedição, chefe e cofre persistem. |
| D · Mercado de Brumária | TESTADO | Posto visitável na margem leste, clima local da serra, estoque, caixa, imposto e registros independentes. O preço de compra reage à disponibilidade. |
| D · Produção e integração nacional | PARCIAL | A banca de Lina vende trigo do estoque real dos NPCs. A Coroa do Amieiro é a origem jogável. Brumária é visitável, com produção própria, origem de personagem e governo jogável ainda pendentes. |
| E · Guilda e fretes | TESTADO | Companhia do Vau com cargos NPC, armazém por permissão, tesouro, reputação, histórico e escolta paga na entrega. Uma carroça por vez navega fisicamente; o pagamento fica reservado. |
| E · Emboscada e perda de carga | TESTADO | Em dias de risco, o saqueador se aproxima e ataca. A derrota deixa toda a carga recuperável por 120 segundos da simulação, e devolve as reservas. A recuperação é única e o estado persiste. |
| E · Expansão de guildas | PENDENTE | Múltiplas guildas, comboios, sede editável, criação clandestina, mercado negro e rotas escolhidas pelo jogador. |
| F · Justiça e conflitos | PENDENTE | A guarda do Vale patrulha e responde à chuva. Testemunhas, multas, prisão, legítima defesa e simulação de PvP ainda aguardam implementação. |
| G · Eventos encadeados e obras | PARCIAL | Calendário, rotinas, colheitas, histórico, construção física da ponte e emboscadas determinísticas existem. Faltam diretor de eventos, crises sazonais, votação, aprovação por rei e ativação de novas regiões por condições. |
| H · Distribuição offline | PARCIAL | Projeto Godot empacotado e verificado. Mapa completo, tutorial ampliado, otimização por regiões e executável Windows independente pendentes. |
| I · Cloud e multiplayer | PENDENTE | Contratos de serviço locais, roteiro técnico e separação entre apresentação e estado persistente. Rede, concorrência, autenticação, sincronização e implantação continuam planejadas. |
| Publicação no GitHub | BLOQUEADO | O projeto está sem remoto e a integração autenticada não encontrou um repositório Mundo Vivo instalado. A CLI `gh` está indisponível neste ambiente. |

## Testes executados

- `verify.gd` · 31 verificações de regras, movimentação e mundo.
- `verify_presentation.gd` · 15 verificações de apresentação.
- `verify_life.gd` · 28 verificações da vida na vila.
- `verify_player_life.gd` · 45 verificações do RPG e migração anterior.
- `verify_expansion.gd` · 40 verificações de recuperação, reforma, ruína, mercados, frete, escolta e carga caída.

O motor Godot 4.7.2 emitiu um aviso sobre o acesso ao repositório de certificados do Windows. O jogo e as suítes foram executados localmente.
