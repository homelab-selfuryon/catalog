package catalog

import (
	"encoding/json"
	"tool/cli"
	"tool/file"
)

// cue cmd generate
//
// Writes out/catalog.json: every team and app, defaults resolved. The contract with the
// repositories that read it is in meta/delivery.md ("Catalog").
command: generate: {
	mkdir: file.MkdirAll & {path: "out"}

	write: file.Create & {
		$after:   mkdir
		filename: "out/catalog.json"
		contents: json.Indent(json.Marshal(catalog), "", "  ") + "\n"
	}

	done: cli.Print & {
		$after: write
		text:   "generated out/catalog.json"
	}
}
