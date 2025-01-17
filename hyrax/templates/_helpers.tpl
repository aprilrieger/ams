{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "hyrax.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "hyrax.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "hyrax.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "hyrax.labels" -}}
helm.sh/chart: {{ include "hyrax.chart" . }}
{{ include "hyrax.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "hyrax.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hyrax.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Worker Selector labels
*/}}
{{- define "hyrax.workerSelectorLabels" -}}
app.kubernetes.io/name: {{ include "hyrax.name" . }}-worker
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "hyrax.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "hyrax.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create default fully qualified service names.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "hyrax.fcrepo.fullname" -}}
{{- printf "%s-%s" .Release.Name "fcrepo" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hyrax.fcrepo.host" -}}
{{- if .Values.fcrepo.enabled }}
{{- include "hyrax.fcrepo.fullname" . }}
{{- else }}
{{- .Values.externalFcrepoHost | default "NO_FCREPO_HOST_DEFINED" }}
{{- end }}
{{- end -}}

{{- define "hyrax.memcached.fullname" -}}
{{- printf "%s-%s" .Release.Name "memcached" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hyrax.minio.fullname" -}}
{{- printf "%s-%s" .Release.Name "minio" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hyrax.mariadb.fullname" -}}
{{- printf "%s-%s" .Release.Name "mariadb" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hyrax.mariadb.host" -}}
{{- if .Values.mariadb.enabled }}
{{- include "hyrax.mariadb.fullname" . }}
{{- else }}
{{- .Values.externalMariadb.db.host }}
{{- end }}
{{- end -}}

{{- define "hyrax.mariadb.database" -}}
{{- if .Values.mariadb.enabled }}
{{- .Values.mariadb.auth.database }}
{{- else }}
{{- .Values.externalMariadb.auth.database | default ( include "hyrax.fullname" . ) }}
{{- end }}
{{- end -}}

{{- define "hyrax.mariadb.username" -}}
{{- if .Values.mariadb.enabled }}
{{- .Values.mariadb.auth.username }}
{{- else }}
{{- .Values.externalMariadb.auth.username | default "mysql" }}
{{- end }}
{{- end -}}

{{- define "hyrax.mariadb.password" -}}
{{- if .Values.mariadb.enabled }}
{{- .Values.mariadb.auth.password }}
{{- else }}
{{- .Values.externalMariadb.auth.password }}
{{- end }}
{{- end -}}

{{- define "hyrax.redis.fullname" -}}
{{- printf "%s-%s" .Release.Name "redis" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "hyrax.solr.fullname" -}}
{{- printf "%s-%s" .Release.Name "solr" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hyrax.solr.host" -}}
{{- if .Values.solr.enabled }}
{{- include "hyrax.solr.fullname" . }}
{{- else }}
{{- .Values.externalSolrHost }}
{{- end }}
{{- end -}}

{{- define "hyrax.solr.collectionName" -}}
{{- if .Values.solr.enabled }}
{{- .Values.solr.collection | default "hyrax" }}
{{- else }}
{{- .Values.externalSolrCollection | default "hyrax" }}
{{- end }}
{{- end -}}

{{- define "hyrax.solr.username" -}}
{{- if .Values.solr.enabled }}
{{- .Values.solr.authentication.adminUsername }}
{{- else }}
{{- .Values.externalSolrUser }}
{{- end }}
{{- end -}}

{{- define "hyrax.solr.password" -}}
{{- if .Values.solr.enabled }}
{{- .Values.solr.authentication.adminPassword }}
{{- else }}
{{- .Values.externalSolrPassword }}
{{- end }}
{{- end -}}

{{- define "hyrax.solr.port" -}}
{{- .Values.externalSolrPort | default "8983" }}
{{- end -}}

{{- define "hyrax.solr.url" -}}
{{- printf "http://%s:%s@%s:%s/solr/%s" (include "hyrax.solr.username" .) (include "hyrax.solr.password" .) (include "hyrax.solr.host" .) (include "hyrax.solr.port" .) (include "hyrax.solr.collectionName" .)  -}}
{{- end -}}

{{- define "hyrax.zk.fullname" -}}
{{- printf "%s-%s" .Release.Name "zookeeper" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hyrax.redis.host" -}}
{{- printf "%s-master" (include "hyrax.redis.fullname" .) -}}
{{- end -}}

{{- define "hyrax.redis.url" -}}
{{- printf "redis://:%s@%s:%s" .Values.redis.password (include "hyrax.redis.host" .) "6379/0" -}}
{{- end -}}

{{- define "hyrax.nginx.host" -}}
{{- printf "%s-%s" .Release.Name "nginx" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hyrax.sharedPvcAccessModes" -}}
{{- if .Values.worker.enabled }}
accessModes:
  - ReadWriteMany
{{- else }}
accessModes:
  - ReadWriteOnce
{{- end }}
{{- end -}}
