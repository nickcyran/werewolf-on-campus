extends Object
## Demo thread data when Greendit's `comments` export is empty.
class_name GreenditDemoThreads


static func threads() -> Array[Dictionary]:
	return [
		{
			"author": "u/testuser02",
			"time": "2h",
			"score": 55,
			"body": "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident.",
			"replies": [
				{
					"author": "u/testuser03",
					"time": "1h",
					"score": 21,
					"body": "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.",
				},
				{
					"author": "u/testuser02",
					"time": "1h",
					"score": 14,
					"body": "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium.",
				},
			],
		},
		{
			"author": "u/testuser04",
			"time": "1h",
			"score": 38,
			"body": "Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.",
		},
		{
			"author": "u/testuser05",
			"time": "50m",
			"score": 27,
			"body": "Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit.",
			"replies": [
				{
					"author": "u/testuser01",
					"time": "30m",
					"score": 9,
					"body": "Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur.",
				},
			],
		},
		{
			"author": "u/testuser06",
			"time": "25m",
			"score": 12,
			"body": "At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti.",
		},
		{
			"author": "u/testuser07",
			"time": "10m",
			"score": 3,
			"body": "TEST TEST - Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus lacinia odio vitae vestibulum vestibulum.",
		},
	]
