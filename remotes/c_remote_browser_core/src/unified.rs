//! Attach extension browser backend to an already-paired desktop agent (Windows unified path).

use std::sync::Arc;
use tracing::{info, warn};

use crate::browser_command;
use crate::browser_ensure;
use crate::browser_idle;
use crate::browser_presence;
use crate::browser_state;
use crate::browser_task;
use crate::extension_ipc;
use crate::mode;

pub fn attach_to_desktop_agent() -> Arc<browser_state::BrowserState> {
    std::env::set_var("C35_BROWSER_ENGINE", "extension");
    mode::hydrate_agent_ui_from_config();

    let state = browser_state::BrowserState::new();
    browser_state::init(state.clone());
    browser_command::register_command_handler();
    browser_task::register_task_handler();
    browser_idle::spawn_screencast_idle_loop(state.clone());

    browser_presence::register_agent_browser_ws_query();
    browser_presence::spawn_browser_presence_reports();

    if let Err(e) = extension_ipc::spawn_extension_ipc_server(state.clone()) {
        warn!("extension ipc server: {e:#}");
    } else {
        info!("unified desktop agent: extension IPC listening");
    }

    std::thread::spawn(|| {
        if let Err(e) = browser_ensure::bootstrap_desktop_extension() {
            warn!("desktop extension bootstrap: {e:#}");
        } else {
            browser_presence::push_browser_presence_now();
        }
    });

    state
}