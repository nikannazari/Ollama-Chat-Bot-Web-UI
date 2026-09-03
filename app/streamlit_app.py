import sys
from pathlib import Path
from datetime import datetime

import streamlit as st


ROOT_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = ROOT_DIR / "src"

if str(SRC_DIR) not in sys.path:
    sys.path.insert(0, str(SRC_DIR))


from chatbot.core.chatbot import ChatBot
from chatbot.services.ollama import OllamaClient


# ==================================================
# Page Configuration
# ==================================================

st.set_page_config(
    page_title="ChatBot",
    page_icon="🤖",
    layout="centered",
)


# ==================================================
# Ollama
# ==================================================

ollama = OllamaClient()


@st.cache_data(ttl=10)
def get_models() -> list[str]:
    return ollama.list_models()


# ==================================================
# Session State
# ==================================================

if "conversations" not in st.session_state:

    st.session_state.conversations = {
        "New Chat": []
    }


if "current_chat" not in st.session_state:

    st.session_state.current_chat = "New Chat"


# ==================================================
# Helper Functions
# ==================================================

def create_new_chat():

    chat_number = len(
        st.session_state.conversations
    ) + 1

    chat_name = f"New Chat {chat_number}"

    st.session_state.conversations[chat_name] = []

    st.session_state.current_chat = chat_name


def delete_current_chat():

    current_chat = st.session_state.current_chat

    if current_chat in st.session_state.conversations:

        del st.session_state.conversations[current_chat]

    if not st.session_state.conversations:

        st.session_state.conversations = {
            "New Chat": []
        }

    st.session_state.current_chat = (
        list(st.session_state.conversations.keys())[0]
    )


# ==================================================
# Sidebar
# ==================================================

with st.sidebar:

    st.header("💬 Conversations")

    # ----------------------------------------------
    # New Chat
    # ----------------------------------------------

    if st.button(
        "➕ New Chat",
        use_container_width=True,
    ):

        create_new_chat()

        st.rerun()

    st.divider()

    # ----------------------------------------------
    # Conversation List
    # ----------------------------------------------

    chat_names = list(
        st.session_state.conversations.keys()
    )

    selected_chat = st.radio(
        "Your Chats",
        chat_names,
        index=chat_names.index(
            st.session_state.current_chat
        ),
    )

    if selected_chat != st.session_state.current_chat:

        st.session_state.current_chat = selected_chat

        st.rerun()

    st.divider()

    # ----------------------------------------------
    # Chat Actions
    # ----------------------------------------------

    if st.button(
        "🗑️ Delete Chat",
        use_container_width=True,
    ):

        delete_current_chat()

        st.rerun()

    st.divider()

    # ----------------------------------------------
    # Model Settings
    # ----------------------------------------------

    st.header("⚙️ Settings")

    models = get_models()

    if not models:

        st.error("No Ollama models found.")

        st.code(
            "ollama serve\n"
            "ollama pull qwen2.5-coder:7b"
        )

        st.stop()

    model = st.selectbox(
        "Model",
        models,
    )

    temperature = st.slider(
        "Temperature",
        min_value=0.0,
        max_value=2.0,
        value=0.7,
        step=0.1,
    )

    context_length = st.select_slider(
        "Context Length",
        options=[
            2048,
            4096,
            8192,
            16384,
            32768,
        ],
        value=4096,
    )

    system_prompt = st.text_area(
        "System Prompt",
        value=(
            "You are a helpful AI assistant. "
            "Answer clearly and accurately."
        ),
        height=150,
    )

    if st.button(
        "🔄 Refresh Models",
        use_container_width=True,
    ):

        get_models.clear()

        st.rerun()


# ==================================================
# Current Conversation
# ==================================================

current_chat = st.session_state.current_chat

messages = st.session_state.conversations[
    current_chat
]


# ==================================================
# Header
# ==================================================

st.title("🤖 ChatBot")

st.caption(
    f"Conversation: {current_chat}"
)


# ==================================================
# Empty Conversation
# ==================================================

if not messages:

    st.info(
        "Start a new conversation by sending a message."
    )


# ==================================================
# Display Messages
# ==================================================

for message in messages:

    with st.chat_message(
        message["role"]
    ):

        st.markdown(
            message["content"]
        )


# ==================================================
# User Input
# ==================================================

prompt = st.chat_input(
    "Send a message..."
)


if prompt:

    # ----------------------------------------------
    # Save User Message
    # ----------------------------------------------

    messages.append(
        {
            "role": "user",
            "content": prompt,
        }
    )

    with st.chat_message("user"):

        st.markdown(prompt)

    # ----------------------------------------------
    # Create ChatBot
    # ----------------------------------------------

    chatbot = ChatBot(
        model=model,
        system_prompt=system_prompt,
        temperature=temperature,
        context_length=context_length,
    )

    # ----------------------------------------------
    # Restore Conversation History
    # ----------------------------------------------

    for message in messages[:-1]:

        chatbot.add_message(
            role=message["role"],
            content=message["content"],
        )

    # ----------------------------------------------
    # Generate Response
    # ----------------------------------------------

    with st.chat_message("assistant"):

        response = st.write_stream(
            chatbot.stream_message(prompt)
        )

    # ----------------------------------------------
    # Save Assistant Message
    # ----------------------------------------------

    if response:

        messages.append(
            {
                "role": "assistant",
                "content": response,
            }
        )

    # ----------------------------------------------
    # Rename New Chat
    # ----------------------------------------------

    if current_chat.startswith("New Chat"):

        title = prompt[:30]

        if len(prompt) > 30:
            title += "..."

        if title not in st.session_state.conversations:

            st.session_state.conversations[
                title
            ] = st.session_state.conversations.pop(
                current_chat
            )

            st.session_state.current_chat = title

    st.rerun()