# Documento de design do Mundo Vivo

As regras abaixo descrevem o RPG sandbox medieval HD-2D e a evolução prevista para o Vale do Amieiro. O estado real de cada sistema está em [Implementation Status](IMPLEMENTATION_STATUS.md). O roteiro de execução está em [Next Steps](NEXT_STEPS.md).

O Vale é o ponto de partida da expansão. Cenário, sprites, proporções, controles e partidas existentes fazem parte da continuidade do projeto. A versão offline funciona localmente. O multiplayer dedicado dependerá de adaptação dos serviços, sincronização, segurança, persistência centralizada e testes em rede.

## 1. DIREÇÃO VISUAL DEFINITIVA

ESTILO OBRIGATÓRIO:

Fantasia medieval HD-2D cinematográfica.

Cenários tridimensionais estilizados com:

- Texturas detalhadas.
- Casas medievais de madeira e pedra.
- Telhados de telha.
- Árvores variadas.
- Florestas densas.
- Vegetação natural.
- Gramados detalhados.
- Rios e lagos.
- Montanhas.
- Iluminação dinâmica.
- Sombras.
- Profundidade de campo discreta.
- Atmosfera de diorama.

PERSONAGENS:

Manter EXATAMENTE a linguagem visual dos personagens
atualmente existentes no Vale do Amieiro 4.0.

Não modificar proporções fundamentais.
Não substituir o visual aprovado.
Não tentar tornar os personagens realistas.

Novos personagens e classes devem utilizar o mesmo padrão.

Criar variações de roupas, acessórios, cabelos e cores
sem romper a identidade visual.

A câmera continuará elevada, com rotação Q/R e zoom.

Implementar ocultação ou transparência temporária de
objetos que bloqueiam a visualização do jogador.

Preservar a qualidade visual em todas as expansões.

## 2. ARQUITETURA OFFLINE PREPARADA PARA ONLINE

Utilizar Godot 4.x e GDScript.

Separar:

- Cliente e apresentação visual.
- Regras de simulação.
- Estado persistente do mundo.
- Gerenciamento de entidades.
- Inventários e transações.
- Navegação.
- Combate.
- Economia.
- Construção.
- Eventos.
- Interfaces.
- Persistência.
- Infraestrutura de rede futura.

Criar uma camada de simulação autoritativa local.

O cliente não deverá ser a única autoridade para:

- Ouro.
- Inventários.
- Fabricação.
- Terrenos.
- Propriedades.
- Comércio.
- Dano.
- Recompensas.
- Construções.

Na versão offline, a simulação autoritativa funciona localmente.

Posteriormente, ela poderá ser transferida ou adaptada para
servidores dedicados, com as mudanças necessárias para rede,
concorrência e segurança.

Evitar dependências obrigatórias de serviços externos.

O jogo precisa iniciar e funcionar sem internet.

## 3. CALENDÁRIO GLOBAL

REGRAS DEFINITIVAS:

1 dia do jogo = 120 minutos reais.
1 hora do jogo = 5 minutos reais.
1 ano = 96 dias do jogo.
1 estação = 24 dias do jogo.

Quatro estações:

- Primavera.
- Verão.
- Outono.
- Inverno.

O calendário será compartilhado entre todas as regiões.

As estações serão invertidas entre hemisférios.

A passagem do tempo deverá afetar:

- NPCs.
- Plantas.
- Animais.
- Economia.
- Eventos.
- Construções.
- Comércio.
- Iluminação.
- Temperatura.
- Clima.

Implementar relógio central e sistema de eventos temporais.

O avanço offline, quando o jogo estiver fechado, deverá
ser configurável e limitado para não gerar resultados absurdos.

## 4. CLIMA GEOGRÁFICO

O mundo deverá possuir regiões climáticas distintas.

Variáveis:

- Latitude.
- Hemisfério.
- Altitude.
- Distância do mar.
- Bioma.
- Temperatura.
- Umidade.
- Precipitação.
- Estação.
- Ventos.

BIOMAS:

- Temperado.
- Tropical.
- Equatorial.
- Árido.
- Costeiro.
- Montanhoso.
- Florestal.
- Pantanoso.
- Frio.
- Alpino.

O inverno não deverá gerar neve em todas as regiões.

Regiões tropicais poderão apresentar estações de chuva
e seca mais marcantes que diferenças de temperatura.

Implementar:

- Chuva.
- Nevoeiro.
- Geadas.
- Neve regional.
- Tempestades.
- Vento.
- Secas.
- Enchentes controladas.

O clima deverá afetar atividades econômicas e ambientais.

## 5. CRIAÇÃO DE PERSONAGENS

Implementar uma tela de criação completa.

Permitir:

- Nome.
- Personalização cosmética.
- Escolha de classe.
- Escolha de nação.
- Visualização do personagem.
- Confirmação definitiva.

A classe escolhida será PERMANENTE.

Não permitir troca livre de classe.

Todos os personagens terão identificadores únicos.

Na versão offline, permitir diferentes personagens salvos,
cada um com seu próprio progresso.

Preparar identificação segura para contas futuras.

## 6. CLASSES DE AVENTURA

Implementar quatro classes:

GUERREIRO:
- Combate corpo a corpo.
- Armaduras.
- Defesa.
- Proteção de grupos.
- Escolta de caravanas.

ARQUEIRO:
- Combate à distância.
- Arcos.
- Munições.
- Rastreamento.
- Exploração.

MAGO:
- Magias ofensivas.
- Consumo de mana.
- Progressão mágica.
- Dependência de poções e equipamentos.

CURANDEIRO:
- Cura.
- Suporte.
- Proteção.
- Recuperação de aliados.
- Habilidades de equipe.

Cada classe deverá possuir:

- Progressão.
- Níveis.
- Experiência.
- Habilidades ativas.
- Habilidades passivas.
- Equipamentos compatíveis.
- Recursos próprios.
- Especializações futuras.

Implementar habilidades reais, com animações, efeitos,
custos e regras de combate.

## 7. CLASSES ECONÔMICAS

Implementar:

AGRICULTOR:
Plantações, colheitas, criação de animais, ingredientes,
fertilizantes e produção agrícola.

MÉDICO:
Fabricação especializada de poções de vida e mana,
tratamentos, processamento de ervas e remédios.

FERREIRO:
Armas, armaduras, ferramentas, reparos e aprimoramentos.

ARTESÃO:
Móveis, decoração, utensílios, componentes de construção
e objetos personalizados.

Cada classe terá exclusividade sobre suas receitas
especializadas.

Não permitir que todas fabriquem tudo.

Criar árvores de progressão e especialização.

O Médico será a principal profissão de produção de poções.
O Curandeiro será a classe de suporte em combate.

São classes diferentes, com funções complementares.

Prever futuras profissões:

- Minerador.
- Lenhador.
- Transportador.

Essas profissões adicionais poderão ser implementadas como
classes fixas futuras ou atividades de coleta limitadas,
sem destruir a importância das classes econômicas atuais.

## 8. ECONOMIA INTERDEPENDENTE

A economia deverá conectar todas as classes.

EXEMPLOS:

Agricultor produz ervas.
Médico compra ervas e fabrica poções.
Mago compra poções.
Mago explora masmorras e obtém materiais.
Ferreiro compra materiais e fabrica equipamentos.
Guerreiro compra equipamentos.
Artesão fabrica móveis para proprietários de casas.

Criar demanda recorrente.

MECÂNICAS:

- Consumo de itens.
- Durabilidade.
- Reparos.
- Materiais de fabricação.
- Equipamentos por raridade.
- Custos de produção.
- Oferta e demanda.
- Contratos.
- Impostos.
- Transporte.
- Armazenamento.

NPCs poderão comprar itens comuns por preços menores,
garantindo uma alternativa básica para o jogador.

Produtos avançados deverão valorizar as profissões.

NPCs poderão fornecer recursos básicos emergenciais,
sem concorrer diretamente com itens especiais dos jogadores.

Evitar ciclos infinitos de geração de ouro e recursos.

## 9. INVENTÁRIO E EQUIPAMENTOS

Implementar:

- Inventário por slots.
- Peso e capacidade.
- Equipamentos.
- Ferramentas.
- Consumíveis.
- Armazéns.
- Baús.
- Transferências.
- Separação de pilhas.
- Compra e venda.
- Durabilidade.
- Reparos.
- Raridades.

RARIDADES:

Comum.
Incomum.
Raro.
Épico.
Lendário.

Itens deverão ter identificadores e dados consistentes.

As operações devem ser atômicas quando necessário.

Impedir duplicação de itens.

Preparar registros de transações para multiplayer futuro.

## 10. NAÇÕES E REIS NPCs

Criar um sistema de nações.

Cada nação terá:

- Rei NPC permanente.
- Capital.
- Vilas.
- Territórios.
- Tesouro.
- Impostos.
- Recursos.
- Leis.
- Guardas.
- Infraestrutura.
- Mercado regional.
- Projetos públicos.
- Relações com outras nações.

JOGADORES NÃO PODERÃO SE TORNAR REIS.

Os reis serão NPCs responsáveis pelo governo.

O jogador escolhe sua nação ao criar o personagem.

Mudar de nação deverá ser possível futuramente apenas
mediante um processo especial e custo elevado.

Começar aproveitando a nação do Vale do Amieiro.

Expandir com regiões e uma segunda nação demonstrável.

Não gerar enormes áreas vazias apenas para dizer que
o mundo ficou maior.

## 11. TERRENOS E PROPRIEDADES

Cada personagem poderá adquirir um terreno inicial.

Terrenos terão:

- ID único.
- Nação.
- Região.
- Coordenadas.
- Dimensões.
- Proprietário.
- Valor.
- Impostos.
- Permissões.
- Construções.
- Histórico.

O jogador poderá personalizar seu terreno.

Permitir:

- Casas.
- Jardins.
- Hortas.
- Cercas.
- Estábulos.
- Depósitos.
- Oficinas.
- Decorações.

Proibir sobreposição de terrenos.

Preparar regras futuras de gestão de terrenos abandonados,
com notificações, prazos e preservação de bens.

## 12. CONSTRUÇÃO PRIVADA

Implementar um modo de construção visual completo.

Permitir:

- Escolher planta.
- Posicionar fundação.
- Construir paredes.
- Instalar portas.
- Instalar janelas.
- Escolher telhados.
- Colocar pisos.
- Colocar móveis.
- Rotacionar peças.
- Mover decorações.
- Remover estruturas.
- Ampliar construções.

Usar recursos reais do inventário.

Validar:

- Limites do terreno.
- Colisões.
- Permissões.
- Custos.
- Materiais.
- Posicionamento.

Criar visualização antecipada antes de confirmar.

As alterações precisam persistir no salvamento.

Construções devem manter a arquitetura medieval HD-2D.

## 13. AGRICULTURA COMPLETA

Criar:

- Preparação de solo.
- Plantio.
- Irrigação.
- Crescimento.
- Colheita.
- Fertilidade.
- Qualidade de produção.
- Sementes.
- Estufas.
- Fertilizantes.
- Armazenamento.
- Criação de animais.

Plantações devem depender de:

- Clima.
- Temperatura.
- Solo.
- Água.
- Estação.
- Bioma.

Implementar culturas regionais.

O jogador poderá vender produtos aos NPCs ou utilizá-los
na cadeia produtiva.

Adicionar comportamentos de animais próprios.

## 14. NPCs AUTÔNOMOS

Preservar os NPCs existentes e aprofundar suas rotinas.

Cada NPC relevante terá:

- Nome.
- Profissão.
- Residência.
- Trabalho.
- Horários.
- Inventário.
- Necessidades simplificadas.
- Relacionamentos sociais básicos.
- Estado de atividade.
- Objetivos.
- Destino.

ATIVIDADES:

- Caminhar.
- Trabalhar.
- Comprar.
- Vender.
- Transportar.
- Descansar.
- Comer.
- Dormir.
- Conversar.
- Procurar abrigo.
- Reagir a acontecimentos.

Criar um sistema de tarefas e prioridades.

NPCs próximos terão movimento e animação detalhados.

NPCs distantes serão simulados de maneira simplificada.

A simulação distante deverá produzir resultados consistentes,
sem precisar executar toda a animação física.

Não criar NPCs completamente estáticos para representar
atividades que deveriam ser visíveis.

## 15. OBRAS PÚBLICAS MISTAS

SISTEMA DEFINITIVO:

O rei NPC poderá propor obras públicas.

Jogadores e guildas também poderão apresentar propostas.

O rei avaliará:

- Utilidade.
- Orçamento.
- Recursos.
- Localização.
- Infraestrutura.
- Segurança.
- Prioridades nacionais.

Se aprovada, a obra será executada por NPCs.

OS NPCs DEVEM CONSTRUIR FISICAMENTE.

TIPOS DE OBRAS:

- Pontes.
- Estradas.
- Mercados.
- Postos de guarda.
- Portos.
- Armazéns.
- Muralhas.
- Fazendas públicas.
- Praças.
- Canais.
- Sistemas de irrigação.

ETAPAS:

Planejamento.
Compra de recursos.
Transporte.
Descarga.
Fundação.
Estrutura.
Acabamento.
Inspeção.
Inauguração.

Criar:

- Andaimes.
- Trabalhadores.
- Carroças.
- Materiais.
- Animações.
- Mudança visual progressiva.

Estruturas concluídas devem alterar o mundo real do jogo.

Exemplo:

Ponte concluída.
Nova travessia habilitada.
Navegação atualizada.
Caravanas utilizam a ponte.
Distância comercial diminui.

O progresso deve persistir.

## 16. MUNDO VIVO E EVENTOS ENCADEADOS

Criar um diretor de eventos dinâmicos.

Eventos terão:

- Causas.
- Condições.
- Consequências.
- Duração.
- Participantes.
- Mudanças persistentes.
- Possíveis soluções.

EXEMPLO:

Seca regional.
Produção agrícola diminui.
Preço dos alimentos aumenta.
Rei solicita suprimentos.
Jogadores vendem produtos.
NPCs transportam mercadorias.
Rei aprova sistema de irrigação.
NPCs constroem o canal.
Produção regional melhora.

OUTRO EXEMPLO:

Tempestade danifica ponte.
Rota comercial é interrompida.
Caravanas precisam fazer desvio.
Custos de transporte aumentam.
Rei inicia reconstrução.
Jogadores fornecem materiais.
NPCs executam os reparos.
Rota é reaberta.

EVENTOS ADICIONAIS:

- Festivais.
- Feiras.
- Colheitas.
- Descobertas de minas.
- Expedições.
- Ataques de monstros.
- Inundações.
- Secas.
- Problemas de abastecimento.
- Obras de expansão.
- Visitas de comerciantes.
- Crescimento urbano.

Evitar crises constantes ou punições aleatórias excessivas.

Cada evento deve possuir regras de recuperação e limites.

## 17. MERCADOS REGIONAIS

Cada nação terá seu próprio mercado.

Preços serão influenciados por:

- Oferta local.
- Demanda local.
- Estoques.
- Produção.
- Impostos.
- Transporte.
- Eventos.
- Consumo.

Não utilizar um mercado global com preços idênticos.

Produtos poderão valer mais em regiões onde são escassos.

Criar:

- Bancas.
- Lojas.
- Mercado público.
- Armazéns.
- Histórico de preços.
- Compra e venda.
- Contratos comerciais.

Na versão offline, NPCs simulados poderão representar
participantes do comércio.

Preparar adaptação futura para mercados entre jogadores.

## 18. CARAVANAS E TRANSPORTE FÍSICO

Criar transporte de mercadorias entre regiões.

TIPOS:

- Pequena carroça.
- Caravana comercial.
- Comboio de guilda.

Permitir:

- Carregar produtos.
- Definir destino.
- Escolher rota.
- Contratar escolta.
- Transportar mercadorias.
- Descarregar.
- Concluir contrato.
- Receber pagamento.

NÃO permitir transferência instantânea de mercadorias
entre nações.

A carga deverá percorrer fisicamente as rotas.

Implementar peso e capacidade.

Caravanas podem ser atacadas dentro das regras do mundo.

REGRA DEFINITIVA:

A derrota de uma caravana pode resultar na perda
de 100% de sua CARGA TRANSPORTADA.

O saque integral refere-se à carga da caravana,
não automaticamente aos equipamentos pessoais
ou ao dinheiro bancário dos acompanhantes.

A carga perdida deverá existir como itens recuperáveis
no mundo por um período controlado.

Implementar regras para evitar duplicação de mercadorias.

Criar contratos de escolta com pagamentos reservados,
condições de entrega e reputação.

## 19. GUILDAS

Implementar guildas com:

- Nome.
- Identidade.
- Membros.
- Cargos.
- Tesouro.
- Armazém.
- Sede.
- Contratos.
- Reputação.
- Histórico.
- Permissões.

CARGOS INICIAIS:

Líder.
Oficial.
Tesoureiro.
Capitão.
Membro.

Criar registros de movimentações de recursos.

Guildas poderão atuar em:

- Comércio.
- Exploração.
- Escoltas.
- Produção.
- Construção.
- Defesa.

Na versão offline, criar guildas simuladas com NPCs
para testar os sistemas.

Preparar os sistemas de membros para jogadores reais
na futura versão online.

## 20. GUILDAS CRIMINOSAS

Implementar guildas criminosas registradas no
sistema clandestino do mundo.

Essa autorização não vem dos reis.

Guildas criminosas terão:

- Registro clandestino.
- Esconderijo.
- Reputação criminal.
- Mercado negro.
- Contratos ilegais fictícios.
- Mercadorias saqueadas.
- Procurados.
- Recompensas.
- Consequências legais.

Criar NPCs e comerciantes do submundo.

A economia clandestina deverá possuir custos, riscos
e restrições, evitando recompensas desproporcionais.

O sistema será inteiramente fictício e integrado
às regras de jogo.

## 21. COMBATE

Implementar combate funcional para as quatro
classes de aventura.

SISTEMAS:

- Vida.
- Mana.
- Atributos.
- Ataques.
- Defesa.
- Habilidades.
- Tempo de recarga.
- Animações.
- Projéteis.
- Efeitos.
- Criaturas.
- Recompensas.
- Experiência.
- Durabilidade.

Criar inimigos com comportamentos diferentes.

Implementar:

- Patrulha.
- Perseguição.
- Ataque.
- Defesa.
- Retorno ao território.
- Derrota.
- Recompensa.

Criar balanceamento inicial para combate solo e em grupo.

Na versão offline, aliados NPCs poderão simular
papéis de uma equipe.

## 22. MASMORRAS DINÂMICAS

Criar masmorras acessíveis no mundo.

Cada masmorra terá:

- Localização.
- Nível recomendado.
- Criaturas.
- Chefes.
- Recompensas.
- Modificadores.
- Dificuldade.
- Estado persistente quando necessário.

A dificuldade poderá variar conforme:

- Progressão do mundo.
- Região.
- Modificadores diários.
- Tipo de masmorra.

Criar categorias para iniciantes e veteranos.

Não tornar todas as masmorras impossíveis para novos jogadores.

Implementar recompensas utilizadas na cadeia econômica.

Criar pelo menos uma masmorra completa no Vale do Amieiro,
com entrada, exploração, combate, chefe e recompensa.

## 23. PVP E CRIMINALIDADE

Preparar a lógica do PvP para futuro multiplayer.

REGRA PLANEJADA:

PvP permitido no mundo, inclusive em cidades.

Guardas NPCs intervêm em agressões ilegais.

O mundo deverá distinguir:

- Cidadão.
- Suspeito.
- Criminoso.
- Fora da lei.
- Reincidente.

Atacar outro personagem poderá gerar consequências
dependendo das leis regionais e do contexto.

DEFESA LEGÍTIMA:

Quem se defende de uma agressão injustificada
não deve receber automaticamente punição criminal.

VÍTIMAS INOCENTES:

Não devem ser presas simplesmente por terem sido derrotadas.

PENALIDADES:

- Multas válidas.
- Perda parcial de itens elegíveis quando não houver ouro.
- Prisão temporária em situações previstas pelas leis.
- Reputação criminal.
- Recompensas por procurados.

A prisão será consequência de infração ou penalidade válida,
não uma punição genérica por derrota.

Evitar perda automática de equipamentos protegidos.

Na versão offline, testar PvP e criminalidade por meio
de NPCs controlados pela simulação.

Não implementar multiplayer real como dependência nesta fase.

## 24. GUARDAS E SISTEMA DE JUSTIÇA

Criar guardas com:

- Patrulhas.
- Áreas de atuação.
- Horários.
- Resposta a agressões.
- Investigação simplificada.
- Aplicação de multas.
- Captura de criminosos.
- Proteção de obras públicas.

As guardas deverão variar conforme as nações.

Regiões perigosas terão proteção reduzida.

Regiões comerciais terão maior presença de patrulhas.

Evitar que os guardas saibam instantaneamente
sobre ocorrências distantes sem qualquer informação.

Implementar testemunhas e comunicação simulada de eventos.

## 25. CONTEÚDO PARA JOGADORES PACÍFICOS

O jogo não deverá obrigar todos a combater.

Criar atividades alternativas:

- Agricultura.
- Pesca.
- Criação de animais.
- Culinária.
- Artesanato.
- Decoração.
- Jardinagem.
- Comércio.
- Transporte.
- Construção.
- Exploração tranquila.
- Feiras.
- Coleções.
- Descobertas.
- Contratos econômicos.

Proteger o equilíbrio entre profissões econômicas
e classes de combate.

Nenhuma classe deverá ser inútil para a economia.

## 26. HISTÓRIA PERSISTENTE DO MUNDO

Criar um registro histórico por região e nação.

Registrar acontecimentos importantes:

- Pontes inauguradas.
- Estradas construídas.
- Grandes festivais.
- Descobertas.
- Crises superadas.
- Novas cidades.
- Obras financiadas por guildas.
- Eventos econômicos.

Exibir parte dessa história em:

- Quadros de avisos.
- Livros.
- Monumentos.
- Placas.
- Diários.
- Notícias regionais.

O mundo deverá carregar marcas de sua própria evolução.

## 27. EXPANSÃO DINÂMICA DO MUNDO

Preparar geração e ativação de novas regiões.

No futuro online, a expansão será influenciada por:

- População ativa.
- Ocupação territorial.
- Atividade econômica.
- Recursos disponíveis.
- Infraestrutura.
- Desempenho dos servidores.

Não expandir apenas pela quantidade de contas criadas.

Implementar regiões com identidade geográfica.

Cada nova região deverá possuir:

- Bioma.
- Recursos.
- Clima.
- Fauna.
- Infraestrutura.
- NPCs.
- Economia.
- Rotas.
- Eventos.

Priorizar crescimento coerente e persistente.

Na versão offline, demonstrar a ativação de uma
nova região por condições simuladas.

## 28. INTERFACE COMPLETA

Criar interface medieval discreta e funcional.

TELAS:

- Menu principal.
- Novo jogo.
- Carregar jogo.
- Criação de personagem.
- Seleção de classe.
- Inventário.
- Equipamentos.
- Habilidades.
- Profissão.
- Receitas.
- Construção.
- Mapa.
- Mercado.
- Contratos.
- Guilda.
- Nação.
- Propriedade.
- Calendário.
- Diário.
- Configurações.

Manter informações essenciais visíveis sem ocupar
excessivamente a tela.

Adicionar atalhos e suporte a mouse e teclado.

Preservar os controles aprovados.

## 29. SALVAMENTO E PERSISTÊNCIA

Implementar salvamento versionado e robusto.

PERSISTIR:

- Personagens.
- Classes.
- Níveis.
- Experiência.
- Inventários.
- Ouro.
- Equipamentos.
- Casas.
- Terrenos.
- Plantações.
- NPCs importantes.
- Mercados.
- Estoques.
- Obras.
- Nações.
- Guildas.
- Contratos.
- Eventos.
- Calendário.
- Estados das regiões.
- História do mundo.

Implementar migração de salvamentos antigos.

Criar backups locais.

Proteger contra corrupção e gravações interrompidas.

Utilizar operações consistentes para transações
que movimentam recursos.

Não permitir duplicação por salvar/carregar repetidamente.

## 30. DESEMPENHO

O jogo deverá possuir configurações:

BAIXO.
MÉDIO.
ALTO.

Aplicar:

- LOD quando apropriado.
- Otimização de vegetação.
- Atualização escalonada de NPCs.
- Simulação simplificada distante.
- Gerenciamento de memória.
- Carregamento por regiões.
- Limites de partículas.
- Otimização de colisões.
- Redução de atualizações desnecessárias.

Não reduzir o padrão artístico do projeto.

Criar indicadores opcionais de FPS e desempenho.

Evitar milhares de NPCs sendo processados integralmente
a cada frame.

## 31. TESTES AUTOMATIZADOS E FUNCIONAIS

Preservar todos os testes anteriores.

Criar testes por sistema.

TESTAR:

- Criação de personagem.
- Classe permanente.
- Progressão.
- Inventário.
- Compra e venda.
- Fabricação.
- Durabilidade.
- Construção de casas.
- Propriedade.
- Agricultura.
- Rotinas de NPCs.
- Calendário.
- Clima.
- Eventos.
- Obras públicas.
- Mercados regionais.
- Caravanas.
- Saque de cargas.
- Guildas.
- Criminalidade.
- Guardas.
- Combate.
- Masmorras.
- Salvamento.
- Migração.
- Expansão de regiões.

TESTES DE INTEGRAÇÃO:

Agricultor produz trigo.
Transportador recolhe trigo.
Comerciante recebe trigo.
Estoque é atualizado.
Jogador compra trigo.
Ouro e estoque são movimentados corretamente.
O estado é salvo.
O jogo é reiniciado.
Os dados permanecem corretos.

OUTRO TESTE:

Rei aprova construção.
NPCs recebem tarefas.
Recursos são transportados.
Materiais são consumidos.
Construção muda visualmente.
A ponte é concluída.
Navegação é atualizada.
O mundo é salvo.
A ponte permanece construída após reiniciar.

Não informar testes aprovados sem execução real.

## 32. ORGANIZAÇÃO E DOCUMENTAÇÃO

Criar documentação:

- README.
- Arquitetura.
- Controles.
- Estrutura de pastas.
- Classes.
- Economia.
- NPCs.
- Calendário.
- Construções.
- Salvamento.
- Eventos.
- Testes.
- Roadmap online.

Criar documento de design principal:

docs/GAME_DESIGN_DOCUMENT.md

Esse arquivo deverá consolidar as regras oficiais
definidas neste prompt.

Criar acompanhamento:

docs/IMPLEMENTATION_STATUS.md

Classificar funcionalidades como:

IMPLEMENTADO.
TESTADO.
PARCIAL.
PENDENTE.
BLOQUEADO.

Nunca confundir planejamento com implementação real.

## 33. GIT E GITHUB

Continuar o projeto existente.

Verificar:

git status
git remote -v
git log -5 --oneline

Preservar arquivos e alterações do usuário.

Criar commits organizados por módulo.

Se GitHub estiver autenticado e autorizado:

- Identificar o repositório existente.
- Configurar remoto quando necessário.
- Fazer commits.
- Enviar alterações.
- Criar tags das versões estáveis.

Se ainda não houver repositório remoto e houver autorização
e autenticação adequadas, criar um repositório para Mundo Vivo.

Não sobrescrever repositórios ou histórico sem autorização.

Não enviar arquivos temporários ou segredos ao GitHub.

Criar .gitignore apropriado ao Godot.

Se o push não for possível, explicar o motivo e deixar
o projeto local organizado.

## 34. IMPLEMENTAÇÃO POR ETAPAS

ESTE É O PONTO MAIS IMPORTANTE.

Não tentar implementar todos os sistemas superficialmente.

Dividir o desenvolvimento em etapas internamente,
mantendo sempre uma versão funcional.

ETAPA A — CONSOLIDAÇÃO DO MUNDO VIVO 4.0

- Inspecionar projeto.
- Corrigir problemas existentes.
- Validar salvamentos.
- Consolidar personagem.
- Consolidar classes.
- Consolidar terrenos.
- Consolidar construção.
- Consolidar inventário.
- Preservar visual.
- Executar testes.

ETAPA B — VIDA DO JOGADOR

- Construção modular completa.
- Casas personalizáveis.
- Agricultura.
- Animais próprios.
- Profissões econômicas.
- Fabricação.
- Inventário expandido.
- Progressão.

ETAPA C — COMBATE E EXPLORAÇÃO

- Classes de aventura.
- Habilidades.
- Equipamentos.
- Criaturas.
- IA de inimigos.
- Masmorra completa.
- Chefes.
- Recompensas.

ETAPA D — ECONOMIA REGIONAL

- Segunda nação demonstrável.
- Mercados independentes.
- Produção regional.
- Estoques.
- Impostos.
- Contratos.
- Comércio entre regiões.
- Transporte físico.

ETAPA E — GUILDAS E CARAVANAS

- Guildas.
- Armazéns.
- Tesouros.
- Contratos.
- Caravanas.
- Escoltas.
- Saque de carga.
- Reputação.
- Comércio clandestino.

ETAPA F — JUSTIÇA E CONFLITOS

- Guardas.
- Leis.
- Criminalidade.
- Reputação.
- Multas.
- Prisão.
- Combate contra NPCs criminosos.
- Simulação das regras futuras de PvP.

ETAPA G — MUNDO VIVO AVANÇADO

- Eventos encadeados.
- Obras públicas propostas por jogadores.
- Projetos aprovados por reis NPCs.
- Construção física.
- Eventos climáticos.
- Expansão de regiões.
- História persistente.
- Comportamentos emergentes.

ETAPA H — ACABAMENTO OFFLINE

- Integração de todos os sistemas.
- Correção de bugs.
- Balanceamento.
- Otimização.
- Áudio.
- Interfaces.
- Tutorial.
- Salvamento robusto.
- Testes finais.
- Documentação.
- Versão offline distribuível.

ETAPA I — PREPARAÇÃO FUTURA PARA CLOUD

DOCUMENTAR E PREPARAR, SEM EXIGIR SERVIDOR ONLINE AGORA:

- Servidor dedicado.
- Sincronização de entidades.
- Autenticação.
- Identidade de contas.
- Persistência centralizada.
- Transações seguras.
- Gerenciamento de regiões.
- Transferência entre áreas.
- Infraestrutura escalável.
- Ferramentas administrativas.
- Segurança contra exploração de regras.
- Observabilidade.
- Backups.
- Testes de carga.

Não apresentar esses sistemas como online funcional
até serem realmente implementados e testados em rede.

## Regras jogáveis de reinos, justiça e submundo na 4.2

O fardo tem o identificador do frete, sua origem, o proprietário anterior quando conhecido e o estado de circulação. Uma carroça perdida gera uma carga recuperável. O batedor Téo recolhe um fardo se alcançar o ponto antes do proprietário. Mira cadastra associados e intermedeia o comércio no Junco. A entrega de contrato retira o identificador da circulação. O estoque legal responde à entrega e ao consumo regional durante a escassez.

A guarda opera com linha de visão, relato identificado e tempo de comunicação. O ataque à carroça é um alerta de proteção e pode abrir um prêmio de escolta. Negociação observada no Junco gera uma suspeita e, depois do prazo, um mandado. A multa pode ser quitada no posto. Uma captura permite recolher ouro e suprimentos elegíveis. A prisão termina no calendário do mundo.

A Prefeitura aceita propostas, aplica o cadastro de terrenos e reserva orçamento e materiais. A mestra Iara se desloca entre depósito e canteiro durante a jornada. A conclusão libera o acesso norte, aumenta a capacidade do mercado ou melhora a observação da guarda, conforme o projeto. A enchente usa clima de Brumária e exige a Ponte Nova pronta. Durante a interdição, a navegação e o preço de varejo do trigo refletem o desvio.

## Economia e diplomacia jogáveis na 4.4

Os mercados mantêm seus estoques anteriores. Pedidos reservam o pagamento no tesouro de origem e recebem produtos reais. Um pedido vencido ou cancelado devolve a reserva. A fronteira cobra o valor do tratado em vigor quando a caravana passa. A seca prolonga a maturação da horta, e o acordo de abastecimento pode despachar trigo da banca pela estrada. A cooperação reserva ouro para reparos físicos.

## Expansão territorial jogável na 4.3

A Coroa do Amieiro mantém o Vale agrícola, o bosque e a Ponte Nova. Brumária tem um entreposto, uma ruína e a capital Alto da Bruma, governada por Rainha Elira. O portão permite cruzar entre os cenários no mesmo relógio. Fora da capital, a simulação conserva estoques, carregamentos e etapas da obra sem instanciar o cenário serrano. Salmar aparece como porto futuro.

Os fretes do Vale entregam ao entreposto. Aldo compra do estoque real desse mercado e transporta até três trigos por vez. A guarda registra a passagem e recolhe tarifa. A Companhia oferece escolta, e a carga de uma derrota permanece recuperável. A Irmandade pode retirar um fardo rastreado enquanto ele ainda está no terreno. A entrega repõe estoque e reduz pressão sobre preços.

Altitude, bioma, hemisfério e influência marítima determinam o clima. A mina tem reservas limitadas. Tempestades podem fechar o Caminho Alto e aumentar o custo do desvio. Rainha Elira financia reparos ou uma moradia com reservas reais de ferro, madeira e ouro. A mestra transporta cada carga. A inauguração reabre o caminho ou habilita o Pouso da Geada, com moradora e nova descoberta no atlas.
