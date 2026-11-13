# Estado da implementação · Mundo Vivo 4.5

A suíte de sociedade acrescenta 13 verificações. A branch de desenvolvimento entrega salários, compras e lares do elenco do Vale, o pedido recorrente de trigo, transporte de ferro, a oficina de Tomás, uma feira e notícias baseadas em eventos. Os saves 4.4 ganham campos opcionais. A oficina utiliza a equipe e as etapas de obra física de Alto da Bruma.

A continuação liga a vaga da oficina à mudança de Beatriz e à construção de uma segunda moradia no Pouso. Há frete de enxadas e pedidos recorrentes de ferro, madeira, ferramentas e alimentos. A suíte de civilização exercita 30 dias de calendário em janelas aceleradas, com recargas periódicas. Ela inicia com oficina e estoque de demonstração. Não equivale a simular todos os turnos completos de uma campanha nova.

Pendências: recrutamento e migração de múltiplos candidatos, cadeia física que leve o ferro do entreposto à oficina de destino, reposição sustentável de alimentos no cenário longo, receitas e festivais adicionais, camadas opcionais do Atlas e indicadores de desempenho. A coleta clandestina serrana continua limitada ao trigo.

| Economia 4.4 | Escopo |
| --- | --- |
| Implementado | Preço dinâmico de trigo no Vale, estoques locais, pedidos com pagamento reservado, forja serrana, tratados, taxas na rota e financiamento de reparos. |
| Parcial | O abastecimento internacional automatizado transporta trigo. Medicina e artesanato participam por receitas existentes e pedidos. A seca alonga a maturação dos cultivos de Teresa. |
| Pendente | Caravanas de exportação de ferro e ferramentas, orçamentos individuais para toda a população, estufas, contratos recorrentes e séries históricas completas de preços. |

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
| E · Emboscada e perda de carga | TESTADO | Em dias de risco, o saqueador se aproxima e ataca. A derrota derruba toda a carga e libera a reserva. A carga fica recuperável por 120 segundos. Um fardo pode entrar no armazém clandestino se o batedor chegar primeiro. A recuperação é única e o estado persiste. |
| E · Irmandade do Junco | TESTADO | Registro com Mira, membros e cargos NPC, um contrato, cobrança de taxa e circulação de fardos rastreados. Múltiplas organizações, sedes editáveis, comboios e rotas livres aguardam implementação. |
| F · Justiça e conflitos | PARCIAL | Patrulha, testemunha, alerta, mandado, captura, multa e prisão persistente. A infração jogável é a negociação clandestina observada. As regras de agressão e legítima defesa têm cobertura direta. PvP e Salmar continuam fora do mapa jogável. |
| G · Eventos encadeados e obras | PARCIAL | Calendário, rotinas, colheitas, histórico, construção física da ponte e emboscadas determinísticas existem. A chuva regional pode interditar a rota norte. O rei avalia oito tipos de proposta e três têm terreno e execução física. O teste cobre transporte e reabertura após reload. Faltam diretor de eventos amplo, outras crises sazonais, votação e novas regiões. |
| H · Distribuição offline | PARCIAL | Projeto Godot empacotado e verificado. Mapa completo, tutorial ampliado, otimização por regiões e executável Windows independente pendentes. |
| I · Cloud e multiplayer | PENDENTE | Contratos de serviço locais, roteiro técnico e separação entre apresentação e estado persistente. Rede, concorrência, autenticação, sincronização e implantação continuam planejadas. |
| H · Atlas e transição | TESTADO | Atlas com descoberta, zoom, deslocamento, seleção e estados de acesso. Portão liga o entreposto a Alto da Bruma, com descarregamento do cenário serrano e continuidade da simulação. |
| H · Mercados e comércio entre coroas | TESTADO | Vale, entreposto e capital têm estoques distintos. Compras do comboio, inspeção, entrega, escassez, tarifas, escolta e saque persistem. |
| H · Desenvolvimento territorial | PARCIAL | Rainha Elira avalia reparo e moradia. A equipe física reabre a estrada e libera o Pouso com uma nova moradora. Bairros maiores, lotes privados serranos e criação de personagem de Brumária estão pendentes. |
| Publicação no GitHub | IMPLEMENTADO | `origin` aponta para o repositório privado existente e a 4.2 está publicada. A branch e a tag da 4.3 são verificadas ao fechar a entrega. |

## Testes executados

- `verify.gd` · 31 verificações de regras, movimentação e mundo.
- `verify_presentation.gd` · 15 verificações de apresentação.
- `verify_life.gd` · 28 verificações da vida na vila.
- `verify_player_life.gd` · 45 verificações do RPG e migração anterior.
- `verify_expansion.gd` · 40 verificações de recuperação, reforma, ruína, mercados, frete, escolta e carga caída.

- `verify_kingdom.gd` · 26 verificações de mercado clandestino, justiça, clima, obra pública e recuperação da rota.

- `verify_realms.gd` · 27 verificações territoriais com transição, cadeia de suprimentos, perda e recuperação de carga, obra e expansão.

O motor Godot 4.7.2 emitiu um aviso sobre o acesso ao repositório de certificados do Windows. O jogo e as suítes foram executados localmente.
