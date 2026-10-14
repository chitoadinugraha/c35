use c35_mod_chat::prompt::computer_use::{
    computer_use_final_text_acceptable, computer_use_goal_met, computer_use_goal_met_with_goal,
    reply_looks_like_computer_use_incomplete, reply_looks_like_computer_use_handoff,
};
use c35_mod_chat::prompt::google_forms::{
    google_forms_summary_sufficient, google_forms_tool_activity_sufficient, ComputerUseToolCounts,
};

#[test]
fn regression_oct13_child_give_up() {
    let text = "The form creation process on Google Forms is currently blocked by the UI state, \
as multiple tabs are open and the Blank form template is not responding to sel";
    assert!(reply_looks_like_computer_use_incomplete(text));
    assert!(!computer_use_final_text_acceptable(text));
}

#[test]
fn goal_met_requires_acceptable_summary_for_computer_use() {
    assert!(!computer_use_goal_met(
        "computer_use",
        "done",
        "Please click Blank form to continue."
    ));
    let forms_goal = "buat google form judul Test Pendaftaran dengan field nama, gender, alamat";
    let forms_ok_counts = ComputerUseToolCounts {
        device_input: 10,
        device_screenshot: 2,
    };
    assert!(computer_use_goal_met_with_goal(
        "computer_use",
        "done",
        "Form Test Pendaftaran created with nama, gender, alamat.",
        forms_goal,
        forms_ok_counts,
    ));
    assert!(!computer_use_goal_met_with_goal(
        "computer_use",
        "done",
        "Form Test Pendaftaran created with nama, gender, alamat.",
        forms_goal,
        ComputerUseToolCounts {
            device_input: 2,
            device_screenshot: 1,
        },
    ));
    assert!(!computer_use_goal_met_with_goal(
        "computer_use",
        "done",
        "Opened Chrome and navigated to forms.new.",
        forms_goal,
        forms_ok_counts,
    ));
    assert!(computer_use_goal_met("research", "done", "Please click for more info."));
    assert!(!computer_use_goal_met("computer_use", "failed", "done text"));
}

#[test]
fn google_forms_tool_activity_heuristics() {
    let goal = "judul Test Pendaftaran, field nama gender alamat";
    assert!(google_forms_tool_activity_sufficient(
        goal,
        ComputerUseToolCounts {
            device_input: 10,
            device_screenshot: 2,
        },
    ));
    assert!(!google_forms_tool_activity_sufficient(
        goal,
        ComputerUseToolCounts {
            device_input: 2,
            device_screenshot: 1,
        },
    ));
}

#[test]
fn google_forms_summary_heuristics() {
    let goal = "judul Test Pendaftaran, field nama gender alamat";
    assert!(google_forms_summary_sufficient(
        goal,
        "Created form Test Pendaftaran with nama, gender, alamat fields."
    ));
    assert!(!google_forms_summary_sufficient(goal, "Opened the template gallery in Chrome."));
}

#[test]
fn handoff_vs_incomplete_boundaries() {
    assert!(reply_looks_like_computer_use_handoff("Please click Submit."));
    assert!(!reply_looks_like_computer_use_incomplete("Please click Submit."));
}
