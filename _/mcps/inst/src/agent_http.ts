import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { jsonContent, resolveOwnerIid } from "./util.js";

const serverUrl = () => (process.env.C35_SERVER_URL ?? "http://127.0.0.1:8080").replace(/\/$/, "");

const mcpAgentKey = () => {
  const key = process.env.C35_MCP_AGENT_KEY?.trim();
  if (!key) throw new Error("C35_MCP_AGENT_KEY required for tool_exec / prompt_* (see _/docs/mcp-security.md)");
  return key;
};

type AgentResponse = {
  ok?: boolean;
  error?: string;
  action?: string;
  [key: string]: unknown;
};

const ownerSchema = {
  owner_iid: z
    .number()
    .optional()
    .describe("Owner iid (default 33000). Allowed: 33000 tester, 99000 chito."),
  uid: z.number().optional().describe("Alias for owner_iid"),
};

const agentPost = async (
  action: string,
  body: Record<string, unknown>,
  ownerIid: number,
): Promise<AgentResponse> => {
  const url = `${serverUrl()}/v1/mcp/agent`;
  let res: Response;
  try {
    res = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-C35-Mcp-Key": mcpAgentKey(),
      },
      body: JSON.stringify({ action, owner_iid: ownerIid, ...body }),
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    return {
      ok: false,
      error: `agent HTTP request failed: ${msg}`,
      action,
      url,
    };
  }

  const text = await res.text();
  let data: AgentResponse;
  try {
    data = text ? (JSON.parse(text) as AgentResponse) : {};
  } catch {
    data = { raw: text };
  }

  if (res.status === 404) {
    return {
      ok: false,
      error: `server endpoint not found (${url}). Set C35_MCP_AGENT_ENABLED=1 on server_ai and redeploy.`,
      action,
      status: res.status,
      ...data,
    };
  }

  if (!res.ok) {
    return {
      ok: false,
      error: data.error ?? `HTTP ${res.status}`,
      action,
      status: res.status,
      ...data,
    };
  }

  return { ok: true, action, ...data };
};

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
        {
          text: prompt,
          locale: locale ?? "en-US",
        },
        resolveOwnerIid(owner_iid, uid),
      );
      return jsonContent(result);
    },
  );

  server.registerTool(
    "prompt_run",
    {
      description:
        "Run full prompt turn via server_ai. Returns assistant text, blocks, and full ai.log trace. Default owner 33000; use owner_iid/uid 99000 to test with chito consumption data.",
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
        {
          text: prompt,
          locale: locale ?? "en-US",
        },
        resolveOwnerIid(owner_iid, uid),
      );
      if (result.ok === false && (result.status === 404 || String(result.error ?? "").includes("not found"))) {
        return jsonContent({
          ok: false,
          error:
            "prompt_run endpoint disabled or not deployed. Set C35_MCP_AGENT_ENABLED=1 and C35_MCP_AGENT_KEY on server_ai.",
          action: "prompt_run",
          detail: result,
        });
      }
      return jsonContent(result);
    },
  );
};
