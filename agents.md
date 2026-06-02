# Instrucoes obrigatorias para Codex neste projeto Godot

Este e um projeto Godot 4.6.3. Codex deve seguir estas regras em toda alteracao.

## Executavel Godot no Windows

Use sempre este executavel:

```powershell
D:\Programs\Tools\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe
```

## Permissao operacional do usuario

O usuario autoriza Codex a:

- executar o Godot pelo terminal para validar scripts, cenas, shaders e recursos;
- executar o jogo pelo Godot quando solicitado;
- abrir o editor/headless editor para reproduzir erros do language server;
- ler logs completos do terminal e corrigir todos os erros encontrados;
- repetir validacao quantas vezes forem necessarias ate o terminal nao mostrar erros;
- criar, editar, mover ou remover arquivos dentro deste projeto quando isso for necessario para corrigir o jogo.

Essas autorizacoes nao removem as regras de seguranca do ambiente Codex. Se o sandbox exigir aprovacao externa para abrir janela grafica, escrever fora do workspace ou criar logs/cache fora do sandbox, Codex deve pedir escalacao pelo mecanismo de ferramentas.

## Validacao obrigatoria apos alterar scripts

Apos alterar qualquer `.gd`, `.gdshader`, `.tscn`, `.tres` ou configuracao do projeto, rode:

```powershell
"D:\Programs\Tools\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe" --headless --path . --quit-after 5
```

Se o erro informado vier do editor, language server ou importacao geral do projeto, rode tambem:

```powershell
"D:\Programs\Tools\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe" --headless --editor --path . --quit-after 5
```

## Como lidar com erros

Se aparecer qualquer erro:

- leia o erro completo;
- identifique o arquivo e a linha;
- corrija a causa raiz;
- rode a validacao novamente;
- repita ate nao haver erros no terminal.

Nunca diga que terminou sem validar no terminal.

## Preferencias tecnicas

- Evite inferencia fraca em GDScript quando o projeto tratar warnings como erro.
- Prefira tipos explicitos para valores vindos de `Variant`, `Dictionary`, `ResourceLoader`, `preload`, `call`, `clamp`, `lerp`, `min`, `max` e APIs dinamicas.
- Use funcoes tipadas quando existirem, como `clampf`, `maxf`, `minf`, `absf`.
- Nao deixe projetos temporarios dentro da raiz do projeto.
- Nao ignore erros do editor so porque a cena principal executou.
