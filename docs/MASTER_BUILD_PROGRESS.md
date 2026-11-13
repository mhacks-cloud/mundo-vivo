# Edição offline · acompanhamento

Base auditada: `9e11384` da 4.5. As dez suítes existentes passaram com 287 verificações. O progresso está na branch `feature/mundo-vivo-completo`.

| Marco | Estado | Critério e evidência |
| --- | --- | --- |
| A · Auditoria | Validado | Base local e remota coincidiram. Suítes de economia, sociedade, combate, comércio, justiça e persistência executadas. |
| B e H · Economia, sociedade e cidades | Parcial | Reposição de trigo, reparo serrano e oficina do Pouso existentes. Falta fechar o balanço monetário, generalizar a contratação e a migração e ligar as cadeias produtivas entre regiões. |
| C, D e J · Campanha e atividades | Marco jogável | Diário em N usa o estado real de terreno, contrato, guilda, travessia e Ruína. A pesca na margem consome isca, respeita o limite diário e produz alimento. |
| E, F, G e I · Mundo, combate e ecossistema | Parcial | Regiões, Ruína da Serra, caravanas, guardas, guildas e fauna existentes preservados. Faltam novos biomas, masmorras, chefes e a expansão das guildas. |
| K · Interface e áudio | Parcial | Continuar, configurações e créditos no menu. Resolução, tela cheia, qualidade, volume geral e sensibilidade persistem. Faltam áudio por categoria, remapeamento e acessibilidade ampliada. |
| L · Testes | Parcial | A suíte de campanha integra a rota pacífica de uma agricultora. A suíte da expansão cobre combate e cofre separadamente. Não houve teste manual de campanha completa nem medição representativa de FPS. |
| M · Exportação | Marco jogável | Windows e Linux x86_64 exportados com templates oficiais Godot 4.7.2. Windows iniciou em modo headless sem erros de script. A execução em Linux segue sem teste neste ambiente. |
| N · Lançamento | Pendente | Publicação de progresso na branch. A edição definitiva depende dos critérios restantes. |

## Apresentação visual

Pavimentos e acessórios urbanos aproveitam a geometria e as texturas existentes. As adições são cenográficas e a navegação mantém os obstáculos anteriores. O Pouso recebe detalhes no mesmo momento em que a moradia correspondente aparece. Os sprites mantêm 32 × 40 pixels, com detalhes por classe e profissão na mesma escala.

## Controles deste marco

- **N** abre o diário de campanha. Cada marco concede XP uma vez por partida.
- **E** na margem do Amieiro, perto da ponte de pedra, pesca usando uma semente. Há limite de duas capturas por dia.
- **B** abre a bolsa e permite consumir o peixe quando há PV a recuperar.
- **P**, **K** e **U** abrem Atlas, economia e sociedade. **F5** salva e **F9** carrega.

## Resultados de validação

O Godot executou 301 verificações sem falhas, incluindo 14 da campanha. A simulação acelerada de 192 dias registrou 127 entregas de trigo, consumo de 379 unidades, estoque mínimo de uma unidade e saldo final de três. Houve bloqueio e reabertura da estrada. O tesouro serrano chegou a zero no dia 137. O teste verifica conservação do trigo da capital em janelas aceleradas e não certifica a solvência do reino.

## Retomada

Investigar o esgotamento do tesouro serrano na simulação de 192 dias. Modelar reposição orçamentária com receitas reais antes de ampliar consumo e população. Depois fechar a cadeia de ferramentas, generalizar o recrutamento e testar a campanha até o conteúdo avançado, incluindo novos biomas e masmorras.
