# ZyTetris — hallazgos

> **Qué es esto.** El registro de huecos del proyecto de piezas que caen, en la forma que pide
> `zymbol-design/LDV.md` § 5.2: `HALLAZGOS.md`, secciones `BUG` / `GAP` / `ERROR` / `IDEA`,
> una tabla resumen y una sola secuencia de identificadores con el alcance del proyecto
> (`BUG-TET-001`).
>
> **Qué se quería decidir.** Si este juego tiene que ser un proyecto LDV, o si puede pasar
> directo sin encontrar nada. `LDV.md` § 6 dice que un tercer juego de terminal «casi no
> validaría nada», así que el único terreno nuevo es el **núcleo en cirílico**: identificadores,
> texto, distribución de teclado, plurales y nombres de archivo. El juego se construyó primero
> contra `ZyTetris_plan.md` (M0–M5) y después se corrieron a propósito los doce rojos esperados
> del plan (R1–R12).
>
> **Estado.** El **2026-11-22** (v0.0.12) el autor decidió y se corrigieron BUG-TET-001 y GAP-TET-002: el texto se
> ordena por punto de código en los cuatro motores, y `GUIDE.md` lo dice. Las demás entradas siguen **ABIERTAS**.
> Antes de esa fecha, todas lo estaban: nada estaba decidido. El autor decide, hallazgo
> por hallazgo, si se implementa, se aplaza o se rechaza. Medido con `zymbol 0.0.11` (VM y árbol)
> y con `web/src/zymbol/zymbol.js` (motor del navegador), el 2026-10-27. El **2026-10-28** se
> corrigió el enunciado de GAP-TET-006, que era falso, y al corregirlo salió BUG-TET-009.

---

## Veredicto

**No pasó directo.** De las sondas del plan salieron una divergencia entre motores y cinco huecos;
uno de los huecos (GAP-TET-006) resultó ser una capacidad que existía y no se encontró, y al
corregirlo apareció una segunda divergencia (BUG-TET-009). Ninguno salió del código del juego: el juego, construido sobre el núcleo cirílico, corrió limpio
(más abajo). Lo que movió el dominio cirílico fueron las *primitivas de texto* del lenguaje:

| Qué se comprobó | Resultado |
|---|---|
| El núcleo sin pantalla (formas, colisión, limpieza de líneas, puntuación, dados, plurales, teclas, récords) | 4 pruebas, **VM = árbol = motor del navegador**, byte a byte |
| Partidas guionizadas (`--keys`, semilla fija, tres pieles, tres idiomas, pausa, fin de partida, captura de nombre) | 8 goldens, VM = árbol; la partida del bot limpia 13 líneas y llega al nivel 2 |
| `zymbol check` sobre todo el paquete | sin errores ni avisos |
| El `.zyp` en el playground (Chrome headless) | carga, corre, las flechas mueven la pieza y, en las capturas, `ц ф в` la giran y la mueven; `L` y `K` cambian idioma y piel; la pantalla final acepta un nombre en cirílico |

Una terminal real (pty de Python, 100×30, VM) arranca los tres puntos de entrada, responde a las
flechas, al espacio, a `k` y a `l`, y sale con `q` imprimiendo la despedida. No se comprobó:
Windows, ni la velocidad del motor del navegador bajo carga.

---

## Resumen

| ID | Tipo | Dónde | Qué | Motores | Estado |
|----|------|-------|-----|---------|--------|
| [BUG-TET-001](#bug-tet-001) | BUG | `zymbol.js` | `$^+` / `$^-` sobre textos usan el orden de la configuración regional; los motores de Rust usan el punto de código | **zyjs es el distinto** | **corregido** 2026-11-22 (D-05) |
| [GAP-TET-002](#gap-tet-002) | GAP | lenguaje / docs | el texto se ordena por punto de código, así que `Ё` va antes de `А` y `ё` después de `я`; no está documentado (R3) | los tres coinciden | **corregido** 2026-11-22: documentado en `GUIDE.md` |
| [GAP-TET-003](#gap-tet-003) | GAP | lexer | ~~`й` (U+0439) e `и`+U+0306 son identificadores distintos que se ven igual; el error nombra el que el usuario ve (R1)~~ | los tres | **CORREGIDO** 2026-11-23 · v0.0.12, los nombres se leen en NFC (D-20) |
| [GAP-TET-004](#gap-tet-004) | GAP | `zymbol check` | la `a` latina y la `а` cirílica son variables distintas y nada avisa (R2) | los tres | ABIERTO |
| [GAP-TET-005](#gap-tet-005) | GAP | lenguaje | ~~no hay función de mayúsculas y minúsculas para texto; el juego pliega A–Z y А–Я por punto de código (R12)~~ | los tres | **CORREGIDO** 2026-11-23 · v0.0.12, `std/text` (D-18) |
| [GAP-TET-006](#gap-tet-006) | GAP | texto → número | ~~no hay conversión de texto a Int: `###"42"` es un error; el argumento de semilla necesita un analizador escrito a mano~~ — `#\|texto\|` lo hace; lo que falla es que la forma no se encuentra | los tres | **retirado como incapacidad** 2026-10-28 · la descubribilidad sigue en GAP-ZYE-008 |
| [IDEA-TET-007](#idea-tet-007) | IDEA | lenguaje | los símbolos de tipo de `#?` (salvo `##_`) no se pueden escribir en una expresión ni en un patrón | los tres | ABIERTO |
| [IDEA-TET-008](#idea-tet-008) | IDEA | `zymbol-formatter` | un arreglo de 8 números con dos o más negativos se rompe en un número por línea; el mismo arreglo sin negativos queda en una línea | `zymbol fmt` | ABIERTO |
| [BUG-TET-009](#bug-tet-009) | BUG | `zymbol.js` | `#\|texto\|` con un entero fuera de ±(2^53−1) da un Int, y lo redondea sin avisar; los motores de Rust devuelven el texto intacto | **zyjs es el distinto** | ABIERTO |

Cada reproducción es un programa completo. Ejecútalo tal como está escrito.

---

## BUG

### BUG-TET-001

**`$^+` y `$^-` sobre textos: el motor del navegador ordena por la configuración regional y los
motores de Rust por punto de código.**

```zymbol
l = ["b", "A", "a", "B"]
>> (l $^+) ¶
```

| Motor | Respuesta |
|---|---|
| zytw | `[A, B, a, b]` |
| zyvm | `[A, B, a, b]` |
| zyjs | `[a, A, b, B]` |

El cirílico también lo muestra: `["Ёжик", "Арбуз", "Яма", "Её", "Жук", "Еда"]` da
`[Ёжик, Арбуз, Еда, Её, Жук, Яма]` en los motores de Rust y `[Арбуз, Еда, Её, Ёжик, Жук, Яма]` en
el navegador. Los operadores de comparación coinciden en los tres (`"Z" < "a"` es `#1`,
`"é" < "z"` es `#0`); solo el orden difiere. La causa está en `web/src/zymbol/zymbol.js`, líneas
11484 y 11488: `a.v.localeCompare(b.v)`, cuya respuesta además depende del idioma del navegador.

No lo ve la puerta: el corpus no tiene ningún programa que ordene textos con mayúsculas y
minúsculas mezcladas o con caracteres no ASCII. El juego no ordena texto (la tabla de récords se
ordena por puntos), así que el fallo se encontró con la sonda R3 del plan y no jugando.

> **CORREGIDO el 2026-11-22** (v0.0.12). **Decisión del autor D-05**, la recomendada de tres: el texto se ordena por
> **punto de código** en los cuatro motores, en cualquier máquina y en cualquier idioma, y no por la configuración regional
> (descartadas: ordenar por idioma, que pedía ICU en Rust y dejaba el golden en manos del `LANG`; y punto de código más un
> comparador de diccionario documentado, que necesita antes GAP-TET-005). `zyjs` ordena ahora con `cmpCodePoint` y, como los
> demás, ordena y luego invierte para `$^-`. Al sondear salieron dos más: `<` entre textos en `zyjs` iba por unidad UTF-16
> (`"😀" < "～"` daba `#1`; `ZyDDT/HALLAZGOS/zyjs.md` § ZYJS-073) y, en los cuatro motores, `$^+` no ordenaba los `Char` ni
> rechazaba lo que no tiene orden (`ZyDDT/HALLAZGOS/GLOBAL.md` § GLB-152). Las tres corregidas el mismo día.
>
> | Motor | `["b", "A", "a", "B"] $^+` | `["Ёжик", "Арбуз", "Яма", "Её", "Жук", "Еда"] $^+` |
> |---|---|---|
> | los cuatro | `[A, B, a, b]` | `[Ёжик, Арбуз, Еда, Её, Жук, Яма]` |
>
> Lo sujeta `zyquality/corpus/collections/sort_orden_natural.zy`.

### BUG-TET-009

**`#|texto|` con un entero fuera de ±(2^53−1): el motor del navegador da un Int, y no siempre
el escrito; los motores de Rust devuelven el texto intacto.**

```zymbol
n = #|"9007199254740993"|
>> n " " (n#?)[1] ¶
```

| Motor | Respuesta |
|---|---|
| zytw | `9007199254740993 ##"` |
| zyvm | `9007199254740993 ##"` |
| zyjs | `9007199254740992 ###` |

zyjs cambia el número sin avisar: `9007199254740993` no tiene representación exacta y queda en
`9007199254740992`. Con `"99999999999999999999"` da `100000000000000000000` como Int. Lo que pasa
después también diverge: `n + 1` es en los motores de Rust el error de `+` sobre un texto, y en
zyjs un `integer overflow` en esa línea.

La causa está en `web/src/zymbol/zymbol.js`, línea 10711, el `case 'eval'` de `#|…|`:
`mkInt(p)` sin comprobar el rango. El mismo archivo tiene un segundo camino para lo mismo,
`parseNumericInput` (línea 7824, la entrada `<< #|v|`), que **sí** lo comprueba
(`inIntRange(n) ? mkInt(n) : mkStr(s)`), y cuyo comentario describe exactamente este caso:
*«which would answer 9007199254740992 for "9007199254740993"»*. Se arregló uno de los dos
caminos.

No lo ve la puerta: `casts/cifra_de_cualquier_escritura.zy` no prueba números grandes, y las
celdas del límite en ZyDDT (`axes/arithmetic.toml`, `axes/diagnostic.toml`) prueban el literal
y la aritmética, no la lectura de un texto. Salió al corregir GAP-TET-006: un argumento de
semilla es justo un texto de cualquier tamaño que llega de fuera.

---

## GAP

### GAP-TET-002

**El texto se ordena por punto de código; en ruso eso no es el alfabeto, y ningún documento lo
dice (R3).** `GUIDE.md` dice «lexicográfico». En los motores de Rust (y en `<` y `>` en los tres)
es por punto de código, así que `Ё` (U+0401) va antes de `А` (U+0410) y `ё` (U+0451) después de
`я` (U+044F); en el alfabeto, `Ё` va entre `Е` y `Ж`. Bien puede ser el diseño correcto. Lo que
falta es la frase que lo diga y, junto con BUG-TET-001, una decisión sobre qué lado tiene razón.

> **CORREGIDO el 2026-11-22** (v0.0.12). La decisión es la de BUG-TET-001 (D-05): por punto de código, que es el diseño.
> `GUIDE.md` ya no dice «lexicográfico»: § Comparison dice *«By code point when two texts are not both numbers … `Ё`
> (U+0401) goes before `А` (U+0410)»* y § Sort lo repite para `$^+`/`$^-`, junto con la decisión D-07 —`$^+` no usa la
> lectura numérica de `<`, porque mezclada con otros textos no es un orden total— y la forma de ordenar números escritos
> como texto: convertirlos antes, `(t$> (s -> #|s|))$^+`. El orden alfabético ruso, con `Ё` entre `Е` y `Ж`, lo escribe el
> programa con un comparador; GAP-TET-005 (mayúsculas y minúsculas) seguía abierto ese día y se corrigió el 2026-11-23.

### GAP-TET-003

> **CORREGIDO el 2026-11-23** (v0.0.12). **Decisión del autor D-20**, la recomendada: un nombre se lee
> en **NFC**, la composición canónica de Unicode. Las dos grafías de `й` son el mismo nombre en los
> cuatro motores, y lo mismo vale para funciones, parámetros, etiquetas, nombres dentro de `{…}`, tipos
> de error y alias de módulo; el programa de abajo imprime `2` y `zymbol check` no avisa de nada. Sólo
> cuenta la equivalencia canónica: `ﬁ` y `fi` siguen siendo nombres distintos. Las cadenas son datos y
> conservan lo escrito, igual que una ruta de módulo, que nombra un fichero. `zymbol fmt` deja cada
> nombre como está escrito. Rust usa el crate `unicode-normalization` (Unicode 18); el navegador, una
> tabla generada de la misma versión que pasa todo `NormalizationTest.txt`, y
> `web/tests/test_normalize.mjs` la compara con el lexer de Rust en 4 000 nombres. La prueba del
> corpus es `zyquality/corpus/i18n/nombres_nfc.zy`. Descartadas: NFKC como Python (une `x²` con `x2`,
> que se ven distintos), rechazar lo que no esté en NFC (un error sobre un nombre que se ve bien) y no
> normalizar y sólo avisar.
>
> **El juego no cambia:** ningún fuente de ZyTetris escribe un nombre descompuesto.
> **Queda:** la `a` latina frente a la `а` cirílica no es equivalencia canónica, así que NFC no la
> toca; sigue abierta como GAP-TET-004.

**Dos identificadores que se ven igual y no lo son (R1).**

```zymbol
й = 2
>> й ¶
```

(El primer nombre es `и` U+0438 + U+0306; el segundo es el carácter único `й`, U+0439.) Las dos
grafías son la letra rusa «й». `zymbol check` informa de la primera como sin uso y de la segunda
como indefinida: un mensaje sobre una variable que el usuario ve definida. Los tres motores
coinciden. Python normaliza los identificadores (NFKC); el lenguaje no ha dicho si debería.

### GAP-TET-004

**La `a` latina y la `а` cirílica son variables distintas y nada avisa (R2).**

```zymbol
a = 1
а = 2
>> a " " а ¶
```

Imprime `1 2` en los tres motores; `zymbol check` dice *No errors or warnings*. Rust avisa de los
identificadores confusables. En un lenguaje cuyos identificadores pueden escribirse en cualquier
escritura, el par se alcanza con un descuido normal de teclado en un teclado ruso.

### GAP-TET-005

> **CORREGIDO el 2026-11-23** (v0.0.12). **Decisión del autor D-18**, la recomendada: un módulo nuevo,
> `std/text`, con `upper`, `lower` y `fold`, por las reglas de Unicode y sin idioma. `upper` y `lower` son
> las correspondencias completas (`ß` → `SS`, sigma final) y dan un texto; `fold` pliega punto a punto,
> conserva la longitud y devuelve lo que recibe, así que un `Char` sigue siendo `Char`. Los cuatro
> motores dan lo mismo: los del navegador llevan una tabla generada del Unicode de Rust (18.0.0).
> Descartadas: una marca nueva (ninguna existente la deriva y `^` ya tiene tres significados) y dejarlo
> como estaba.
>
> **Lo que cambió en el juego:** el autor pidió llamarlo en ruso, como dice `zymbol-design/I18N.md`
> («Wrapping the standard library»). `стд/текст.zy` es esa capa: sólo importa `std/text` y lo reexporta
> como `прописные`, `строчные` y `свёртка`, sin lógica. `ввод::строчная` ya no suma 32 a dos alfabetos:
> es `текст::свёртка(к)`, y pliega cualquier escritura. `тесты/ввод` ganó una línea (`É Ü Ω` → `é ü ω`,
> que la tabla vieja devolvía tal cual) y las 28 comparaciones de `тесты/запуск.sh` siguen en verde. El
> paquete pide ahora `engine = ">=0.0.12"`, y el `.zyp` del playground se regeneró desde el proyecto.
> **Queda:** el orden alfabético ruso con `Ё` entre `Е` y `Ж` (ver BUG-TET-001) sigue siendo cosa de un
> comparador escrito por el programa: `std/text` no ordena.

**No hay función de mayúsculas y minúsculas para texto (R12).** `ТЕТРАИС` ↔ `тетраис` exige que el
lenguaje sepa qué es una letra. El juego lo necesita para una sola cosa, las teclas: `Ц` y `ц`
deben girar la pieza. `ввод.zy` lo hace por punto de código: latino 65–90 → +32, cirílico
1040–1071 → +32, `Ё` → `ё`. Sirve para esas dos escrituras y ninguna más. Tampoco lo tiene ningún
módulo de `std/` (`math random json io net db term time`).

### GAP-TET-006

> **CORREGIDO el 2026-10-28, y el enunciado era falso.** El lenguaje **sí** lee un texto como
> número: `#|texto|` devuelve el Int, el Float o el texto intacto si no lo es, con cifras de
> cualquier escritura. Lo sujeta `zyquality/corpus/casts/cifra_de_cualquier_escritura.zy`. Lo
> señaló el autor: ya lo había encontrado ZyEdit en **GAP-ZYE-008**, corregido el 2026-10-26.
>
> ```zymbol
> #|"42"| → 42     #|"-3"| → -3     #|"4.5"| → 4.5     #|"4x"| → "4x"     #|"٤٢"| → 42
> ```
>
> El hallazgo se queda porque es la **segunda vez** que se llega a la misma conclusión
> equivocada, por el mismo camino (probar `###`, el cast hermano), y **un día después** de que
> la primera se corrigiera en otro proyecto. Es evidencia para GAP-ZYE-008, no un hueco nuevo.

**Lo que decía:** que no hay conversión de texto a Int.

```zymbol
x = ###"42"
>> x ¶
```

Error en los motores de Rust: `### requires a numeric value, got String`. El juego toma su
semilla de la línea de comandos (`zymbol run тетраис.zy -- 42`, como recomienda `GUIDE.md` para
repetir una partida al azar), así que `ввод::число` recorría los caracteres y sumaba los dígitos,
con un tope de 15 cifras para no salir de los enteros seguros. GoL escribió la misma función
(`αριθμός`, en `μέτρηση/όλα.zy`) para sus propios argumentos.

**Lo que pasa de verdad:** `ввод::число` es ahora `н = #|т|` y un `? (н#?)[1] <> "###"` que
devuelve 0 para todo lo que no se lea como Int, la misma forma a la que llegó ZyEdit en su
`to_number`. Acepta lo que el analizador a mano rechazaba: un signo (`-3`; `привить` ya convierte
cualquier entero en un estado válido del generador), espacios alrededor y cifras de otra
escritura (`٤٢`). El tope de 15 cifras sobra: fuera de ±(2^53−1) `#|…|` deja el texto, y eso da 0.
`тесты/ввод` lo comprueba en los tres motores; su golden cambió en una línea
(`"1234567890123456"` daba 0 por el tope y ahora da el número) y ganó otra con los casos nuevos.
El límite de 2^53 no está en la prueba porque ahí los motores no coinciden: BUG-TET-009.

**Lo que sigue abierto** es lo de GAP-ZYE-008: ningún error de `###"42"`, `##."42"` o `"12" + 1`
dice que la forma es `#|texto|`. Esta ficha no propone nada distinto; añade el segundo caso.
`GoL/μέτρηση/όλα.zy` conserva su `αριθμός` escrito a mano.

---

## IDEA

### IDEA-TET-007

**Los símbolos de tipo de `#?` no se pueden comparar.** `##_` sí (`v == ##_`); los demás no:

```zymbol
a = [1, 2]
t = (a#?)[1]
>> (t == ##]) ¶
```

es un error de análisis en el segundo `#`, y lo mismo dentro de un patrón. `рекорды::загрузить`
querría preguntar «¿el archivo se decodificó como un arreglo?» y no puede, así que confía en un
JSON válido de forma equivocada (anotado en su cabecera). No está verificado si es intencionado:
`GUIDE.md` muestra los símbolos solo impresos, nunca comparados.

### IDEA-TET-008

**`zymbol fmt` rompe un arreglo numérico en un elemento por línea cuando contiene dos o más
negativos.** La tabla de formas de un juego de piezas que caen es una columna de filas como
`[0, 0, -1, 0, 1, 0, 0, -1]`:

```zymbol
a = [0, 0, -1, 0, 1, 0, 0, -1]
b = [0, 0, -1, 0, 1, 0, 0, 1]
```

`fmt` deja `b` en una línea y escribe `a` en ocho. Los arreglos cortos no se ven afectados
(`[-1, -2]` y `[1, -2, 3, -4]` se quedan), un arreglo de 9 números de dos cifras se queda, y seis
`-1` explotan; así que la regla no es el ancho. El primer formateo de `ядро/фигуры.zy` convirtió
una tabla de 28 líneas en 150. El juego guarda ahora las formas desplazadas +1 (sin negativos),
lo que lo evita; si el formateador debería evitarlo él mismo es la pregunta.

---

## Los rojos esperados del plan, uno por uno

| | Esperado | Resultado |
|---|---|---|
| R1 | `й` ≠ `и`+◌̆ | **Confirmado** → GAP-TET-003 |
| R2 | `a` latina ≠ `а` cirílica, sin aviso | **Confirmado** → GAP-TET-004 |
| R3 | `$^+` por punto de código | **Confirmado, y peor**: los motores no coinciden → BUG-TET-001, GAP-TET-002 |
| R4 | Las teclas del teclado ruso llegan enteras | **Sin rojo.** `ц ф ы в` llegan como 1094, 1092, 1099, 1074, en la CLI y en el navegador |
| R5 | Plurales cubiertos por la puerta | **Sin rojo.** Doce cuentas × tres idiomas, `тесты/язык` (`ru`: `21 линия`, `11 линий`, `112 линий`) |
| R6 | Coste de `$~` sobre el tablero | **Sin rojo, con un matiz.** `a[i]$~ v` en el sitio no copia nada (`copied=0`). Pasar el arreglo por valor a una función lo copia entero en cada llamada (`copied` 40 000 → 400 000 al pasar de 200 a 2 000 celdas), por diseño (MEM); con `a<~` es `copied=0`. Con 200 celdas no importa |
| R7 | Semilla para `std/random` | **Sin rojo.** `semilla` da los mismos números en los tres motores; el juego usa su propio generador Park–Miller para que una prueba sea un solo número |
| R8 | Bucle en tiempo real | **Sin rojo.** La gravedad cuenta cuadros de 50 ms (`@~ 50`); se comporta igual en la CLI y en el navegador |
| R9 | Borrar pantalla y ocultar el cursor | **Sin rojo.** `>>\|` hace las dos cosas |
| R10 | Nombres cirílicos en los récords | **Sin rojo.** Ida y vuelta por JSON en los tres motores (`[["Анна",1200]]`); un archivo ausente o roto es una tabla vacía. En el navegador `std/io` es un disco virtual por ejecución, así que la tabla dura lo que dure la ejecución |
| R11 | Nombres de archivo y de carpeta en cirílico | **Sin rojo.** `<# ./ядро/фигуры => фигуры` en los tres motores; `рекорды.json` se escribe y se vuelve a leer |
| R12 | Función de mayúsculas y minúsculas | **Confirmada su ausencia** → GAP-TET-005, **corregido** el 2026-11-23 con `std/text` (D-18) |

## Lo construido que el plan no pedía

La pieza siguiente a la vista, el desplazamiento del giro contra la pared (se prueba el giro 0,
±1 y ±2 celdas al lado; no las tablas de las guías posteriores), una caída que bloquea al
instante, la semilla como argumento e impresa al final, y un mensaje en el panel con plural
cuando se limpian líneas (`Убрано: 3 линии`).
