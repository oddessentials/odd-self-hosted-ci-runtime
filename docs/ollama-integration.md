# Ollama Integration Guide

This guide covers integrating the Ollama LLM server with OSCR for local AI code review.

## Quick Start

```bash
# Start OSCR with Ollama sidecar
docker compose --profile github up -d

# Pre-pull the model (requires network)
docker exec oscr-ollama ollama pull codellama:7b
```

## Network Configuration

Ollama is accessible via two hostnames on the OSCR network:

| URL | Usage |
|-----|-------|
| `http://ollama:11434` | Service name (default) |
| `http://ollama-sidecar:11434` | Alias (odd-ai-reviewers default) |

Set `OLLAMA_BASE_URL` in your workflow secrets if you need to override.

## Model Requirements

| Model | RAM | Response Time |
|-------|-----|---------------|
| `codellama:7b` | 4GB | 30-90s |
| `deepseek-coder-v2:16b` | 8GB | 60-120s |
| `qwen2.5-coder:7b` | 4GB | 30-80s |

## Air-Gap Model Provisioning

For environments with no outbound internet access, models must be provisioned before blocking egress.

### Option 1: Pre-baked Volume (Recommended)

**On internet-connected host:**
```bash
# Start Ollama and pull model
docker run -d --name ollama-staging ollama/ollama:0.5.5
docker exec ollama-staging ollama pull codellama:7b

# Export the model data
docker cp ollama-staging:/root/.ollama ./ollama-data
tar czf ollama-models.tar.gz ollama-data/

# Cleanup
docker rm -f ollama-staging
```

**On air-gapped host:**
```bash
# Create the volume
docker volume create ollama-models

# Import the data
docker run --rm -v ollama-models:/root/.ollama -v $(pwd):/backup alpine \
  sh -c "cd /root/.ollama && tar xzf /backup/ollama-models.tar.gz --strip-components=1"

# Start OSCR (will use existing volume)
docker compose --profile github up -d
```

### Option 2: Modelfile Import

```bash
# On air-gapped host, copy the model file manually
docker exec oscr-ollama ollama create codellama:7b -f /path/to/Modelfile
```

> ⚠️ **Operator Note:** The `ollama-models` volume can be large (4-16GB per model). Treat this as an operator-managed artifact with appropriate backup/restore procedures.

## Version Pinning

| Component | Current Version | Notes |
|-----------|-----------------|-------|
| Ollama | `0.5.5` | Pinned in docker-compose.yml |
| codellama | `7b` | Pre-pull required |

## Troubleshooting

### "Cannot connect to Ollama"
1. Verify Ollama is running: `docker ps | grep ollama`
2. Check network: `docker exec <runner> curl -s http://ollama:11434/api/version`
3. Verify `OLLAMA_BASE_URL` secret is set correctly

### Model not found
1. Pre-pull required: `docker exec oscr-ollama ollama pull codellama:7b`
2. Check available: `docker exec oscr-ollama ollama list`
