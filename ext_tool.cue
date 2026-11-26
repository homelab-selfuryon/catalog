package catalog

import (
	"encoding/json"
	"tool/cli"
	"tool/file"
)

// cue cmd generate
//
// Writes out/catalog.json (every team and app, defaults resolved; for reading, sent nowhere) and
// out/<repository>.json, the view each repository receives (views.cue). The contract with those
// repositories is in meta/delivery.md ("Catalog").
command: generate: {
	mkdir: file.MkdirAll & {path: "out"}

	write: file.Create & {
		$after:   mkdir
		filename: "out/catalog.json"
		contents: json.Indent(json.Marshal(catalog), "", "  ") + "\n"
	}

	for repo, v in views {
		"write-\(repo)": file.Create & {
			$after:   mkdir
			filename: "out/\(repo).json"
			contents: json.Indent(json.Marshal(v), "", "  ") + "\n"
		}
	}

	done: cli.Print & {
		$after: [for k, v in command.generate if k != "done" {v}]
		text:   "generated out/catalog.json and out/<repository>.json: \(len(views)) views"
	}
}
