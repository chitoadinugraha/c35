use wa_rs::wa_rs_proto::whatsapp as wa;
use wa_rs_binary::jid::JidExt;
use wa_rs_core::types::message::MessageSource;

pub fn wa_linked_inbound_accept(source: &MessageSource, msg: &wa::Message) -> bool {
    if source.is_from_me || source.is_group {
        return false;
    }
    if source.chat.is_status_broadcast() || source.chat.is_newsletter() || source.chat.is_broadcast_list() {
        return false;
    }
    if source.is_incoming_broadcast() {
        return false;
    }
    if msg.reaction_message.is_some() || msg.enc_reaction_message.is_some() {
        return false;
    }
    if msg.protocol_message.is_some()
        && msg.conversation.is_none()
        && msg.extended_text_message.is_none()
        && msg.image_message.is_none()
        && msg.video_message.is_none()
        && msg.audio_message.is_none()
        && msg.document_message.is_none()
        && msg.sticker_message.is_none()
    {
        return false;
    }
    true
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::str::FromStr;
    use wa_rs_binary::jid::Jid;

    fn source(chat: &str) -> MessageSource {
        MessageSource {
            chat: Jid::from_str(chat).expect("jid"),
            sender: Jid::from_str("628111@s.whatsapp.net").expect("jid"),
            is_from_me: false,
            is_group: chat.ends_with("@g.us"),
            addressing_mode: None,
            sender_alt: None,
            recipient_alt: None,
            broadcast_list_owner: None,
            recipient: None,
        }
    }

    #[test]
    fn rejects_status_broadcast_chat() {
        assert!(!wa_linked_inbound_accept(&source("status@broadcast"), &wa::Message::default()));
    }

    #[test]
    fn accepts_dm_text() {
        let msg = wa::Message {
            conversation: Some("hi".into()),
            ..Default::default()
        };
        assert!(wa_linked_inbound_accept(
            &source("628222@s.whatsapp.net"),
            &msg,
        ));
    }
}