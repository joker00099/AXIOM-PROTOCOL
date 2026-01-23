# Axiom Protocol Monitoring Stack

Production-grade monitoring for Axiom Protocol using Prometheus and Grafana.

## Quick Start

### 1. Deploy monitoring stack

```bash
cd monitoring
docker-compose up -d
```

### 2. Access dashboards

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **AlertManager**: http://localhost:9093

### 3. Configure alerts

Edit `alertmanager.yml` to add your Slack webhook and email settings:

```bash
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
export SMTP_USERNAME="your-email@gmail.com"
export SMTP_PASSWORD="your-app-password"
```

Then restart:

```bash
docker-compose restart alertmanager
```

## Metrics Collected

### Node Metrics
- `axiom_block_height` - Current block height
- `axiom_blocks_total` - Total blocks mined
- `axiom_transactions_total` - Total transactions processed
- `axiom_peer_count` - Number of connected peers
- `axiom_vdf_duration_seconds` - VDF computation time
- `axiom_pow_duration_seconds` - PoW mining time

### Energy Metrics
- `axiom_energy_total_wh` - Total energy consumed (Watt-hours)
- `axiom_energy_per_block_wh` - Energy per block
- `axiom_energy_per_tx_wh` - Energy per transaction
- `axiom_carbon_total_kg` - Total carbon emissions

### Bridge Metrics
- `axiom_bridge_volume_axm` - Bridge volume in AXM
- `axiom_bridge_transactions_total` - Bridge transaction count
- `axiom_bridge_oracle_status` - Oracle health status

### System Metrics (Node Exporter)
- CPU usage
- Memory usage
- Disk usage
- Network I/O

## Alerts

The system monitors for:

- **Critical**: Node down, block production stalled
- **High**: Bridge oracle offline
- **Warning**: High resource usage, low peer count
- **Info**: Energy consumption spikes

## Customization

### Add custom metrics

Edit `prometheus.yml` to add more scrape targets:

```yaml
scrape_configs:
  - job_name: 'my-custom-exporter'
    static_configs:
      - targets: ['localhost:9999']
```

### Add custom alerts

Edit `alerts.yml`:

```yaml
- alert: MyCustomAlert
  expr: my_metric > 100
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "My custom alert"
```

## Production Deployment

For production, use environment variables:

```bash
# Set Grafana password
export GRAFANA_PASSWORD="strong-password-here"

# Deploy
docker-compose up -d
```

### SSL/TLS

For HTTPS access, add a reverse proxy (nginx/traefik) in front of Grafana:

```nginx
server {
    listen 443 ssl;
    server_name grafana.axiom.network;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
    }
}
```

## Troubleshooting

### View logs

```bash
docker-compose logs -f prometheus
docker-compose logs -f grafana
docker-compose logs -f alertmanager
```

### Restart services

```bash
docker-compose restart prometheus
docker-compose restart grafana
```

### Update configuration

After changing config files:

```bash
docker-compose restart prometheus
```

### Stop stack

```bash
docker-compose down
```

## Kubernetes Deployment

For Kubernetes, use Prometheus Operator:

```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```

## Support

- Documentation: https://docs.axiom.network/monitoring
- Discord: https://discord.gg/axiom
- GitHub Issues: https://github.com/Ghost-84M/Axiom-Protocol/issues
