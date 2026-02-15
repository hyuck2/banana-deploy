{{/*
Fullname: {appname}-{env}
*/}}
{{- define "common-chart.fullname" -}}
{{- printf "%s-%s" .Values.appname .Values.env | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "common-chart.labels" -}}
app.kubernetes.io/name: {{ .Values.appname }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/env: {{ .Values.env }}
helm.sh/chart: {{ .Chart.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "common-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ .Values.appname }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
