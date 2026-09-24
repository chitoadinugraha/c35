use c35_mod_chat::prompt::thought::parse_candidate;
use c35_mod_chat::prompt::tool_loop::tool_calls_dup;
use c35_mod_chat::tools::{cluster_tool_exec, http_client};
use futures_util::future::join_all;
use serde_json::json;
use std::time::{Duration, Instant};

#[test]
fn test_parse_candidate_parallel_function_calls() {
    let raw = json!({
        "candidates": [{
            "content": {
                "role": "model",
                "parts": [
                    {
                        "functionCall": {
                            "name": "delegate_run",
                            "args": { "topic_id": "research", "goal": "Find Rust docs" }
                        }
                    },
                    {
                        "functionCall": {
                            "name": "delegate_run",
                            "args": { "topic_id": "research", "goal": "Find Go docs" }
                        }
                    },
                    {
                        "functionCall": {
                            "name": "web_search",
                            "args": { "query": "Rust vs Go" }
                        }
                    }
                ]
            }
        }],
        "usageMetadata": {
            "promptTokenCount": 100,
            "candidatesTokenCount": 45
        }
    });

    let out = parse_candidate(&raw);
    assert_eq!(out.function_calls.len(), 3);
    assert_eq!(out.function_calls[0].0, "delegate.run");
    assert_eq!(out.function_calls[0].1["goal"], "Find Rust docs");
    assert_eq!(out.function_calls[1].0, "delegate.run");
    assert_eq!(out.function_calls[1].1["goal"], "Find Go docs");
    assert_eq!(out.function_calls[2].0, "web.search");
    assert_eq!(out.function_calls[2].1["query"], "Rust vs Go");

    // Backward compatibility: function_call must point to the first item
    assert_eq!(out.function_call, Some(out.function_calls[0].clone()));
    assert_eq!(out.in_tok, 100);
    assert_eq!(out.out_tok, 45);
}

#[test]
fn test_tool_calls_dup_detection() {
    let calls_1 = vec![
        ("web.search".to_string(), json!({"query": "q1"})),
        ("delegate.run".to_string(), json!({"topic_id": "t1"})),
    ];
    let calls_2 = vec![
        ("web.search".to_string(), json!({"query": "q1"})),
        ("delegate.run".to_string(), json!({"topic_id": "t1"})),
    ];
    let calls_3 = vec![
        ("web.search".to_string(), json!({"query": "q2"})),
        ("delegate.run".to_string(), json!({"topic_id": "t1"})),
    ];

    assert!(tool_calls_dup(&calls_1, &calls_2));
    assert!(!tool_calls_dup(&calls_1, &calls_3));
    assert!(!tool_calls_dup(&[], &calls_1));
}

#[tokio::test]
async fn test_parallel_tool_dispatch_and_response_format() {
    let client = http_client(Duration::from_secs(5));
    let calls = vec![
        ("unknown_tool_a".to_string(), json!({"param": "alpha"})),
        ("unknown_tool_b".to_string(), json!({"param": "beta"})),
    ];

    let start = Instant::now();
    let executions = join_all(calls.iter().map(|(name, args)| {
        let client = &client;
        async move {
            let tool_started = Instant::now();
            let (result, tool_cost) = cluster_tool_exec(client, name, args, None).await;
            let tool_ms = tool_started.elapsed().as_millis() as i64;
            (name.clone(), args.clone(), result, tool_cost, tool_ms)
        }
    }))
    .await;
    let _elapsed = start.elapsed();

    assert_eq!(executions.len(), 2);

    let mut function_parts = Vec::with_capacity(executions.len());
    let mut total_cost = 0.0f64;

    for (name, _args, result, tool_cost, _tool_ms) in executions {
        total_cost += tool_cost;
        assert_eq!(result["ok"], false);
        assert!(result["error"].as_str().unwrap().contains("unknown cluster tool"));

        let llm_result = result.get("llm").cloned().unwrap_or(result.clone());
        function_parts.push(json!({
            "functionResponse": {
                "name": name.replace('.', "_"),
                "response": llm_result
            }
        }));
    }

    assert_eq!(total_cost, 0.0);
    assert_eq!(function_parts.len(), 2);
    assert_eq!(function_parts[0]["functionResponse"]["name"], "unknown_tool_a");
    assert_eq!(function_parts[1]["functionResponse"]["name"], "unknown_tool_b");

    // Construct single role: 'function' message matching Gemini API specs
    let function_msg = json!({
        "role": "function",
        "parts": function_parts
    });

    assert_eq!(function_msg["role"], "function");
    assert_eq!(function_msg["parts"].as_array().unwrap().len(), 2);
}
