//! Decode CSA site_config.doc (protobuf SiteDoc) to c35 draft doc_json on stdout.
//! Usage: csa_decode_site_doc < doc.bin   OR   csa_decode_site_doc path/to/doc.bin

use c35_mod_site::doc::site_doc_to_json;
use c35_proto::{pb_decode, SiteDoc};
use std::io::Read;

fn main() {
    let bytes = read_bytes().expect("read stdin or file");
    let doc: SiteDoc = pb_decode(&bytes).expect("decode SiteDoc");
    let json = site_doc_to_json(&doc).expect("site_doc_to_json");
    println!("{}", serde_json::to_string(&json).expect("json"));
}

fn read_bytes() -> std::io::Result<Vec<u8>> {
    let mut args: Vec<String> = std::env::args().skip(1).collect();
    if args.is_empty() {
        let mut buf = Vec::new();
        std::io::stdin().read_to_end(&mut buf)?;
        return Ok(buf);
    }
    std::fs::read(&args[0])
}
