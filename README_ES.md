# ZyTetris

**ТЕТРАИС** — piezas que caen para la terminal, escrito en Zymbol con un **núcleo en ruso
(cirílico)**: identificadores, textos, nombres de archivo y plurales están en ruso. Se juega en
ruso, inglés o español, con tres pieles y mejores puntuaciones. Zymbol **v0.0.11+**; también corre
en el playground web como `.zyp`.

Se hizo para comprobar si un juego con núcleo cirílico tiene que ser un proyecto LDV: lo que
encontró está en [HALLAZGOS.md](HALLAZGOS.md) (dos divergencias entre motores y cinco huecos,
uno de ellos una conversión que existía y no se encontró) y
contra qué se midió, en `ZyTetris_plan.md`.

## Jugar

```bash
zymbol run тетраис.zy          # ruso
zymbol run tetris.zy           # inglés
zymbol run tetris_es.zy        # español
zymbol run тетраис.zy -- 42    # la misma partida otra vez: al salir se imprime la semilla
zymbol run ZyTetris.zyp        # el paquete (zymbol package . -o ZyTetris.zyp)
```

| Acción | Teclas |
|---|---|
| Mover | `←` `→` · `a` `d` · `ф` `в` |
| Girar | `↑` · `w` · `ц` |
| Bajar | `↓` · `s` · `ы` |
| Caída | espacio |
| Pausa | `p` · `з` |
| Idioma (ru → en → es) | `l` · `д` |
| Piel (corchetes → emojis → bloques) | `k` · `л` |
| Salir | `q` · `й` · Esc |

Las mayúsculas valen igual. Hacen falta 22 filas y 80 columnas. Al terminar, una puntuación que
entra en la tabla pide un nombre (Enter lo guarda, Esc lo descarta); la tabla se guarda en
`рекорды.json` (en el playground el disco es por ejecución y dura lo que dure la ejecución).

## Pruebas

```bash
bash тесты/запуск.sh           # 28 comparaciones: VM · árbol · motor del navegador
bash тесты/запуск.sh --regen   # reescribe los goldens desde la VM: leer antes el diff
```

La estructura de carpetas y las reglas están descritas en [README.md](README.md).
