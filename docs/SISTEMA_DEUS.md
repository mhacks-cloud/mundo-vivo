# Sistema Deus · primeira versão

O editor faz parte da edição de desenvolvimento do Vale do Amieiro. Abra o projeto no Godot e execute com **F5**. Pressione **F8** para abrir e fechar. O preset **Windows Dev** também habilita o editor por meio da feature `sistema_deus_dev`; os presets **Windows** e **Linux** para jogadores não a habilitam. Não há senha no executável. A verificação de autorização futura deverá ocorrer em um serviço autoritativo antes de aceitar comandos de edição.

## Uso

1. Crie ou carregue uma partida no Vale e pressione **F8**. A simulação, os NPCs e as caravanas param durante a edição.
2. Selecione um objeto na lista ou clique na sua base. Arraste para mover. A grade de 0,5 m pode ser desligada. As setas do painel ajustam a posição em 0,1 m; os botões giram em passos de 15 graus.
3. Use **Adicionar**, **Duplicar** ou **Excluir** em poços, árvores, barris e caixas. O poço dos Fundadores pode ser movido, mas não removido.
4. Escolha um revestimento, marque **Pintar** e clique no terreno para aplicar um quadrado de 1 m. A ferramenta usa os materiais já presentes no diorama. Pintura não cria obstáculos novos.
5. **Desfazer** e **Refazer** afetam a sessão atual. **Salvar** grava as mudanças; **Cancelar** descarta a sessão. **Anterior** restaura o backup da região. Fechar com alterações não salvas descarta essas alterações.

Durante a edição, **Q/R** giram a câmera e a roda do mouse ajusta a distância. Clique no chão vazio para mudar o centro de observação. **Ctrl+Z**, **Ctrl+Y** e **Ctrl+S** equivalem a Desfazer, Refazer e Salvar.

## Persistência e limites

O arquivo `user://world_edits/vale.json` guarda um patch da região, separado dos arquivos de partida. Cada objeto tem ID persistente, região, tipo, posição, rotação, estado, data e versão do esquema. A escrita usa arquivo temporário e conserva `vale.json.previous`. O patch é aplicado uma vez na montagem do diorama, evitando duplicação após carregar a partida. O mesmo patch vale para todas as partidas locais dessa instalação.

O protótipo rejeita posições fora da região, dentro do rio, sobre lotes residenciais, fachadas, portas e outros objetos editáveis. Depois reconstrói uma grade de navegação candidata e exige três corredores de circulação abertos. Poços adicionais não criam ações de interação; o marco original acompanha a nova posição. Mover casas, oficinas, estradas estruturais, pontes, lotes e estruturas com estado econômico ainda exige um comando específico que migre também propriedade, interações, colisões, navegação e salvamentos. Esses objetos não aparecem na lista editável para evitar perda de dados.

As versões de jogador executam o cenário salvo quando o patch existe na mesma instalação, mas não exibem o editor. Para distribuir uma alteração de cenário a outras instalações, o patch validado deverá ser empacotado como dado base em uma etapa de publicação. A versão atual não sincroniza edições entre computadores e não contém autenticação online.

## Extensão

`WorldEditStore` valida o esquema e controla as revisões. `ValeDiorama` registra objetos estáticos por ID e aplica transforms sem remontar o mapa. `WorldEditor` reúne comandos, histórico local, validação e interface. Para adicionar uma categoria, registre o tipo no esquema, crie um construtor visual isolado no diorama e inclua suas regras de colisão, propriedade e navegação antes de expô-lo no painel. Futuras ferramentas de cidades, biomas, NPCs e obras deverão emitir comandos validados pelo sistema que mantém o respectivo estado, e não alterar somente o nó visual.

Execute `tests/verify_world_editor.gd` no Godot para repetir a movimentação do poço, árvore e barril, a recarga da região, a verificação de rota e a restauração do backup.
