import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { agentPost, ownerSchema } from "./agent_http_shared.js";
import { debugOwnerIid, jsonContent, resolveOwnerIid } from "./util.js";

const deviceOwner = (owner_iid?: number, uid?: number) =>
  owner_iid ?? uid ?? debugOwnerIid();

export const registerDeviceAgentTools = (server: McpServer) => {
  server.registerTool(
    "device_screenshot",
    {
      description:
        "Capture JPEG screenshot from a paired remote device via cluster device.screenshot (default owner 99000).",
      inputSchema: {
        device_iid: z.number().describe("Remote device identity id"),
        max_width: z.number().optional(),
        som: z.boolean().optional().describe("Set-of-Mark UI overlay"),
        ...ownerSchema,
      },
    },
    async ({ device_iid, max_width, som, owner_iid, uid }) => {
      const owner = deviceOwner(owner_iid, uid);
      const args: Record<string, unknown> = { device_iid };
      if (max_width !== undefined) args.max_width = max_width;
      if (som !== undefined) args.som = som;
      const result = await agentPost("tool_exec", { tool_name: "device.screenshot", args_json: args }, owner);
      return jsonContent(result);
    },
  );

  server.registerTool(
    "device_command",
    {
      description: "Run shell/PowerShell on a paired remote device (device.command). Default owner 99000.",
      inputSchema: {
        device_iid: z.number(),
        command: z.string(),
        shell: z.enum(["powershell", "cmd"]).optional(),
        timeout_secs: z.number().optional(),
        ...ownerSchema,
      },
    },
    async ({ device_iid, command, shell, timeout_secs, owner_iid, uid }) => {
      const owner = deviceOwner(owner_iid, uid);
      const args: Record<string, unknown> = { device_iid, command };
      if (shell) args.shell = shell;
      if (timeout_secs !== undefined) args.timeout_secs = timeout_secs;
      const result = await agentPost("tool_exec", { tool_name: "device.command", args_json: args }, owner);
      return jsonContent(result);
    },
  );

  server.registerTool(
    "device_input",
    {
      description: "Send mouse/keyboard input to remote device (device.input). Default owner 99000.",
      inputSchema: {
        device_iid: z.number(),
        event_type: z.string(),
        x: z.number().optional(),
        y: z.number().optional(),
        key_code: z.number().optional(),
        text: z.string().optional(),
        screenshot_after: z.boolean().optional(),
        ...ownerSchema,
      },
    },
    async (input) => {
      const { device_iid, owner_iid, uid, ...rest } = input;
      const owner = deviceOwner(owner_iid, uid);
      const args: Record<string, unknown> = { device_iid, ...rest };
      const result = await agentPost("tool_exec", { tool_name: "device.input", args_json: args }, owner);
      return jsonContent(result);
    },
  );

  server.registerTool(
    "device_list_http",
    {
      description: "List remote devices via /v1/mcp/agent device_list (no DATABASE_URL required).",
      inputSchema: { ...ownerSchema },
    },
    async ({ owner_iid, uid }) => {
      const owner = owner_iid ?? uid ?? resolveOwnerIid();
      const result = await agentPost("device_list", {}, owner);
      return jsonContent(result);
    },
  );

  server.registerTool(
    "device_get_http",
    {
      description: "Get one remote device via /v1/mcp/agent device_get.",
      inputSchema: {
        device_iid: z.number(),
        ...ownerSchema,
      },
    },
    async ({ device_iid, owner_iid, uid }) => {
      const owner = owner_iid ?? uid ?? resolveOwnerIid();
      const result = await agentPost("device_get", { args_json: { device_iid } }, owner);
      return jsonContent(result);
    },
  );
};
