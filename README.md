# Mundo Vivo

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
| **F5 / F9** dentro do jogo | Salvar / carregar |
| **F6** | Alternar gráficos baixos, médios e altos |
| **F7** | Alternar profundidade de campo, gradação de cor e vinheta |
| **F1** | Mostrar ou recolher a ajuda |
| **F10** | Ocultar ou restaurar toda a interface |
| **T** | Avançar três horas do relógio para experimentar a iluminação e as rotinas |

Saia do caminho de terra para chegar à praça. A **Raposa Dourada** fica ao norte do poço e a **Forja do Amieiro** a oeste. A horta fica atrás da forja. Atravesse a ponte de pedra e siga a trilha para o norte para chegar à entrada da Ruína da Serra.

A segunda ponte fica rio acima, na margem da vila. Durante o dia, Ivo e Mara levam madeira até o canteiro e trabalham por alguns segundos a cada carga. Para ajudar, pressione **E** na pilha de madeira e leve a carga até a margem. A obra passa por estacas, longarinas e tabuleiro. A passagem abre após oito entregas. **F5** guarda o calendário, a posição, a carga do jogador e o progresso da obra em `user://vale_do_amieiro.json`. O último estado válido é lido ao iniciar.

Um dia do vale dura **120 minutos reais** com o jogo aberto. O ano tem **96 dias** e cada estação dura **24 dias**. A tecla **T** avança o relógio imediatamente. Os moradores retomam a rotina do novo horário e continuam percorrendo os trajetos em tempo real.

## Estrutura

| Pasta | Responsabilidade |
| --- | --- |
| `scenes/` | Cena de entrada do Vale do Amieiro |
| `scripts/presentation/` | Montagem do diorama, câmera, iluminação e atores em `AnimatedSprite3D` |
| `scripts/world/` | `WorldClock`, `SeasonManager`, `RegionalClimate`, `NPCManager`, `ConstructionManager` e `InteractionSystem` |
| `scripts/persistence/` | `SaveManager` e formato local de salvamento |
| `assets/`, `shaders/` e `ui/` | Texturas, rio, precipitação, lente e interface |
| `data/` e `tests/` | Perfil geográfico e verificações automatizadas |

`WorldSimulation` expõe `tick`, `command`, `snapshot` e `restore` para o estado de calendário e construção. A cena local encaminha entregas de madeira como comandos e atualiza a geometria da obra ao receber a mudança de etapa. Essa fronteira permite mover o estado da obra para uma futura autoridade de rede. Movimento, colisão e execução dos trajetos dos moradores ainda rodam localmente.

## Checklist

### Implementado

- [x] Vila 3D explorável, com casas enxaimel, poço, taberna, forja, canteiros, mercados, vegetação, rio, duas pontes, bosque e entrada da ruína.
- [x] Jogador em pixel art com repouso e caminhada, colisão, interação e câmera de seguimento com zoom e rotação.
- [x] Seis moradores com rotas, diálogos e horários de trabalho e descanso. Os dois carpinteiros carregam madeira e usam animação de martelar.
- [x] Obra com andaimes, três fases construtivas, colaboração do jogador e abertura física da passagem.
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
```

### Limites do protótipo

- A visita à ruína termina na entrada selada. As casas, a taberna e a forja são exploráveis pelo exterior.
- Há um único perfil geográfico ativo no mapa. O cálculo de clima aceita outros perfis. As estações mudam a paleta do terreno e das plantas. O acúmulo de neve é representado apenas por uma cobertura leve quando o clima indica neve.
- A iluminação usa luz ambiente global, sol, sombras e fontes locais. A oclusão de contato das fundações é calculada pelo material do solo. Iluminação indireta com rebotes físicos fica pendente. A lente reconstrói a profundidade a partir do buffer do Compatibility e mantém o foco no personagem.
- As rotas dos moradores usam pontos de passagem predefinidos. A posição exata deles é reconstruída ao carregar a partir do horário e da obra.
- Multiplayer e servidor autoritativo ficam para uma etapa posterior. A entrega é o projeto Godot executável pelo editor. O rio usa um reflexo de céu aproximado pelo ângulo de visão. Os sons são sintetizados para o protótipo.

## Recursos visuais

O atlas original de telhas, alvenaria, madeira e reboco foi gerado com a ferramenta ImageGen integrada e recortado em quatro texturas de 128 × 128 em `assets/textures/`. As duas imagens do briefing orientaram a composição e o tratamento dos materiais. Sprites, modelos modulares, vegetação, pavimento, texturas de terreno e shaders foram construídos para este projeto. Nenhum pacote de arte de terceiros foi incorporado. A atualização acrescenta quatro recortes de folhagem e quatro de terreno gerados com ImageGen integrado. Os sons são amostras PCM produzidas pelo código do jogo. A interface procura fontes disponíveis no sistema e usa o fallback do Godot quando necessário.

Prompt do atlas

> Game texture atlas, four exact equal quadrants in a 1024x1024 square image, no dividers, no labels, no margin. Production asset for original HD-2D medieval village diorama based on the mood of the two user references (no copied assets). Orthographic straight-on flat textures, seamless within each quadrant, crisp hand-painted 16-bit pixel clusters, natural muted rich palette, neutral diffuse illumination, no objects or perspective. Upper left: rows of aged terracotta curved roof tiles, warm russet ocher individual tile highlights and dark seams. Upper right: rough gray warm limestone irregular masonry wall with thin dark mortar. Lower left: dark walnut weathered wood grain, horizontal boards, muted earthy brown. Lower right: antique honey cream lime plaster with finely mottled ocher surface. All four intended to crop individually as repeating textures on real 3D meshes.

## Git

O projeto de trabalho preserva o commit inicial `db18fee`. A tag `seguranca/antes-hd2d` aponta para a versão anterior. A atualização tem commit local na mesma branch. Para publicar a versão local em um repositório privado novo, a partir da pasta com o histórico Git e com a CLI autenticada, execute `gh repo create mundo-vivo --private --source=. --remote=origin --push`.


## Atualização HD-2D

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

## Medição e validação

Medição local a 1280 × 720, Godot 4.7.2, Compatibility/OpenGL, RTX 3050 Laptop 6 GB, VSync desligado. Foram amostrados 90 quadros por perfil com a câmera voltada para a praça, após aquecimento. Os números representam uma amostra curta nesta máquina.

| Perfil | Tempo médio por quadro | FPS equivalentes | Chamadas de desenho por quadro |
| --- | ---: | ---: | ---: |
| Baixo | 1,50 ms | 666 | 206 |
| Médio | 2,60 ms | 384 | 412 |
| Alto | 2,93 ms | 341 | 528 |

O ajuste final da lente acrescentou amostras diretas do quadro para tornar o desfoque perceptível no OpenGL. As duas pontes também foram agrupadas por material. O Godot emitiu um aviso de acesso ao repositório de certificados do Windows neste ambiente. A importação, as capturas e os testes offline foram concluídos.

O projeto local está sem remoto configurado. A busca na integração GitHub retornou zero repositórios instalados para `mundo-vivo`. A CLI `gh` estava indisponível e a integração acessível não oferecia criação de repositório.
