fn main() {
    mod embed {
        include!("../agent_version_build.rs");
    }
    embed::embed_agent_version("../VERSION.android");
}
