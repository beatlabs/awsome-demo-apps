# EXTERNAL DNS

External-dns (https://github.com/kubernetes-incubator/external-dns) lets you configure DNS entries
for your Kubernetes LoadBalancers.

The way it works is that it uses either aws creds or a role (through kube2iam in our case) and connects
to our Route53 hosted zones.

In our case it is configured to parse Services of type LoadBalancer for appropriate annotations.
It then will create 2 records in Route53, one Alias to the LoadBalancer and one TXT record. This one
is used for syncing, i.e. when a service is deleted in Kubernetes it will delete the Record. It then will 
parse those TXT records to see that it was actually created by itself and will not mess up with irreleveant entries.

## TL;DR

For each stack we have to do the following (this is what Jenkins does behind the scenes):
```bash
helm upgrade --install --reset-values --namespace kube-system --version 1.6.1 \
    -f values.yaml \
    --set podAnnotations."iam\.amazonaws\.com/role=${EXTERNAL_DNS_ROLE}" \
    --set "zoneIdFilters[0]"="${PUBLIC_DOMAIN_ZONE_ID}" \
    --wait external-dns stable/external-dns

```

**EXTERNAL_DNS_ROLE** and **PUBLIC_DOMAIN_ZONE_ID** are outputs of terraform for each stack. Jenkins does that behind the scenes, but if you want to manually get them you have to run the following in the stacks folder of our terraform repo:
```bash
export EXTERNAL_DNS_ROLE=$(terraform output k8s_externaldns_k8s_role_name)
export PUBLIC_DOMAIN_ZONE_ID=$(terraform output public_domain_zone_id)
```

You now can create the following kubernetes service with type LoadBalancer:
```
kind: Service
apiVersion: v1
metadata:
  annotations:
    external-dns.alpha.kubernetes.io/hostname: "testy2.sandbox.thebeat.co."
  name: demo-app-public
spec:
  selector:
    app: demo
  type: LoadBalancer
  ports:
  - name: http
    port: 80
    targetPort: 5000
```

**IMPORTANT**: Do not use the same URL schemas as the ones used by traefik.

## IAM Policies used

The IAM Policy that needs to be used is:
```
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": [
       "route53:ChangeResourceRecordSets"
     ],
     "Resource": [
       "arn:aws:route53:::hostedzone/*"
     ]
   },
   {
     "Effect": "Allow",
     "Action": [
       "route53:ListHostedZones",
       "route53:ListResourceRecordSets"
     ],
     "Resource": [
       "*"
     ]
   }
 ]
}
```

We then create a role for each stack (e.g. external-dns.${CLUSTER_NAME}).
This role can be assumed only by the nodes in our Autoscaling Group. This is achieved here:
```
        "Principal": {
          "AWS": "${var.kubernetes_worker_principal}"
        },

```

## Configuration options

Here we will break down some important configuration options found in `values.yaml`.

- **registry**: This can be either `txt` or `noop`. If txt, then alongside the A record it will also create a txt record. If you want to enable syncing (see below), this has to be set to `txt`. If `noop` it will just create the A record.
- **policy**: This can be either `sync` or `upsert-only`. If `upsert-only` is set, then external-dns will only create records and it will not try to delete one if needed. Syncing will actually delete records created by external-dns but the `registry` option (see above) has to be set to `txt`.
- **zoneIdFilters**: Be default external-dns will list for changes in all available zones, which is not the best case for us. This options let's you set a list of zone ids and it will only look there. In our case we set the zone id for the `<stack>.thebeat.co` zone. This is achieved during helm install: `--set "zoneIdFilters[0]"="${PUBLIC_DOMAIN_ZONE_ID}"`.
- **sources**: External-dns can watch for annotations for both kubernetes `services` and `ingress` instances. In our case we only want to watch for `services` since our ingress is handled by traefik (which is actually instant as the wildcard dns entry is already there).
- **interval**: The interval between two consecutive synchronizations in duration format. By default it is set to `1m`. We have to monitor this closely, since there is a case where may hit Route53 quota. In this case we may have to bump this up, with the tradeoff of DNS entries of newly created LoadBalancer taking longer to actually appear.

## Gotchas

There is an annotation of setting up the ttl of the DNS entry `external-dns.alpha.kubernetes.io/ttl: "60"`. However with our use case with Route53 where the dns entries are an ALIAS to the internal LoadBalancer this seems to be discarded.

Also you should consider the fact that external-dns gets triggered every 1m (or otherwise according to `interval`). This means that creation/deletion of records could take some minutes to get triggered.