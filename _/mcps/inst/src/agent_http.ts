import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { agentPost, ownerSchema } from "./agent_http_shared.js";
import { jsonContent, resolveOwnerIid } from "./util.js";

export const registerAgentTools = (server: McpServer) => {
  server.registerTool(
    "tool_exec",
    {
      description:
        "Execute a cluster tool via server_ai /v1/mcp/agent. Default owner 33000; pass owner_iid/uid 99000 for chito data.",
      inputSchema: {
        tool: z.string().describe("Tool name (e.g. consumption.today)"),
        args: z.record(z.unknown()).optional().describe("Tool arguments object"),
        locale: z.string().optional().describe("Locale (default en-US)"),
        ...ownerSchema,
      },
    },
    async ({ tool, args, locale, owner_iid, uid }) => {
      const name = tool.trim();
      if (!name) throw new Error("tool required");
      const result = await agentPost(
        "tool_exec",
        {
          tool_name: name,
          args_json: args ?? {},
          locale: locale ?? "en-US",
        },
        resolveOwnerIid(owner_iid, uid),
      );
      return jsonContent(result);
    },
  );

  server.registerTool(
    "prompt_compose",
    {
      description:
        "Compose prompt (inst + tools) via server_ai without running LLM. Returns compose trace (tool filter, ranker, sim).",
      inputSchema: {
        text: z.string().describe("User prompt text"),
        locale: z.string().optional().describe("Locale (default en-US)"),
        ...ownerSchema,
      },
    },
    async ({ text, locale, owner_iid, uid }) => {
      const prompt = text.trim();
      if (!prompt) throw new Error("text required");
      const result = await agentPost(
        "prompt_compose",
        { text: prompt, locale: locale ?? "en-US" },
        resolveOwnerIid(owner_iid, uid),
      );
      return jsonContent(result);
    },
  );

  server.registerTool(
    "device_list_http",
    {
      description: "List paired remote devices via /v1/mcp/agent device_list (release compare).",
      inputSchema: ownerSchema,
    },
    async ({ owner_iid, uid }) => {
      const result = await agentPost("device_list", {}, resolveOwnerIid(owner_iid, uid));
      return jsonContent(result);
    },
  );

  server.registerTool(
    "prompt_run",
    {
      description:
        "Run full prompt turn via server_ai. Returns assistant text, blocks, and full ai.log trace.",
      inputSchema: {
        text: z.string().describe("User prompt text"),
        locale: z.string().optional().describe("Locale (default id-ID or en-US)"),
        ...ownerSchema,
      },
    },
    async ({ text, locale, owner_iid, uid }) => {
      const prompt = text.trim();
      if (!prompt) throw new Error("text required");
      const result = await agentPost(
        "prompt_run",
        { text: prompt, locale: locale ?? "en-US" },
        resolveOwnerIid(owner_iid, uid),
      );
      if (result.ok === false && (result.status === 404 || String(result.error ?? "").includes("not found"))) {
        return jsonContent({
          ok: false,
          error: "prompt_run disabled. Set C35_MCP_AGENT_ENABLED=1 on server_ai.",
          action: "prompt_run",
          detail: result,
        });
      }
      return jsonContent(result);
    },
  );
};
