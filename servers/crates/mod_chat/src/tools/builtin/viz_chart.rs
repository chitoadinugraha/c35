use crate::tool;
use crate::viz_chart::{viz_chart_block_from_value, viz_chart_llm_summary};
use anyhow::Result;
use serde_json::{json, Value};

use crate::tools::ToolContext;

pub async fn viz_chart_exec(_ctx: &ToolContext, args: &Value) -> Result<Value> {
    match viz_chart_block_from_value(args) {
        Ok(block) => {
            let llm = viz_chart_llm_summary(&block["body"]);
            Ok(json!({
                "ok": true,
                "runner": "cluster",
                "tool": "viz.chart",
                "block": block,
                "llm": llm,
            }))
        }
        Err(e) => Ok(json!({
            "ok": false,
            "runner": "cluster",
            "tool": "viz.chart",
            "error": e,
        })),
    }
}

tool! {
    struct: VizChartTool,
    name: "viz.chart",
    aliases: ["chart", "viz_chart"],
    description: "Attach a native bar, line, or pie chart block to the assistant message. Use for trends, comparisons over time, or share breakdowns. Put numbers only in the chart — keep prose as a short summary.",
    topics: ["general"],
    rag_phrases: [
        "chart", "grafik", "graph", "plot", "trend", "time series", "breakdown", "pie chart",
        "bar chart", "line chart", "visualize", "visualisasi",
    ],
    ui_calling_key: "tool.viz.chart.calling",
    ui_done_key: "tool.viz.chart.done",
    readonly: true,
    parameters: {
        chart_type: (string, "bar | line | pie", required),
        title: (string, "Chart title", optional),
        x_label: (string, "X axis label", optional),
        y_label: (string, "Y axis label", optional),
        labels: (array, "Category or time labels (same order as each series values)", required),
        series: (array, "Array of { name, values } — values length must match labels", required),
    },
    execute: |args, ctx| viz_chart_exec(ctx, &args).await
}
