# Trenazo Survival

Juego de acción 2D de supervivencia por oleadas hecho en **Godot 4.7**. Peleas sobre un tren en movimiento contra oleadas de sicarios, pesados y francotiradores, con un jefe cada 5 oleadas. El objetivo es aguantar el mayor número de oleadas posible.

## Cómo ejecutarlo

1. Instala [Godot 4.7](https://godotengine.org/download) (versión estándar, no .NET).
2. Clona el repositorio:
   ```bash
   git clone https://github.com/Clay666-bru/Juego-Godot.git
   ```
3. Abre Godot, pulsa **Importar** y selecciona el archivo `project.godot`.
4. Pulsa **F5** (o el botón ▶) para jugar. La escena inicial es el menú (`scenes/menu/menu.tscn`).

> La carpeta `.godot/` no se sube al repo; Godot la regenera al importar el proyecto la primera vez.

## Controles

| Acción | Tecla |
|---|---|
| Moverse | `A` / `D` o flechas ← → |
| Saltar | `Espacio` |
| Agacharse (en el suelo) | `S` |
| Rodar / esquivar (invencible mientras dura) | `F` |
| Apuntar | Ratón |
| Disparar (mantener) | Click izquierdo |
| Reiniciar tras Game Over | `R` |

## Mecánicas

### Jugador
- **10 de vida**. Al recibir daño queda invencible 1.5 s y parpadea en rojo.
- **Rodar** dura 0.25 s, avanza rápido en la dirección a la que miras y te hace invencible.
- Agacharse reduce la hitbox a la mitad pero te deja quieto.
- Apunta libremente con el ratón en 360°.

### Armas

| Arma | Cadencia | Velocidad de bala | Daño | Balas por disparo | Dispersión |
|---|---|---|---|---|---|
| Pistola (inicial) | 0.30 s | 600 | 1 | 1 | 0° |
| Ametralladora | 0.08 s | 700 | 1 | 1 | ±3° |
| Escopeta | 0.25 s | 550 | 1 | 3 | ±12° |
| Láser | 0.15 s | 800 | 2 | 1 | 0° |

Las armas se obtienen recogiendo pickups que sueltan los enemigos. Al reiniciar vuelves a la pistola.

### Pickups
- **Arma** (sprite de arma): cambia tu arma actual por una al azar (ametralladora, escopeta o láser).
- **Vida** (cruz verde): cura 1 o 3 puntos según el enemigo.
- Desaparecen a los 8 s; parpadean durante los últimos 3 s.

### Enemigos

| Enemigo | Vida | Comportamiento | Botín |
|---|---|---|---|
| **Sicario** | 1 | Corre hacia ti, se detiene a 200 px y dispara en horizontal cada 1 s. Salta obstáculos. | 50% vida (+1) |
| **Pesado** | 4 | Avanza lento sin parar y dispara ráfagas de 3 balas cada 1.5 s. | Arma + vida (+3) |
| **Francotirador** | 1 | Aparece en zonas altas, no se mueve y dispara balas muy rápidas (900) apuntadas directo a ti cada 0.8 s. | 50% vida (+1) |
| **Jefe (SUV)** | 20 + 10 por cada jefe previo | Recorre el nivel de lado a lado, salta obstáculos, dispara un anillo de 20 balas y daña al contacto. | 4 pickups al azar |

### Oleadas
- La primera oleada empieza 1 s después de entrar al nivel; entre oleadas hay 2 s de pausa.
- Cada **5 oleadas** aparece un jefe (oleada 5, 10, 15…) con más vida y disparo más rápido cada vez (mínimo 0.5 s entre disparos).
- Composición de la oleada número *n* (contando desde 0):
  - Sicarios: `min(2 + n/2, 10)`
  - Pesados: `min(n/3, 5)`
  - Francotiradores: `min(n/4, 4)`
- Al morir, la pantalla de Game Over muestra la oleada alcanzada.

## Estructura del proyecto

```
├── project.godot              Configuración, autoloads, controles y capas de colisión
├── assets/
│   ├── audio/music/           Música del menú y del nivel
│   ├── audio/sfx/             Disparo, golpe, muerte y pickup
│   ├── fonts/                 Fuente del título
│   └── sprites/               Jugador, enemigos, armas, UI y fondos
├── scenes/
│   ├── menu/menu.tscn         Menú principal (escena inicial)
│   ├── main.tscn              Escena de juego: mundo, jugador, cámara y HUD
│   ├── levels/level_1.tscn    Nivel con terreno, plataformas y puntos de aparición
│   ├── levels/test_level.tscn Nivel de pruebas
│   ├── player/                Jugador
│   ├── enemies/               Sicario, pesado, francotirador, jefe y bala enemiga
│   └── weapons/               Bala del jugador y pickup
└── scripts/
    ├── autoloads/             Singletons globales (ver abajo)
    ├── menu/menu.gd           Fondo animado del menú y botones Jugar/Salir
    ├── main.gd                HUD, Game Over, reinicio y carga del nivel
    ├── camera_controller.gd   Cámara que sigue al jugador, con límites y temblor
    ├── player/player.gd       Máquina de estados del jugador
    ├── levels/level_1.gd      Generación de oleadas, fondo con scroll y jefes
    ├── enemies/               IA de cada enemigo
    └── weapons/               Balas y pickups
```

### Autoloads (singletons)

| Nombre | Archivo | Función |
|---|---|---|
| `WeaponManager` | `scripts/autoloads/weapon_manager.gd` | Arma actual y tabla de estadísticas de cada arma. |
| `Effects` | `scripts/autoloads/effects.gd` | Efectos visuales generados por código: destellos, chispas, explosiones y sangre. |
| `Sounds` | `scripts/autoloads/sounds.gd` | Música de fondo en bucle y efectos de sonido posicionales. Si falta un archivo de audio genera un pitido de respaldo. |

### Capas de colisión

| Capa | Nombre | Quién está ahí |
|---|---|---|
| 1 | (por defecto) | Terreno, paredes y plataformas |
| 2 | Player | Jugador |
| 3 | Enemies | Todos los enemigos |
| 4 | Bullets | Balas del jugador (detectan capa 3) y balas enemigas (detectan capa 2) |
| 5 | Pickups | Pickups (detectan capa 2) |

### Flujo del juego

1. `menu.tscn` → botón **Jugar** cambia a `main.tscn`.
2. `main.gd` instancia `level_1.tscn` dentro de `World/LevelContainer`, coloca al jugador en `StartPosition` y conecta las señales `wave_started` y `boss_spawned` del nivel al HUD.
3. `level_1.gd` genera enemigos en los marcadores de `Spawners/Ground`, `Spawners/High` (francotiradores) y `Spawners/BossSpawn`. Cuando todos los enemigos emiten `died`, programa la siguiente oleada.
4. Cuando el jugador emite `died`, `main.gd` muestra el Game Over; con `R`, `restart_game()` limpia la escena y recarga el nivel.

## Historial de correcciones

**9 de noviembre de 2026**
- Las balas recibían su arma y dirección después de entrar a la escena, así que todas las armas se comportaban como pistola (el láser hacía 1 de daño en vez de 2, la velocidad nunca cambiaba) y las balas siempre se dibujaban apuntando a la derecha. Ahora se configuran antes de agregarlas, tanto las del jugador como las enemigas.
- Varios impactos en el mismo frame hacían que un enemigo "muriera" varias veces y soltara botín repetido. `take_damage()` ahora ignora el daño si el enemigo ya tiene 0 de vida.
- Al reiniciar quedaban balas, pickups y efectos de la partida anterior. `restart_game()` ahora los elimina.

## Pendientes conocidos

- `S` está asignada a la vez a *agacharse* y a *apuntar abajo* (esta última no se usa en el código).
- Los enemigos que salen de la pantalla desaparecen y cuentan como derrotados. Los francotiradores pueden aparecer fuera de la vista inicial.
- Las balas del jugador atraviesan paredes y plataformas.
- `Esc` (acción `pause`) está configurada pero aún no hay menú de pausa, y desde el Game Over no se puede volver al menú principal.
- Rodar justo después de recibir daño termina antes la invencibilidad de ese golpe.
