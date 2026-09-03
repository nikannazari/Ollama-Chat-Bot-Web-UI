from collections.abc import Generator

from chatbot.services.ollama import OllamaClient


class ChatBot:

    def __init__(
        self,
        model: str,
        ollama_client: OllamaClient | None = None,
        system_prompt: str | None = None,
        temperature: float = 0.7,
        context_length: int = 4096,
    ):

        self.model = model
        self.client = ollama_client or OllamaClient()

        self.system_prompt = system_prompt
        self.temperature = temperature
        self.context_length = context_length

        self.messages: list[dict[str, str]] = []

    def add_message(
        self,
        role: str,
        content: str,
    ) -> None:

        self.messages.append(
            {
                "role": role,
                "content": content,
            }
        )

    def build_prompt(self) -> str:

        prompt_parts = []

        for message in self.messages:

            role = message["role"]
            content = message["content"]

            if role == "user":
                prompt_parts.append(
                    f"User: {content}"
                )

            elif role == "assistant":
                prompt_parts.append(
                    f"Assistant: {content}"
                )

        prompt_parts.append("Assistant:")

        return "\n".join(prompt_parts)

    def send_message(
        self,
        message: str,
    ) -> str | None:

        self.add_message(
            role="user",
            content=message,
        )

        prompt = self.build_prompt()

        response = self.client.generate(
            model=self.model,
            prompt=prompt,
            system_prompt=self.system_prompt,
            temperature=self.temperature,
            context_length=self.context_length,
        )

        if response is None:
            return None

        answer = response.get("response")

        if not answer:
            return None

        self.add_message(
            role="assistant",
            content=answer,
        )

        return answer

    def stream_message(
        self,
        message: str,
    ) -> Generator[str, None, None]:

        self.add_message(
            role="user",
            content=message,
        )

        prompt = self.build_prompt()

        full_response = ""

        for chunk in self.client.generate_stream(
            model=self.model,
            prompt=prompt,
            system_prompt=self.system_prompt,
            temperature=self.temperature,
            context_length=self.context_length,
        ):

            full_response += chunk

            yield chunk

        if full_response:

            self.add_message(
                role="assistant",
                content=full_response,
            )

    def clear_history(self) -> None:

        self.messages.clear()