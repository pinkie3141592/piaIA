# Proceso de diseño: Dominio PDDL "Robot Barista"

## 1. Escenario elegido

Un robot de una sola mano trabaja en una cafetería. Debe tomar tazas vacías de la barra, prepararlas en las estaciones correspondientes (cafetera y lechera) y entregarlas en la mesa del cliente que las pidió.

Elegí este escenario porque combina tres cosas que me interesaban modelar: **navegación** por un mapa, **manipulación** con capacidad limitada (una taza a la vez) y **transformación del estado** de los objetos (una taza vacía se convierte en café, y luego en latte). Esto produce planes largos y con orden obligatorio.

## 2. Predicados y por qué los definí

Definí 10 predicados (el mínimo pedido era 4), agrupados por función.

### Navegación
| Predicado | Significado | Razón de diseño |
|---|---|---|
| `(robot-en ?r ?u)` | El robot está en la ubicación `u` | Permite que las acciones dependan de dónde está el robot. |
| `(conectado ?a ?b)` | Se puede ir de `a` a `b` | Modela un mapa con restricciones. La cafetería **no** es un grafo completo: para ir de la barra a las mesas hay que pasar por la cafetera y la lechera, lo que alarga el plan. |

### Manipulación
| Predicado | Significado | Razón de diseño |
|---|---|---|
| `(taza-en ?t ?u)` | La taza está apoyada en `u` | Posición de las tazas cuando nadie las sostiene. |
| `(sosteniendo ?r ?t)` | El robot sostiene la taza `t` | Estado "en la mano". Es mutuamente excluyente con `taza-en`. |
| `(mano-libre ?r)` | El robot no sostiene nada | **Restricción clave**: el robot solo carga una taza a la vez. Esto obliga a atender las tazas en secuencia y a regresar por la segunda. |

### Estado de la bebida
| Predicado | Significado | Razón de diseño |
|---|---|---|
| `(vacia ?t)` | La taza está vacía | Precondición para servir café. Evita servir dos veces en la misma taza. |
| `(con-cafe ?t)` | La taza tiene café | Es precondición de agregar leche, y sirve de meta para el americano. |
| `(con-leche ?t)` | La taza tiene leche (latte) | Meta para la primera bebida. |

### Estaciones
| Predicado | Significado | Razón de diseño |
|---|---|---|
| `(estacion-cafe ?u)` | En `u` se puede servir café | Propiedad de la ubicación en vez de un tipo fijo, así otros problemas pueden tener varias cafeteras. |
| `(estacion-leche ?u)` | En `u` se puede agregar leche | Igual que el anterior. |

**Tipos:** `robot`, `ubicacion`, `taza`. Uso `:typing` para que los parámetros de cada acción queden bien acotados.

## 3. Acciones y cómo llegué al esquema final

Necesitaba modelar tres tipos de cosas: moverse, manipular objetos y transformar bebidas. Eso dio **5 esquemas de acción** (el mínimo pedido era 3).

### `mover (?r ?a ?b)`
- **Precondiciones:** `robot-en r a`, `conectado a b`
- **Agrega:** `robot-en r b`
- **Elimina:** `robot-en r a`
- **Decisión:** exigir `conectado` hace que el mapa importe. Sin esa precondición el robot "teletransportaría" y el plan sería mucho más corto.

### `tomar (?r ?t ?u)`
- **Precondiciones:** `robot-en r u`, `taza-en t u`, `mano-libre r`
- **Agrega:** `sosteniendo r t`
- **Elimina:** `taza-en t u`, `mano-libre r`
- **Decisión:** la taza deja de estar en la ubicación y pasa a la mano. `mano-libre` impide tomar una segunda taza.

### `soltar (?r ?t ?u)`
- **Precondiciones:** `robot-en r u`, `sosteniendo r t`
- **Agrega:** `taza-en t u`, `mano-libre r`
- **Elimina:** `sosteniendo r t`
- **Decisión:** es la inversa de `tomar`. Sirve para entregar la taza en una mesa.

### `servir-cafe (?r ?t ?u)`
- **Precondiciones:** `robot-en r u`, `estacion-cafe u`, `sosteniendo r t`, `vacia t`
- **Agrega:** `con-cafe t`
- **Elimina:** `vacia t`
- **Decisión:** la taza debe estar en la mano del robot mientras se sirve, y la estación debe ser de café. Quitar `vacia` impide servir dos veces.

### `agregar-leche (?r ?t ?u)`
- **Precondiciones:** `robot-en r u`, `estacion-leche u`, `sosteniendo r t`, `con-cafe t`
- **Agrega:** `con-leche t`
- **Elimina:** nada
- **Decisión:** exigir `con-cafe` fuerza el orden **café → leche**. Es la dependencia causal central del dominio.

## 4. Evolución del diseño

1. **Primera versión:** una sola acción `preparar-latte` que hacía todo. El plan resultaba de 1 o 2 pasos, lo cual era trivial.
2. **Separación en pasos:** dividí la preparación en `servir-cafe` y `agregar-leche`, con `con-cafe` como puente entre ambas.
3. **Agregué navegación:** introduje ubicaciones y `mover` con un mapa no completo, para que el robot tenga que recorrer estaciones.
4. **Agregué manipulación:** `tomar`, `soltar` y `mano-libre`, de modo que el robot deba cargar la taza mientras la prepara.
5. **Segunda bebida:** añadí una segunda taza con una meta distinta (solo café) para que el robot deba **regresar** a la barra, lo que vuelve el plan más largo y menos obvio.

## 5. Problema de prueba

- **Objetos:** 1 robot (`bot`), 5 ubicaciones (`barra`, `cafetera`, `lechera`, `mesa1`, `mesa2`) y 2 tazas (`t1`, `t2`).
- **Mapa:** `barra ↔ cafetera ↔ lechera ↔ mesa1 ↔ mesa2`, y además `lechera ↔ mesa2`.
- **Estado inicial:** el robot está en la barra con la mano libre; `t1` y `t2` están vacías sobre la barra.
- **Meta:** `t1` con leche (latte) en `mesa1` y `t2` con café (americano) en `mesa2`.
- **Longitud del plan:** 16 pasos, muy por encima del mínimo de 5.

## 6. En qué se diferencia de los dominios de inspiración

| Aspecto | Air Cargo | Blocks World | Robot Barista |
|---|---|---|---|
| Los objetos cambian de estado | No, solo cambian de lugar | No, solo de posición | **Sí** (vacía → café → leche) |
| Orden causal entre acciones | Cargar → volar → descargar | Despejar → apilar | **Café antes que leche**, con estaciones especiales |
| Capacidad del agente | Los aviones cargan varios | El brazo carga un bloque | Una taza a la vez, pero **con transformación mientras se carga** |
| Mapa | Grafo de aeropuertos | No hay navegación | Grafo **no completo** con estaciones con propiedades |
| Meta | Posición final | Configuración de torre | Posición **y** estado del objeto |

No es un Air Cargo renombrado porque aquí las acciones no solo trasladan objetos: algunas modifican propiedades de los objetos (`servir-cafe`, `agregar-leche`) y dependen de propiedades del lugar (`estacion-cafe`, `estacion-leche`). Tampoco es un Blocks World, porque el agente se desplaza por un mapa.

## 7. Plan obtenido

Planificador usado: editor.planning.domains. Plan de **16 pasos**:

```
 1. (tomar bot t1 barra)
 2. (mover bot barra cafetera)
 3. (servir-cafe bot t1 cafetera)
 4. (mover bot cafetera lechera)
 5. (agregar-leche bot t1 lechera)
 6. (mover bot lechera mesa1)
 7. (soltar bot t1 mesa1)
 8. (mover bot mesa1 lechera)
 9. (mover bot lechera cafetera)
10. (mover bot cafetera barra)
11. (tomar bot t2 barra)
12. (mover bot barra cafetera)
13. (servir-cafe bot t2 cafetera)
14. (mover bot cafetera lechera)
15. (mover bot lechera mesa2)
16. (soltar bot t2 mesa2)
```

### Explicación paso a paso

**Fase A: preparar y entregar el latte (t1), pasos 1 a 7**

| Paso | Acción | Precondiciones que cumple | Efecto relevante |
|---|---|---|---|
| 1 | `tomar bot t1 barra` | Robot en barra, `t1` en barra, mano libre | Robot sostiene `t1`; mano ocupada |
| 2 | `mover barra → cafetera` | Robot en barra, barra conectada con cafetera | Robot en cafetera |
| 3 | `servir-cafe t1` | Robot en cafetera, es estación de café, sostiene `t1`, `t1` vacía | `t1` con café; deja de estar vacía |
| 4 | `mover cafetera → lechera` | Robot en cafetera, conectada con lechera | Robot en lechera |
| 5 | `agregar-leche t1` | Robot en lechera, estación de leche, sostiene `t1`, `t1` con café | `t1` con leche: **primera mitad de la meta** |
| 6 | `mover lechera → mesa1` | Robot en lechera, conectada con mesa1 | Robot en mesa1 |
| 7 | `soltar t1 mesa1` | Robot en mesa1, sostiene `t1` | `t1` en mesa1, mano libre: **latte entregado** |

**Fase B: regresar por la segunda taza, pasos 8 a 10**

| Paso | Acción | Por qué es necesaria |
|---|---|---|
| 8 | `mover mesa1 → lechera` | Primer tramo de regreso. `mesa1` solo conecta con `lechera` y `mesa2`. |
| 9 | `mover lechera → cafetera` | Segundo tramo de regreso. |
| 10 | `mover cafetera → barra` | `t2` sigue en la barra, y es el único lugar donde se puede tomar. |

Estos tres pasos existen porque el mapa **no es completo** y porque el robot no pudo llevar las dos tazas a la vez.

**Fase C: preparar y entregar el americano (t2), pasos 11 a 16**

| Paso | Acción | Precondiciones que cumple | Efecto relevante |
|---|---|---|---|
| 11 | `tomar bot t2 barra` | Robot en barra, `t2` en barra, mano libre (liberada en el paso 7) | Robot sostiene `t2` |
| 12 | `mover barra → cafetera` | Robot en barra | Robot en cafetera |
| 13 | `servir-cafe t2` | Robot en cafetera, sostiene `t2`, `t2` vacía | `t2` con café: **cumple la condición de estado de la meta** |
| 14 | `mover cafetera → lechera` | Robot en cafetera | Robot en lechera |
| 15 | `mover lechera → mesa2` | Robot en lechera, conectada con mesa2 | Robot en mesa2 |
| 16 | `soltar t2 mesa2` | Robot en mesa2, sostiene `t2` | `t2` en mesa2: **meta completa** |

### Por qué el plan funciona

- **Dependencia causal:** el paso 5 (`agregar-leche`) solo es posible porque el paso 3 agregó `con-cafe`.
- **Una sola mano:** el paso 11 solo es posible porque el paso 7 devolvió `mano-libre`. Por eso el robot debe terminar con `t1` antes de tomar `t2`.
- **Mapa limitado:** los pasos 8, 9 y 10 son consecuencia directa de que `mesa1` no está conectada con la barra.
- **Paso 14:** el robot pasa por la lechera con `t2` aunque no le agrega leche, porque es el único camino hacia `mesa2` desde la cafetera. Esto se debe al mapa, no a la receta.
- **Cumplimiento de la meta:** `t1` tiene leche y está en mesa1 (pasos 5 y 7), y `t2` tiene café y está en mesa2 (pasos 13 y 16).

## 8. Archivos del repositorio

- `domain.pddl`: tipos, predicados y las 5 acciones.
- `problem.pddl`: objetos, estado inicial y meta.
- `DISENO.md`: este documento.
- Enlace al video: https://youtu.be/CRvxXGHtL18