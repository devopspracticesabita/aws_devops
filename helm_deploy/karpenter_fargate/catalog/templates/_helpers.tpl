{{- define "catalog.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "catalog.fullname" -}}
{{ printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "catalog.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: service
app.kubernetes.io/owner: retail-store-sample
app.kubernetes.io/managed-by: Helm
{{- end }}