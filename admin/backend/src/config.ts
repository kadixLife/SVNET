function required(name: string): string {
  const value = process.env[name];
  if (!value || value.startsWith("CHANGE_")) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function numberFromEnv(name: string, fallback: number): number {
  const raw = process.env[name];
  if (!raw) {
    return fallback;
  }

  const value = Number(raw);
  if (!Number.isFinite(value)) {
    throw new Error(`Invalid numeric environment variable: ${name}`);
  }

  return value;
}

export const config = {
  host: process.env.HOST ?? "0.0.0.0",
  port: numberFromEnv("PORT", 3001),
  frontendOrigin: process.env.FRONTEND_ORIGIN ?? "http://localhost:3000",
  adminUser: required("ADMIN_USER"),
  adminPasswordHash: required("ADMIN_PASSWORD_HASH"),
  jwtSecret: required("JWT_SECRET"),
  authCookieName: process.env.AUTH_COOKIE_NAME ?? "svnet_admin_session",
  cookieSecure: process.env.COOKIE_SECURE === "true",
  databaseUrl: required("DATABASE_URL"),
  svnetCli: process.env.SVNET_CLI ?? "/usr/local/bin/svnet",
  svnetBaseDir: process.env.SVNET_BASE_DIR ?? "/opt/svobodanet",
  mikrotikHost: process.env.MIKROTIK_HOST ?? "10.88.0.2",
  mikrotikApiPort: numberFromEnv("MIKROTIK_API_PORT", 8728)
};
