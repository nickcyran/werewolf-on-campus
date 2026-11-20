class_name EndStateTier extends Resource
## One score band on an end screen: the pup and the words shown for it. A screen picks
## the band with the highest [member min_ratio] the player's share of right answers reaches.

@export_range(0.0, 1.0, 0.01) var min_ratio := 0.0
@export var pup: Texture2D
@export var headline := ""
@export_multiline var message := ""
## Theme type variation for the label that carries the verdict.
@export var verdict_style: StringName
## Theme type variation for the disc behind the pup.
@export var backdrop_style: StringName
## How far the pup bobs while idle. Zero keeps it still.
@export var bob_height := 0.0


static func pick(tiers: Array[EndStateTier], correct: int, total: int) -> EndStateTier:
	var ratio := float(correct) / total if total > 0 else 0.0
	var best: EndStateTier = null
	for tier in tiers:
		if ratio >= tier.min_ratio && (!best || tier.min_ratio > best.min_ratio):
			best = tier
	return best
