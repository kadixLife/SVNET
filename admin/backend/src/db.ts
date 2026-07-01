import { Pool } from "pg";
import { config } from "./config";

export const pool = new Pool({
  connectionString: config.databaseUrl
});

export async function initDb(): Promise<void> {
  await pool.query(`
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

export async function logAction(actor: string, action: string, result: string, details: unknown): Promise<void> {
  await pool.query(
    "insert into action_log (actor, action, result, details) values ($1, $2, $3, $4::jsonb)",
    [actor, action, result, JSON.stringify(details ?? {})]
  );
}
