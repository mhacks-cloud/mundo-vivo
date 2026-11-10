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
| **F7** | Alternar desfoque nas bordas |
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
- [x] Renderização OpenGL em 1280 × 720, com inspeção visual de dia e à noite.
- [x] Testes de calendário, estações, parâmetros climáticos, movimentação, colisão, interação, câmera, rotinas, conclusão das pontes e restauração do salvamento.

Para repetir a verificação no terminal, substitua `godot` pelo caminho do executável. No Windows, a edição `_console.exe` exibe o relatório no terminal.

```powershell
godot --headless --path . --editor --import
godot --headless --path . --quit-after 100
godot --headless --path . --fixed-fps 60 --script res://tests/verify.gd
```

### Limites do protótipo

- A visita à ruína termina na entrada selada. As casas, a taberna e a forja são exploráveis pelo exterior.
- Há um único perfil geográfico ativo no mapa. O cálculo de clima aceita outros perfis. A vegetação mantém a mesma aparência durante as quatro estações.
- A iluminação usa luz ambiente global, sol, sombras e fontes locais. Iluminação indireta com rebotes físicos fica pendente. O desfoque é um efeito de lente baseado nas bordas da tela.
- As rotas dos moradores usam pontos de passagem predefinidos. A posição exata deles é reconstruída ao carregar a partir do horário e da obra.
- Multiplayer e servidor autoritativo ficam para uma etapa posterior. A entrega é o projeto Godot executável pelo editor.

## Recursos visuais

O atlas original de telhas, alvenaria, madeira e reboco foi gerado com a ferramenta ImageGen integrada e recortado em quatro texturas de 128 × 128 em `assets/textures/`. As duas imagens do briefing orientaram a composição e o tratamento dos materiais. Sprites, modelos modulares, vegetação, pavimento, texturas de terreno e shaders foram construídos para este projeto. Nenhum pacote de arte de terceiros foi incorporado. A interface procura fontes disponíveis no sistema e usa o fallback do Godot quando necessário.

Prompt do atlas

> Game texture atlas, four exact equal quadrants in a 1024x1024 square image, no dividers, no labels, no margin. Production asset for original HD-2D medieval village diorama based on the mood of the two user references (no copied assets). Orthographic straight-on flat textures, seamless within each quadrant, crisp hand-painted 16-bit pixel clusters, natural muted rich palette, neutral diffuse illumination, no objects or perspective. Upper left: rows of aged terracotta curved roof tiles, warm russet ocher individual tile highlights and dark seams. Upper right: rough gray warm limestone irregular masonry wall with thin dark mortar. Lower left: dark walnut weathered wood grain, horizontal boards, muted earthy brown. Lower right: antique honey cream lime plaster with finely mottled ocher surface. All four intended to crop individually as repeating textures on real 3D meshes.

## Git

O projeto de trabalho tem um commit inicial local. Para publicar a versão local em um repositório privado novo, a partir da pasta com o histórico Git e com a CLI autenticada, execute `gh repo create mundo-vivo --private --source=. --remote=origin --push`.

