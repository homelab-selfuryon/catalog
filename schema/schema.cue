// Package schema types the catalog: teams, apps and what they get by default. A team directory
// says only how it differs; `catalog.json` carries every value resolved.
package schema

import "list"

#Catalog: {
	teams: [string]~(N,_): #Team & {name: N}
	apps: [string]~(N,_):  #App & {name: N}

	// An app belongs to a team that exists and gets tenant namespaces.
	_appTeams: {for a, s in apps {(a): teams[s.team].tenant & true}}
}

#Team: {
	// Not `system`: its Argo CD Applications namespace would be Argo CD's own (argocd-system).
	name!:        =~"^[a-z][a-z0-9]{1,20}$" & !="system"
	description!: string & !=""

	// Permission of the GitHub team of the same name on the repositories it owns.
	github: permission: *"maintain" | "admin" | "push" | "triage" | "pull"

	// A product team runs apps in tenant namespaces (`<team>-staging`, `<team>-prod`,
	// `<team>-pr-<n>`) with these quotas; the platform team has none.
	tenant: *true | bool
	if tenant {
		// Quotas come from a size; single values can be overridden (platform review).
		size: *"small" | "medium" | "large"
		quota: {
			for env, q in #Sizes[size] {
				(env): {for k, v in q {(k): *v | #Quantity}}
			}
		}
	}
}

#Envs: ["preview", "staging", "prod"]

#App: {
	name!:        =~"^[a-z][a-z0-9-]{1,40}$"
	team!:        string
	description!: string & !=""
	repo:         *"homelab-selfuryon/\(name)" | =~"^homelab-selfuryon/[a-z][a-z0-9-]{1,40}$"
	tier:         *"tier-3" | "tier-2" | "tier-1"
	lifecycle:    *"active" | "experimental" | "deprecated"
	envs:         *#Envs | [...or(#Envs)]
	cluster:      *"alpha-01" | string
	// Previews: an environment per pull request.
	preview: list.Contains(envs, "preview")
}

#Quantity: =~"^[0-9]+(\\.[0-9]+)?(m|Ki|Mi|Gi|Ti)?$"

#Quota: {
	requestsCPU:            #Quantity
	requestsMemory:         #Quantity
	limitsMemory:           #Quantity
	pods:                   #Quantity
	persistentVolumeClaims: #Quantity
	requestsStorage:        #Quantity
}

// Quota sizes per environment. `small` is what the notes team was onboarded with.
#Sizes: [string]: [or(#Envs)]: #Quota
#Sizes: {
	small: {
		staging: {requestsCPU: "2", requestsMemory: "2Gi", limitsMemory: "4Gi", pods: "20", persistentVolumeClaims: "4", requestsStorage: "20Gi"}
		prod:    {requestsCPU: "4", requestsMemory: "4Gi", limitsMemory: "8Gi", pods: "30", persistentVolumeClaims: "4", requestsStorage: "20Gi"}
		preview: {requestsCPU: "500m", requestsMemory: "512Mi", limitsMemory: "1Gi", pods: "8", persistentVolumeClaims: "2", requestsStorage: "4Gi"}
	}
	medium: {
		staging: {requestsCPU: "4", requestsMemory: "4Gi", limitsMemory: "8Gi", pods: "40", persistentVolumeClaims: "8", requestsStorage: "40Gi"}
		prod:    {requestsCPU: "8", requestsMemory: "8Gi", limitsMemory: "16Gi", pods: "60", persistentVolumeClaims: "8", requestsStorage: "40Gi"}
		preview: {requestsCPU: "1", requestsMemory: "1Gi", limitsMemory: "2Gi", pods: "16", persistentVolumeClaims: "4", requestsStorage: "8Gi"}
	}
	large: {
		staging: {requestsCPU: "8", requestsMemory: "8Gi", limitsMemory: "16Gi", pods: "80", persistentVolumeClaims: "16", requestsStorage: "80Gi"}
		prod:    {requestsCPU: "16", requestsMemory: "16Gi", limitsMemory: "32Gi", pods: "120", persistentVolumeClaims: "16", requestsStorage: "80Gi"}
		preview: {requestsCPU: "2", requestsMemory: "2Gi", limitsMemory: "4Gi", pods: "32", persistentVolumeClaims: "8", requestsStorage: "16Gi"}
	}
}
