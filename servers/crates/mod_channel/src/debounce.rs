use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;

use c35_ctx::AppState;

use crate::hub::channel_hub;
use crate::turn::ChannelTurnJob;

struct PendingTurn {
    job: ChannelTurnJob,
}

#[derive(Default)]
struct ChatState {
    timer: Option<tokio::task::JoinHandle<()>>,
    typing: bool,
    pending: Option<PendingTurn>,
}

#[derive(Default)]
pub struct ChatDebouncer {
    chats: HashMap<i64, ChatState>,
}

impl ChatDebouncer {
    pub fn schedule(&mut self, state: Arc<AppState>, job: ChannelTurnJob) {
        let chat_id = job.chat_id;
        let chat_state = self.chats.entry(chat_id).or_default();
        if chat_state.typing {
            chat_state.pending = Some(PendingTurn { job });
            return;
        }
        if let Some(prev) = chat_state.timer.take() {
            prev.abort();
        }
        let timer = tokio::spawn(async move {
            tokio::time::sleep(Duration::from_millis(1200)).await;
            if let Err(e) = super::turn::execute_channel_turn(state, job).await {
                tracing::error!("[c35:channel] turn failed chat_id={chat_id}: {e:#}");
            }
        });
        chat_state.timer = Some(timer);
    }

    pub fn turn_started(&mut self, chat_id: i64) {
        if let Some(entry) = self.chats.get_mut(&chat_id) {
            entry.timer = None;
            entry.typing = true;
        }
    }

    pub async fn turn_finished(&mut self, state: Arc<AppState>, chat_id: i64) {
        let pending = {
            let entry = match self.chats.get_mut(&chat_id) {
                Some(e) => e,
                None => return,
            };
            entry.typing = false;
            entry.pending.take()
        };
        if let Some(p) = pending {
            self.schedule(state, p.job);
        }
    }
}

pub async fn debouncer_turn_started(chat_id: i64) {
    channel_hub().debouncer.lock().await.turn_started(chat_id);
}

pub async fn debouncer_turn_finished(state: Arc<AppState>, chat_id: i64) {
    channel_hub().debouncer.lock().await.turn_finished(state, chat_id).await;
}
