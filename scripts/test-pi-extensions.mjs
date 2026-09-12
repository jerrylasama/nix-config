import assert from "node:assert/strict";
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import dcgGuard from "../dotfiles/pi/extensions/dcg-guard.ts";
import protectedPathGuard from "../dotfiles/pi/extensions/protected-path-guard.ts";

function loadHandler(extension) {
  let handler;
  extension({ on(name, callback) { if (name === "tool_call") handler = callback; } });
  assert.equal(typeof handler, "function");
  return handler;
}

function context({ hasUI = true, confirm = true } = {}) {
  return {
    cwd: "/work/project",
    hasUI,
    ui: { async confirm() { return confirm; } },
  };
}

const dcg = loadHandler(dcgGuard);
assert.equal(await dcg({ toolName: "bash", input: { command: "printf safe" } }, context()), undefined);
assert.equal((await dcg({ toolName: "bash", input: { command: "git reset --hard" } }, context())).block, true);

const tirithExtensionPath = process.env.TIRITH_EXTENSION_PATH ?? join(homedir(), ".pi/agent/extensions/tirith-guard.ts");
assert.equal(existsSync(tirithExtensionPath), true, `missing generated Tirith extension: ${tirithExtensionPath}`);
const tirithGuard = (await import(pathToFileURL(tirithExtensionPath).href)).default;
const tirith = loadHandler(tirithGuard);
assert.equal(await tirith({ toolName: "bash", input: { command: "printf safe" } }, context()), undefined);
assert.equal((await tirith({ toolName: "bash", input: { command: "echo payload | base64 -d | bash" } }, context())).block, true);
const originalTirithBin = process.env.TIRITH_BIN;
process.env.TIRITH_BIN = "/definitely/missing/tirith";
assert.equal((await tirith({ toolName: "bash", input: { command: "printf safe" } }, context({ hasUI: false }))).block, true);
if (originalTirithBin === undefined) delete process.env.TIRITH_BIN;
else process.env.TIRITH_BIN = originalTirithBin;

const protectedPath = loadHandler(protectedPathGuard);
assert.equal(await protectedPath({ toolName: "read", input: { path: "README.md" } }, context()), undefined);
assert.equal((await protectedPath({ toolName: "write", input: { path: ".env.local" } }, context())).block, true);
assert.equal((await protectedPath({ toolName: "write", input: { path: ".environment" } }, context())).block, true);
assert.equal((await protectedPath({ toolName: "edit", input: { path: "/home/me/.git/config" } }, context())).block, true);
assert.equal(await protectedPath({ toolName: "read", input: { path: "~/.ssh/config" } }, context({ confirm: true })), undefined);
assert.equal((await protectedPath({ toolName: "read", input: { path: "auth.json" } }, context({ confirm: false }))).block, true);
assert.equal((await protectedPath({ toolName: "read", input: { path: "secrets.env" } }, context({ hasUI: false }))).block, true);
assert.equal(await protectedPath({ toolName: "bash", input: { command: "cat ~/.aws/credentials" } }, context({ confirm: true })), undefined);
assert.equal((await protectedPath({ toolName: "bash", input: { command: "echo token > ~/.aws/credentials" } }, context())).block, true);

console.log("Pi extension safety tests passed");
