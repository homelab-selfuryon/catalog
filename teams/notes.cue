package teams

notes: {
	team: description: "Product team behind the example apps notes-api and notes-stats"

	apps: {
		"notes-api": {
			description: "Example app: notes REST API on Postgres"
			tier:        "tier-3"
		}
		"notes-stats": {
			description: "Example app: calls notes-api with a projected ServiceAccount token"
			tier:        "tier-3"
		}
	}
}
