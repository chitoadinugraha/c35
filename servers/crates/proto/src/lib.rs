//! Generated c35 protobuf types from `_/schemas/proto/c35/*.proto`.

include!(concat!(env!("OUT_DIR"), "/c35.rs"));

pub use prost::Message;

pub fn pb_encode<M: Message>(msg: &M) -> Vec<u8> {
    msg.encode_to_vec()
}

pub fn pb_decode<M: Message + Default>(bytes: &[u8]) -> Result<M, prost::DecodeError> {
    M::decode(bytes)
}
