import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { registerAgentTools } from "./agent_http.js";
import { registerInstTools } from "./inst.js";
import { registerLogTools } from "./log.js";
import { registerMsgTools } from "./msg.js";

const server = new McpServer({ name: "c35", version: "0.2.0" });

registerInstTools(server);
registerLogTools(server);
registerMsgTools(server);
registerAgentTools(server);

const main = async () => {
  if (!process.env.DATABASE_URL?.trim()) {
    console.error("DATABASE_URL required");
    process.exit(1);
  }
  const transport = new StdioServerTransport();
  await server.connect(transport);
};

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
