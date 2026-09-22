# Messaging Channels (Telegram & WhatsApp)

Status: **Implemented & Active**

`c35_mod_channel` provides multi-channel messaging capabilities for AI bots across Telegram and WhatsApp.

---

## Supported Channels & Providers

| Platform | Provider | Transport | Inbound | Outbound |
| :--- | :--- | :--- | :--- | :--- |
| **Telegram** | Bot API | Webhook (`/v1/channels/telegram/webhook/{bot_iid}/{channel_id}/{secret}`) | Long polling / Webhook | REST API (`sendMessage`, `sendVoice`, `sendPhoto`, `sendDocument`) |
| **WhatsApp** | `meta_api` (Cloud API) | Webhook (`/v1/channels/whatsapp/webhook/{bot_iid}/{channel_id}`) | Cloud API Webhook | Graph API v21.0 (`/messages`, `/media`) |
| **WhatsApp** | `linked` (QR Device) | `channel_whatsapp_device` worker via `wa-rs` | NATS `msg.in` | NATS `msg.send` |

---

## 1. Message Splitting (Chunking)

Neither Telegram nor WhatsApp webhook APIs support streaming tokens in the style of SSE/WebSockets. Outbound replies are buffered per turn and delivered in chunks complying with platform length limits:

- **Chunk Threshold**: `4096` UTF-8 characters (`TG_TEXT_MAX` / `WA_CLOUD_TEXT_MAX`).
- **Splitting Strategy**:
  - Prefers splitting on paragraph boundaries (`\n\n` or `\n`), falling back to whitespace.
  - **Telegram Resiliency**: Each chunk is dispatched with `parse_mode = "HTML"`. If Telegram returns an error (e.g., formatting tag severed across chunks), it automatically falls back to plain text for that specific chunk.
  - **WhatsApp**: Text is split into clean chunks delivered sequentially to the recipient phone number.

---

## 2. Typing Indicator (Continuous Heartbeat)

Telegram and WhatsApp typing statuses expire after ~5 seconds on client apps. To prevent indicators from disappearing during 10–30+ second LLM inference:

- **`ChannelTypingGuard`**: An RAII heartbeat guard spawned at the start of `execute_channel_turn`.
- **Interval**: Ticks every **4 seconds** in a background `tokio` task.
- **Actions**:
  - **Telegram**: `sendChatAction` with `"record_voice"` (if user sent voice) or `"typing"`.
  - **WhatsApp Cloud**: Posts `{"typing_indicator": {"type": "text"}}` to Meta Graph API.
  - **WhatsApp Device**: Publishes `ActChannelMsgTyping { active: true, speak }` over NATS.
- **Teardown**: Automatically cancelled when the guard drops upon reply delivery or turn failure. Linked WhatsApp devices receive an explicit `active: false` packet to dismiss the indicator.

---

## 3. Voice Notes Pipeline

Bidirectional voice support: inbound voice note → STT transcription → LLM turn (`speak = true`) → TTS audio synthesis → voice reply with text caption.

### Inbound (Speech-to-Text)
1. **Telegram**:
   - Webhook extracts `voice` or `audio` `file_id`.
   - Fetches file path via `/getFile` and downloads raw OGG bytes.
2. **WhatsApp Cloud API**:
   - Webhook extracts audio `media_id`.
   - `fetch_meta_cloud_media`: Queries Meta Graph API for temporary download URL with Bearer token, downloads raw bytes, and stores into CAS (`cas_put`).
3. **STT Processing** (`c35_mod_chat::audio`):
   - In-memory `ffmpeg` converts OGG/Opus to 16 kHz mono WAV.
   - Transcribes via Gemini inline audio with Chromium STT fallback (`id-ID` and `en-US`).
   - Refusal/hallucination validation filters invalid outputs.

### Outbound (Text-to-Speech)
When inbound is voice or `speak == true`:
1. `speech_text_clean`: Strips `<thought>` blocks, backticks, URLs, and Markdown markers.
2. `speech_text_cap`: Caps spoken audio to 2 sentences for natural conversational delivery.
3. `speech_lang_tts_code`: Detects Indonesian (`id`) vs English (`en`) from text hint words.
4. `web_tts`: Synthesizes MP3 audio bytes.
5. **Delivery**:
   - **Telegram**: `tg_send_voice_reply` uploads multipart `voice.ogg` to `/sendVoice` with the text transcription as caption below the waveform. Falls back to `/sendAudio` if needed.
   - **WhatsApp Cloud**: `wa_cloud_upload_media` uploads bytes to `/media`, then `wa_cloud_send_audio` posts message with `type: "audio"`.
   - **WhatsApp Device**: Publishes `ActChannelMsgSend` with `media: [ActChannelMediaItem { kind: "audio" }]`.
   - **Fallback**: If TTS synthesis fails, gracefully falls back to text delivery.

---

## 4. Media Pipeline (Images & Documents)

### Inbound
- **Telegram**: Webhook parses `photo` (selecting the largest `PhotoSize` resolution) and `document` into `ChannelInboundAttachment`.
- **WhatsApp Cloud**: Webhook parses `image` and `document` attachments.
- **CAS Resolution**: `resolve_inbound_attachments_cas` downloads raw bytes from Telegram or WhatsApp and saves into Content Addressable Storage (`cas_put`), setting `item.hash`. The multimodal LLM turn receives the CAS hash for vision/multimodal processing.

### Outbound
- **Telegram**:
  - Photos: `tg_send_photo_url` (`/sendPhoto`).
  - Documents: `tg_send_document_bytes` (`/sendDocument`).
- **WhatsApp Cloud**: `wa_cloud_send_media` uploads media bytes and sends with `type: "image"` or `type: "document"`.
- **WhatsApp Device**: Dispatched via NATS media items.

---

## 5. NATS Subjects (Device / QR Channel)

| Subject | Direction | Purpose |
| :--- | :---: | :--- |
| `c35.act.channel.whatsapp.device.pair` | server → worker | Start/restart QR pair (`ActChannelWhatsappPair`) |
| `c35.ev.channel.{owner_iid}.{bot_iid}.{channel_id}.pair` | worker → server | Pair status push (`EvChannelPairUpdate`) |
| `c35.ev.channel.{owner_iid}.{bot_iid}.{channel_id}.msg.in` | worker → server | Inbound WhatsApp message |
| `c35.act.channel.{owner_iid}.{bot_iid}.{channel_id}.msg.send` | server → worker | Outbound message delivery |
| `c35.act.channel.{owner_iid}.{bot_iid}.{channel_id}.msg.typing` | server → worker | Typing / recording state heartbeat |

---

## 6. Configuration & Environment

| Environment Variable | Description | Default |
| :--- | :--- | :--- |
| `TELEGRAM_API_BASE` | Base URL for Telegram Bot API | `https://api.telegram.org` |
| `META_GRAPH_API_BASE` | Base URL for Meta WhatsApp Cloud API | `https://graph.facebook.com/v21.0` |
| `WHATSAPP_WORKER_URL` | Base URL for `channel-whatsapp-device` HTTP endpoints | Empty |
| `GEMINI_API_KEY` | Key for Gemini transcription and LLM turns | Required |
| `CAS_DIR` | Directory for local file storage cache | `.cache/cas` |

---

## 7. Channel Lifecycle, Deletion & Cancellation

### Bot Deletion
When a bot is deleted by the user:
1. **Confirmation UI**: The client (`IoBotDeleteDialog` in [`clients/app/lib/widgets/bots/io_bot_delete_dialog.dart`](file:///d:/c35/clients/app/lib/widgets/bots/io_bot_delete_dialog.dart)) enforces a multi-step safety confirmation:
   - User must type the bot name or handle.
   - User slides the `UiSlideConfirm` bar.
   - A 3-second countdown initiates (`3... 2... 1...`).
   - A red "Permanently Delete Bot" button triggers `store.botDelete(id)`.
2. **Server-Side Cleanup**:
   - `identity_delete` detects `kind == "bot"` and calls `bot_channels_disconnect_all`.
   - **Telegram**: Webhook is deleted via Telegram Bot API `/deleteWebhook`.
   - **WhatsApp Device**: Worker is commanded to `/stop` with `wipe_session: true`, which disconnects the client and deletes the SQLite session file from disk.
   - **Database**: Channel registrations and bot identities are permanently removed.

### Draft Cancellation
When creating a new bot (`InBotCreate` in [`clients/app/lib/widgets/bots/in_bot_create.dart`](file:///d:/c35/clients/app/lib/widgets/bots/in_bot_create.dart)):
- If channels are connected during Step 1/2 and the user cancels or dismisses the wizard, `_cleanupDraft()` disconnects every connected channel (deleting Telegram webhooks and terminating WhatsApp sessions) and deletes the draft bot identity.
- Pop navigation and disposal hooks guarantee that cancelled setups never leave active webhooks or orphaned worker sessions running.

### Transaction Guarantees
- **Message Ingestion (`chat_msg_external_put` / `chat_msg_assistant_put`)**: Wrapped in `pool.begin()` transactions ensuring the message is inserted and `ai.chat` is updated atomically.
- **WhatsApp Sibling Deactivation (`channel_whatsapp_deactivate_siblings`)**: Updates across all other sibling bots owned by the user are wrapped in an atomic transaction.


