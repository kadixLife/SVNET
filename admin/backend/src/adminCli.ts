import bcrypt from "bcryptjs";
import { deleteAdminUsers, initDb, logAction, pool, updateAdminPassword } from "./db";

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
  const updated = await updateAdminPassword(username, hash);
  if (!updated) {
    throw new Error(`Admin user not found: ${username}`);
  }

  await logAction("cli", "admin-reset-password", "success", { username });
  console.log(`Admin password updated for ${username}`);
}

async function resetSetup() {
  const marker = requiredEnv("SVNET_ADMIN_RESET_SETUP");
  if (marker !== "RESET_SETUP") {
    throw new Error("SVNET_ADMIN_RESET_SETUP confirmation is invalid");
  }

  const deletedAdmins = await deleteAdminUsers();
  await logAction("cli", "admin-reset-setup", "success", { deletedAdmins });
  console.log(`Admin setup reset. Deleted admin users: ${deletedAdmins}`);
}

async function main() {
  await initDb();
  const command = process.argv[2];
  if (command === "reset-password") {
    await resetPassword();
    return;
  }

  if (command === "reset-setup") {
    await resetSetup();
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
