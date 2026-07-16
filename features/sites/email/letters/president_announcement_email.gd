extends PanelContainer
## Binds `EmailData` fields into the announcement letter layout (Tri-fang style).


func apply_data(data: EmailData) -> void:
	if !data:
		return
	%FromLine.text = "From: %s" % data.sender
	%SentLine.text = "Sent: %s" % data.sent_line
	%ToLine.text = "To: %s" % data.to_line
	%SubjectLine.text = "Subject: %s" % data.subject
	%Headline.bbcode_enabled = true
	%Headline.text = "[center][b]%s[/b][/center]" % data.subject
	%BodyText.text = data.body
	%BannerRich.text = (
		"[font_size=11]OFFICE OF THE PRESIDENT[/font_size]\n"
		+ "[font_size=20][b]Dr. Chandra Hel Acheron[/b][/font_size]\n"
		+ "[font_size=13][i]President[/i][/font_size]"
	)
