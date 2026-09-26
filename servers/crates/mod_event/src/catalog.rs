#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum EventClass {
    Event,
    Error,
}

impl EventClass {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Event => "event",
            Self::Error => "error",
        }
    }

    pub fn log_kind(self) -> &'static str {
        match self {
            Self::Event => "conn",
            Self::Error => "error",
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum EventScope {
    User,
    Device,
    Channel,
}

#[derive(Clone, Debug)]
pub struct EventDef {
    pub kind: &'static str,
    pub slug: &'static str,
    pub scope: EventScope,
    pub class: EventClass,
    pub desc: &'static str,
    pub txt_en: &'static str,
}

const CATALOG: &[EventDef] = &[
    EventDef {
        kind: "user.sign_in",
        slug: "sign-in",
        scope: EventScope::User,
        class: EventClass::Event,
        desc: "User obtained a session",
        txt_en: "$name signed in",
    },
    EventDef {
        kind: "user.sign_out",
        slug: "sign-out",
        scope: EventScope::User,
        class: EventClass::Event,
        desc: "User ended session",
        txt_en: "$name signed out",
    },
    EventDef {
        kind: "user.sign_in_failed",
        slug: "sign-in-failed",
        scope: EventScope::User,
        class: EventClass::Error,
        desc: "Sign-in rejected",
        txt_en: "Sign-in failed",
    },
    EventDef {
        kind: "user.connected",
        slug: "connected",
        scope: EventScope::User,
        class: EventClass::Event,
        desc: "App WebSocket connected",
        txt_en: "$name connected",
    },
    EventDef {
        kind: "user.disconnected",
        slug: "disconnected",
        scope: EventScope::User,
        class: EventClass::Event,
        desc: "App WebSocket closed",
        txt_en: "$name disconnected",
    },
    EventDef {
        kind: "consumption.meal_logged",
        slug: "meal-logged",
        scope: EventScope::User,
        class: EventClass::Event,
        desc: "Meal saved",
        txt_en: "$name logged $item_count items · $calories kcal",
    },
    EventDef {
        kind: "consumption.meal_updated",
        slug: "meal-updated",
        scope: EventScope::User,
        class: EventClass::Event,
        desc: "Meal updated",
        txt_en: "$name updated a meal · $calories kcal",
    },
    EventDef {
        kind: "consumption.meal_deleted",
        slug: "meal-deleted",
        scope: EventScope::User,
        class: EventClass::Event,
        desc: "Meal removed",
        txt_en: "$name removed a meal",
    },
    EventDef {
        kind: "channel.connected",
        slug: "connected",
        scope: EventScope::Channel,
        class: EventClass::Event,
        desc: "Channel connected",
        txt_en: "Channel connected ($platform)",
    },
    EventDef {
        kind: "channel.disconnected",
        slug: "disconnected",
        scope: EventScope::Channel,
        class: EventClass::Event,
        desc: "Channel disconnected",
        txt_en: "Channel disconnected ($platform)",
    },
    EventDef {
        kind: "device.agent_connected",
        slug: "agent-connected",
        scope: EventScope::Device,
        class: EventClass::Event,
        desc: "Remote agent WS up",
        txt_en: "Agent connected",
    },
    EventDef {
        kind: "device.agent_disconnected",
        slug: "agent-disconnected",
        scope: EventScope::Device,
        class: EventClass::Event,
        desc: "Remote agent WS down",
        txt_en: "Agent disconnected",
    },
    EventDef {
        kind: "device.unpaired",
        slug: "unpaired",
        scope: EventScope::Device,
        class: EventClass::Event,
        desc: "Remote device unpaired",
        txt_en: "Device unpaired",
    },
];

pub fn event_by_kind(kind: &str) -> Option<&'static EventDef> {
    CATALOG.iter().find(|e| e.kind == kind)
}

pub fn catalog_list() -> &'static [EventDef] {
    CATALOG
}
