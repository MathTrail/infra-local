# MathTrail Infrastructure Local

Local development infrastructure for the MathTrail platform. Deploys services into a K3d Kubernetes cluster using Helm charts from the [mathtrail-charts](https://github.com/RyazanovAlexander/mathtrail-charts) repository.

## Prerequisites

- A running K3d cluster (see [mathtrail-infra-local devcontainer](.devcontainer/devcontainer.json) or create one on the host)

## Quick Start

Open this repo in the devcontainer, then:

```bash
just deploy
```

To remove everything:

```bash
just uninstall
```

## Services

| Service    | Chart                  | Namespace   | Access                          |
|------------|------------------------|-------------|---------------------------------|
| PostgreSQL | `mathtrail/postgresql` | `mathtrail` | `postgres.mathtrail.svc:5432`   |
| Redis      | `mathtrail/redis`      | `mathtrail` | `redis-master.mathtrail.svc:6379` |
| Kafka      | `mathtrail/kafka`      | `mathtrail` | `kafka.mathtrail.svc:9092`      |

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
- [`kafka-values.yaml`](values/kafka-values.yaml) — KRaft mode (no ZooKeeper), single controller, PLAINTEXT listeners, 1Gi storage
