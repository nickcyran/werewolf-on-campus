class_name GuidedLearningData
extends RefCounted

# ── To add a new source ───────────────────────────────────────────────────────
# 1. Call _src() with the display name, chrome URL, and source type.
# 2. Assign .scene / .image / .video / .audio to the matching content.
# 3. Set whichever indicator bools apply (true = this source has that indicator).
# 4. Append to the return array.
# ─────────────────────────────────────────────────────────────────────────────

static func get_intro_text() -> String:
	return (
		"[b]Reliability Indicators[/b]\n\n"
		+ "All the indicators of reliability or unreliability in the fake sources "
		+ "can be applied to anything you encounter online in real life.\n\n"
		+ "Multiple [color=#f5a0a0]negative[/color] indicators mean a source is likely [b]unreliable[/b], "
		+ "while multiple [color=#a0f5c0]positive[/color] indicators show a more [b]reliable[/b] one.\n\n"
		+ "Match up the actual indicators to the werewolf sources to show why some are "
		+ "reliable and others are not.\n\n"
		+ "[i]Drag indicators from the pools on the right onto each source, then click "
		+ "Submit Response to see how you did.[/i]"
	)


static func get_sources() -> Array[GuidedLearningSource]:
	var sources: Array[GuidedLearningSource] = []
	var s: GuidedLearningSource

	# ── NoWolves ──────────────────────────────────────────────────────────────
	s = _src("NoWolves", "nowolves.news/articles/signs-of-a-werewolf", GuidedLearningSource.Type.SCENE)
	s.scene = preload("res://features/sites/nowolves/nowolves.tscn")
	s.no_date = true
	s.no_author_info = true
	s.emotional_language = true
	s.no_funding_info = true
	s.overly_broad_claims = true
	s.claims_without_evidence = true
	s.hyperbole = true
	s.source_profits = true
	s.mixed_accuracy = true
	sources.append(s)

	# ── Greendit ──────────────────────────────────────────────────────────────
	s = _src("Greendit", "greendit.net/r/campuslife", GuidedLearningSource.Type.SCENE)
	s.scene = preload("res://features/sites/greendit/greendit.tscn")
	s.no_author_info = true
	s.opinion_entertainment = true
	sources.append(s)

	# ── CloudMail ─────────────────────────────────────────────────────────────
	s = _src("CloudMail", "cloudmail.edu/inbox", GuidedLearningSource.Type.SCENE)
	s.scene = preload("res://features/sites/email/EmailClient.tscn")
	s.reliable_publisher = true
	s.accessible_author_info = true
	s.expert_credentials = true
	s.clearly_labeled_news = true
	sources.append(s)

	# ── Channel 29 ────────────────────────────────────────────────────────────
	s = _src("Channel 29", "channel29news.com/staff/mary-harker", GuidedLearningSource.Type.SCENE)
	s.scene = preload("res://features/sites/channel29/channel29.tscn")
	s.reliable_publisher = true
	s.accessible_author_info = true
	s.informative_language = true
	s.expert_credentials = true
	s.clearly_labeled_news = true
	sources.append(s)

	# ── ACWW ──────────────────────────────────────────────────────────────────
	s = _src("ACWW", "acww.tri-fang.edu", GuidedLearningSource.Type.SCENE)
	s.scene = preload("res://features/sites/acww/acww_main.tscn")
	s.dismissive_tone = true
	s.outside_expertise = true
	s.demands_trust = true
	s.source_profits = true
	s.mixed_accuracy = true
	sources.append(s)

	# ── Trifang News ──────────────────────────────────────────────────────────
	s = _src("Trifang News", "tri-fang.edu/news", GuidedLearningSource.Type.SCENE)
	s.scene = preload("res://features/sites/trifangnews/trifang_news.tscn")
	s.recent_date = true
	s.reliable_publisher = true
	s.informative_language = true
	s.clearly_labeled_news = true
	sources.append(s)

	return sources


static func _src(name: String, url: String, t: GuidedLearningSource.Type) -> GuidedLearningSource:
	var s := GuidedLearningSource.new()
	s.display_name = name
	s.url = url
	s.type = t
	return s
