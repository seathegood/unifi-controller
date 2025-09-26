# UniFi Network Controller Container

A production-ready Docker image for the UniFi Network Application, packaged on Debian Bookworm with automated release management and seamless Docker Hub publishing.

---

## Overview
This project bundles the UniFi Network Application in a hardened, multi-stage container image. The final runtime stage is based on **Debian Bookworm**, giving you an up-to-date security baseline while keeping full compatibility with UniFi’s official `.deb` packages. The controller is deliberately separated from MongoDB—run them as individual services for maximum flexibility and observability.

---

## Image Highlights
- **Bookworm runtime** – fresh security patches and long-term support.
- **Multi-architecture builds** – published for both `linux/amd64` and `linux/arm64`.
- **External MongoDB** – connect to your own database instance (`mongo:7` works out of the box).
- **Automated upgrade flow** – scheduled GitHub Actions detect new UniFi releases, open PRs, run tests, and publish to Docker Hub.
- **Auto-synced documentation** – this README is pushed to Docker Hub whenever it changes.

---

## Quick Start (Docker CLI)
```bash
docker run -d \
  --name unifi-controller \
  --hostname unifi \
  -p 3478:3478/udp \
  -p 8080:8080/tcp \
  -p 8443:8443/tcp \
  -p 8880:8880/tcp \
  -p 8843:8843/tcp \
  -p 6789:6789/tcp \
  -p 27117:27117/tcp \
  -p 10001:10001/udp \
  -p 1900:1900/udp \
  -p 123:123/udp \
  -e TZ=America/Chicago \
  -e DB_MONGO_LOCAL=false \
  -e DB_MONGO_URI=mongodb://mongo:27017/unifi \
  -e STATDB_MONGO_URI=mongodb://mongo:27017/unifi_stat \
  -v $(pwd)/unifi/cert:/usr/lib/unifi/cert \
  -v $(pwd)/unifi/data:/usr/lib/unifi/data \
  -v $(pwd)/unifi/logs:/usr/lib/unifi/logs \
  seathegood/unifi-controller:latest
```

---

## Docker Compose Example
```yaml
services:
  mongo:
    image: mongo:7.0
    command: --wiredTigerCacheSizeGB 1
    volumes:
      - ./mongo/data/db:/data/db
    restart: unless-stopped

  unifi-controller:
    image: seathegood/unifi-controller:latest
    pull_policy: never
    hostname: unifi
    domainname: example.local
    ports:
      - "3478:3478/udp"
      - "8080:8080/tcp"
      - "8443:8443/tcp"
      - "8880:8880/tcp"
      - "8843:8843/tcp"
      - "6789:6789/tcp"
      - "27117:27117/tcp"
      - "10001:10001/udp"
      - "1900:1900/udp"
      - "123:123/udp"
    environment:
      DB_MONGO_LOCAL: "false"
      DB_MONGO_URI: mongodb://mongo:27017/unifi
      STATDB_MONGO_URI: mongodb://mongo:27017/unifi_stat
      TZ: America/Chicago
    volumes:
      - ./unifi/cert:/usr/lib/unifi/cert
      - ./unifi/data:/usr/lib/unifi/data
      - ./unifi/logs:/usr/lib/unifi/logs
    depends_on:
      - mongo
    restart: unless-stopped
```

---

## Kubernetes Deployment (excerpt)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: unifi-controller
spec:
  replicas: 1
  selector:
    matchLabels:
      app: unifi-controller
  template:
    metadata:
      labels:
        app: unifi-controller
    spec:
      containers:
        - name: unifi-controller
          image: seathegood/unifi-controller:latest
          ports:
            - containerPort: 8443
              name: https
            - containerPort: 8080
              name: inform
            - containerPort: 3478
              protocol: UDP
              name: stun
          env:
            - name: DB_MONGO_LOCAL
              value: "false"
            - name: DB_MONGO_URI
              value: mongodb://mongo.default.svc.cluster.local:27017/unifi
            - name: STATDB_MONGO_URI
              value: mongodb://mongo.default.svc.cluster.local:27017/unifi_stat
            - name: TZ
              value: America/Chicago
          volumeMounts:
            - name: unifi-data
              mountPath: /usr/lib/unifi/data
            - name: unifi-logs
              mountPath: /usr/lib/unifi/logs
      volumes:
        - name: unifi-data
          persistentVolumeClaim:
            claimName: unifi-data
        - name: unifi-logs
          persistentVolumeClaim:
            claimName: unifi-logs
```
_Expose the required ports using a `Service` (typically `LoadBalancer` or `NodePort`). MongoDB can be provided by operators such as Bitnami’s chart or an external managed instance._

---

## Configuration Reference
| Variable | Default | Description |
| --- | --- | --- |
| `DB_MONGO_LOCAL` | `false` | Set to `true` to run the legacy in-container MongoDB (not recommended). |
| `DB_MONGO_URI` | `mongodb://mongo:27017/unifi` | Primary MongoDB connection string for controller data. |
| `STATDB_MONGO_URI` | `mongodb://mongo:27017/unifi_stat` | MongoDB URI for stat collections. |
| `TZ` | `UTC` | Timezone for log timestamps. |
| `UNIFI_DB_NAME` | `unifi` | Database name used by the controller. |

**Volumes**
- `/usr/lib/unifi/cert` – place `privkey.pem` and `fullchain.pem` for custom TLS.
- `/usr/lib/unifi/data` – controller config and backups (persist this!).
- `/usr/lib/unifi/logs` – application logs.

**Ports** (all must be reachable by devices/clients)
- UDP: `3478`, `10001`, `1900`, `123`
- TCP: `8080`, `8443`, `8880`, `8843`, `6789`, `27117`

---

## Automated Release Pipeline
1. **Daily upstream scan** – `Check for Upstream UniFi Version` queries the UniFi community GraphQL API.
2. **Auto PR** – when a new GA version appears, a branch `unifi-update-<version>` is created with updated `Dockerfile`, `versions.txt`, and release notes.
3. **Build & smoke tests** – multi-arch build, Hadolint linting, and an amd64 runtime test run on GitHub Actions.
4. **Auto approval & merge** – once checks pass, the PR is approved and merged automatically in the upstream repo.
5. **Tag & publish** – a follow-up workflow creates a GitHub release, pushes `seathegood/unifi-controller:<version>` and `latest` to Docker Hub, and syncs this README.

---

## Support & Contributions
Issues and PRs are welcome! Please:
- Provide detailed reproduction steps and logs for issues.
- Follow existing code style and add tests or documentation for new features.
- Use the Discussions tab for general questions.

---

## License
MIT License – see [`LICENSE`](LICENSE) for details.

