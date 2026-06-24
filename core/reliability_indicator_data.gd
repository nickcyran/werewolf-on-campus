class_name ReliabilityIndicatorData
extends RefCounted

## true = positive reliability indicator, false = negative
const IS_POSITIVE: Array[bool] = [
	false, # 0  No date
	false, # 1  No easy way to learn about the author or publisher
	false, # 2  Emotional, fearful language or graphics
	false, # 3  Dismissive or judgmental tone
	false, # 4  No clear source of funding or intent
	false, # 5  Overly broad claims
	false, # 6  Claims without evidence
	false, # 7  Hyperbole or strong exaggeration
	false, # 8  Appeal to an authority outside their field of expertise
	false, # 9  Opinion piece, editorial, or entertainment
	false, # 10 Demands trust from readers / viewers
	false, # 11 Source directly profits in some way
	false, # 12 Mix of accurate and inaccurate information
	true,  # 13 Recent date
	true,  # 14 Reliable publisher or author
	true,  # 15 Easily accessed information about the author or source
	true,  # 16 Informative, unmanipulative language
	true,  # 17 Expert or authority with clear credentials on this topic
	true,  # 18 Clearly labeled as news or a factual announcement
]

const INDICATORS: Array[String] = [
	"No date",                                                    # 0  NEG
	"No easy way to learn about the author or publisher",         # 1  NEG
	"Emotional, fearful language or graphics",                    # 2  NEG
	"Dismissive or judgmental tone",                              # 3  NEG
	"No clear source of funding or intent",                       # 4  NEG
	"Overly broad claims",                                        # 5  NEG
	"Claims without evidence",                                    # 6  NEG
	"Hyperbole or strong exaggeration",                           # 7  NEG
	"Appeal to an authority outside their field of expertise",    # 8  NEG
	"Opinion piece, editorial, or entertainment",                 # 9  NEG
	"Demands trust from readers / viewers",                       # 10 NEG
	"Source directly profits in some way",                        # 11 NEG
	"Mix of accurate and inaccurate information",                 # 12 NEG
	"Recent date",                                                # 13 POS
	"Reliable publisher or author",                               # 14 POS
	"Easily accessed information about the author or source",     # 15 POS
	"Informative, unmanipulative language",                       # 16 POS
	"Expert or authority with clear credentials on this topic",   # 17 POS
	"Clearly labeled as news or a factual announcement",          # 18 POS
]
