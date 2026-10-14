# open-code-free-api

Use a **free model** from your own project as an OpenCode provider — no paid API keys.

OpenCode picks up custom providers from `opencode.json` in your project. This repo
provides a drop-in config for an OpenAI-compatible free-model endpoint, plus a
one-command installer that keeps the model list up to date automatically.

## Requirements

- [OpenCode](https://opencode.ai) installed
- Node.js (already required by OpenCode)
- Your free-model project running with an OpenAI-compatible API:
  - `POST {baseURL}/chat/completions`
  - `GET  {baseURL}/models`

## Quickstart

From **inside the project** where you want OpenCode to use the free model:

```bash
git clone https://github.com/<your-org>/open-code-free-api.git
cd open-code-free-api
./install.sh /path/to/your/project/opencode.json
```

Then start OpenCode in that project — the free models appear in the model picker
under the **Free Model** provider.

## Configuration

Environment variables understood by `install.sh`:

| Variable               | Default                     | Purpose                |
|------------------------|-----------------------------|------------------------|
| `FREE_MODEL_BASE_URL`  | `http://localhost:8080/v1`  | Endpoint of free model |
| `FREE_MODEL_API_KEY`   | `free`                      | API key (if any)       |

Example:

```bash
FREE_MODEL_BASE_URL=http://192.168.1.10:8000/v1 \
FREE_MODEL_API_KEY=my-key \
./install.sh
```

## How it works

1. `install.sh` queries `GET {baseURL}/models` on your server and writes the
   returned model IDs into `opencode.json`, so the model list is always current.
2. The provider uses `@ai-sdk/openai-compatible` — OpenCode's built-in
   OpenAI-format adapter — so no custom server code is needed.
3. To refresh the model list later (e.g. after pulling a new model), just
   re-run `install.sh`.

## Keeping the model list up to date

The installer auto-discovers models from the server. To pin a fixed list instead,
edit `models.json` (an array of model IDs) and reinstall.

## Project layout

```
opencode.json   provider template (merged into your project by install.sh)
models.json     fallback model list if the server is unreachable
install.sh      one-command installer
```

## License

MIT
