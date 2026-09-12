import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { homedir } from "node:os";
import { basename, isAbsolute, relative, resolve, sep } from "node:path";

const HOME_PROTECTED_DIRECTORIES = [
  ".ssh",
  ".gnupg",
  ".aws",
  ".azure",
  ".kube",
  ".oci",
  ".config/gcloud",
  ".config/gh",
  ".config/doctl",
  ".config/hcloud",
  ".config/rclone",
];

const READ_ONLY_TOOLS = new Set(["read", "grep", "find", "ls"]);
const WRITE_TOOLS = new Set(["write", "edit"]);

function isWithin(path: string, directory: string): boolean {
  const rel = relative(directory, path);
  return rel === "" || (!rel.startsWith(`..${sep}`) && rel !== "..");
}

export function protectedPathReason(
  rawPath: string,
  cwd = process.cwd(),
  home = homedir(),
): string | undefined {
  const expanded = rawPath === "~" ? home : rawPath.startsWith("~/") ? resolve(home, rawPath.slice(2)) : rawPath;
  const absolute = resolve(isAbsolute(expanded) ? expanded : resolve(cwd, expanded));
  const parts = absolute.split(sep).filter(Boolean);
  const name = basename(absolute);

  if (parts.includes(".git")) return ".git repository metadata";
  if (name.startsWith(".env")) return "environment secret file";
  if (name === "auth.json") return "Pi authentication data";
  if (name === "secrets.env") return "local secrets file";

  for (const directory of HOME_PROTECTED_DIRECTORIES) {
    if (isWithin(absolute, resolve(home, directory))) return `protected credential directory ~/.${directory.replace(/^\./, "")}`;
  }
  return undefined;
}

function inputPaths(input: unknown): string[] {
  if (!input || typeof input !== "object") return [];
  const value = input as Record<string, unknown>;
  const candidates = [value.path, value.file_path, value.paths];
  return candidates.flatMap((candidate) =>
    typeof candidate === "string"
      ? [candidate]
      : Array.isArray(candidate)
        ? candidate.filter((item): item is string => typeof item === "string")
        : [],
  );
}

function shellProtectedReason(command: string, cwd: string, home: string): string | undefined {
  const expanded = command
    .replace(/\$\{HOME\}/g, home)
    .replace(/\$HOME\b/g, home)
    .replace(/(^|[\s"'=])~\//g, `$1${home}/`);
  const pathLike = expanded.match(/(?:^|[\s"'=])([^\s"';&|<>]+)/g) ?? [];

  for (const token of pathLike) {
    const cleaned = token.trim().replace(/[),:]+$/, "");
    const reason = protectedPathReason(cleaned, cwd, home);
    if (reason) return reason;
  }
  return undefined;
}

export function shellMutatesProtectedPath(command: string): boolean {
  return /(?:^|[;&|]\s*|\b)(?:rm|mv|cp|install|touch|mkdir|rmdir|truncate|tee|chmod|chown|chgrp|shred)\b|(?:^|\s)(?:sed|perl)\s+[^\n;&|]*-[A-Za-z]*i|(?:^|[^<])>{1,2}(?!>)/i.test(command);
}

export default function protectedPathGuard(pi: ExtensionAPI): void {
  pi.on("tool_call", async (event, ctx) => {
    const cwd = ctx.cwd;
    const home = homedir();

    if (WRITE_TOOLS.has(event.toolName)) {
      const match = inputPaths(event.input)
        .map((path) => protectedPathReason(path, cwd, home))
        .find(Boolean);
      if (match) return { block: true, reason: `Blocked write to ${match}.` };
      return;
    }

    if (READ_ONLY_TOOLS.has(event.toolName)) {
      const match = inputPaths(event.input)
        .map((path) => protectedPathReason(path, cwd, home))
        .find(Boolean);
      if (!match) return;
      if (!ctx.hasUI) return { block: true, reason: `Blocked access to ${match}: confirmation is unavailable without a UI.` };
      const allowed = await ctx.ui.confirm("Confirm protected-path access", `Allow ${event.toolName} access to ${match}?`);
      if (!allowed) return { block: true, reason: `Blocked access to ${match} by user.` };
      return;
    }

    if (event.toolName === "bash") {
      const command = String((event.input as { command?: unknown }).command ?? "");
      const match = shellProtectedReason(command, cwd, home);
      if (!match) return;
      if (shellMutatesProtectedPath(command)) return { block: true, reason: `Blocked shell mutation of ${match}.` };
      if (!ctx.hasUI) return { block: true, reason: `Blocked shell access to ${match}: confirmation is unavailable without a UI.` };
      const allowed = await ctx.ui.confirm("Confirm protected-path access", `Allow shell access to ${match}?\n\n${command}`);
      if (!allowed) return { block: true, reason: `Blocked shell access to ${match} by user.` };
    }
  });
}
