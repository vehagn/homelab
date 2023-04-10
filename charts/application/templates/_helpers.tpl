{{/*
Common labels
*/}}
{{- define "common.labels" -}}
app.kubernetes.io/name: {{ .Values.name }}
{{- with .Values.additionalLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "common.annotations" -}}
{{- with .Values.annotations }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Returns string "true" or empty which will be evaluated to boolean false
*/}}
{{- define "deployment.create" -}}
{{- if not .Values.authOnly }}
{{- true }}
{{- end }}
{{- end }}

{{/*
Returns string "true" or empty which will be evaluated to boolean false
*/}}
{{- define "service.create" -}}
{{- if and .Values.service.create (include "deployment.create" .) }}
{{- true }}
{{- end }}
{{- end }}

{{/*
Returns string "true" or empty which will be evaluated to boolean false
*/}}
{{- define "ingressRoute.create" -}}
{{- if and .Values.ingressRoute.create (or .Values.authOnly (include "service.create" .)) }}
{{- true }}
{{- end }}
{{- end }}

{{/*
Returns string "true" or empty which will be evaluated to boolean false
*/}}
{{- define "auth.create" -}}
{{- if or .Values.authOnly (and .Values.auth.enabled .Values.auth.create (include "ingressRoute.create" .)) }}
{{- true }}
{{- end }}
{{- end }}