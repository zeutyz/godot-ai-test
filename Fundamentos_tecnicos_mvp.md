# Fundamentos tecnicos do MVP procedural

Este documento registra as decisoes atuais do MVP e como elas se conectam aos objetivos dos arquivos de metodologia.

## Arvores estilizadas

A referencia em `Metodologias_e_etapas.md` pede arvores fluffy/cartoon com:

- tronco procedural com `SurfaceTool`;
- folhagem via `MultiMeshInstance3D`;
- clusters de 2 a 3 planos cruzados por copa;
- boas normais, iluminacao estilizada e vento em shader;
- performance adequada para mundo aberto.

No MVP, `src/world/procedural_vegetation.gd` segue essa direcao:

- troncos sao malhas geradas por `SurfaceTool`, com raio base entre 1.0 e 1.5 e altura na faixa de floresta alta;
- copas usam `MultiMeshInstance3D` e malha de planos cruzados, com normal esferica no shader `shaders/foliage_wind.gdshader`;
- o shader usa posicao de mundo e fase por instancia para vento organico;
- a distribuicao de arvores usa prioridade local para aproximar blue noise/Poisson em CPU enquanto a fase compute ainda nao existe.

## Grama densa

Grama densa precisa de `MultiMeshInstance3D`, nao de milhares de nos. O MVP usa uma unica malha de laminas cruzadas e milhares de transforms por chunk. A escala e propositalmente fracionaria:

- X/Z reduzido para manter tufos pequenos;
- Y reduzido para evitar grama com escala de arvore;
- duas camadas de amostragem aumentam cobertura sem multiplicar materiais.

## Terreno e normais

O terreno ainda e CPU-side, mas ja respeita principios que preparam a migracao GPU-driven:

- chunks usam coordenadas inteiras multiplicadas por `chunk_size`, evitando deslocamento fracionario e cintilacao;
- LOD separa resolucao perto, media e distante;
- o raio de unload e maior que o raio de load, evitando recarregamento fantasma ao mover a camera;
- normais sao validadas por `tools/validate_world_normals.gd`, com media Y positiva.

## Otimizacao futura do terreno

A direcao teorica dos `.md` e migrar para:

- heightmap em compute shader;
- normais por diferencas finitas em GPU;
- mapas derivados de slope, flow, moisture e heat;
- scattering de vegetacao por compute com prioridade deterministica;
- culling por frustum/Hi-Z e draw indireto.

O MVP atual preserva essa arquitetura por separacao de responsabilidades:

- `WorldProfile` concentra dados procedurais;
- `TerrainChunk` so materializa malha;
- `TerrainChunkManager` controla streaming, LOD, load/unload e metricas;
- `ProceduralVegetation` concentra scattering e pode ser substituido por compute no futuro.

## Mapeamento visual

O terreno usa variacao por world position no shader, nao UV dependente de camera. Isso evita textura "nadando" quando a camera se move e reduz pixelacao usando noise continuo em vez de blocos discretos.

## Luz, sombra e GI estilizadas

O objetivo visual nao e realismo fotografico, mas leitura de forma com atmosfera quente. Por isso o MVP usa:

- luz direcional quente com sombras longas e suaves;
- fill light frio para simular ceu e reduzir pretos duros;
- `SDFGI`, `SSAO`, `SSIL` e glow leve como aproximacao de iluminacao global dinamica;
- `VoxelGI` de referencia acompanhando a camera por snapping, coerente com mundo em chunks;
- shaders toon com rampas suaves, rim light e translucencia falsa na folhagem.

Esta combinacao segue a fase 3 dos `.md`: bandas suaves de iluminacao, rim light atmosferico e sombras com borda menos dura.

## Streaming e histerese

O raio de descarregamento precisa ser maior que o raio de carregamento. O MVP usa `view_radius` para criar chunks e `unload_radius` maior para remover chunks. Isso cria histerese: ao recuar um pouco, o chunk recem-carregado permanece em memoria, evitando recarregamento fantasma.
