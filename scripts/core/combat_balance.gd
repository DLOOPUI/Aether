class_name CombatBalance
extends Resource
## Multiplicadores globales de combate (editable en `resources/combat_balance.tres`).

@export_range(0.1, 5.0, 0.05) var player_damage_multiplier: float = 1.0
@export_range(0.1, 5.0, 0.05) var experience_gain_multiplier: float = 1.0
## Daño que recibe el jugador (menor = más fácil).
@export_range(0.25, 3.0, 0.05) var damage_taken_multiplier: float = 1.0
