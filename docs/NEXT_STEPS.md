# Retomada do desenvolvimento

## Ponto de partida

A versão 4.1 introduz partidas individuais, recuperação de save, reformas, a Ruína da Serra, o posto comercial de Brumária e a Companhia do Vau. O último fluxo integrado leva o trigo da bolsa para uma carroça, reserva o pagamento, simula a escolta e entrega ao mercado regional. Em dia de risco, o saqueador pode derrotar a escolta e deixar a carga no terreno. O código que executa e persiste o fluxo está em `frontier_trade.gd`, `guild_ledger.gd`, `vale_caravan.gd` e `vale_life.gd`.

Outros pontos de retomada:

- `save_manager.gd` guarda o esquema 4 e a recuperação de arquivos.
- `homestead.gd` valida a reforma e conserva as dependências das peças.
- `ruin_run.gd` e `vale_ruin.gd` controlam a expedição e o cofre.
- `verify_expansion.gd` cobre os fluxos novos. As quatro suítes anteriores continuam em `tests/`.
- `GAME_DESIGN_DOCUMENT.md` reúne as regras aprovadas. `IMPLEMENTATION_STATUS.md` registra as lacunas.

## Próxima entrega · comércio clandestino da etapa E

Comece por um comerciante NPC em um esconderijo acessível na borda do Vale. Acrescente procedência e proprietário à carga recuperável e preserve esses campos na bolsa ou em um registro referenciado por identificador. Use o mesmo fluxo de pagamento e estoque que os fretes existentes. A venda clandestina deve validar a procedência, liquidar a mercadoria uma única vez e registrar uma ocorrência local. Acrescente testes de recusa de carga comum, expiração, recarga, pagamento único e impossibilidade de vender a mesma carga em dois mercados. Depois inclua a associação clandestina persistente e seus contratos fictícios.

Na etapa F, ligue essas ocorrências à testemunha presente e ao tempo de comunicação. A guarda só recebe um relato quando ele chega. Separe os papéis de agressor, defensor e vítima no evento. Teste multa, legítima defesa, recusa de punição por mera derrota e preservação de equipamento protegido. Na etapa G, use o mesmo histórico para aprovações do rei, projetos físicos, clima e recuperação.

## Infraestrutura futura

| Camada | Ponto de partida local | Trabalho para um servidor dedicado |
| --- | --- | --- |
| Identidade | UUID do personagem e arquivo de campanha | Vincular personagem a conta autenticada, autorizar sessão e revogar credenciais. |
| Regras | Classes GDScript de inventário, construção, economia e combate | Receber comandos versionados com identificador e sequência, validar distância e permissão usando posição autoritativa, aplicar limites e processar comandos repetidos com idempotência. |
| Transações | Mutação síncrona e save local com checksum | Persistir inventário, ouro e reservas em transações com controle de concorrência. Registrar eventos confirmados e estabelecer política de compensação. |
| Regiões | Grade de navegação local e marcadores de região | Definir autoridade por região, transferência de entidade com confirmação, sincronização diferencial e interesse por proximidade. |
| Operação | Logs de jogo, arquivos locais e suítes Godot | Adicionar métricas de tick, filas, erros e replays, backups com restauração exercitada, administração autorizada e testes de carga por região. |

O próximo módulo usa apenas Godot 4.7.2, GDScript e os assets já versionados. Os testes headless estão no README. Publicar os commits existentes requer o URL do repositório correspondente e credenciais Git com permissão de escrita.
