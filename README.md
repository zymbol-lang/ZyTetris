# ZyTetris

<!-- The name of the game is one line here and one constant in `название.zy` (НАЗВАНИЕ). -->
**ТЕТРАИС** — falling blocks for the terminal, written in Zymbol with a **Russian (Cyrillic) core**:
identifiers, texts, file names and plurals are all in Russian. Playable in Russian, English or
Spanish, in three skins, with high scores. Zymbol **v0.0.11+**; also runs in the web playground
as a `.zyp`.

It was built to check whether a game on a Cyrillic core has to be an LDV project: see
[HALLAZGOS.md](HALLAZGOS.md) for what it found (two engine divergences and five gaps, one of
them a conversion that existed and was not found) and
`ZyTetris_plan.md` for what it was measured against.

## Play

```bash
zymbol run тетраис.zy          # Russian
zymbol run tetris.zy           # English
zymbol run tetris_es.zy        # Spanish
zymbol run тетраис.zy -- 42    # the same game again: the seed is printed when you quit
zymbol run ZyTetris.zyp        # the package (zymbol package . -o ZyTetris.zyp)
```

| Action | Keys |
|---|---|
| Move | `←` `→` · `a` `d` · `ф` `в` |
| Turn | `↑` · `w` · `ц` |
| Soft drop | `↓` · `s` · `ы` |
| Hard drop | space |
| Pause | `p` · `з` |
| Language (ru → en → es) | `l` · `д` |
| Skin (brackets → emoji → blocks) | `k` · `л` |
| Quit | `q` · `й` · Esc |

Upper case works too. The game needs 22 rows and 80 columns. At the end, a score that enters the
table asks for a name (Enter keeps it, Esc drops it); the table is saved in `рекорды.json`
(in the playground the disk is per run, so it lasts as long as the run).

## Skins

Every cell is 2 columns wide in every skin, so the well keeps its shape.

| Skin | Cell | Empty |
|---|---|---|
| `скобки` (default) | `[]` in the colour of the piece | `. ` |
| `эмодзи` | `🟨🟪🟩🟥🟦🟧`, `⬜` for the I (there is no cyan square) | `⬛` |
| `прямоугольники` | `██` in colour | two spaces |

`█` has an "ambiguous" width: in a CJK locale a terminal may draw it in 2 columns. The brown
square `🟫` is unused, kept for a ghost piece.

## Layout

```
тетраис.zy  tetris.zy  tetris_es.zy   entry points, one per language
игра.zy        the loop: gravity by 50 ms frames, keys, language and skin on the fly
экран.zy       everything that touches the terminal (delta drawing, no flicker)
ввод.zy        key → action in both layouts; case folding; the seed argument
рекорды.zy     the high scores: JSON, at most five
название.zy    НАЗВАНИЕ, the name
ядро/          the rules, with no screen: фигуры (shapes), стакан (the well), правила (score, dice)
облик/         the skins and the selector
язык/          the three languages and the selector; the Russian plural is a function
тесты/         tests with a golden each; запуск.sh runs them
```

## Tests

```bash
bash тесты/запуск.sh           # 28 comparisons, VM · tree-walker · browser engine
bash тесты/запуск.sh --regen   # rewrite the goldens from the VM: read the diff first
```

Four tests run on the three engines (the core, the messages, the keys, the high scores). Eight
scripted games (`партия_N.keys`, fixed seed) run on the VM and the tree-walker with
`zymbol run --keys`; the browser engine has no virtual keyboard. `партия_6` was played by a bot
that shares the game's dice and shapes: 13 lines, level 2.

## Rules

Ten lines per level; a line clear scores 40 · 100 · 300 · 1200 times the level; soft drop 1 point
per row, hard drop 2. A turn that hits a wall is tried 1 and 2 cells aside. The author does not
know the rules of the 1984 original: these are the usual ones of later versions.
