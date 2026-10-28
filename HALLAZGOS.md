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
> **Estado.** Todas las entradas están **ABIERTAS**: nada está decidido. El autor decide, hallazgo
> por hallazgo, si se implementa, se aplaza o se rechaza. Medido con `zymbol 0.0.11` (VM y árbol)
> y con `web/src/zymbol/zymbol.js` (motor del navegador), el 2026-10-27.

---

## Veredicto

**No pasó directo.** De las sondas del plan salieron una divergencia entre motores y cinco huecos.
Ninguno salió del código del juego: el juego, construido sobre el núcleo cirílico, corrió limpio
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
| [BUG-TET-001](#bug-tet-001) | BUG | `zymbol.js` | `$^+` / `$^-` sobre textos usan el orden de la configuración regional; los motores de Rust usan el punto de código | **zyjs es el distinto** | ABIERTO |
| [GAP-TET-002](#gap-tet-002) | GAP | lenguaje / docs | el texto se ordena por punto de código, así que `Ё` va antes de `А` y `ё` después de `я`; no está documentado (R3) | los tres coinciden | ABIERTO |
| [GAP-TET-003](#gap-tet-003) | GAP | lexer | `й` (U+0439) e `и`+U+0306 son identificadores distintos que se ven igual; el error nombra el que el usuario ve (R1) | los tres | ABIERTO |
| [GAP-TET-004](#gap-tet-004) | GAP | `zymbol check` | la `a` latina y la `а` cirílica son variables distintas y nada avisa (R2) | los tres | ABIERTO |
| [GAP-TET-005](#gap-tet-005) | GAP | lenguaje | no hay función de mayúsculas y minúsculas para texto; el juego pliega A–Z y А–Я por punto de código (R12) | los tres | ABIERTO |
| [GAP-TET-006](#gap-tet-006) | GAP | lenguaje | no hay conversión de texto a Int: `###"42"` es un error; el argumento de semilla necesita un analizador escrito a mano | los tres | ABIERTO |
| [IDEA-TET-007](#idea-tet-007) | IDEA | lenguaje | los símbolos de tipo de `#?` (salvo `##_`) no se pueden escribir en una expresión ni en un patrón | los tres | ABIERTO |
| [IDEA-TET-008](#idea-tet-008) | IDEA | `zymbol-formatter` | un arreglo de 8 números con dos o más negativos se rompe en un número por línea; el mismo arreglo sin negativos queda en una línea | `zymbol fmt` | ABIERTO |

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

---

## GAP

### GAP-TET-002

**El texto se ordena por punto de código; en ruso eso no es el alfabeto, y ningún documento lo
dice (R3).** `GUIDE.md` dice «lexicográfico». En los motores de Rust (y en `<` y `>` en los tres)
es por punto de código, así que `Ё` (U+0401) va antes de `А` (U+0410) y `ё` (U+0451) después de
`я` (U+044F); en el alfabeto, `Ё` va entre `Е` y `Ж`. Bien puede ser el diseño correcto. Lo que
falta es la frase que lo diga y, junto con BUG-TET-001, una decisión sobre qué lado tiene razón.

### GAP-TET-003

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

**No hay función de mayúsculas y minúsculas para texto (R12).** `ТЕТРАИС` ↔ `тетраис` exige que el
lenguaje sepa qué es una letra. El juego lo necesita para una sola cosa, las teclas: `Ц` y `ц`
deben girar la pieza. `ввод.zy` lo hace por punto de código: latino 65–90 → +32, cirílico
1040–1071 → +32, `Ё` → `ё`. Sirve para esas dos escrituras y ninguna más. Tampoco lo tiene ningún
módulo de `std/` (`math random json io net db term time`).

### GAP-TET-006

**No hay conversión de texto a Int.**

```zymbol
x = ###"42"
>> x ¶
```

Error en los motores de Rust: `### requires a numeric value, got String`. El juego toma su
semilla de la línea de comandos (`zymbol run тетраис.zy -- 42`, como recomienda `GUIDE.md` para
repetir una partida al azar), así que `ввод::число` recorre los caracteres y suma los dígitos.
GoL escribió la misma función (`_αριθμός`) para sus propios argumentos. Ya son dos aplicaciones
que la han necesitado.

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
| R12 | Función de mayúsculas y minúsculas | **Confirmada su ausencia** → GAP-TET-005 |

## Lo construido que el plan no pedía

La pieza siguiente a la vista, el desplazamiento del giro contra la pared (se prueba el giro 0,
±1 y ±2 celdas al lado; no las tablas de las guías posteriores), una caída que bloquea al
instante, la semilla como argumento e impresa al final, y un mensaje en el panel con plural
cuando se limpian líneas (`Убрано: 3 линии`).
