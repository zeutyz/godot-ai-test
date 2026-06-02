O que estamos construindo

Um motor de terreno procedural completo dentro da Godot 4.6.3, capaz de gerar mundos vastos, vivos e estilizados — com a estética quente, pintada à mão e orgânica dos filmes do Studio Ghibli. Não é um jogo final, mas sim a espinha dorsal tecnológica que permitirá criar qualquer experiência nesse universo visual: um RPG de exploração, um simulador de voo, ou simplesmente um mundo para caminhar e contemplar.

O coração do sistema: GPU-Driven Rendering

Toda a geração do mundo acontece na GPU, de forma massivamente paralela e assíncrona. A CPU fica livre para a lógica do jogo — IA, diálogos, física do personagem — enquanto a GPU esculpe o terreno, simula rios e vento, e posiciona milhões de árvores e folhas de grama em tempo real.

O terreno nasce de ruído procedural refinado por simulação física de erosão hidráulica e térmica. A água cai, escorre, dissolve o solo, forma vales e deposita sedimentos em planícies. Montanhas parecem verdadeiras porque foram esculpidas por processos geológicos reais, não por fórmulas matemáticas frias.

A vegetação responde a esse terreno: inclinações íngremes geram rochas expostas; vales úmidos viram florestas densas; topos de montanha ficam áridos. Cada árvore, cada pedra, cada tufo de grama é posicionado por algoritmos estocásticos na GPU, com distribuição de ruído azul que evita agrupamentos artificiais.

A estética: pintura viva

O visual não busca realismo fotográfico. Busca a magia da aquarela.

O terreno usa texturização virtual em tempo de execução — materiais são misturados proceduralmente em um atlas dinâmico, criando transições suaves como pigmento se espalhando no papel. A grama amostra a cor do solo exatamente onde nasce, eliminando qualquer emenda visível entre chão e vegetação. Caminhos de terra batida empurram a grama para debaixo da superfície automaticamente, sem nenhum processamento de física.

As copas das árvores usam normais esféricas — a luz bate nelas como se fossem nuvens fofas e redondas, não conjuntos de cartões sobrepostos. O sombreamento é toon, mas com gradientes suaves entre as bandas de luz, e um rim light sutil que simula a atmosfera difusa de um dia de verão. Sombras são suaves, com bordas que lembram pinceladas de aquarela.

A grama é gerada analiticamente como curvas de Bézier — cada lâmina é uma forma suave que se move com o vento, não um plano texturizado. O vento não é uma animação pré-gravada: é uma simulação procedural baseada em ruído matemático e posição no mundo, criando frentes de ar que atravessam vales e florestas de forma orgânica.

A escala: mundos virtualmente infinitos

O sistema de chunks em streaming carrega o terreno em anéis ao redor da câmera, com níveis de detalhe adaptativos. Próximo ao jogador, a malha é densa e rica em detalhes. Na distância, a tesselação se reduz suavemente, mantendo o horizonte vasto sem consumir polígonos desnecessários.

Milhões de instâncias de vegetação são geradas, mas apenas as visíveis são renderizadas. Um sistema de culling hierárquico na GPU descarta tudo que está atrás de montanhas ou fora do campo de visão, enviando para a rasterização apenas o que realmente importa — tudo em uma única chamada de desenho indireto.

O mundo reage ao tempo. Chuva aumenta a erosão em tempo real, criando riachos temporários. Nuvens volumétricas se formam sobre áreas úmidas. A vegetação inclina-se com frentes de vento que propagam-se fisicamente pelo terreno.

O que torna isso diferente

Não é um gerador de terreno comum. É um ecossistema digital completo onde geologia, hidrologia, botânica e atmosfera interagem em um loop fechado, tudo rodando em silício gráfico em tempo real. A estética Ghibli não é apenas um filtro pós-processamento — é o resultado natural de uma simulação que respeita as leis da natureza, mas as expressa através de uma lente estilizada, quente e humana.

O objetivo final é um mundo onde o jogador possa parar em um topo de colina, olhar para um vale coberto de floresta, ver o vento mover as copas das árvores como ondas, notar um riacho brilhando ao longe, e sentir — não pensar, mas sentir — que aquilo ali é um lugar real, com história, com peso, com alma.

