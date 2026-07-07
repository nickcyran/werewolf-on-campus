extends Object
class_name GreenditDemoThreads


static func threads() -> Array[GreenditComment]:
	return [
		_c("u/testuser02", "2h", 55,
			"Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident.",
			[
				_c("u/testuser03", "1h", 21, "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.", []),
				_c("u/testuser02", "1h", 14, "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium.", []),
			]
		),
		_c("u/testuser04", "1h", 38,
			"Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.",
			[]
		),
		_c("u/testuser05", "50m", 27,
			"Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit.",
			[
				_c("u/testuser01", "30m", 9, "Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur.", []),
			]
		),
		_c("u/testuser06", "25m", 12,
			"At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti.",
			[]
		),
		_c("u/testuser07", "10m", 3,
			"TEST TEST - Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus lacinia odio vitae vestibulum vestibulum.",
			[]
		),
	]


static func _c(author: String, time: String, score: int, body: String,
		replies: Array[GreenditComment]) -> GreenditComment:
	var c := GreenditComment.new()
	c.author = author
	c.time = time
	c.score = score
	c.body = body
	c.replies = replies
	return c
