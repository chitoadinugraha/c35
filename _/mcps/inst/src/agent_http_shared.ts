import { z } from "zod";

const serverUrl = () => (process.env.C35_SERVER_URL ?? "http://127.0.0.1:8080").replace(/\/$/, "");

const mcpAgentKey = () => {
  const key = process.env.C35_MCP_AGENT_KEY?.trim();
  if (!key) throw new Error("C35_MCP_AGENT_KEY required (see _/docs/mcp-security.md)");
  return key;
};

export type AgentResponse = {
  ok?: boolean;
  error?: string;
  action?: string;
  [key: string]: unknown;
};

export const ownerSchema = {
  owner_iid: z
    .number()
    .optional()
    .describe("Owner iid (default 33000). Allowed: 33000 tester, 99000 chito."),
  uid: z.number().optional().describe("Alias for owner_iid"),
};

export const agentPost = async (
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
    return { ok: false, error: `agent HTTP request failed: ${msg}`, action, url };
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
      error: `server endpoint not found (${url}). Set C35_MCP_AGENT_ENABLED=1 on server_ai.`,
      action,
      status: res.status,
      ...data,
    };
  }

  if (!res.ok) {
    return { ok: false, error: data.error ?? `HTTP ${res.status}`, action, status: res.status, ...data };
  }

  return { ok: true, action, ...data };
};
