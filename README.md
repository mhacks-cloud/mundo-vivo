# Mundo Vivo 4.5 · desenvolvimento

Pressione **U** para consultar a vida nas cidades, os caixas dos estabelecimentos, os salários e as notícias. A Feira da Colheita vende alimentos na praça no dia 11 de cada estação, das 08:00 às 19:00. O pedido de trigo volta ao quadro a cada três dias após o aceite anterior. Alto da Bruma exporta ferro ao entreposto quando há excedente.

A suíte `tests/verify_society.gd` cobre carteiras, refeições, contratos, ferro, oficina e feira. `tests/verify_civilization.gd` acompanha a mudança de Beatriz, a obra no Pouso e o transporte de enxadas em janelas de 30 dias.

**Vale do Amieiro** é o primeiro mapa jogável de um sandbox medieval offline. A vila é construída em 3D, com texturas pixeladas, personagens animados em 2D e iluminação que acompanha o relógio do vale.

## Jogar

1. Extraia o ZIP.
2. No gerenciador de projetos do [Godot 4](https://godotengine.org/download/windows/), escolha **Importar** e selecione `project.godot`.
3. Abra o projeto, aguarde a importação dos recursos e pressione **F5** no editor.

Validado no Windows com Godot 4.7.2 e renderizador Compatibility/OpenGL. O projeto usa GDScript e funciona offline. As texturas e shaders já estão incluídos.

| Controle | Ação |
| --- | --- |
| **WASD** | Caminhar em relação à câmera |
| **Q / R** | Girar a câmera |
| **Roda do mouse** | Aproximar ou afastar |
| **E** | Interagir com o ponto ou morador indicado |
| **B / C** | Inventário / ficha, equipamentos e registros |
| **H / M** | Construção / contratos |
| **I / J** | Consultar a carga da ponte / abrir o Diário do Vale |
| **F / Shift** | Técnica da classe no campo de treino / defesa do guerreiro |
| **Z / clique esquerdo** | Girar / confirmar a peça no modo de construção |
| **Esc** | Fechar a ficha ou cancelar a peça |
| **F5 / F9** dentro do jogo | Salvar / carregar |
| **F6** | Alternar gráficos baixos, médios e altos |
| **F7** | Alternar profundidade de campo, gradação de cor e vinheta |
| **F1** | Mostrar ou recolher a ajuda |
| **F10** | Ocultar ou restaurar toda a interface |
| **T** | Avançar três horas do relógio para experimentar a iluminação e as rotinas |

Saia do caminho de terra para chegar à praça. A **Raposa Dourada** fica ao norte do poço e a **Forja do Amieiro** a oeste. A horta fica atrás da forja. Atravesse a ponte de pedra e siga a trilha para o norte para chegar à entrada da Ruína da Serra.

A segunda ponte fica rio acima, na margem da vila. Use **E** no depósito para recolher o recurso disponível e **E** no canteiro para descarregar. Ivo e Mara também buscam as cargas e montam a estrutura. A travessia abre após oito instalações e a inspeção. **F5** grava o mundo da partida selecionada. Escolha a partida no menu inicial para continuar.

Para acompanhar a economia, visite a horta atrás da forja e a banca junto à Raposa Dourada. O quadro público fica perto do banco a nordeste do poço. O diário (**J**) registra as colheitas, entregas, compras, trabalhos, cumprimentos e ocorrências da vila.

Um dia dura **120 minutos reais**, uma hora dura **5 minutos reais**, o ano tem **96 dias** e cada estação dura **24 dias**. **T** avança três horas do relógio. Na inicialização, a diferença desde o último salvamento adianta somente o calendário, com limite padrão de 30 minutos reais configurável em `data/regiao.json`. Use `0` em `limite_offline_minutos` para desativar esse avanço. **F9** restaura exatamente a hora gravada.
### Sua primeira casa

1. Crie o personagem, escolha o traje, a classe permanente e a Coroa do Amieiro. Escolha entre Horta Velha e Prado da Ponte.
2. Siga o caminho de terra ao sul da praça até os lotes delimitados. Abra **H** junto ao seu terreno e escolha uma peça ou monte a casa inicial por 20 madeiras e 4 pedras. Fique fora das quatro células centrais para montar a casa.
3. Escolha canteiro, cerca, piso, parede, porta, janela, telhado ou mobília. A prévia verde confirma o encaixe. **Z** gira e clique esquerdo instala. **Esc** cancela. O telhado some enquanto o personagem está sobre o piso, para facilitar o uso do interior.
4. Use **E** na banca de Lina para negociar das 07:00 às 19:00. A alquimia fica junto à taberna, a forja a oeste da praça e a marcenaria a noroeste do poço. **M** consulta contratos e o quadro público a nordeste do poço recebe as entregas.
5. Para as classes de aventura, atravesse a ponte de pedra e vá ao sul pela margem leste. **F** acerta o alvo adequado à sua técnica. O alvo de guarda contra-ataca de perto. Recupere vida e mana longe da área ou use consumíveis.

O menu inicial oferece partidas independentes, com um personagem por arquivo. A partida anterior aparece na mesma lista. **F5** grava a partida selecionada e **F9** restaura sua gravação. Quando a gravação principal falha na validação, **Recuperar** abre a última cópia válida.
## Estrutura

| Pasta | Responsabilidade |
| --- | --- |
| `scenes/` | Cena de entrada do Vale do Amieiro |
| `scripts/presentation/` | Montagem do diorama, câmera, iluminação e atores em `AnimatedSprite3D` |
| `scripts/world/` | Calendário, clima, rotinas, navegação, construção, estoques, economia e diário de eventos |
| `scripts/persistence/` | `SaveManager` e formato local de salvamento |
| `assets/`, `shaders/` e `ui/` | Texturas, rio, precipitação, lente e interface |
| `data/` e `tests/` | Perfil geográfico e verificações automatizadas |

`WorldSimulation` coordena calendário, economia e obra. `NPCManager` guarda horários, destino, estado e necessidades. A cena transforma destinos em movimento físico usando `VillageNavigation`, que usa [AStarGrid2D](https://docs.godotengine.org/en/stable/classes/class_astargrid2d.html). Os estoques, as transações e as fases da obra estão separados da renderização para uma futura autoridade de rede.

## Checklist

### Implementado

- [x] Vila 3D explorável, com casas enxaimel, poço, taberna, forja, canteiros, mercados, vegetação, rio, duas pontes, bosque e entrada da ruína.
- [x] Jogador em pixel art com repouso e caminhada, colisão, interação e câmera de seguimento com zoom e rotação.
- [x] Nove moradores com profissão, casa, destinos, necessidades, turnos, diálogos e reação à chuva. Doze animais de seis espécies com locomoção, animação e sons.
- [x] Obra com pedido, separação, transporte, descarga, preparação da margem, andaimes, fundações, estrutura, acabamentos, inspeção e abertura da travessia.
- [x] Economia com estoques persistentes, lavoura em fases, ferramentas forjadas, carga física, compras simuladas e diário local.
- [x] Ciclo diurno e noturno, calendário e clima calculado por latitude, hemisfério, altitude e bioma. Céu limpo, névoa, chuva e neve fazem parte do modelo.
- [x] Três perfis gráficos, profundidade de campo estilizada e salvamento local.

### Validado

- [x] Importação das texturas e inicialização da cena principal em Godot 4.7.2.
- [x] Renderização OpenGL em 1280 × 720, com inspeção visual de dia, à noite, sob chuva e no outono.
- [x] Testes de calendário, estações, parâmetros climáticos, movimentação, colisão, interação, câmera, rotinas, conclusão das pontes e restauração do salvamento.

Para repetir a verificação no terminal, substitua `godot` pelo caminho do executável. No Windows, a edição `_console.exe` exibe o relatório no terminal.

```powershell
godot --headless --path . --editor --import
godot --headless --path . --quit-after 100
godot --headless --path . --fixed-fps 60 --script res://tests/verify.gd
godot --headless --path . --fixed-fps 60 --script res://tests/verify_presentation.gd
godot --headless --path . --fixed-fps 60 --script res://tests/verify_life.gd
godot --headless --path . --fixed-fps 60 --script res://tests/verify_player_life.gd
godot --headless --path . --fixed-fps 60 --script res://tests/verify_expansion.gd
godot --headless --path . --fixed-fps 60 --script res://tests/verify_kingdom.gd
godot --headless --path . --fixed-fps 60 --script res://tests/verify_realms.gd
```

### Limites do protótipo

- As casas dos NPCs, a taberna e a forja são exploráveis pelo exterior.
- O Vale e o posto de Brumária têm perfis climáticos distintos. As estações mudam a paleta do terreno e das plantas. O acúmulo de neve é representado apenas por uma cobertura leve quando o clima indica neve.
- A iluminação usa luz ambiente global, sol, sombras e fontes locais. A oclusão de contato das fundações é calculada pelo material do solo. Iluminação indireta com rebotes físicos fica pendente. A lente reconstrói a profundidade a partir do buffer do Compatibility e mantém o foco no personagem.
- Os destinos das rotinas são pontos de serviço definidos na vila. A navegação resolve os trechos entre eles. Repouso e abrigo são representados junto às residências e aos estabelecimentos, cujos interiores ficam para outra etapa.
- Multiplayer e servidor autoritativo ficam para uma etapa posterior. A entrega é o projeto Godot executável pelo editor. O rio usa um reflexo de céu aproximado pelo ângulo de visão. Os sons são sintetizados para o protótipo.

## Recursos visuais

O atlas original de telhas, alvenaria, madeira e reboco foi gerado com a ferramenta ImageGen integrada e recortado em quatro texturas de 128 × 128 em `assets/textures/`. As duas imagens do briefing orientaram a composição e o tratamento dos materiais. Sprites, modelos modulares, vegetação, pavimento, texturas de terreno e shaders foram construídos para este projeto. Nenhum pacote de arte de terceiros foi incorporado. A atualização acrescenta quatro recortes de folhagem e quatro de terreno gerados com ImageGen integrado. Os sons são amostras PCM produzidas pelo código do jogo. A interface procura fontes disponíveis no sistema e usa o fallback do Godot quando necessário.

Prompt do atlas

> Game texture atlas, four exact equal quadrants in a 1024x1024 square image, no dividers, no labels, no margin. Production asset for original HD-2D medieval village diorama based on the mood of the two user references (no copied assets). Orthographic straight-on flat textures, seamless within each quadrant, crisp hand-painted 16-bit pixel clusters, natural muted rich palette, neutral diffuse illumination, no objects or perspective. Upper left: rows of aged terracotta curved roof tiles, warm russet ocher individual tile highlights and dark seams. Upper right: rough gray warm limestone irregular masonry wall with thin dark mortar. Lower left: dark walnut weathered wood grain, horizontal boards, muted earthy brown. Lower right: antique honey cream lime plaster with finely mottled ocher surface. All four intended to crop individually as repeating textures on real 3D meshes.

## Git

O projeto de trabalho preserva o commit inicial `db18fee`. A tag `seguranca/antes-hd2d` aponta para a versão anterior. A atualização tem commit local na mesma branch. Para publicar a versão local em um repositório privado novo, a partir da pasta com o histórico Git e com a CLI autenticada, execute `gh repo create mundo-vivo --private --source=. --remote=origin --push`.


## Histórico da versão 2.0 · Atualização HD-2D

- `scripts/presentation/diorama.gd` e `palette.gd` acrescentam módulos de fachada, sacadas, toldos, carroça, vasos e detalhes de margem. Os mesmos pontos de passagem, construções e rotas do Vale continuam em uso.
- `scripts/presentation/vale_foliage.gd` e `shaders/foliage.gdshader` agrupam camadas de folhas, pinheiros, arbustos e gramíneas em MultiMesh. O vento move as pontas e a câmera abre uma área de visibilidade na copa. Fachadas que cortam a linha entre câmera e jogador são ocultadas temporariamente, mantendo suas colisões.
- `shaders/terrain.gdshader` mistura terra, grama, pedras e raízes com bordas irregulares, escurecimento junto a fundações, variação sazonal e solo úmido.
- `scripts/presentation/vale.gd`, `shaders/lens.gdshader` e `shaders/river.gdshader` concentram a revisão de câmera, luz, foco e rio. A opção F7 desliga a lente, e F10 remove todos os painéis para fotografias.
- `scripts/presentation/pixel_actor.gd` desenha sprites originais em 32 × 40, com frente, costas e perfis espelhados. As animações incluem repouso, caminhada e trabalho. Ao conversar, o morador faz uma pausa e se vira para o jogador.
- `scripts/presentation/vale_audio.gd` produz vento, correnteza, crepitação da vila, pássaros, passos e marteladas. A correnteza e o trabalho têm posição no mundo.
- `tests/verify.gd` preserva as 31 verificações originais. `tests/verify_presentation.gd` acrescenta 15 verificações de câmera, HUD, presets, orientações, estações e fontes de áudio.

### Perfis de renderização

| Perfil | Configuração |
| --- | --- |
| Baixo | Contato das fundações, vegetação essencial, alcance de 59 m, lente e MSAA desativados |
| Médio | Mais folhagem, sombras em 2 cascatas, alcance de 83 m, lente moderada, MSAA 2× |
| Alto | Folhagem completa, sombras em 4 cascatas, alcance de 115 m, lente completa, MSAA 4× |

### Novas texturas

Os arquivos estão em `assets/textures/`. Folhagem em 192 × 192 por peça: `oak_leaf.png`, `pine_bough.png`, `bramble.png` e `meadow_tuft.png`. Terreno em 256 × 256 por material: `meadow.png`, `path_dirt.png`, `setts.png` e `riverbank.png`.

Prompt da folhagem

> Transparent original 2D game asset texture atlas in a 2x2 equal square grid, no lines, no labels, no borders, each quadrant has one isolated asset fully inside cell with clear transparent margins. Upper left broad irregular gnarled oak canopy foliage spray, jagged silhouette like clusters of tiny oak leaves viewed front from slightly above, no trunk. Upper right dense downsloping pine bough with needles on angled brown twig and jagged tapering fan silhouette. Lower left dense broadleaf ivy bramble bush foliage with small muted ivory blooms and bright sprigs, irregular asymmetric silhouette. Lower right fine long wispy meadow grass tuft with ferns and a few yellow and violet tiny wildflowers. All use the same hand painted 16 bit pixel art / HD-2D medieval diorama art direction: sharp chunky pixel marks, detailed granular clusters, deep olive and moss green dark shadows, subdued natural sunlit pale green highlights, natural realistic tree silhouettes distilled into old RPG art, no gradients, no giant round blobs, no shadows outside silhouettes, no background, no anti-aliasing. A production game texture atlas, not a scene.

Prompt do terreno

> Original square 2x2 grid of seamless medieval landscape game terrain textures, exact equal quadrants with no border gaps labels or markings. Orthographic top down fully flat surfaces. Upper left rich green old meadow short mossy grass ground cover, tiny dark olive and golden blades and small leaf litter patches, muted textured woodland ground; upper right worn amber umber dirt road made of granular soil with little gravel; bottom left tightly packed irregular rounded gray slate cobblestones (about 14 stones across the quadrant) with dirt joints, weathered moss hints; bottom right dark stone and root riverbank earth with subtle moss details. Hand-painted pixel art with visible pixel clusters, crisp 16-bit fantasy medieval HD-2D diorama material, muted natural greens warm earth and warm gray, contrast but neutral even lighting and no perspective. All four quadrants filled edge to edge as textures.

## Medição da versão 2.0

Medição local a 1280 × 720, Godot 4.7.2, Compatibility/OpenGL, RTX 3050 Laptop 6 GB, VSync desligado. Foram amostrados 90 quadros por perfil com a câmera voltada para a praça, após aquecimento. Os números representam uma amostra curta nesta máquina.

| Perfil | Tempo médio por quadro | FPS equivalentes | Chamadas de desenho por quadro |
| --- | ---: | ---: | ---: |
| Baixo | 1,50 ms | 666 | 206 |
| Médio | 2,60 ms | 384 | 412 |
| Alto | 2,93 ms | 341 | 528 |

O ajuste final da lente acrescentou amostras diretas do quadro para tornar o desfoque perceptível no OpenGL. As duas pontes também foram agrupadas por material. O Godot emitiu um aviso de acesso ao repositório de certificados do Windows neste ambiente. A importação, as capturas e os testes offline foram concluídos.

O projeto local está sem remoto configurado. A busca na integração GitHub retornou zero repositórios instalados para `mundo-vivo`. A CLI `gh` estava indisponível e a integração acessível não oferecia criação de repositório.

## Histórico da versão 3.0 · A Vila Ganha Vida

| Área | Implementação |
| --- | --- |
| Horta | Teresa prepara, planta, rega ou aproveita a chuva, cuida dos brotos e colhe. A colheita fica no inventário de Teresa até o depósito. Os canteiros mostram terra, brotos ou plantas maduras. |
| Transporte | Nilo recolhe trigo na horta e descarrega na banca. Também entrega ferro e madeira à forja conforme a necessidade e leva ferramentas ao depósito. A inauguração habilita a travessia nova para as rotas. |
| Comércio e forja | Lina converte trigo em alimentos. Compras de moradores reduzem o estoque e aumentam a demanda da horta. Baltasar consome ferro e madeira para forjar ferramentas. Os painéis indicam horários e estoques. |
| Rotinas | Cada morador tem horário, residência, local de trabalho, estado, destino, fome e cansaço. Os guardas alternam turnos e reforçam a margem na chuva. Há pausas, refeições, descanso, sono e cumprimentos entre moradores. |
| Ponte | As cargas são reservadas no depósito, transportadas, descarregadas e consumidas nas instalações. A geometria mostra o progresso. A inspeção é obrigatória e persistente. Ao inaugurar, a colisão abre e a malha de navegação é reconstruída. |
| Fauna | Galinhas ciscam, vacas e ovelhas pastam, pássaros pousam e voam, o gato repousa e o cão ronda. Os doze animais têm limites locais, colisão e sons sintetizados por espécie. |
| Salvamento | O formato 2 carrega o formato 1. Persiste relógio, ponte, posição e carga do viajante, moradores e destinos, estoques, canteiros e os últimos 64 eventos. A carga em trânsito fica em um único inventário. |
| Desempenho | A navegação é recalculada ao mudar o destino ou abrir a ponte. A movimentação distante usa passos maiores com colisão, a fauna usa atualizações escalonadas e encontros sociais são verificados a cada meio segundo. |

A versão 3.0 mantém o layout e o renderizador Compatibility da 2.0. Os sprites animados em cena são originais e desenhados pelo código. Os retratos das fichas são dez PNGs de 128 × 128 em `assets/portraits/`. O atlas de nove retratos e o retrato individual de Branca foram produzidos com ImageGen integrado, recortados e redimensionados para a interface. As novas faíscas de forja usam partículas e os novos sons são sintetizados pelo jogo.

- **Arquivos principais.** `npc_manager.gd`, `village_navigation.gd`, `village_inventory.gd`, `village_economy.gd`, `village_journal.gd`, `world_simulation.gd` e `construction_manager.gd` implementam a simulação. `vale.gd`, `diorama.gd`, `pixel_actor.gd`, `vale_fauna.gd`, `vale_audio.gd` e `vale_hud.gd` cuidam da apresentação e da interação.
- **Verificação.** As 46 verificações da versão 2.0 passaram antes das mudanças. A versão 3.0 passa nas suítes de 31, 15 e 28 verificações. Duas asserções anteriores foram atualizadas para o elenco de nove moradores e as três fontes de marteladas. A nova suíte percorre a economia na cena real, testa clima, fauna e a nova rota e recarrega duas vezes um salvamento com carga em trânsito.
- **Correções durante os testes.** A leitura do cabeçalho passou a aceitar as versões após a conversão numérica do JSON. A navegação passou a conferir a folga das quinas. A inspeção ganhou duração própria após um teste detectar que entregas simultâneas podiam antecipar a abertura.
- **Limites.** O comércio ocorre entre NPCs. A guarda reage a riscos climáticos, com combate pendente. A simulação em tempo fechado adianta o calendário sem sintetizar entregas ou compras. Os dados locais já estão separados da cena, com servidor autoritativo, comércio entre jogadores e sincronização de rede ainda pendentes.
- **GitHub.** A tag `seguranca/antes-vila-viva` preserva o commit `0ac00d6`. O repositório local está sem remoto. A integração autenticada não encontrou repositório instalado correspondente a `mundo-vivo`, e a CLI `gh` estava indisponível.

### Prompts dos retratos

> A square production UI atlas for a medieval pixel-art RPG, exact 3 by 3 equal cells, each cell a unique distinct portrait on a solid very dark forest green background #18221c. No frames, no text, no labels, no cell separators. Face and shoulders entirely inside each cell with ample padding. Hand-placed 16-bit SNES pixel art with visibly stepped hard pixel clusters, warm light and deep colored shadows, original designs, serious warm human expressions. Row 1 left to right: young blonde player with blue teal wool traveler coat and gold clasp; dark brown-haired male carpenter Ivo in rust brown cap and leather tool vest; brown-haired female carpenter Mara in ochre headscarf and russet sleeves. Row 2 left to right: brunette merchant Lina in plum linen with ivory collar; blacksmith Baltasar with dark graying beard and slate blue work shirt and leather apron; auburn-haired farmer Teresa in green dress and ocher straw hat. Row 3 left to right: bearded transporter Nilo with sea green coat, travel hood and shoulder strap; young tan male guard Afonso with small iron nasal helmet and maroon gambeson; older gray-haired resident Beatriz in warm olive hood. View three-quarter bust, all heads around the same relative height. Original classic RPG illustration, no copied assets, game portrait texture sheet only.

> Single square game UI portrait of Branca, an original medieval night watchwoman around 30 with dark brown bob hair partly visible under a riveted steel nasal helmet, violet slate gambeson, dark brown belt, simple iron lantern clasp, tan complexion. Face and shoulders with margin, three quarter bust facing right, original classic 16-bit RPG hand-placed pixel art, hard blocky edge pixels, deep forest green solid backdrop (#18221c), late afternoon warm key light and deep colored shadows, no text or borders. Fit an existing atlas of pixel portrait icons featuring detailed shoulder clothing.

## Histórico da versão 4.0 · Sua Vida Começa Aqui

| Área | Implementação |
| --- | --- |
| Personagem | Cadastro com nome validado, prévia do sprite da 3.0, cinco cores de roupa, quatro tons de cabelo, classe e nação gravadas. |
| Nações | Coroa do Amieiro jogável e Brumária e Salmar cadastradas para expansão. Rei exclusivamente NPC, regiões, lotes, tesouro, imposto, caixa de mercado e reputação. |
| Casa | Dois lotes exclusivos de 7,5 × 7,5 m. Fundação, piso, paredes, duas portas, duas janelas, dois telhados, cerca, banco, canteiro e flores. Encaixes por célula e borda, prévia, rotação, cancelamento, colisões e consumo de materiais. A casa inicial usa 20 módulos. |
| Inventário | Bolsa de 85 kg, baú de 260 kg, pilhas, durabilidade e quatro slots de equipamento. Coleta, compra, venda, uso, equipar, guardar, retirar e descarte. |
| Economia pessoal | Ouro e caixa regional finitos, imposto arredondado em ouro, preços distintos de compra e venda, serviços de reparo, cinco contratos de entrega única, reputação e registros. Vendas de trigo e entregas abastecem os estoques da vila. |
| Agricultor | Planta, rega e colhe trigo ou ervas no lote. A chuva pode regar. No galinheiro, alimenta com trigo e recolhe ovos depois de um intervalo. |
| Médico | Processa ervas e frascos em remédio e poção de mana. O remédio recupera vida e a poção restaura mana. |
| Ferreiro | Forja espada, enxada e armadura com exigência de nível. Repara com ferro. Outras classes podem pagar pelo serviço. |
| Artesão | Produz bancos e encaixes usados nas portas e janelas especiais da casa. |
| Aventureiros | Guerreiro usa espada e defesa. Arqueiro dispara flechas e registra rastros. Mago lança projéteis com mana. Curandeiro restaura a aliada ferida. Concluir exercícios e registrar descobertas concede XP. |
| Persistência | O formato 3 carrega os formatos 1 e 2. Salva perfil, lote, módulos, plantas, baú, inventário, ouro, equipamentos, XP, contratos, mercado e estado de treino, além do mundo 3.0. |

### Arquivos e verificação

- `life_catalog.gd`, `life_inventory.gd`, `player_life.gd`, `homestead.gd` e `training_session.gd` concentram o catálogo, o inventário, a progressão, a economia, as regras de terreno e o combate.
- `vale_life.gd`, `vale_housing.gd` e `vale_life_ui.gd` ligam essas regras aos controles, à geometria e à interface. `pixel_actor.gd` reutiliza os desenhos e as animações existentes para a prévia e as cores do traje.
- A suíte `verify_player_life.gd` percorre cadastro, aquisição, plantio, casa, colisões, baú, comércio, treino, migração e reabertura. A versão 4.0 reúne 45 verificações novas e 74 regressões. As três suítes da 3.0 continuam cobrindo os NPCs, a ponte, o clima, a câmera e a movimentação. Elas desativam o cadastro apenas nas instâncias de teste de regressão.
- A tag `seguranca/antes-sua-vida` preserva `d6bcff7`. A busca na integração GitHub não retornou um repositório correspondente e o projeto local está sem remoto. A publicação requer o URL do repositório existente e credenciais Git autorizadas. Com ambos, execute `git remote add origin URL_DO_REPOSITORIO` e `git push -u origin main` na pasta do projeto com histórico.

### Escopo atual

O combate é de treino PvE, com alvos fixos e uma aliada. Criaturas livres, expedições, escolta de caravanas, especializações, troca de nação e multiplayer ficam para versões futuras. Os lotes são privados e a construção é aditiva. As portas instaladas são passagens abertas. O calendário pode avançar ao reabrir, conforme a configuração do Vale, enquanto o inventário e as transações voltam ao estado gravado.

## Jogar a expansão 4.4

Pressione **K** para consultar estoques, preços, tesouros, tratados e pedidos. Aceite e entregue pedidos no quadro da praça do Vale ou no mercado indicado. O pagamento fica reservado até a conclusão. **P** abre o atlas com preços do trigo e relação entre os reinos. Na capital serrana, a forja atende ferreiros e o mercado compra ferramentas novas.

```sh
godot --headless --path . --fixed-fps 60 --script res://tests/verify_economy.gd
```

## Jogar a expansão 4.3

- Pressione **P** para abrir o Atlas dos Reinos. Use a roda para aproximar, arraste para deslocar e clique em um destino para consultar clima e rotas.
- Siga a estrada leste do mercado da fronteira e interaja com o portão. Alto da Bruma tem um mercado próprio, uma pedreira de extração finita e uma sede da Coroa onde Rainha Elira avalia projetos.
- O frete do Vale vende trigo no entreposto. Aldo compra lotes desse estoque para a capital quando há demanda. A fronteira cobra a tarifa, e o trigo só entra no estoque de Alto da Bruma depois da entrega. Membros da Companhia do Vau podem assinar a escolta junto ao portão.
- Tempestades podem fechar o Caminho Alto. O comboio usa a encosta, onde o risco e o custo sobem. O reparo reabre o trecho. Com entregas suficientes, a rainha financia uma moradia e libera o Pouso da Geada.

O repositório existente é [mhacks-cloud/mundo-vivo](https://github.com/mhacks-cloud/mundo-vivo). Abra `project.godot` no Godot 4.7.2 após clonar ou extrair o ZIP.

## Jogar a expansão 4.2

- Em Brumária, procure Mira do Junco no extremo norte. **E** abre o armazém da Irmandade. Em dias de risco, uma carroça derrotada deixa trigo recuperável. Se o batedor chegar a tempo, um fardo identificado sai da carga caída e entra no armazém clandestino.
- **L** abre o registro de justiça. O pagamento voluntário é feito no posto em Brumária. Uma testemunha com visão direta registra a ocorrência. O mandado só fica ativo após o relato. A apreensão se limita a consumíveis elegíveis e o saldo pode virar prisão temporária.
- **E** na Prefeitura do Vale abre as propostas. Após chuva intensa em Brumária e com a Ponte Nova pronta, o acesso norte pode ficar interditado. A rota alternativa usa a ponte de pedra e reduz o pagamento líquido do frete em 3 ouro. A equipe trabalha entre 06:00 e 19:00 e continua de onde parou ao carregar a partida.
- O rei também pode iniciar o reparo no dia seguinte à enchente ou um posto após ocorrências na fronteira, se o tesouro e o depósito puderem sustentar o projeto.

Veja o [changelog](CHANGELOG.md) e o [estado de implementação](docs/IMPLEMENTATION_STATUS.md).

A partir do ZIP, extraia a pasta `Mundo Vivo` e importe `project.godot` pelo gerenciador de projetos do Godot 4.7.2. Use **F6** para testar a cena aberta ou **F5** para iniciar o projeto. Para clonar o remoto privado, copie a URL de clonagem pelo botão **Code** do GitHub e execute `git clone` com essa URL usando uma conta autorizada. Abra o mesmo `project.godot` na pasta clonada.

## Jogar a expansão 4.1

- No menu inicial, escolha **Nova partida**, **Carregar** ou **Recuperar**. Cada partida tem inventário, mundo e progresso próprios.
- No seu lote, abra **H → Mover ou remover peças**. Bancos e vasos podem mudar de encaixe. Retire os elementos dependentes antes de remover pisos ou fundações.
- Para explorar a Ruína da Serra, use **E** na entrada a nordeste, na margem leste. Derrote os dois vigias para abrir a câmara da Sentinela. Use **F** para sua técnica e **E** para abrir o cofre e sair.
- A **Companhia do Vau** recebe membros e doações junto à marcenaria. O quadro **Fretes** fica ao norte da praça. Leve 3 trigos para despachar a carroça. Membros podem reservar a escolta no mesmo pedido. Em dia de emboscada, **F** protege a carga e **E** recupera um fardo caído ao alcance.
- O mercado de **Brumária** fica a leste do rio, na estrada para a serra. Sua banca compra e vende a partir de estoque próprio. O frete paga na chegada.

[Documento de design](docs/GAME_DESIGN_DOCUMENT.md) · [Estado da implementação](docs/IMPLEMENTATION_STATUS.md) · [Retomada e roteiro para Cloud](docs/NEXT_STEPS.md)
