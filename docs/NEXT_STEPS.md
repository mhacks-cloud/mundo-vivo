# Retomada do desenvolvimento

## Ponto de partida

A versão 4.1 introduz partidas individuais, recuperação de save, reformas, a Ruína da Serra, o posto comercial de Brumária e a Companhia do Vau. O último fluxo integrado leva o trigo da bolsa para uma carroça, reserva o pagamento, simula a escolta e entrega ao mercado regional. Em dia de risco, o saqueador pode derrotar a escolta e deixar a carga no terreno. O código que executa e persiste o fluxo está em `frontier_trade.gd`, `guild_ledger.gd`, `vale_caravan.gd` e `vale_life.gd`.

Outros pontos de retomada:

- `save_manager.gd` guarda o esquema 4 e a recuperação de arquivos.
- `homestead.gd` valida a reforma e conserva as dependências das peças.
- `ruin_run.gd` e `vale_ruin.gd` controlam a expedição e o cofre.
- `verify_expansion.gd` cobre os fluxos novos. As quatro suítes anteriores continuam em `tests/`.
- `GAME_DESIGN_DOCUMENT.md` reúne as regras aprovadas. `IMPLEMENTATION_STATUS.md` registra as lacunas.

## Próxima entrega · expansão das nações

A 4.2 acrescentou comércio clandestino, justiça testemunhada e projetos do rei. As próximas lacunas são terrenos públicos para mercado, praça e irrigação, tesouros e autoridades de outras nações, conflitos com mais tipos de ocorrência, e mais de um contrato por guilda. Ampliar a cobertura para um ciclo econômico completo depois da reabertura e para partidas com vários mandados simultâneos.

## Infraestrutura futura

| Camada | Ponto de partida local | Trabalho para um servidor dedicado |
| --- | --- | --- |
| Identidade | UUID do personagem e arquivo de campanha | Vincular personagem a conta autenticada, autorizar sessão e revogar credenciais. |
| Regras | Classes GDScript de inventário, construção, economia e combate | Receber comandos versionados com identificador e sequência, validar distância e permissão usando posição autoritativa, aplicar limites e processar comandos repetidos com idempotência. |
| Transações | Mutação síncrona e save local com checksum | Persistir inventário, ouro e reservas em transações com controle de concorrência. Registrar eventos confirmados e estabelecer política de compensação. |
| Regiões | Grade de navegação local e marcadores de região | Definir autoridade por região, transferência de entidade com confirmação, sincronização diferencial e interesse por proximidade. |
| Operação | Logs de jogo, arquivos locais e suítes Godot | Adicionar métricas de tick, filas, erros e replays, backups com restauração exercitada, administração autorizada e testes de carga por região. |

O próximo módulo usa apenas Godot 4.7.2, GDScript e os assets já versionados. Os testes headless estão no README. Publicar os commits existentes requer o URL do repositório correspondente e credenciais Git com permissão de escrita.
