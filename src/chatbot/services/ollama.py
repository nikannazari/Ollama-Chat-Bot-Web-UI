import json
from collections.abc import Generator

import requests


class OllamaClient:

    def __init__(
        self,
        base_url: str = "http://localhost:11434",
    ):
        self.base_url = base_url.rstrip("/")

    def generate(
        self,
        model: str,
        prompt: str,
        system_prompt: str | None = None,
        temperature: float = 0.7,
        context_length: int = 4096,
        stream: bool = False,
    ) -> dict | None:

        url = f"{self.base_url}/api/generate"

        data = {
            "model": model,
            "prompt": prompt,
            "stream": stream,
            "options": {
                "temperature": temperature,
                "num_ctx": context_length,
            },
        }

        if system_prompt:
            data["system"] = system_prompt

        try:
            response = requests.post(
                url,
                json=data,
                timeout=120,
            )

            response.raise_for_status()

            return response.json()

        except requests.RequestException as error:
            print(f"Ollama error: {error}")
            return None

    def generate_stream(
        self,
        model: str,
        prompt: str,
        system_prompt: str | None = None,
        temperature: float = 0.7,
        context_length: int = 4096,
    ) -> Generator[str, None, None]:

        url = f"{self.base_url}/api/generate"

        data = {
            "model": model,
            "prompt": prompt,
            "stream": True,
            "options": {
                "temperature": temperature,
                "num_ctx": context_length,
            },
        }

        if system_prompt:
            data["system"] = system_prompt

        try:
            with requests.post(
                url,
                json=data,
                stream=True,
                timeout=120,
            ) as response:

                response.raise_for_status()

                for line in response.iter_lines():

                    if not line:
                        continue

                    data = json.loads(
                        line.decode("utf-8")
                    )

                    chunk = data.get(
                        "response",
                        "",
                    )

                    if chunk:
                        yield chunk

                    if data.get("done", False):
                        break

        except (
            requests.RequestException,
            json.JSONDecodeError,
        ) as error:

            print(f"Ollama streaming error: {error}")

    def list_models(self) -> list[str]:

        url = f"{self.base_url}/api/tags"

        try:
            response = requests.get(
                url,
                timeout=10,
            )

            response.raise_for_status()

            data = response.json()

            return [
                model["name"]
                for model in data.get("models", [])
                if model.get("name")
            ]

        except (
            requests.RequestException,
            json.JSONDecodeError,
        ) as error:

            print(f"Ollama model list error: {error}")

            return []