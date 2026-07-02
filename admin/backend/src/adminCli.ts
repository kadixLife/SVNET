import bcrypt from "bcryptjs";
import { initDb, logAction, pool, upsertAdminUser } from "./db";

function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing ${name}`);
  }
  return value;
}

async function resetPassword() {
  const username = requiredEnv("SVNET_ADMIN_USER");
  const password = requiredEnv("SVNET_ADMIN_PASSWORD");

  if (username.length < 3) {
    throw new Error("Username must be at least 3 characters");
  }

  if (password.length < 12) {
    throw new Error("Password must be at least 12 characters");
  }

  const hash = await bcrypt.hash(password, 12);
  await upsertAdminUser(username, hash);
  await logAction("cli", "admin-reset-password", "success", { username });
  console.log(`Admin password updated for ${username}`);
}

async function main() {
  await initDb();
  const command = process.argv[2];
  if (command === "reset-password") {
    await resetPassword();
    return;
  }

  throw new Error(`Unknown admin command: ${command ?? ""}`);
}

main()
  .catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  })
  .finally(async () => {
    await pool.end();
  });
