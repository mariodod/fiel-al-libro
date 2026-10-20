class_name Harm
extends RefCounted
## What a blow may do, and what it costs.
##
## The two asymmetry rules, GDD.md §7.2 and D4. They are the reason the
## two characters are not the same character with different numbers:
##
## 1. **Quixote cannot harm innocents.** A blow that lands on a thing
##    that must not be harmed does no damage, and it costs **Humanity** —
##    and it hard-locks his Book-only abilities until the chapter ends.
##    D4: *"You can attack innocents. It costs Humanity."* The world must
##    feel dangerous and the player must feel responsible.
## 2. **Sancho cannot meaningfully damage enemies.** His kit is control.
##    He wins by revealing and refuting while Quixote does the killing.
##    So his damage is scaled down against a hostile, and his poise damage
##    is not: he staggers, he does not kill.
##
## Sancho's rule is *not* "he hits softer". It is "he hits a different
## thing": the same blow that would break a thing's guard leaves it
## reeling instead of dead.

## Who a thing is, and what may be done to it.
enum Faction {
	PRACTICE,  ## a training target. Anyone may hit it, for full damage.
	INNOCENT,  ## a thing that must not be harmed. Hitting it costs Humanity.
	HOSTILE,   ## an enemy. Sancho cannot meaningfully damage it.
}


## The damage a blow does, given who is throwing it and what it lands on.
##
## Zero means the blow does not land at all: that is Quixote and an
## innocent.
static func damage_for(faction: int, attacker: CharacterPawn, amount: float) -> float:
	if attacker == null or attacker.data == null:
		return amount
	match faction:
		Faction.INNOCENT:
			if not attacker.data.can_harm_innocents:
				# The blow does not land. The knight's hand does not go
				# through, however hard he swings.
				return 0.0
			return amount
		Faction.HOSTILE:
			# "Sancho cannot meaningfully damage enemies."
			return amount * attacker.data.enemy_damage_scale
		_:
			return amount


## The Humanity a blow costs, given who is throwing it and what it lands
## on.
##
## Nobody gets to hit the innocent for free. Quixote pays more, because
## it is his conscience that is the expensive part.
static func humanity_cost(faction: int, attacker: CharacterPawn) -> int:
	if faction != Faction.INNOCENT:
		return 0
	if attacker == null or attacker.data == null:
		return 0
	return int(attacker.data.innocent_humanity_cost)


## Did the blow land at all? A blow on an innocent that Quixote cannot
## make does not, and the world says so.
static func lands(faction: int, attacker: CharacterPawn) -> bool:
	return damage_for(faction, attacker, 1.0) > 0.0
