# MathTrail Infrastructure Local

Local development infrastructure for the MathTrail platform.

## Prerequisites

- A running K3d cluster (managed by [mathtrail-infra-local-k3s](../mathtrail-infra-local-k3s))

## Quick Start

Open this repo in the devcontainer, then:

```bash
just deploy
```

This will:

1. Add the `mathtrail` Helm repo
2. Create the `mathtrail` namespace
3. Install services with local development values

To remove everything:

```bash
just uninstall
```

## Services

| Service    | Deployed via                | Namespace   | Access                                       |
|------------|-----------------------------|-------------|----------------------------------------------|
| PostgreSQL | Helm (`mathtrail/postgresql`)| `mathtrail` | `postgres-postgresql.mathtrail.svc:5432`     |
| Redis      | Helm (`mathtrail/redis`)     | `mathtrail` | `redis-master.mathtrail.svc:6379`            |
| Kafka      | Strimzi Operator + CR        | `mathtrail` | `kafka-kafka-bootstrap.mathtrail.svc:9092`   |

## Default Credentials

| Service    | Username    | Password    | Database    |
|------------|-------------|-------------|-------------|
| PostgreSQL | `mathtrail` | `mathtrail` | `mathtrail` |
| Redis      | —           | `mathtrail` | —           |
| Kafka      | —           | —           | PLAINTEXT   |

## Configuration

Local values files are in the [`values/`](values/) directory:

- [`postgresql-values.yaml`](values/postgresql-values.yaml) — standalone, 1Gi storage, nano resources
- [`redis-values.yaml`](values/redis-values.yaml) — standalone, 1Gi storage, nano resources
- [`strimzi-values.yaml`](values/strimzi-values.yaml) — Strimzi operator config
- [`kafka-cluster.yaml`](manifests/kafka-cluster.yaml) — single-node KRaft Kafka cluster CR, no TLS, 1Gi storage
