@tool
class_name GuidedLearningSource
extends Resource

enum Type {SCENE, IMAGE, VIDEO, AUDIO}

@export var display_name: String = ""
@export var url: String = "" # shown in the chrome address bar
@export var type: Type = Type.SCENE

@export_group("Content")
@export var scene: PackedScene # Type.SCENE / Type.APP
@export var image: Texture2D # Type.IMAGE
@export var video: VideoStream # Type.VIDEO
@export var audio: AudioStream # Type.AUDIO

# ── Negative indicators ───────────────────────────────────────────────────────
@export_group("Negative Indicators")
@export var no_date: bool = false
@export var no_author_info: bool = false
@export var emotional_language: bool = false
@export var dismissive_tone: bool = false
@export var no_funding_info: bool = false
@export var overly_broad_claims: bool = false
@export var claims_without_evidence: bool = false
@export var hyperbole: bool = false
@export var outside_expertise: bool = false
@export var opinion_entertainment: bool = false
@export var demands_trust: bool = false
@export var source_profits: bool = false
@export var mixed_accuracy: bool = false

# ── Positive indicators ───────────────────────────────────────────────────────
@export_group("Positive Indicators")
@export var recent_date: bool = false
@export var reliable_publisher: bool = false
@export var accessible_author_info: bool = false
@export var informative_language: bool = false
@export var expert_credentials: bool = false
@export var clearly_labeled_news: bool = false


# Returns the indices into ReliabilityIndicatorData.INDICATORS that are checked.
# Order must stay in sync with that array (negatives 0-12, positives 13-18).
func get_indicator_indices() -> Array[int]:
	var result: Array[int] = []
	var checks: Array[bool] = [
		no_date, no_author_info, emotional_language, dismissive_tone,
		no_funding_info, overly_broad_claims, claims_without_evidence,
		hyperbole, outside_expertise, opinion_entertainment,
		demands_trust, source_profits, mixed_accuracy,
		recent_date, reliable_publisher, accessible_author_info,
		informative_language, expert_credentials, clearly_labeled_news,
	]
	for i in range(checks.size()):
		if checks[i]:
			result.append(i)
	return result
