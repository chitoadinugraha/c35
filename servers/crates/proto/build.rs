fn main() -> Result<(), Box<dyn std::error::Error>> {
    let manifest = std::path::Path::new(env!("CARGO_MANIFEST_DIR"));
    let proto_root = manifest.join("../../../_/schemas/proto");
    let c35 = proto_root.join("c35");

    let protos = [
        "types.proto",
        "identity.proto",
        "billing.proto",
        "chat.proto",
        "log.proto",
        "event.proto",
        "skill.proto",
        "task.proto",
        "remote.proto",
        "consumption.proto",
        "site.proto",
        "mail.proto",
        "collection.proto",
        "tx.proto",
        "sync.proto",
        "referral.proto",
        "admin.proto",
        "inst.proto",
        "channel.proto",
        "device.proto",
        "catalog.proto",
        "hint.proto",
        "session.proto",
        "voice.proto",
        "stats.proto",
        "object.proto",
        "report.proto",
        "fetch.proto",
        "wire.proto",
    ];

    std::env::set_var("PROTOC", protoc_bin_vendored::protoc_bin_path()?);

    let paths: Vec<_> = protos
        .iter()
        .map(|name| {
            let p = c35.join(name);
            println!("cargo:rerun-if-changed={}", p.display());
            p
        })
        .collect();

    prost_build::Config::new().compile_protos(&paths, &[proto_root])?;
    Ok(())
}
