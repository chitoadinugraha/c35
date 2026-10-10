//! CLI pairing UI (no tray / GTK on scaffold).

pub struct PairUi {
    quit: bool,
}

impl PairUi {
    pub fn new(_cli: bool) -> Self {
        Self { quit: false }
    }

    pub fn user_requested_quit(&self) -> bool {
        self.quit
    }

    pub fn set_connecting(&self) {
        println!("Connecting to Alien AI for pairing code…");
    }

    pub fn set_code(&self, code: &str, expires_in_sec: i64) {
        println!();
        println!("+--------------------------------------------------------------+");
        println!("|  Alien AI — Pair this Linux device                           |");
        println!("|  Code: {:<8}  (expires in ~{} sec)                    |", code, expires_in_sec);
        println!("|  In the app: Devices -> Pair with Code                       |");
        println!("+--------------------------------------------------------------+");
        println!();
    }

    pub fn set_status(&self, msg: &str) {
        println!("{msg}");
    }

    pub fn close(&self) {}
}
