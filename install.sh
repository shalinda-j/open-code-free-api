#!/usr/bin/env bash
set -euo pipefail

PROVIDER_NAME="free-model"
BASE_URL="${FREE_MODEL_BASE_URL:-http://localhost:8080/v1}"
API_KEY="${FREE_MODEL_API_KEY:-free}"
TARGET="${1:-opencode.json}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Free Model provider for OpenCode"
echo "    Endpoint: $BASE_URL"
echo "    Target:   $TARGET"

if MODELS_JSON="$(curl -sf --max-time 10 "$BASE_URL/models" || true)"; then
  SERVER_MODELS="$(printf '%s' "$MODELS_JSON" | node -e '
    let s = ""; process.stdin.on("data", d => s += d).on("end", () => {
      try { (JSON.parse(s).data || []).forEach(m => console.log(m.id)); } catch {}
    });' | tr "\n" " ")"
  if [ -n "$SERVER_MODELS" ]; then
    echo "    Found $(printf '%s' "$SERVER_MODELS" | tr " " "\n" | grep -c .) model(s) on server"
  fi
else
  echo "    Warning: server not reachable, using bundled model list"
fi

export PROVIDER_NAME BASE_URL API_KEY ROOT_DIR TARGET SERVER_MODELS_STR="$SERVER_MODELS"

node <<'NODE'
const fs = require("fs");
const path = require("path");

const [providerName, baseUrl, apiKey, rootDir, target] = [
  process.env.PROVIDER_NAME,
  process.env.BASE_URL,
  process.env.API_KEY,
  process.env.ROOT_DIR,
  path.resolve(process.env.TARGET || "opencode.json"),
];

const serverModels = (process.env.SERVER_MODELS_STR || "").trim().split(/\s+/).filter(Boolean);
let bundledModels = [];
try { bundledModels = JSON.parse(fs.readFileSync(path.join(rootDir, "models.json"), "utf8")); } catch {}
const modelIds = serverModels.length ? serverModels : bundledModels;

const models = {};
for (const id of modelIds) {
  models[id] = { name: id };
}

const provider = {
  [providerName]: {
    npm: "@ai-sdk/openai-compatible",
    name: "Free Model",
    options: { apiKey, baseURL: baseUrl },
    models,
  },
};

let config = {};
if (fs.existsSync(target)) {
  try { config = JSON.parse(fs.readFileSync(target, "utf8")); } catch (e) {
    console.error(`Error: ${target} is not valid JSON`); process.exit(1);
  }
}
config.provider = { ...(config.provider || {}), ...provider };
fs.writeFileSync(target, JSON.stringify(config, null, 2) + "\n");
console.log(`==> Installed "${providerName}" provider with ${modelIds.length} model(s) into ${target}`);
NODE

echo
echo "Done. Restart OpenCode (or start it in this directory) and select"
echo "a model from the "${PROVIDER_NAME}" provider in the model picker."
echo
echo "Tip: set FREE_MODEL_BASE_URL / FREE_MODEL_API_KEY env vars before"
echo "installing to configure a different endpoint or key."
