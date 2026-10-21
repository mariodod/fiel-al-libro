class_name EnemyMoveData
extends Resource
## One move in a Venture's moveset.
##
## A character's verbs are `AbilityData`: things the player chooses to do.
## A move is the other kind of thing — a shape in the world that comes at
## you. It has a **tell** (the wind-up), a reach, an arc, and a recovery,
## and the recovery is the window: the moment the thing is open and you
## can hit it.
##
## The tell is not decoration. GDD.md §7.1: an enemy says what it is
## about to do, and the companion reads that to time its parry
## (`is_winding_up()` and `time_until_strike()`). A move without a
## wind-up cannot be parried, and a boss that cannot be parried is a
## boss that cannot be read.
##
## Two Ventures with two forms have two movesets, and "fighting it in each
## form is a different fight" (NEXT_STEPS.md §2, task 2.11) is a promise
## this class has to keep.

enum Shape {
	SWEEP,   ## an arc in front of it
	RING,    ## all the way round it: a thing that turns
	CHARGE,  ## it comes at you as it strikes
}

@export var id: StringName = &""
@export var display_name_key: StringName = &""

@export_group("Damage")
@export var damage: float = 10.0
@export var poise_damage: float = 10.0

@export_group("Shape")
@export var shape: Shape = Shape.SWEEP
## How far the blow reaches, from the thing's own centre.
@export var reach: float = 3.0
## The width of the blow, in degrees. A ring is a sweep of 360.
@export var arc_degrees: float = 90.0

@export_group("Timing")
## How long the tell lasts. The player reads the swing in this.
@export var windup_seconds: float = 0.6
## How long the blow itself takes.
@export var strike_seconds: float = 0.15
## How long it is open afterwards. The window.
@export var recover_seconds: float = 1.0
## How long before this move can come out again.
@export var cooldown: float = 1.5
## How far it comes forward while it strikes. Only a CHARGE moves.
@export var step_distance: float = 0.0
## A blow that was meant to break a guard.
##
## It is caught and turned back on the arm that threw it, and it is
## telegraphed with the biggest tell the thing has. Not every blow is
## worth catching: a spinning blade is turned aside — the guard holds
## and the thing keeps coming — but a blow that was meant to break a
## guard is caught and turned back. Without this rule a companion can
## stun-lock a Venture just by standing next to it.
@export var heavy: bool = false


## Is this a move that goes all the way round?
func is_ring() -> bool:
	return shape == Shape.RING


## The half-angle of the blow, in radians.
func half_arc() -> float:
	return deg_to_rad(arc_degrees * 0.5)
