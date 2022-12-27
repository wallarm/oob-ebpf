{{- define "podDisruptionBudget.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "policy/v1/PodDisruptionBudget" -}}
{{- print "policy/v1" -}}
{{- else -}}
{{- print "policy/v1beta1" -}}
{{- end -}}
{{- end -}}

{{- define "cronJob.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "batch/v1/CronJob" -}}
{{- print "batch/v1" -}}
{{- else -}}
{{- print "batch/v1beta1" -}}
{{- end -}}
{{- end -}}

{{- define "role.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "rbac.authorization.k8s.io/v1/Role" -}}
{{- print "rbac.authorization.k8s.io/v1" -}}
{{- else -}}
{{- if .Capabilities.APIVersions.Has "rbac.authorization.k8s.io/v1beta1/Role" -}}
{{- print "rbac.authorization.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "rbac.authorization.k8s.io/v1alpha1" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "roleBinding.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "rbac.authorization.k8s.io/v1/RoleBinding" -}}
{{- print "rbac.authorization.k8s.io/v1" -}}
{{- else -}}
{{- if .Capabilities.APIVersions.Has "rbac.authorization.k8s.io/v1beta1/RoleBinding" -}}
{{- print "rbac.authorization.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "rbac.authorization.k8s.io/v1alpha1" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "ingress.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "networking.k8s.io/v1/Ingress" -}}
{{- print "networking.k8s.io/v1" -}}
{{- else -}}
{{- if .Capabilities.APIVersions.Has "networking.k8s.io/v1beta1/Ingress" -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "extensions/v1beta1" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for HorizontalPodAutoscaler kind of objects.
*/}}
{{- define "horizontalPodAutoscaler.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "autoscaling/v2/HorizontalPodAutoscaler" -}}
{{- print "autoscaling/v2" -}}
{{- else -}}
{{- if .Capabilities.APIVersions.Has "autoscaling/v2beta2/HorizontalPodAutoscaler" -}}
{{- print "autoscaling/v2beta2" -}}
{{- else -}}
{{- print "autoscaling/v2beta1" -}}
{{- end -}}
{{- end -}}
{{- end -}}
