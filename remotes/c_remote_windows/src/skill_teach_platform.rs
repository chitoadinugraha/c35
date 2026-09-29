pub fn register() {
    c_remote_core::skill_teach::register_platform(
        crate::skill_teach_hook::platform_start,
        crate::skill_teach_hook::platform_stop,
        crate::skill_teach_hook::platform_set_last,
    );
}
