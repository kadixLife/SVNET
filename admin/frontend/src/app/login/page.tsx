"use client";

import { FormEvent, useEffect, useState } from "react";
import { ShieldCheck } from "lucide-react";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export default function LoginPage() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    api<{ setupRequired: boolean; needsSetup?: boolean }>("/setup/status")
      .then((status) => {
        if (status.setupRequired ?? status.needsSetup) {
          window.location.href = "/setup";
        }
      })
      .catch(() => undefined);
  }, []);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLoading(true);
    setError("");
    try {
      await api("/auth/login", {
        method: "POST",
        body: JSON.stringify({ username, password })
      });
      window.location.href = "/";
    } catch {
      setError("Неверный логин или пароль.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center px-4 py-10">
      <form onSubmit={submit} className="w-full max-w-sm rounded-lg border border-border bg-white p-6 shadow-sm">
        <div className="mb-6 flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-md bg-primary text-primary-foreground">
            <ShieldCheck className="h-5 w-5" />
          </div>
          <div>
            <h1 className="text-lg font-semibold">SVNET Admin</h1>
            <p className="text-sm text-muted-foreground">Вход для администратора VPS.</p>
          </div>
        </div>

        <label className="mb-2 block text-sm font-medium">Пользователь</label>
        <Input value={username} onChange={(event) => setUsername(event.target.value)} autoComplete="username" />

        <label className="mb-2 mt-4 block text-sm font-medium">Пароль</label>
        <Input
          value={password}
          onChange={(event) => setPassword(event.target.value)}
          type="password"
          autoComplete="current-password"
        />

        {error ? <p className="mt-4 text-sm text-red-700">{error}</p> : null}

        <Button className="mt-6 w-full" disabled={loading}>
          {loading ? "Проверка..." : "Войти"}
        </Button>
      </form>
    </main>
  );
}
