fn main() {
    let path = std::env::args().nth(1).expect("usage: hash_blake3 <file>");
    let body = std::fs::read(&path).expect("read file");
    print!("{}", blake3::hash(&body).to_hex());
}
