use c35_mod_admin::{staff_tool_eligible, StaffView};

use crate::tools::ToolDef;

pub fn tool_staff_eligible(def: &ToolDef, staff: &StaffView) -> bool {
    staff_tool_eligible(staff, &def.requires_global_roles)
}
