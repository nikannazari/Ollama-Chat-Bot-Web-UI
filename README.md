# 🤖 Chat-Bot

A local AI chatbot built with **Python**, **Streamlit**, and **Ollama**.

Chat-Bot provides a modern web interface for interacting with locally running Large Language Models (LLMs), with support for real-time streaming, multiple conversations, model selection, custom system prompts, and optional local conversation storage.

---

## ✨ Features

* 🤖 Local AI inference with Ollama
* ⚡ Real-time response streaming
* 🔍 Automatic Ollama model discovery
* 🧠 Multiple Ollama model support
* 💬 Multiple conversations
* 🔄 Switch between conversations
* 🗑️ Create and delete conversations
* 🌡️ Temperature control
* 🧠 Context length configuration
* 📝 Custom system prompts
* 💾 Optional conversation storage
* 📄 JSON-based conversation storage
* 🖥️ Streamlit web interface
* 💻 CLI interface
* 🧩 Modular project architecture

---

## 🏗️ Architecture

The project separates the chatbot logic, Ollama communication, validation, and user interface into independent components.

```text
Chat-Bot/
│
├── app/
│   └── streamlit_app.py
│
├── assets/
│
├── src/
│   └── chatbot/
│       ├── __init__.py
│       ├── main.py
│       │
│       ├── core/
│       │   ├── __init__.py
│       │   └── chatbot.py
│       │
│       ├── services/
│       │   ├── __init__.py
│       │   └── ollama.py
│       │
│       └── utils/
│           ├── __init__.py
│           └── validators.py
│
├── .gitignore
├── LICENSE
├── README.md
├── pyproject.toml
└── requirements.txt
```

---

## 🧰 Technologies

| Technology | Purpose                        |
| ---------- | ------------------------------ |
| Python     | Core programming language      |
| Streamlit  | Web interface                  |
| Ollama     | Local LLM runtime              |
| Requests   | HTTP communication with Ollama |
| JSON       | Conversation storage           |

---

## 📋 Requirements

Before running the project, make sure you have:

* Python **3.10+**
* Ollama
* At least one Ollama model
* `pip`
* A supported operating system such as Linux, macOS, or Windows

---

# 🚀 Installation

## 1. Clone the Repository

```bash
git clone <YOUR_REPOSITORY_URL>
cd Chat-Bot
```

---

## 2. Create a Virtual Environment

Linux / macOS:

```bash
python -m venv .venv
```

Windows:

```powershell
python -m venv .venv
```

---

## 3. Activate the Virtual Environment

### Linux / macOS

```bash
source .venv/bin/activate
```

### Windows

```powershell
.venv\Scripts\activate
```

---

## 4. Install Dependencies

```bash
pip install -r requirements.txt
```

For development, install the project itself in editable mode:

```bash
pip install -e .
```

---

# 🦙 Ollama Setup

Chat-Bot uses Ollama to run AI models locally.

Make sure Ollama is installed on your system.

Start the Ollama server:

```bash
ollama serve
```

You can verify that the Ollama API is running with:

```bash
curl http://localhost:11434/api/tags
```

If the server is working, Ollama will return information about the installed models.

---

## 📥 Install a Model

For example:

```bash
ollama pull qwen2.5-coder:7b
```

You can see your installed models with:

```bash
ollama list
```

The application automatically retrieves the available models from Ollama, so you don't need to hard-code model names inside the application.

---

# ▶️ Run the Application

From the project root:

```bash
streamlit run app/streamlit_app.py
```

Streamlit will start the local web server and provide a URL for the application.

---

# 💻 CLI Mode

The project also provides a command-line interface.

First install the project:

```bash
pip install -e .
```

Then run:

```bash
python -m chatbot.main
```

The CLI supports:

```text
exit
clear
```

### `exit`

Closes the chatbot.

### `clear`

Clears the current conversation history.

---

# ⚙️ Configuration

The Streamlit interface provides several configuration options.

## 🤖 Model

The application automatically detects models installed in Ollama.

You can select the model you want to use directly from the sidebar.

---

## 🌡️ Temperature

Temperature controls the randomness of model responses.

Lower values generally produce more deterministic responses.

Higher values allow more variation and creativity.

Example:

```text
0.0 → More deterministic
0.7 → Balanced
1.5 → More creative
2.0 → High randomness
```

---

## 🧠 Context Length

Context length determines how much conversation history can be provided to the model.

Available options include:

```text
2048
4096
8192
16384
32768
```

Higher context lengths can increase memory usage and inference requirements.

---

## 📝 System Prompt

You can define a custom system prompt to control the behavior of the AI assistant.

For example:

```text
You are a helpful Python programming assistant.
Always explain code clearly and provide practical examples.
```

---

# 💬 Conversations

Chat-Bot supports multiple independent conversations.

Each conversation maintains its own message history.

You can:

* Create a new conversation
* Switch between conversations
* Delete conversations
* Continue an existing conversation
* Store conversations locally

Example:

```text
Conversations

├── Python Help
├── Linux Questions
├── Machine Learning
└── General Chat
```

---

# 💾 Conversation Storage

Conversation storage is optional.

You can enable it from the Streamlit sidebar using:

```text
Save conversations to disk
```

Then specify a directory where conversations should be stored.

Conversations are stored as JSON files.

Example:

```text
conversations/
│
├── Python Help.json
├── Linux Questions.json
└── Machine Learning.json
```

A conversation file contains the conversation name and message history.

Example:

```json
{
    "name": "Python Help",
    "messages": [
        {
            "role": "user",
            "content": "How do I create a virtual environment?"
        },
        {
            "role": "assistant",
            "content": "You can create one using python -m venv .venv."
        }
    ]
}
```

Conversation storage is completely local and does not require a cloud database.

---

# 🔒 Privacy

Chat-Bot is designed around local AI inference.

The normal request flow is:

```text
User
  │
  ▼
Streamlit
  │
  ▼
ChatBot
  │
  ▼
OllamaClient
  │
  ▼
Ollama
  │
  ▼
Local AI Model
```

Prompts are sent to the locally running Ollama server.

The application does not require an external AI API such as OpenAI or Gemini.

If conversation storage is enabled, conversations are saved on the local filesystem.

---

# 🧩 Project Components

## `ChatBot`

Located at:

```text
src/chatbot/core/chatbot.py
```

Responsible for:

* Managing conversation history
* Adding messages
* Building prompts
* Sending messages
* Streaming responses
* Clearing conversation history

---

## `OllamaClient`

Located at:

```text
src/chatbot/services/ollama.py
```

Responsible for communicating with the Ollama HTTP API.

It provides:

* Model discovery
* Standard text generation
* Streaming text generation
* Ollama API error handling

---

## `validators`

Located at:

```text
src/chatbot/utils/validators.py
```

Responsible for basic input validation.

For example:

* Validating messages
* Validating model names

---

## Streamlit Application

Located at:

```text
app/streamlit_app.py
```

Provides the graphical interface for:

* Chatting with the AI
* Selecting models
* Managing conversations
* Configuring generation parameters
* Configuring system prompts
* Enabling conversation storage

---

# 🔄 Application Flow

A typical message follows this flow:

```text
User enters message
        │
        ▼
Streamlit UI
        │
        ▼
ChatBot
        │
        ▼
Build conversation prompt
        │
        ▼
OllamaClient
        │
        ▼
Ollama API
        │
        ▼
Local LLM
        │
        ▼
Streaming response
        │
        ▼
Streamlit UI
```

---

# 🛠️ Development

The project is structured to make future development easier.

Possible future improvements include:

* Persistent conversation loading
* Database-backed conversation storage
* User authentication
* Chat export
* Markdown rendering improvements
* File uploads
* Document-based RAG
* Embedding support
* Vector databases
* Tool calling
* Agent capabilities
* Voice input/output
* Model performance monitoring
* Docker support
* REST API

---

# 📄 License

This project is licensed under the **MIT License**.

See the [`LICENSE`](LICENSE) file for details.

---

# 👤 Author

**Nikan Nazari**

---

## ⭐ Contributing

Contributions, suggestions, and improvements are welcome.

If you find a bug or have an idea for improving the project, feel free to open an issue or submit a pull request.

---

## 📌 Project Status

**Version:** `1.0.0`

The current version focuses on providing a clean local chatbot foundation using **Ollama + Python + Streamlit**, with a modular architecture suitable for future expansion.
