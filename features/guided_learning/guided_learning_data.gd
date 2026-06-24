class_name GuidedLearningData
extends RefCounted

## One entry per browser site plus an intro slide.
## indicator_indices maps into ReliabilityIndicatorData.INDICATORS.
static func get_sections() -> Array:
	return [
		{
			"type": "intro",
		},
		{
			"name": "NoWolves",
			"url": "nowolves.news/articles/signs-of-a-werewolf",
			"scene": preload("res://features/sites/nowolves/nowolves.tscn"),
			"indicator_indices": [0, 1, 2, 4, 5, 6, 7, 11, 12]
		},
		{
			"name": "Greendit",
			"url": "greendit.net/r/campuslife",
			"scene": preload("res://features/sites/greendit/greendit.tscn"),
			"indicator_indices": [1, 9]
		},
		{
			"name": "CloudMail",
			"url": "cloudmail.edu/inbox",
			"scene": preload("res://features/sites/email/EmailClient.tscn"),
			"indicator_indices": [14, 15, 17, 18]
		},
		{
			"name": "Channel 29",
			"url": "channel29news.com/staff/mary-harker",
			"scene": preload("res://features/sites/channel29/channel29.tscn"),
			"indicator_indices": [14, 15, 16, 17, 18]
		},
		{
			"name": "ACWW",
			"url": "acww.tri-fang.edu",
			"scene": preload("res://features/sites/acww/acww_main.tscn"),
			"indicator_indices": [3, 8, 10, 11, 12]
		},
		{
			"name": "Trifang News",
			"url": "tri-fang.edu/news",
			"scene": preload("res://features/sites/trifangnews/trifang_news.tscn"),
			"indicator_indices": [13, 14, 16, 18]
		},
	]
