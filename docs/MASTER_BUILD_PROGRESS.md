# Edição offline · acompanhamento

Base auditada: `9e11384` da 4.5. As dez suítes existentes passaram com 287 verificações. O progresso está na branch `feature/mundo-vivo-completo`.

| Marco | Estado | Critério e evidência |
| --- | --- | --- |
| A · Auditoria | Validado | Base local e remota coincidiram. Suítes de economia, sociedade, combate, comércio, justiça e persistência executadas. |
| B e H · Economia, sociedade e cidades | Parcial | Na janela acelerada de 192 dias, o tesouro serrano permaneceu positivo. O mercado recebe apenas verba existente, e o entreposto reserva caixa para comprar trigo antes de importar ferro e madeira. Madeira e ferro chegam fisicamente à ferraria; o depósito do Vale compra enxadas forjadas. Contratação e migração ainda usam a rota de Beatriz. |
| C, D e J · Campanha e atividades | Marco jogável | Diário em N usa o estado real de terreno, contrato, guilda, travessia e Ruína. A pesca na margem consome isca, respeita o limite diário e produz alimento. |
| E, F, G e I · Mundo, combate e ecossistema | Parcial | Regiões, Ruína da Serra, caravanas, guardas, guildas e fauna existentes preservados. Faltam novos biomas, masmorras, chefes e a expansão das guildas. |
| K · Interface e áudio | Parcial | Continuar, configurações e créditos no menu. Resolução, tela cheia, qualidade, volume geral e sensibilidade persistem. Faltam áudio por categoria, remapeamento e acessibilidade ampliada. |
| L · Testes | Parcial | Treze suítes somaram 332 verificações sem falhas; a série de 192 dias encerrou com código 0. Benchmark headless de 300 quadros: média de 0,309 ms por quadro neste computador. Não é uma medição de FPS de renderização em hardware modesto. |
| O · Sistema Deus | Primeira versão funcional | Poço, oito árvores e oito barris existentes possuem IDs estáveis. Interface de desenvolvimento permite mover, girar, adicionar, duplicar, remover, pintar, validar, salvar, desfazer e restaurar revisão anterior. Os saves dos jogadores são separados. Casas e estruturas com estado econômico ainda exigem comandos próprios. |
| M · Exportação | Marco jogável | Windows e Linux x86_64 exportados com templates oficiais Godot 4.7.2. Windows iniciou em modo headless sem erros de script. A execução em Linux segue sem teste neste ambiente. |
| N · Lançamento | Progresso publicado | Mudanças na branch pública `feature/mundo-vivo-completo`. A `main` permanece na 4.4; a edição definitiva depende dos critérios restantes. |

## Apresentação visual

Pavimentos e acessórios urbanos aproveitam a geometria e as texturas existentes. As adições são cenográficas e a navegação mantém os obstáculos anteriores. O Pouso recebe detalhes no mesmo momento em que a moradia correspondente aparece. Os sprites mantêm 32 × 40 pixels, com detalhes por classe e profissão na mesma escala.

## Controles deste marco

- **N** abre o diário de campanha. Cada marco concede XP uma vez por partida.
- **E** na margem do Amieiro, perto da ponte de pedra, pesca usando uma semente. Há limite de duas capturas por dia.
- **B** abre a bolsa e permite consumir o peixe quando há PV a recuperar.
- **P**, **K** e **U** abrem Atlas, economia e sociedade. **F5** salva e **F9** carrega.

## Resultados de validação

As treze suítes de regressão somaram 332 verificações sem falhas. A simulação acelerada de 192 dias registrou 127 entregas de trigo, consumo de 379 unidades, estoque mínimo de uma unidade e saldo final de três, sem dias de estoque zerado. Houve bloqueio e reabertura da estrada. O tesouro serrano terminou em 366; antes da revisão, chegava a zero no dia 137. Na mesma janela, 48 madeiras foram exportadas e 24 enxadas foram forjadas. O teste acompanha a conservação do trigo e o caixa da capital nessa janela; não certifica solvência indefinida. O editor passou em 21 verificações, incluindo recarga, pintura, movimento dos NPCs, backup e cancelamento.

## Retomada

Generalizar recrutamento e migração além de Beatriz. Expandir consumo e transporte físico das ferramentas entre o entreposto e o Vale, testar finanças em horizontes maiores e medir FPS em hardware modesto. Depois ampliar a campanha e as regiões, e criar comandos de edição específicos para casas, oficinas e vias estruturais. Não promover a branch a lançamento antes dessas validações.
