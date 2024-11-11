#!/usr/bin/env bash
set -euo pipefail

pids=()

generate_litellm_model() {
	model="$1"
	key_env="$2"

	if [[ -n "${!key_env:-}" ]]; then
		>&2 echo "[!] Found key ${key_env} for ${provider}"
		cat <<EOF
- model_name: "${model}"
  litellm_params:
    model: "${model}"
    api_key: "os.environ/${key_env}"
EOF
	fi
}

generate_litellm_provider() {
	provider="$1"
	key_env="$2"

	generate_litellm_model "${provider}/*" "${key_env}"
}

generate_litellm_config() {
	cat <<EOF
model_list:
- model_name: huggingface/google/gemma-2-2b-it
  litellm_params:
    model: huggingface/google/gemma-2-2b-it
EOF
	generate_litellm_provider "openai" "OPENAI_API_KEY"
	generate_litellm_provider "perplexity" "PERPLEXITY_API_KEY"
	generate_litellm_provider "anthropic" "ANTHROPIC_API_KEY"

	while read -r model; do
		generate_litellm_model "github/${model}" "GITHUB_API_KEY"
	done </assets/azure-models.txt

	if [[ -n "${LITELLM_MODELS_BASE64:-}" ]]; then
		echo "${LITELLM_MODELS_BASE64}" | base64 -d
	fi
}

start_litellm() {
	(
	# KISS: No persistence for LiteLLM
	unset DATABASE_URL

	litellm \
		--host "127.0.0.1" \
		--port "4000" \
		--config /tmp/litellm_config.yaml
	) &
	pids+=("$!")
}

start_open_webui() {
	(
	# By default, we expect it to be deployed to a private HF Space.
	# You can enable WEBUI_AUTH as needed
	if [[ -z "${WEBUI_AUTH:-}" ]]; then
		>&2 echo "[!] Enabling single user mode"
		export WEBUI_AUTH="False"
	fi

	# The less the user needs to configure, the better :)
	if [[ -n "${OPENAI_API_KEY:-}" ]] && [[ -z "${WEBUI_SECRET_KEY:-}${WEBUI_JWT_SECRET_KEY:-}" ]]; then
		>&2 echo "[!] Using OpenAI API key as Web UI secret key"
		export WEBUI_SECRET_KEY="${OPENAI_API_KEY}"
	fi

	if [[ -z "${ENABLE_RAG_WEB_SEARCH:-}${RAG_WEB_SEARCH_ENGINE:-}" ]]; then
		if [[ -n "${BRAVE_SEARCH_API_KEY:-}" ]]; then
			export RAG_WEB_SEARCH_ENGINE="brave"
			export ENABLE_RAG_WEB_SEARCH="True"
		fi
	fi

	if [[ -z "${DATABASE_URL:-}" ]]; then
		unset DATABASE_URL
	fi

	export ENABLE_OLLAMA_API="${ENABLE_OLLAMA_API:-False}"

	export OPENAI_API_BASE_URLS="http://localhost:4000"
	export OPENAI_API_KEY="sk-unused"

	export ENABLE_IMAGE_GENERATION="True"
	export IMAGES_OPENAI_API_BASE_URL="http://localhost:4000"
	export IMAGES_OPENAI_API_KEY="sk-unused"

	export PGSSLCERT=/tmp/postgresql.crt

	env
	/app/backend/start.sh
	) &
	pids+=("$!")
}

wait_litellm() {
	while ! curl -s http://localhost:4000 >/dev/null; do
		>&2 echo "[!] Waiting for LiteLLM..."
		sleep 1
	done
}

generate_litellm_config >/tmp/litellm_config.yaml
>&2 cat /tmp/litellm_config.yaml

start_litellm
wait_litellm
start_open_webui

for pid in "${pids[@]}"; do
    wait "$pid"
done
