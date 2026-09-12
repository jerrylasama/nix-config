// Pi integration recipe maintained by destructive_command_guard:
// https://github.com/Dicklesworthstone/destructive_command_guard/blob/v0.14.3/docs/pi-integration.md
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { spawn } from "node:child_process";

const DCG_BIN = process.env.DCG_BIN ?? "dcg";
const UNAVAILABLE = { deny: false, reason: "" };

export function dcgDecision(command: string): Promise<{ deny: boolean; reason: string }> {
  return new Promise((resolve) => {
    let settled = false;
    const settle = (decision: { deny: boolean; reason: string }) => {
      if (settled) return;
      settled = true;
      resolve(decision);
    };

    let child;
    try {
      child = spawn(DCG_BIN, ["--robot", "test", command], {
        stdio: ["ignore", "pipe", "ignore"],
      });
    } catch {
      settle(UNAVAILABLE);
      return;
    }

    let stdout = "";
    child.stdout?.on("data", (chunk) => {
      stdout += chunk.toString();
    });
    child.on("error", () => settle(UNAVAILABLE));
    child.on("close", (code) => {
      if (code === 1) {
        let reason = "Blocked by dcg (destructive command).";
        try {
          const parsed = JSON.parse(stdout);
          if (parsed?.reason) reason = parsed.reason;
          if (parsed?.rule_id) reason += ` [${parsed.rule_id}]`;
        } catch {
          // The exit code remains authoritative if dcg emits malformed JSON.
        }
        settle({ deny: true, reason });
      } else {
        settle(UNAVAILABLE);
      }
    });
  });
}

export default function dcgGuard(pi: ExtensionAPI): void {
  pi.on("tool_call", async (event) => {
    if (event.toolName !== "bash") return;
    const command = String((event.input as { command?: unknown }).command ?? "");
    if (!command.trim()) return;

    let decision;
    try {
      decision = await dcgDecision(command);
    } catch {
      decision = UNAVAILABLE;
    }
    if (decision.deny) return { block: true, reason: decision.reason };
  });
}
