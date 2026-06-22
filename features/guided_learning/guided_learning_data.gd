class_name GuidedLearningData
extends RefCounted

## One entry per browser site. fact_indices maps into WerewolfFactData.FACTS.
static func get_sections() -> Array:
	return [
		{
			"name": "NoWolves",
			"url": "nowolves.news/articles/signs-of-a-werewolf",
			"scene": preload("res://features/sites/nowolves/nowolves.tscn"),
			"fact_indices": [2, 3, 4, 7]
		},
		{
			"name": "Greendit",
			"url": "greendit.net/r/campuslife",
			"scene": preload("res://features/sites/greendit/greendit.tscn"),
			"fact_indices": [3]
		},
		{
			"name": "CloudMail",
			"url": "cloudmail.edu/inbox",
			"scene": preload("res://features/sites/email/EmailClient.tscn"),
			"fact_indices": [4]
		},
		{
			"name": "Channel 29",
			"url": "channel29news.com/staff/mary-harker",
			"scene": preload("res://features/sites/channel29/channel29.tscn"),
			"fact_indices": [5]
		},
		{
			"name": "ACWW",
			"url": "acww.tri-fang.edu",
			"scene": preload("res://features/sites/acww/acww_main.tscn"),
			"fact_indices": [7]
		},
		{
			"name": "Trifang News",
			"url": "tri-fang.edu/news",
			"scene": preload("res://features/sites/trifangnews/trifang_news.tscn"),
			"fact_indices": [2]
		},
	]
