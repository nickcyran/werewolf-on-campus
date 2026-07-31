extends EmailReadingLayout
## Binds `EmailData` fields into the announcement letter layout (Tri-fang style).


func apply_data(data: EmailData) -> void:
	if !data:
		return
	%FromLine.text = "From: %s" % data.sender
	%SentLine.text = "Sent: %s" % data.get_sent_line()
	%ToLine.text = "To: %s" % data.to_line
	%SubjectLine.text = "Subject: %s" % data.subject
	%Headline.text = "[center][b]%s[/b][/center]" % data.subject
	%BodyText.text = data.body
