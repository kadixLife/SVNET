import { config } from "./config";
import { CommandResult, runFile } from "./processRunner";

export const SVNET_COMMANDS = {
  status: ["--status"],
  doctor: ["--doctor"],
  version: ["--version"],
  publishStatus: ["--publish-status"],
  publishOn: ["--publish-on"],
  publishOff: ["--publish-off"],
  updatesCheck: ["--check-updates"],
  updatesDryRun: ["--update-dry-run"],
  updatesApply: ["--update"],
  backupCreate: ["--backup"],
  adminStatus: ["--admin-status"]
} as const;

export type SvnetCommandKey = keyof typeof SVNET_COMMANDS;

export function svnetCommandText(key: SvnetCommandKey): string {
  return ["svnet", ...SVNET_COMMANDS[key]].join(" ");
}

export async function runSvnetCommand(key: SvnetCommandKey, timeoutMs = 120_000): Promise<CommandResult> {
  const args = SVNET_COMMANDS[key];
  if (!args) {
    throw new Error("Command is not allowlisted");
  }

  return runFile(config.svnetCli, [...args], { timeoutMs });
}
