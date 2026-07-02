import cookie from "@fastify/cookie";
import cors from "@fastify/cors";
import jwt from "@fastify/jwt";
import bcrypt from "bcryptjs";
import Fastify, { FastifyReply, FastifyRequest } from "fastify";
import { promises as fs } from "node:fs";
import net from "node:net";
import os from "node:os";
import path from "node:path";
import { config } from "./config";
import { getAdminUser, hasAdminUsers, initDb, logAction, upsertAdminUser } from "./db";
import { parseStatusFlags, parseSvnetVersion, parseUpdateCheck } from "./parsers";
import { runFile } from "./processRunner";
import { runSvnetCommand, SvnetCommandKey, svnetCommandText } from "./svnetCli";

type LoginBody = {
  username?: string;
  password?: string;
};

type SetupBody = {
  setupToken?: string;
  username?: string;
  password?: string;
};

type ConfirmBody = {
  confirm?: boolean;
};

const listFiles: Record<string, string> = {
  "direct-domains": "direct-domains.txt",
  "vpn-domains": "vpn-domains.txt",
  "direct-ip": "direct-ip.txt",
  "vpn-ip": "vpn-ip.txt",
  "local-bypass": "local-bypass.txt"
};

const app = Fastify({
  logger: true
});

function currentUser(request: FastifyRequest): string {
  const user = request.user as { sub?: string } | undefined;
  return user?.sub ?? "unknown";
}

async function requireAuth(request: FastifyRequest, reply: FastifyReply): Promise<void> {
  try {
    await request.jwtVerify();
  } catch {
    reply.code(401).send({ ok: false, error: "unauthorized" });
  }
}

function requireConfirmation(request: FastifyRequest, reply: FastifyReply): boolean {
  const body = (request.body ?? {}) as ConfirmBody;
  if (body.confirm !== true) {
    reply.code(400).send({ ok: false, error: "confirmation_required" });
    return false;
  }

  return true;
}

async function runAction(
  request: FastifyRequest,
  reply: FastifyReply,
  action: string,
  commandKey: SvnetCommandKey,
  timeoutMs = 120_000
) {
  if (!requireConfirmation(request, reply)) {
    return;
  }

  const result = await runSvnetCommand(commandKey, timeoutMs);
  const ok = result.exitCode === 0 && !result.timedOut;
  await logAction(currentUser(request), action, ok ? "success" : "failed", {
    command: svnetCommandText(commandKey),
    exitCode: result.exitCode,
    timedOut: result.timedOut
  });

  return {
    ok,
    command: svnetCommandText(commandKey),
    result
  };
}

async function systemMetrics() {
  const disk = await runFile("df", ["-h", config.svnetBaseDir], { timeoutMs: 5_000 }).catch((error) => ({
    command: "df",
    args: ["-h", config.svnetBaseDir],
    exitCode: 1,
    signal: null,
    stdout: "",
    stderr: error instanceof Error ? error.message : String(error),
    timedOut: false
  }));

  return {
    memory: {
      totalBytes: os.totalmem(),
      freeBytes: os.freemem()
    },
    disk
  };
}

async function listBackups() {
  const backupsDir = path.join(config.svnetBaseDir, "backups");
  try {
    const entries = await fs.readdir(backupsDir);
    const items = await Promise.all(
      entries.map(async (name) => {
        const fullPath = path.join(backupsDir, name);
        const stat = await fs.stat(fullPath);
        return {
          name,
          path: fullPath,
          sizeBytes: stat.size,
          modifiedAt: stat.mtime.toISOString(),
          isDirectory: stat.isDirectory()
        };
      })
    );

    return items.sort((a, b) => b.modifiedAt.localeCompare(a.modifiedAt));
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      return [];
    }
    throw error;
  }
}

async function readList(name: string) {
  const fileName = listFiles[name];
  if (!fileName) {
    return null;
  }

  const listsDir = path.resolve(config.svnetBaseDir, "lists");
  const fullPath = path.resolve(listsDir, fileName);
  if (!fullPath.startsWith(`${listsDir}${path.sep}`)) {
    throw new Error("Unsafe list path");
  }

  const content = await fs.readFile(fullPath, "utf8").catch((error) => {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      return "";
    }
    throw error;
  });

  return {
    name,
    fileName,
    entries: content
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line.length > 0 && !line.startsWith("#"))
  };
}

function checkTcp(host: string, port: number, timeoutMs: number): Promise<boolean> {
  return new Promise((resolve) => {
    const socket = net.createConnection({ host, port });
    const timer = setTimeout(() => {
      socket.destroy();
      resolve(false);
    }, timeoutMs);

    socket.once("connect", () => {
      clearTimeout(timer);
      socket.end();
      resolve(true);
    });
    socket.once("error", () => {
      clearTimeout(timer);
      resolve(false);
    });
  });
}

async function registerRoutes() {
  await app.register(cors, {
    origin: config.frontendOrigin,
    credentials: true
  });
  await app.register(cookie);
  await app.register(jwt, {
    secret: config.jwtSecret,
    cookie: {
      cookieName: config.authCookieName,
      signed: false
    }
  });

  app.get("/api/health", async () => ({
    ok: true,
    service: "svnet-admin-backend",
    version: "1.1.0-alpha.6"
  }));

  app.get("/api/setup/status", async () => ({
    ok: true,
    needsSetup: !(await hasAdminUsers())
  }));

  app.post("/api/setup", async (request, reply) => {
    if (await hasAdminUsers()) {
      return reply.code(409).send({ ok: false, error: "setup_already_completed" });
    }

    const body = (request.body ?? {}) as SetupBody;
    const username = body.username?.trim() ?? "";
    const password = body.password ?? "";

    if (body.setupToken !== config.adminSetupToken) {
      return reply.code(401).send({ ok: false, error: "invalid_setup_token" });
    }

    if (username.length < 3) {
      return reply.code(400).send({ ok: false, error: "username_too_short" });
    }

    if (password.length < 12) {
      return reply.code(400).send({ ok: false, error: "password_too_short" });
    }

    const hash = await bcrypt.hash(password, 12);
    await upsertAdminUser(username, hash);
    await logAction("setup", "admin-setup", "success", { username });
    return { ok: true };
  });

  app.post("/api/auth/login", async (request, reply) => {
    const body = (request.body ?? {}) as LoginBody;
    if (!body.username || !body.password) {
      return reply.code(401).send({ ok: false, error: "invalid_credentials" });
    }

    const user = await getAdminUser(body.username);
    if (!user) {
      return reply.code(401).send({ ok: false, error: "invalid_credentials" });
    }

    const valid = await bcrypt.compare(body.password, user.passwordHash);
    if (!valid) {
      return reply.code(401).send({ ok: false, error: "invalid_credentials" });
    }

    const token = app.jwt.sign({ sub: user.username, role: "admin" }, { expiresIn: "12h" });
    reply.setCookie(config.authCookieName, token, {
      httpOnly: true,
      sameSite: "lax",
      secure: config.cookieSecure,
      path: "/",
      maxAge: 12 * 60 * 60
    });

    return { ok: true, user: user.username };
  });

  app.post("/api/auth/logout", { preHandler: requireAuth }, async (_request, reply) => {
    reply.clearCookie(config.authCookieName, { path: "/" });
    return { ok: true };
  });

  app.get("/api/auth/me", { preHandler: requireAuth }, async (request) => ({
    ok: true,
    user: currentUser(request)
  }));

  app.get("/api/svnet/version", { preHandler: requireAuth }, async () => {
    const result = await runSvnetCommand("version", 30_000);
    return {
      ok: result.exitCode === 0,
      version: parseSvnetVersion(result.stdout),
      result
    };
  });

  app.get("/api/svnet/status", { preHandler: requireAuth }, async () => {
    const result = await runSvnetCommand("status", 120_000);
    const output = `${result.stdout}\n${result.stderr}`;
    return {
      ok: result.exitCode === 0,
      parsed: parseStatusFlags(output),
      system: await systemMetrics(),
      result
    };
  });

  app.get("/api/svnet/doctor", { preHandler: requireAuth }, async () => {
    const result = await runSvnetCommand("doctor", 120_000);
    return { ok: result.exitCode === 0, result };
  });

  app.get("/api/publish/status", { preHandler: requireAuth }, async () => {
    const result = await runSvnetCommand("publishStatus", 60_000);
    return { ok: result.exitCode === 0, result };
  });

  app.post("/api/publish/on", { preHandler: requireAuth }, async (request, reply) =>
    runAction(request, reply, "publish-on", "publishOn", 120_000)
  );

  app.post("/api/publish/off", { preHandler: requireAuth }, async (request, reply) =>
    runAction(request, reply, "publish-off", "publishOff", 120_000)
  );

  app.get("/api/updates/check", { preHandler: requireAuth }, async () => {
    const result = await runSvnetCommand("updatesCheck", 120_000);
    return {
      ok: result.exitCode === 0,
      parsed: parseUpdateCheck(result.stdout),
      result
    };
  });

  app.get("/api/updates/dry-run", { preHandler: requireAuth }, async () => {
    const result = await runSvnetCommand("updatesDryRun", 120_000);
    return { ok: result.exitCode === 0, result };
  });

  app.post("/api/updates/apply", { preHandler: requireAuth }, async (request, reply) =>
    runAction(request, reply, "safe-update", "updatesApply", 600_000)
  );

  app.get("/api/backups", { preHandler: requireAuth }, async () => ({
    ok: true,
    backups: await listBackups(),
    restoreNotice: "Restore пока доступен только через CLI: sudo svnet"
  }));

  app.post("/api/backups/create", { preHandler: requireAuth }, async (request, reply) =>
    runAction(request, reply, "backup-create", "backupCreate", 180_000)
  );

  app.get("/api/lists/:name", { preHandler: requireAuth }, async (request, reply) => {
    const { name } = request.params as { name: string };
    const list = await readList(name);
    if (!list) {
      return reply.code(404).send({ ok: false, error: "unknown_list" });
    }
    return { ok: true, list };
  });

  app.get("/api/mikrotik/status", { preHandler: requireAuth }, async () => {
    const ping = await runFile("ping", ["-c", "1", "-W", "1", config.mikrotikHost], { timeoutMs: 3_000 })
      .then((result) => result.exitCode === 0)
      .catch(() => false);

    return {
      ok: true,
      host: config.mikrotikHost,
      ping,
      apiPort: config.mikrotikApiPort,
      apiTcpOpen: await checkTcp(config.mikrotikHost, config.mikrotikApiPort, 2_000),
      mode: "read-only"
    };
  });
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function initDbWithRetry(): Promise<void> {
  let lastError: unknown;
  for (let attempt = 1; attempt <= 30; attempt += 1) {
    try {
      await initDb();
      return;
    } catch (error) {
      lastError = error;
      app.log.warn({ attempt, error }, "Database is not ready yet");
      await sleep(2_000);
    }
  }

  throw lastError;
}

async function start() {
  await initDbWithRetry();
  await registerRoutes();
  await app.listen({ host: config.host, port: config.port });
}

start().catch((error) => {
  app.log.error(error);
  process.exit(1);
});
