#[cfg(target_os = "windows")]
mod win_mount {
    use c_remote_drive::runtime::{drive_mount, drive_unmount};
    use c_remote_drive::vfs_winfsp::init_winfsp_dll_path;

    #[tokio::test]
    async fn mount_a_drive_smoke() {
        init_winfsp_dll_path();
        let key = std::env::var("C35_DRIVE_SMOKE_SESSION").unwrap_or_else(|_| "smoke-session-not-paired".into());
        let base = std::env::var("C35_SERVER_URL").unwrap_or_else(|_| "https://alienai.id".into());
        drive_mount(&key, &base).await.expect("drive_mount");
        assert!(std::path::Path::new("A:\\").exists(), "A: should exist after mount");
        let out = std::process::Command::new("cmd")
            .args(["/c", "vol", "A:"])
            .output()
            .expect("vol");
        let vol_txt = String::from_utf8_lossy(&out.stdout);
        assert!(
            vol_txt.contains("Alien AI"),
            "vol A: should show Alien AI label, got: {vol_txt}"
        );
        drive_unmount();
    }
}