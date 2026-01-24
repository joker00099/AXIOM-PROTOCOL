#!/bin/bash
# AXIOM Protocol - Deploy All 5 Validators
# Automated deployment for complete validator network

set -e

echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║        AXIOM Protocol - Multi-Validator Deployment                   ║"
echo "║                  Deploy All 5 Mainnet Validators                      ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check system resources
echo -e "${YELLOW}Checking system resources...${NC}"
AVAILABLE_DISK=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
AVAILABLE_RAM=$(free -g | awk '/^Mem:/{print $7}')

echo -e "Available disk: ${AVAILABLE_DISK}GB"
echo -e "Available RAM: ${AVAILABLE_RAM}GB"
echo ""

if [ "$AVAILABLE_DISK" -lt 20 ]; then
    echo -e "${RED}✗ Insufficient disk space. Need 20GB+, have ${AVAILABLE_DISK}GB${NC}"
    exit 1
fi

if [ "$AVAILABLE_RAM" -lt 12 ]; then
    echo -e "${YELLOW}⚠ Low RAM (${AVAILABLE_RAM}GB). Recommended: 16GB+ for 5 validators${NC}"
    echo -e "Continue anyway? (y/n)"
    read -r CONTINUE
    if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
        exit 0
    fi
fi

# Build once
echo -e "${YELLOW}Building AXIOM Protocol...${NC}"
if [ ! -f "target/release/qubit" ]; then
    cargo build --release
fi
echo -e "${GREEN}✓ Build complete${NC}"
echo ""

# Validator configuration
declare -A VALIDATORS=(
    [1]="8545:8546:9100:axm1validator1"
    [2]="8546:8547:9101:axm1validator2"
    [3]="8547:8548:9102:axm1validator3"
    [4]="8548:8549:9103:axm1validator4"
    [5]="8549:8550:9104:axm1validator5"
)

echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║                    Deploying 5 Validators                             ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""

for i in {1..5}; do
    IFS=':' read -r P2P RPC METRICS ADDR <<< "${VALIDATORS[$i]}"
    
    echo -e "${YELLOW}═══ Deploying Validator $i/5 ═══${NC}"
    echo "  Name: axiom-validator-$i"
    echo "  P2P Port: $P2P"
    echo "  RPC Port: $RPC"
    echo "  Metrics: $METRICS"
    echo ""
    
    # Generate unique address
    VALIDATOR_ADDR="${ADDR}$(openssl rand -hex 20)"
    
    # Create validator directory
    VALIDATOR_DIR="./validator-$i"
    mkdir -p "$VALIDATOR_DIR"
    
    # Create validator config
    cat > "$VALIDATOR_DIR/axiom-validator-$i.toml" << EOF
# AXIOM Protocol - Validator $i Configuration
[node]
name = "axiom-validator-$i"
node_type = "full"
metrics_enabled = true

[network]
listen_address = "/ip4/0.0.0.0/tcp/$P2P"
bootstrap_peers = []
max_peers = 50
max_inbound_peers = 30
max_outbound_peers = 20
enable_mdns = true
enable_kademlia = true
connection_timeout = 30
gossip_heartbeat = 1
network_id = 1

[consensus]
vdf_steps = 3600000
pow_difficulty = 1000
block_time_seconds = 3600
difficulty_adjustment_interval = 2016
max_block_size = 1000000
max_transactions_per_block = 10000
min_transaction_fee = 100000000
confirmation_depth = 6

[mining]
enabled = true
threads = 2
miner_address = "$VALIDATOR_ADDR"
intensity = 80
min_peers_to_mine = 3

[storage]
data_dir = "$VALIDATOR_DIR/data"
cache_size_mb = 512
compression = true
pruning = "full"
max_db_size_gb = 10

[ai]
neural_guardian_enabled = true
threat_threshold = 0.7
model_update_interval = 86400
oracle_enabled = false
min_oracle_stake = 50000000000
oracle_consensus_threshold = 3

[rpc]
enabled = true
listen_address = "127.0.0.1:$RPC"
cors_allowed_origins = ["*"]
max_connections = 100
request_timeout = 30
websocket_enabled = true
rate_limit = 60

[logging]
level = "info"
file_enabled = true
log_file = "$VALIDATOR_DIR/validator-$i.log"
max_file_size_mb = 100
max_backups = 5
json_format = false
colored = true
EOF
    
    # Create data directory
    mkdir -p "$VALIDATOR_DIR/data"
    
    # Create start script
    cat > "$VALIDATOR_DIR/start-validator-$i.sh" << EOF
#!/bin/bash
cd "\$(dirname "\$0")/.."
./target/release/qubit --config validator-$i/axiom-validator-$i.toml
EOF
    chmod +x "$VALIDATOR_DIR/start-validator-$i.sh"
    
    # Save validator info
    echo "$VALIDATOR_ADDR" > "$VALIDATOR_DIR/address.txt"
    
    echo -e "${GREEN}✓ Validator $i configured${NC}"
    echo -e "${GREEN}  Address: $VALIDATOR_ADDR${NC}"
    echo ""
done

# Create master control script
cat > control-validators.sh << 'EOF'
#!/bin/bash
# Master control script for all validators

COMMAND=$1

case $COMMAND in
    start)
        echo "Starting all 5 validators..."
        for i in {1..5}; do
            echo "Starting validator $i..."
            nohup ./validator-$i/start-validator-$i.sh > validator-$i/output.log 2>&1 &
            echo $! > validator-$i/pid.txt
            sleep 2
        done
        echo "✓ All validators started"
        ;;
    
    stop)
        echo "Stopping all validators..."
        for i in {1..5}; do
            if [ -f "validator-$i/pid.txt" ]; then
                PID=$(cat validator-$i/pid.txt)
                if kill -0 $PID 2>/dev/null; then
                    kill -SIGTERM $PID
                    echo "✓ Stopped validator $i (PID: $PID)"
                else
                    echo "⚠ Validator $i not running"
                fi
                rm validator-$i/pid.txt
            fi
        done
        pkill -f "qubit.*validator"
        echo "✓ All validators stopped"
        ;;
    
    status)
        echo "Validator Status:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        for i in {1..5}; do
            if [ -f "validator-$i/pid.txt" ]; then
                PID=$(cat validator-$i/pid.txt)
                if kill -0 $PID 2>/dev/null; then
                    RPC_PORT=$((8545 + i))
                    PEERS=$(curl -s http://localhost:$RPC_PORT 2>/dev/null && echo "✓" || echo "✗")
                    echo "Validator $i: RUNNING (PID: $PID) RPC: $PEERS"
                else
                    echo "Validator $i: STOPPED"
                fi
            else
                echo "Validator $i: NOT STARTED"
            fi
        done
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        ;;
    
    logs)
        VALIDATOR=${2:-1}
        if [ -f "validator-$VALIDATOR/validator-$VALIDATOR.log" ]; then
            tail -f "validator-$VALIDATOR/validator-$VALIDATOR.log"
        else
            echo "Log file not found for validator $VALIDATOR"
        fi
        ;;
    
    restart)
        $0 stop
        sleep 3
        $0 start
        ;;
    
    *)
        echo "Usage: $0 {start|stop|status|logs [1-5]|restart}"
        echo ""
        echo "Commands:"
        echo "  start   - Start all 5 validators"
        echo "  stop    - Stop all validators gracefully"
        echo "  status  - Show status of all validators"
        echo "  logs N  - Tail logs for validator N (1-5)"
        echo "  restart - Stop and restart all validators"
        exit 1
        ;;
esac
EOF

chmod +x control-validators.sh

# Create network configuration file
cat > validator-network.json << EOF
{
  "network": "mainnet",
  "network_id": 1,
  "validators": [
    {
      "id": 1,
      "name": "axiom-validator-1",
      "p2p_port": 8545,
      "rpc_port": 8546,
      "metrics_port": 9100,
      "address": "$(cat validator-1/address.txt)"
    },
    {
      "id": 2,
      "name": "axiom-validator-2",
      "p2p_port": 8546,
      "rpc_port": 8547,
      "metrics_port": 9101,
      "address": "$(cat validator-2/address.txt)"
    },
    {
      "id": 3,
      "name": "axiom-validator-3",
      "p2p_port": 8547,
      "rpc_port": 8548,
      "metrics_port": 9102,
      "address": "$(cat validator-3/address.txt)"
    },
    {
      "id": 4,
      "name": "axiom-validator-4",
      "p2p_port": 8548,
      "rpc_port": 8549,
      "metrics_port": 9103,
      "address": "$(cat validator-4/address.txt)"
    },
    {
      "id": 5,
      "name": "axiom-validator-5",
      "p2p_port": 8549,
      "rpc_port": 8550,
      "metrics_port": 9104,
      "address": "$(cat validator-5/address.txt)"
    }
  ],
  "consensus": {
    "type": "byzantine-multisig",
    "threshold": "3-of-5",
    "quorum": 3
  }
}
EOF

# Create monitoring dashboard
cat > monitoring/prometheus/local-validators.yml << EOF
# Prometheus configuration for local validator cluster

global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'axiom-validators'
    static_configs:
      - targets:
        - 'localhost:9100'
        - 'localhost:9101'
        - 'localhost:9102'
        - 'localhost:9103'
        - 'localhost:9104'
        labels:
          cluster: 'local'
          network: 'mainnet'
EOF

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║                    ✅ DEPLOYMENT COMPLETE                             ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Successfully deployed 5 validators!${NC}"
echo ""
echo "Validator Details:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for i in {1..5}; do
    IFS=':' read -r P2P RPC METRICS ADDR <<< "${VALIDATORS[$i]}"
    FULL_ADDR=$(cat "validator-$i/address.txt")
    echo "Validator $i:"
    echo "  Directory: ./validator-$i/"
    echo "  Address: $FULL_ADDR"
    echo "  RPC: http://localhost:$RPC"
    echo "  Metrics: http://localhost:$METRICS"
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}Quick Commands:${NC}"
echo "  Start all:    ./control-validators.sh start"
echo "  Stop all:     ./control-validators.sh stop"
echo "  Check status: ./control-validators.sh status"
echo "  View logs:    ./control-validators.sh logs 1"
echo "  Restart all:  ./control-validators.sh restart"
echo ""
echo -e "${YELLOW}Configuration Files:${NC}"
echo "  Network config: validator-network.json"
echo "  Monitoring:     monitoring/prometheus/local-validators.yml"
echo ""
echo -e "${YELLOW}Monitoring:${NC}"
echo "  cd monitoring && docker-compose up -d"
echo "  Grafana: http://localhost:3000"
echo ""
echo -e "${GREEN}✨ Ready to start validating on AXIOM mainnet!${NC}"
echo ""
