# Linux One-Click Start

Run in project root:

```bash
chmod +x start_all.sh stop_all.sh
./start_all.sh
```

After startup:

- Frontend: <http://localhost:8080>
- Consul: <http://localhost:8500>

Generated files:

- Logs: `tmp/logs`
- PIDs: `tmp/pids`

Stop everything:

```bash
./stop_all.sh
```

Stop only Go services and keep Docker containers:

```bash
./stop_all.sh --keep-docker
```

Useful start options:

```bash
./start_all.sh --only-infra
./start_all.sh --skip-docker
./start_all.sh --skip-init --skip-product-init
```

Useful stop options:

```bash
./stop_all.sh --no-force
```
