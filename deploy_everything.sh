#!/bin/bash

# Install kube2iam
helm upgrade --install --reset-values --namespace kube-system \
--set=extraArgs.base-role-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/,host.iptables=true,host.interface=weave,rbac.create=true \
kube2iam stable/kube2iam

# Install traefik-private
helm upgrade --install --reset-values --version 1.61.1 --namespace kube-system \
--values traefik/charts/traefik/traefik-private.yaml \
--set deployment.podAnnotations."iam\.amazonaws\.com/role"=k8s-${STACK_NAME}-TraefikIAMRole,dashboard.domain=traefik.private.k8s.${CLUSTER_NAME},service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-cert"=${K8S_PRIVATE_ACM_CERT_ARN} \
traefik-private stable/traefik

# Install traefik-public
helm upgrade --install --reset-values --version 1.61.1 --namespace kube-system \
--values traefik/charts/traefik/traefik-public.yaml \
--set deployment.podAnnotations."iam\.amazonaws\.com/role"=k8s-${STACK_NAME}-TraefikIAMRole,dashboard.domain=traefik.k8s.${CLUSTER_NAME},service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-cert"=${K8S_PUBLIC_ACM_CERT_ARN} \
--set service.annotations.\"service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert\"=${public_domain_certificate_arn} \
traefik-public stable/traefik

# Install monitoring
helm upgrade --install --reset-values --version 9.2.0 --namespace kube-monitoring \
--values monitoring/charts/prometheus/values.yaml \
--set "alertmanager.ingress.hosts={alertmanager.private.k8s.${CLUSTER_NAME}}" \
--set "pushgateway.ingress.hosts={pushgateway.private.k8s.${CLUSTER_NAME}}" \
--set "server.ingress.hosts={prometheus.private.k8s.${CLUSTER_NAME}}" \
prometheus stable/prometheus

# Install grafana
helm upgrade --install --reset-values --version 4.0.0 --namespace kube-monitoring \
--values monitoring/charts/grafana/values.yaml \
--set "ingress.hosts={grafana.private.k8s.${CLUSTER_NAME}}" \
grafana stable/grafana

# Install cluster-autoscaler
helm upgrade --install --reset-values \
    --version 3.2.0 --namespace kube-system \
    cluster-autoscaler stable/cluster-autoscaler \
    --set autoDiscovery.clusterName=${CLUSTER_NAME}  \
    --values cluster-autoscaler/charts/values.yaml
