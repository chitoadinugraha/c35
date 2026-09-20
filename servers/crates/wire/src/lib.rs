use thiserror::Error;

#[derive(Debug, Error)]
pub enum WireErr {
    #[error("{code}: {message}")]
    Client { code: &'static str, message: String },
    #[error("unauthorized")]
    Unauthorized,
    #[error("internal: {0}")]
    Internal(String),
}

impl WireErr {
    pub fn client(code: &'static str, message: impl Into<String>) -> Self {
        Self::Client {
            code,
            message: message.into(),
        }
    }

    pub fn into_proto(self) -> c35_proto::Err {
        match self {
            Self::Unauthorized => c35_proto::Err {
                code: "unauthorized".into(),
                message: "Please sign in again.".into(),
            },
            Self::Client { code, message } => c35_proto::Err {
                code: code.into(),
                message,
            },
            Self::Internal(_msg) => c35_proto::Err {
                code: "internal".into(),
                message: "Something went wrong. Please try again.".into(),
            },
        }
    }
}

pub type WireResult<T> = Result<T, WireErr>;
