import { Pool } from "pg";
import { config } from "./config";

export const pool = new Pool({
  connectionString: config.databaseUrl
});

export async function initDb(): Promise<void> {
  await pool.query(`
    create table if not exists admin_users (
      id bigserial primary key,
      username text not null unique,
      password_hash text not null,
      created_at timestamptz not null default now(),
      updated_at timestamptz not null default now()
    );

    create table if not exists action_log (
      id bigserial primary key,
      actor text not null,
      action text not null,
      result text not null,
      details jsonb not null default '{}'::jsonb,
      created_at timestamptz not null default now()
    );
  `);
}

export async function hasAdminUsers(): Promise<boolean> {
  const result = await pool.query("select 1 from admin_users limit 1");
  return result.rows.length > 0;
}

export async function getAdminUser(username: string): Promise<{ username: string; passwordHash: string } | null> {
  const result = await pool.query("select username, password_hash from admin_users where username = $1 limit 1", [
    username
  ]);
  const row = result.rows[0] as { username: string; password_hash: string } | undefined;
  if (!row) {
    return null;
  }

  return {
    username: row.username,
    passwordHash: row.password_hash
  };
}

export async function upsertAdminUser(username: string, passwordHash: string): Promise<void> {
  await pool.query(
    `
      insert into admin_users (username, password_hash)
      values ($1, $2)
      on conflict (username)
      do update set password_hash = excluded.password_hash, updated_at = now()
    `,
    [username, passwordHash]
  );
}

export async function logAction(actor: string, action: string, result: string, details: unknown): Promise<void> {
  await pool.query(
    "insert into action_log (actor, action, result, details) values ($1, $2, $3, $4::jsonb)",
    [actor, action, result, JSON.stringify(details ?? {})]
  );
}
