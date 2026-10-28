# ZyTetris — plan del proyecto LDV

Un juego de piezas que caen, escrito en Zymbol con **núcleo en ruso (cirílico)**, para validar el
lenguaje con una escritura que todavía no recorre ningún otro proyecto, y para sumar otro juego a los
repositorios. Este plan lo redacta Claude; lo marcado **(verificado)** lo comprobé con
`zymbol 0.0.11` (rama `v0.0.11`, commit `a4a59e1`) en la VM y en el árbol; lo marcado
**(predicción)** es una hipótesis sin probar. Este plan no sustituye a lo que decida el autor.

## 1. Objetivo y alcance

- **Objetivo de validación:** cirílico, plurales del ruso, entrada de teclado en la distribución
  rusa, matrices anidadas, juego en tiempo real y persistencia, todo con pruebas reproducibles.
- **Segundo objetivo:** un juego más, jugable, con varias pieles (`[]`, emojis…).
- **Fuera de alcance:** puntuación en red, sonido, y cualquier réplica de código o de aspecto de
  una versión comercial.
- **Fidelidad de origen:** el juego original es de 1984, de Alexéi Pázhitnov, hecho en un Electronika 60
  con caracteres de texto; la piel por defecto con corchetes es coherente con eso.

**Nombre.** `ZyTetris` contiene una marca registrada cuyo titular ha litigado contra clones (no es
consejo legal). Conviene que el nombre sea **una sola constante** (`НАЗВАНИЕ`) y una sola línea del
README, para renombrar sin tocar el código si hiciera falta.

## 2. Lo ya comprobado en v0.0.11 (verificado)

| Qué | Resultado |
|---|---|
| Identificadores en cirílico, con mayúsculas y minúsculas distintas (`Счёт` y `счёт`) | Funcionan, igual en los dos motores |
| `$#`, trozos `s$[a..b]`, índice `s[1]` y códigos (`##!c` con `c = 'я'` da 1103, `##'1103` da `я`) con texto cirílico | Correctos |
| Emojis `🟥🟧🟨🟩🟦🟪🟫⬜⬛` en cadenas | Cada uno es **un** carácter (`$#` los cuenta de uno en uno), se trocean bien y `##!'🟥'` da 128997 |
| Rendimiento con texto cirílico (recorrer, `$#`, trozo) en la VM | Igual que con ASCII: 4 ms para 147 456 caracteres |
| Regla de plurales rusos (1 линия, 2 линии, 5 линий) escrita en Zymbol | 18 casos de prueba, VM = árbol = referencia en Python (ver 7) |

Bibliotecas estándar documentadas que usaría el juego (**no probadas**): `std/random`, `std/time`,
`std/term`, `std/io` y `std/json`.

## 3. Estructura propuesta

Siguiendo el patrón que usa ZyGoL (núcleo en un idioma, puntos de entrada por idioma, pruebas con
salida esperada):

```
зитетрис/
├── тетрис.zy            # punto de entrada en ruso (el idioma del núcleo)
├── tetris.zy            # punto de entrada en inglés
├── tetris_es.zy         # punto de entrada en español
├── ядро/                # núcleo, en ruso: фигуры, стакан, правила, счёт
├── облик/               # pieles: скобки.zy, эмодзи.zy, прямоугольники.zy
├── язык/                # textos y склонение (ru, en, es)
├── тесты/               # pruebas con .expected por piel e idioma
├── README.md  README_ES.md
└── HALLAZGOS.md         # formato LDV (ver 8)
```

## 4. Pieles

Cada celda ocupa **2 columnas** en todas las pieles: `[` y `]` son de ancho 1 y los emojis son de
ancho 2 (verificado en la tabla de anchos de Unicode), así que el tablero no se descuadra al cambiar.

| Piel | Celda llena | Celda vacía | Nota |
|---|---|---|---|
| `скобки` (por defecto) | `[]` | `. ` | La más compatible: funciona en cualquier terminal. Es la que más se parece al original |
| `эмодзи` | `🟥 🟧 🟨 🟩 🟦 🟪` por pieza, `⬜` para la I, `⬛` vacía | `⬛` | **No existe un cuadrado cian**, de ahí `⬜` para la I; `🟫` queda para el fantasma de la pieza o las filas de relleno. Los cuadrados de color son de Unicode 12 (2019): un terminal antiguo los dibuja como un recuadro vacío |
| `прямоугольники` | `██` | `  ` | Aproxima los rectángulos de la primera versión. **Aviso:** `█`, `▒`, `▓` tienen ancho «ambiguo»: en terminales con configuración regional CJK pueden ocupar 2 columnas, y la celda 4 |

La piel es **un módulo** con constantes (`облик.ПУСТО`, `облик.ФИГУРА[вид]`); el juego no debe
conocer ningún carácter concreto. Colores estándar: I cian, O amarillo, T púrpura, S verde, Z rojo,
J azul, L naranja.

## 5. Rojos esperados

Una lista **escrita antes de empezar**, para registrar después cuáles se cumplen y cuáles no.

**Ya observados (verificado, v0.0.11), a registrar como hallazgos desde el principio:**

- **R1 · Normalización de identificadores.** `й` como un solo carácter (U+0439) y `и` más acento
  combinado (U+0438 U+0306) se ven iguales y son identificadores distintos; el error dice
  `undefined variable 'й'` sobre algo que el usuario ve definido. Python normaliza los identificadores.
- **R2 · Letras gemelas.** La `a` latina y la `а` cirílica son variables distintas y `zymbol check` no
  avisa. Rust avisa de los identificadores confusables.
- **R3 · Orden alfabético.** `$^+` ordena por punto de código: `Ёжик` sale **antes** que `Арбуз`, y
  en el alfabeto ruso va entre `Е` y `Ж`. Puede ser una decisión de diseño; falta documentarla.

**Predicciones (sin probar):**

- **R4 · Teclado ruso.** En la distribución ЙЦУКЕН las teclas de juego llegan como caracteres de dos
  bytes (`ц ф ы в` en lugar de `w a s d`). ¿La lectura de teclas sin Enter las devuelve enteras?
- **R5 · Plurales.** El diseño de i18n resuelve la concordancia con **funciones** y no con tablas
  (`I18N.md`). La regla rusa ya funciona; la duda es si la puerta de pruebas cubre los mensajes
  compuestos de la pantalla final.
- **R6 · Matrices anidadas.** `m[i>j]$~ x` para el tablero y los giros: comprobar que el coste no
  crece con el tamaño del tablero (en v0.0.10 `$~` copiaba el arreglo entero).
- **R7 · Azar reproducible.** Semilla propia (un generador congruencial, como el de GO) para las
  pruebas y `std/random` para jugar; ¿admite `std/random` fijar la semilla?
- **R8 · Bucle en tiempo real.** Gravedad por reloj (`std/time`) y lectura de teclas sin bloquear.
- **R9 · Terminal.** Borrar pantalla y ocultar el cursor con `std/term`.
- **R10 · Persistencia.** Guardar las mejores puntuaciones con nombres cirílicos en JSON y
  ordenarlas (ver R3).
- **R11 · Nombres de archivo en cirílico** en las rutas de importación y en el sistema de archivos.
- **R12 · Mayúsculas y minúsculas** de texto cirílico (`ТЕТРИС` ↔ `тетрис`): ¿hay función?

## 6. Pruebas

- **Determinismo:** semilla propia más teclas guionizadas (`zymbol run --keys`, que ZyGoL ya usa
  para probar juegos de pantalla completa), y una salida esperada por piel e idioma.
- **Los dos motores:** cada prueba en `--vm` y en `--tw`; deben coincidir.
- **Sin terminal:** el núcleo (piezas, giros, colisión, líneas, puntuación) se prueba sin dibujar nada.
- **Mensajes compuestos:** casos 0, 1, 2, 4, 5, 11, 12, 14, 21, 101, 111 y 112 en cada idioma.

## 7. Boceto verificado: plurales rusos

```
склонение(n, один, несколько, много) {
    ост10 = n % 10
    ост100 = n % 100
    ? ост10 == 1 {
        ? ост100 <> 11 { <~ один }
    }
    ? ост10 >= 2 {
        ? ост10 <= 4 {
            ? ост100 < 12 { <~ несколько }
            ? ост100 > 14 { <~ несколько }
        }
    }
    <~ много
}
>> 21 " " склонение(21, "линия", "линии", "линий") ¶   // 21 линия
```

Comprobado con 18 valores (0, 1, 2, 4, 5, 11, 12, 14, 15, 20, 21, 22, 25, 101, 111, 112, 121, 1000)
contra una implementación independiente en Python, en la VM y en el árbol.

## 8. Hallazgos

Un `HALLAZGOS.md` con el formato de los demás proyectos LDV (secciones `BUG`, `GAP`, `ERROR`,
`IDEA`, tabla resumen e identificadores con el alcance del proyecto en **una sola secuencia**, por
ejemplo `GAP-TET-001`). R1 a R3 entran el primer día; el resto, cuando se pruebe.

## 9. Hitos

| Hito | Contenido | Se sabe que terminó cuando |
|---|---|---|
| M0 | Esqueleto, `НАЗВАНИЕ`, piezas y giros | Los 7 tetrominós con sus giros pasan una prueba en los dos motores |
| M1 | Tablero, colisión, bloqueo de piezas y líneas | Una partida guionizada con semilla da siempre la misma salida |
| M2 | Pieles | La misma partida se dibuja en las tres pieles sin descuadre |
| M3 | Bucle en tiempo real y teclado en las dos distribuciones | Se juega con `w a s d` y con `ц ф ы в` |
| M4 | Puntuación, niveles y mensajes con plurales | Los 12 casos de plurales pasan en ru, en y es |
| M5 | Mejores puntuaciones guardadas | Se guardan y ordenan nombres cirílicos |
| M6 | README, `HALLAZGOS.md` y registro en LDV | Pasa la puerta del proyecto |

## 10. Lo que no sé

- **Reglas de la primera versión de 1984** (puntuación, niveles, velocidad): las fuentes que leí
  describen su aspecto, no sus reglas. Para fidelidad estricta habría que usar fuentes primarias.
- Si `std/random` admite una semilla fija, si `std/term` lee teclas de varios bytes, y si hay una función de
  mayúsculas y minúsculas para texto no ASCII.
- Cómo se comporta en terminales Windows, que no probé.
