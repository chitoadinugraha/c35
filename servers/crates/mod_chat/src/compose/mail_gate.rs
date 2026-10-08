use crate::tools::ToolDef;

pub fn tool_platform_mail_eligible(def: &ToolDef, platform_mail: bool) -> bool {
    if !def.requires_platform_mail {
        return true;
    }
    platform_mail
}
