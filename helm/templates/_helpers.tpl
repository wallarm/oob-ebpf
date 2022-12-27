{{/*
Expand the name of the chart.
*/}}
{{- define "wallarm-oob.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "wallarm-oob.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name for Processing Unit
*/}}
{{- define "processing.fullname" }}
{{- printf "%s-processing" (include "wallarm-oob.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create the name for Aggregation Unit
*/}}
{{- define "aggregation.fullname" }}
{{- printf "%s-aggregation" (include "wallarm-oob.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create the name for Aggregation Unit
*/}}
{{- define "agent.fullname" }}
{{- printf "%s-agent" (include "wallarm-oob.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create the name for shared secret
*/}}
{{- define "wallarm-oob.sharedSecretName" }}
{{- printf "%s-credentials" (include "wallarm-oob.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create the name of the service account for Processing Unit
*/}}
{{- define "processing.serviceAccountName" -}}
{{- if .Values.processing.serviceAccount.name -}}
{{- .Values.processing.serviceAccount.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{ template "processing.fullname" . }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account for Aggregation Unit
*/}}
{{- define "aggregation.serviceAccountName" -}}
{{- if .Values.aggregation.serviceAccount.name -}}
{{- .Values.aggregation.serviceAccount.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{ template "aggregation.fullname" . }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account for Aggregation Unit
*/}}
{{- define "agent.serviceAccountName" -}}
{{- if .Values.aggregation.serviceAccount.name -}}
{{- .Values.aggregation.serviceAccount.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{ template "agent.fullname" . }}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "wallarm-oob.labels" -}}
helm.sh/chart: {{ .Chart.Name | quote }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
{{- if .Values.extraLabels }}
{{ toYaml .Values.extraLabels }}
{{- end }}
{{- end -}}

{{/*
Common annotations
*/}}
{{- define "wallarm-oob.annotations" -}}
{{- if .Values.extraAnnotations -}}
{{- toYaml .Values.extraAnnotations -}}
{{- end -}}
{{- end -}}

{{/*
Annotations for Processing Unit
*/}}
{{- define "processing.annotations" -}}
{{ template "wallarm-oob.annotations" . }}
{{- if .Values.processing.extraAnnotations }}
{{ toYaml .Values.processing.extraAnnotations }}
{{- end }}
{{- end -}}

{{/*
Annotations for Aggregation Unit
*/}}
{{- define "aggregation.annotations" -}}
{{ template "wallarm-oob.annotations" . }}
{{- if .Values.aggregation.extraAnnotations }}
{{ toYaml .Values.aggregation.extraAnnotations }}
{{- end }}
{{- end -}}

{{/*
Annotations for Agent Unit
*/}}
{{- define "agent.annotations" -}}
{{ template "wallarm-oob.annotations" . }}
{{- if .Values.agent.extraAnnotations }}
{{ toYaml .Values.agent.extraAnnotations }}
{{- end }}
{{- end -}}

{{/*
Labels for Processing Unit
*/}}
{{- define "processing.labels" -}}
{{ template "wallarm-oob.labels" . }}
{{ template "processing.selectorLabels" . }}
{{- if .Values.processing.extraLabels }}
{{ toYaml .Values.processing.extraLabels }}
{{- end }}
{{- end -}}

{{/*
Labels for Aggregation Unit
*/}}
{{- define "aggregation.labels" -}}
{{ template "wallarm-oob.labels" . }}
{{ template "aggregation.selectorLabels" . }}
{{- if .Values.aggregation.extraLabels }}
{{ toYaml .Values.aggregation.extraLabels }}
{{- end }}
{{- end -}}

{{/*
Labels for Agent Unit
*/}}
{{- define "agent.labels" -}}
{{ template "wallarm-oob.labels" . }}
{{ template "agent.selectorLabels" . }}
{{- if .Values.agent.extraLabels }}
{{ toYaml .Values.agent.extraLabels }}
{{- end }}
{{- end -}}

{{/*
Selector labels for Processing Unit
*/}}
{{- define "processing.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wallarm-oob.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/component: "processing"
{{- end -}}

{{/*
Selector labels for Aggregation Unit
*/}}
{{- define "aggregation.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wallarm-oob.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/component: "aggregation"
{{- end -}}

{{/*
Selector labels for Aggregation Unit
*/}}
{{- define "agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wallarm-oob.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/component: "agent"
{{- end -}}

{{/*
Docker image name
*/}}
{{- define "image" -}}
{{- if .fullname -}}
{{- printf "%s" .fullname -}}
{{- else -}}
{{- if .registry -}}
{{- printf "%s/%s:%s" .registry .name .tag -}}
{{- else -}}
{{- printf "%s:%s" .name .tag -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{- define "wallarm-oob.credentials" -}}
- name: WALLARM_API_HOST
  valueFrom:
    secretKeyRef:
      key: WALLARM_API_HOST
      name: {{ template "wallarm-oob.sharedSecretName" . }}
- name: WALLARM_API_PORT
  valueFrom:
    secretKeyRef:
      key: WALLARM_API_PORT
      name: {{ template "wallarm-oob.sharedSecretName" . }}
- name: WALLARM_API_USE_SSL
  valueFrom:
    secretKeyRef:
      key: WALLARM_API_USE_SSL
      name: {{ template "wallarm-oob.sharedSecretName" . }}
- name: WALLARM_API_TOKEN
  valueFrom:
    secretKeyRef:
      key: WALLARM_API_TOKEN
      name: {{ template "wallarm-oob.sharedSecretName" . }}
- name: WALLARM_NODE_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: WALLARM_SYNCNODE_OWNER
  value: www-data
- name: WALLARM_SYNCNODE_GROUP
  value: www-data
{{- end -}}


{{/*
Default SecurityContext
*/}}
{{- define "wallarm-oob.defaultSecurityContext"}}
privileged: false
runAsUser: 101
allowPrivilegeEscalation: false
capabilities:
  drop:
  - ALL
{{- end }}

{{/*
Node SecurityContext
*/}}
{{- define "wallarm-oob.serviceSecurityContext" -}}
privileged: false
runAsUser: 101
allowPrivilegeEscalation: false
capabilities:
  drop:
    - ALL
  add:
    - NET_BIND_SERVICE
{{- end }}

{{/*
Agent SecurityContext
*/}}
{{- define "wallarm-oob.agentSecurityContext" -}}
privileged: true
runAsUser: 0
capabilities:
  add:
    - SYS_ADMIN
    - SYS_PTRACE
{{- end }}