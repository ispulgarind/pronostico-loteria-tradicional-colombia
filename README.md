# Pronóstico de ventas de lotería tradicional en Colombia

**SARIMA con calendario de sorteos frente a ETS e ingenuo estacional, para el acumulado de 3 y 6 meses**

Trabajo final de *Series de Tiempo Univariadas* (código 3009297), Pregrado en Estadística, Universidad Nacional de Colombia, sede Medellín. Semestre 2026-II. Profesor: Juan Pablo Valencia Arango.

---

## Introducción

Este repositorio contiene el código, los datos y los documentos de un estudio de pronóstico de las **ventas mensuales nacionales del juego de lotería tradicional en Colombia**, publicadas por Coljuegos entre enero de 2012 y junio de 2026 (174 meses).

El propósito es responder, con evidencia fuera de muestra, si un modelo SARIMA que incorpora el número de sorteos del mes como covariable **pronostica mejor el valor acumulado de las ventas en los próximos 3 y 6 meses** que dos referentes simples: el ingenuo estacional y un suavizamiento exponencial (ETS) elegido por AICc. La pregunta se plantea para quien programa el gasto de salud financiado con la renta de la lotería, y admite una respuesta negativa: si el SARIMA no mejora al referente, ese resultado se reporta igual.

## Pregunta de investigación

> ¿En qué medida un modelo SARIMA con el número de sorteos mensual como covariable mejora el pronóstico de las ventas mensuales nacionales de lotería tradicional, en millones de pesos corrientes, acumuladas en los próximos 3 y 6 meses, medido con MASE y evaluando la cobertura empírica de sus intervalos al 80 y al 95 %, frente al ingenuo estacional y al modelo ETS seleccionado mediante el criterio de información AICc, para la programación de los ingresos por derechos de explotación en los fondos de salud de las secretarías de salud de las entidades territoriales titulares de una lotería?

## Contexto

- **Qué es el juego.** La lotería tradicional es un arbitrio rentístico de los departamentos y del Distrito Capital, que la administran mediante empresas industriales y comerciales del Estado (Ley 643 de 2001, arts. 12 y 14). Sus recursos se destinan a la salud.
- **Qué llega a salud.** Cuando la lotería la opera directamente la empresa del Estado, la renta es el 12 % de los ingresos brutos más los excedentes de la operación (art. 6); si la opera un tercero, los derechos de explotación son como mínimo el 17 % (Decreto 1068 de 2015, art. 2.7.1.5.1). Se giran al fondo de salud dentro de los diez primeros días hábiles del mes siguiente (art. 12). A ello se suman el impuesto a los ganadores y el de las loterías foráneas (art. 48).
- **Cómo se programa hoy.** Las entidades territoriales proyectan sus rentas por vigencia anual en el Marco Fiscal de Mediano Plazo (Ley 819 de 2003). En el de Antioquia, cada renta se proyecta con un modelo estacional sobre series mensuales, y en la sección consultada no se reportan errores de pronóstico, intervalos ni cifras a 3 o 6 meses.
- **El vacío que atiende el trabajo.** Quien programa el gasto del trimestre y del semestre necesita el ingreso acumulado en esos plazos y una idea de cuánto confiar en él. Este trabajo evalúa, fuera de muestra y por horizonte, qué tan bien se puede pronosticar ese acumulado.
- **Alcance.** Se modela la serie nacional (la suma de las 14 loterías ordinarias). El reparto a cada territorio se hace multiplicando por la participación de su lotería, cuya estabilidad se verifica en el análisis. La modelación lotería por lotería queda como trabajo futuro.

## Insumos

| Insumo | Fuente | Uso | Ubicación |
|---|---|---|---|
| Ventas mensuales por lotería (3.173 registros originales) | Coljuegos, *Ventas del juego de lotería tradicional*, Datos Abiertos Colombia, conjunto `2zg4-ahca` | Serie de estudio | `datos/crudos/` |
| Cronograma anual de sorteos ordinarios | Consejo Nacional de Juegos de Suerte y Azar (acuerdos anuales, p. ej. Acuerdo 809 de 2025) | Covariable: número de sorteos por mes | `datos/crudos/`  |
| Índice de precios al consumidor | DANE | Sensibilidad: serie deflactada | `datos/crudos/`  |
| Normativa | Ley 643 de 2001; Decreto 1068 de 2015; Ley 819 de 2003 | Contexto y supuestos | `informe/referencias.bib` |

Enlace del conjunto de datos: <https://www.datos.gov.co/dataset/Ventas-del-Juego-de-Loter-a-Tradicional/2zg4-ahca>

## Descripción técnica

**Datos y preparación.** La base original trae año, mes, lotería y ventas en pesos, con valores como texto y 34 escrituras distintas de los nombres. La limpieza (`R/02-limpieza.R`) unifica los nombres, deja las 14 loterías ordinarias, corrige cuatro registros con tres ceros de más, reasigna una fila de enero de 2012 de Medellín a Cauca, suma las filas desagregadas de julio de 2025 y conserva abril de 2020 (sin sorteos) con ventas iguales a cero. Cada decisión queda en una tabla de depuración. De ahí salen dos bases:

- `ventas_por_loteria_mes`: una fila por año, mes y lotería.
- `base_filtrada`: la serie nacional, con año, mes, `total` (pesos corrientes) y `ventas_mill` (millones de pesos corrientes).

**Variable pronosticada.** El acumulado de las ventas en los *h* meses siguientes al origen *T*, con *h* = 3 y *h* = 6.

**Modelos.**
- *SARIMA con regresores*: regresión con errores SARIMA sobre la serie transformada con Box y Cox (λ de Guerrero), con el número de sorteos del mes y variables de intervención para 2020.
- *ETS*: especificación elegida por AICc sobre el entrenamiento de cada origen.
- *Ingenuo estacional*: el mismo mes del año anterior.

Los intervalos del acumulado se obtienen simulando trayectorias del modelo y sumándolas, con innovaciones normales y con bootstrap de residuos.

**Validación.** Origen móvil con 25 orígenes y ventana creciente. Se reportan por horizonte y referente el MASE (con escalador del entrenamiento de cada origen), el RMSE, la cobertura empírica de los intervalos al 80 y al 95 % y la prueba unilateral de Diebold y Mariano con corrección de muestra pequeña (α = 0,05). La respuesta negativa está definida de antemano, por horizonte y por referente.

**Sensibilidad.** Ventana deslizante en lugar de creciente, exclusión de 2020, exclusión de julio de 2025, serie terminada en abril de 2026 y serie deflactada por el IPC.

**Software.** R, con `tidyverse`, `tsibble`, `fable` y `feasts`. El entorno se declara con `renv`.

## Estructura del repositorio

```
.
├── README.md
├── renv.lock                    # entorno declarado
├── datos/
│   ├── crudos/                  # lo descargado, sin tocar
│   └── procesados/              # lo que produce el código, nunca editado a mano
├── R/
│   ├── 01-descarga.R            # descarga desde la fuente
│   ├── 02-limpieza.R            # limpieza y construcción de bases
│   ├── 03-modelos.R             # estimación y pronóstico
│   └── 04-validacion.R 
│   ├── 05-residuos.R            # validación de los residuos
│   ├── referencias.bib          # referencias 
├── informe/
│   ├── trabajo-final.tex        # documento
│   └── referencias.bib
├── app/                         # producto de consulta (Shiny) [por construir]
├── salidas/                     # figuras y tablas generadas
└── ejecutar-todo.R              # script maestro
```

## Cómo reproducir

1. Clonar el repositorio y abrir el proyecto en R.
2. Restaurar el entorno: `renv::restore()`.
3. Ejecutar `source("ejecutar-todo.R")`. [Disponible cuando se cierre la implementación; mientras tanto, los scripts de `R/` se ejecutan en orden.]

## Estado del proyecto

| Elemento | Estado |
|---|---|
| Pregunta, objetivos y justificación | Listo |
| Revisión de literatura | Listo |
| Limpieza y construcción de las bases | Listo |
| Marco teórico | En redacción |
| Análisis descriptivo | En curso |
| Estimación y diagnóstico del modelo | Pendiente |
| Validación de origen móvil y sensibilidad | Pendiente |
| Aplicación y informe parametrizado | Pendiente |

## Supuestos y límites

- Se supone que los ingresos brutos equivalen a las ventas de la serie de Coljuegos y que las loterías se operan directamente; los excedentes de la operación y los impuestos no se modelan.
- La covariable cuenta, para cada lotería, el día fijo de su sorteo; el cronograma oficial traslada algunos sorteos por festivos, lo que puede desplazar un sorteo de un mes a otro en pocos casos.
- Tres decisiones de depuración se apoyan en la escala de los datos y no están confirmadas con la fuente: la reasignación de la fila de enero de 2012, la corrección de los cuatro valores con tres ceros de más y la suma de las filas de julio de 2025.
- Mayo y junio de 2026 no incluyen al Quindío (13 loterías en lugar de 14).

## Equipo

Isabela Pulgarín Durango y Manuela Ramírez Restrepo.

## Licencia y datos

 Los datos son abiertos y los publica Coljuegos en datos.gov.co; la licencia de uso es la que indica la ficha del conjunto.

## Referencias principales

- Coljuegos (2026). *Ventas del juego de lotería tradicional*. Datos Abiertos Colombia.
- Congreso de la República de Colombia (2001). *Ley 643 de 2001*, régimen propio del monopolio rentístico de juegos de suerte y azar.
- Hyndman, R. J. y Koehler, A. B. (2006). Another look at measures of forecast accuracy. *International Journal of Forecasting*, 22(4), 679-688.
- Diebold, F. X. y Mariano, R. S. (1995). Comparing predictive accuracy. *Journal of Business & Economic Statistics*, 13(3), 253-263.
- Cao, Q., Sun, Z. y Li, H. (2026). Comparative analysis of SARIMA, Prophet, and a diagnostic decomposition-correction hybrid for long-horizon lottery sales forecasting. *Entropy*, 28(3), 286.

La lista completa está en `informe/referencias.bib`.
