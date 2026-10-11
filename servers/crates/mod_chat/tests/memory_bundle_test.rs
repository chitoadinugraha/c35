use c35_mod_chat::memory::{dot_product_256, is_trivial_query, l2_normalize_256};
use c35_proto::{ScopeInstruction, ScopeInstructionBundle, UserMemoryBundle, UserMemoryBundleItem};
use prost::Message;

#[test]
fn test_dot_product_256_normalized() {
    let mut vec_a = vec![0.0f32; 256];
    let mut vec_b = vec![0.0f32; 256];

    // Orthogonal unit vectors
    vec_a[0] = 1.0;
    vec_b[1] = 1.0;
    let sim_ortho = dot_product_256(&vec_a, &vec_b);
    assert!(sim_ortho.abs() < 1e-6, "orthogonal vectors must have sim 0.0");

    // Identical unit vectors
    let sim_ident = dot_product_256(&vec_a, &vec_a);
    assert!((sim_ident - 1.0).abs() < 1e-6, "identical unit vectors must have sim 1.0");

    // Random non-normalized vectors normalized via l2_normalize_256
    for i in 0..256 {
        vec_a[i] = (i as f32) * 0.1;
        vec_b[i] = (i as f32) * 0.1;
    }
    l2_normalize_256(&mut vec_a);
    l2_normalize_256(&mut vec_b);
    let sim_scaled = dot_product_256(&vec_a, &vec_b);
    assert!((sim_scaled - 1.0).abs() < 1e-5, "self dot product after L2 norm must be 1.0");
}

#[test]
fn test_is_trivial_query() {
    // Trivial queries should bypass expensive embedding API calls
    assert!(is_trivial_query("ok"));
    assert!(is_trivial_query("oke"));
    assert!(is_trivial_query("siap"));
    assert!(is_trivial_query("lanjut"));
    assert!(is_trivial_query("terima kasih"));
    assert!(is_trivial_query("makasih"));
    assert!(is_trivial_query("halo!"));
    assert!(is_trivial_query("   "));

    // Substantive queries must NOT be marked trivial
    assert!(!is_trivial_query("Berapa stok produk kopi luwak hari ini?"));
    assert!(!is_trivial_query("Tolong kirim invoice ke client"));
    assert!(!is_trivial_query("Siapa nama manajer operasional cabang timur?"));
}

#[test]
fn test_user_memory_bundle_protobuf_roundtrip() {
    let mut item1 = UserMemoryBundleItem {
        id: 101,
        key: "business_name".into(),
        content: "Kopi Kenangan Senopati".into(),
        is_pinned: true,
        tags: vec!["fact".into()],
        embedding: vec![0.1f32; 256],
    };
    l2_normalize_256(&mut item1.embedding);

    let mut item2 = UserMemoryBundleItem {
        id: 102,
        key: "owner_preference".into(),
        content: "Laporan harian dalam format CSV".into(),
        is_pinned: false,
        tags: vec!["preference".into()],
        embedding: vec![0.2f32; 256],
    };
    l2_normalize_256(&mut item2.embedding);

    let bundle = UserMemoryBundle {
        owner_iid: 12345678,
        bot_iid: 0,
        updated_ts_ms: 1760000000,
        items: vec![item1, item2],
    };

    let encoded = bundle.encode_to_vec();
    assert!(!encoded.is_empty());

    let decoded = UserMemoryBundle::decode(encoded.as_slice()).expect("decode UserMemoryBundle");
    assert_eq!(decoded.owner_iid, 12345678);
    assert_eq!(decoded.items.len(), 2);
    assert_eq!(decoded.items[0].key, "business_name");
    assert_eq!(decoded.items[0].embedding.len(), 256);
    assert!(decoded.items[0].is_pinned);
    assert_eq!(decoded.items[1].key, "owner_preference");
    assert_eq!(decoded.items[1].embedding.len(), 256);
    assert!(!decoded.items[1].is_pinned);

    // RAM dot product against a mock query
    let mut query_vec = vec![0.1f32; 256];
    l2_normalize_256(&mut query_vec);
    let sim = dot_product_256(&query_vec, &decoded.items[0].embedding);
    assert!((sim - 1.0).abs() < 1e-5, "query matches item1 perfectly");
}

#[test]
fn test_scope_instruction_bundle_protobuf_roundtrip() {
    let item = ScopeInstruction {
        id: 501,
        owner_iid: 88888,
        scope_kind: "user".into(),
        scope_iid: 88888,
        mode: "prepend".into(),
        body: "Selalu jawab dalam Bahasa Indonesia yang formal dan ramah.".into(),
        updated_ts_ms: 1760000000,
    };

    let bundle = ScopeInstructionBundle {
        owner_iid: 88888,
        updated_ts_ms: 1760000000,
        items: vec![item],
    };

    let encoded = bundle.encode_to_vec();
    let decoded = ScopeInstructionBundle::decode(encoded.as_slice()).expect("decode ScopeInstructionBundle");
    assert_eq!(decoded.owner_iid, 88888);
    assert_eq!(decoded.items.len(), 1);
    assert_eq!(decoded.items[0].body, "Selalu jawab dalam Bahasa Indonesia yang formal dan ramah.");
    assert_eq!(decoded.items[0].mode, "prepend");
}
