use crate::pair_window::PairWindow;

pub enum PairUi {
    Window(PairWindow),
    Cli,
}

impl PairUi {
    pub fn spawn(cli: bool) -> Self {
        if cli {
            Self::Cli
        } else {
            Self::Window(PairWindow::spawn())
        }
    }

    pub fn set_code(&self, code: &str, expires_in_sec: i64) {
        match self {
            Self::Window(w) => w.set_code(code, expires_in_sec),
            Self::Cli => print_code(code, expires_in_sec),
        }
    }

    pub fn set_status(&self, status: &str) {
        match self {
            Self::Window(w) => w.set_status(status),
            Self::Cli => println!(">>> {status}"),
        }
    }

    pub fn close(&self) {
        if let Self::Window(w) = self {
            w.close();
        }
    }
}

fn print_code(code: &str, expires_in_sec: i64) {
    println!();
    println!("============================================================");
    println!(">>> Alien AI Remote Agent - Pairing Required");
    println!(">>> Enter this in Alien AI -> Devices -> Pair with Code");
    println!(">>> [ {} ]  (expires in {}s)", code, expires_in_sec);
    println!("============================================================");
}
