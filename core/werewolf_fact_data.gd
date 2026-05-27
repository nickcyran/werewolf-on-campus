class_name WerewolfFactData
extends RefCounted

## Statements on the Werewolf Fact Checker. Order is fixed for saves and scoring.
const FACTS: Array[String] = [
	"Wears yellow & bright colors",
	"Afraid of vacuum cleaners",
	"Enhanced sense of smell and sight",
	"Shedding",
	"Disappears on the full moon",
	"Allergic to silver",
	"Repelled by garlic",
	"Regularly eats meat",
]

## For each fact: whether it is true for this game's werewolves. The player checks
## boxes for statements they believe are true; a match counts as a point.
const CORRECT_CHECKED: Array[bool] = [
	false,
	false,
	true,
	true,
	true,
	true,
	false,
	true,
]


static func fact_count() -> int:
	return FACTS.size()


static func count_matches(player_checked: Dictionary) -> int:
	var n := mini(FACTS.size(), CORRECT_CHECKED.size())
	var ok := 0
	for i in range(n):
		if bool(player_checked.get(i, false)) == CORRECT_CHECKED[i]:
			ok += 1
	return ok
