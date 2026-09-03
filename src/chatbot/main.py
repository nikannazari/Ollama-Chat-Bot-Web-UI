from chatbot.core.chatbot import ChatBot
from chatbot.utils.validators import validate_message


DEFAULT_MODEL = "qwen2.5-coder:7b"


def main() -> None:
    chatbot = ChatBot(
        model=DEFAULT_MODEL,
    )

    print("=" * 50)
    print("                CHATBOT")
    print("=" * 50)
    print(f"Model: {DEFAULT_MODEL}")
    print("Type 'exit' to quit.")
    print("Type 'clear' to clear conversation.")
    print()

    while True:
        message = input("You: ").strip()

        if message.lower() == "exit":
            print("Goodbye!")
            break

        if message.lower() == "clear":
            chatbot.clear_history()
            print("Conversation cleared.")
            continue

        if not validate_message(message):
            print("Message cannot be empty.")
            continue

        print("Assistant: ", end="")

        response = chatbot.send_message(message)

        if response is None:
            print(
                "Unable to get a response from Ollama."
            )
            continue

        print(response)
        print()


if __name__ == "__main__":
    main()