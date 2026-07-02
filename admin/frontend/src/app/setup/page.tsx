"use client";

import { FormEvent, useEffect, useState } from "react";
import { KeyRound, ShieldCheck } from "lucide-react";
import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { api } from "@/lib/api";

export default function SetupPage() {
  const [setupToken, setSetupToken] = useState("");
  const [username, setUsername] = useState("admin");
  const [password, setPassword] = useState("");
  const [repeatPassword, setRepeatPassword] = useState("");
  const [needsSetup, setNeedsSetup] = useState<boolean | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    api<{ needsSetup: boolean }>("/setup/status")
      .then((status) => {
        setNeedsSetup(status.needsSetup);
        if (!status.needsSetup) {
          window.location.href = "/login";
        }
      })
      .catch(() => setError("Backend setup API недоступен."));
  }, []);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");

    if (password !== repeatPassword) {
      setError("Пароли не совпадают.");
      return;
    }

    if (password.length < 12) {
      setError("Пароль должен быть не короче 12 символов.");
      return;
    }

    setLoading(true);
    try {
      await api("/setup", {
        method: "POST",
        body: JSON.stringify({ setupToken, username, password })
      });
      window.location.href = "/login";
    } catch {
      setError("Setup token неверный или пользователь уже создан.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center px-4 py-10">
      <form onSubmit={submit} className="w-full max-w-md rounded-lg border border-border bg-white p-6 shadow-sm">
        <div className="mb-6 flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-md bg-primary text-primary-foreground">
            <ShieldCheck className="h-5 w-5" />
          </div>
          <div>
            <h1 className="text-lg font-semibold">Первичная настройка</h1>
            <p className="text-sm text-muted-foreground">Создайте администратора SVNET Admin Panel.</p>
          </div>
        </div>

        <Alert className="mb-5 flex gap-2">
          <KeyRound className="mt-0.5 h-4 w-4 flex-none" />
          <span>Setup token показывает `svnet --admin-install` после установки. Не отправляйте его в чаты.</span>
        </Alert>

        {needsSetup === null ? <p className="mb-4 text-sm text-muted-foreground">Проверка setup mode...</p> : null}

        <label className="mb-2 block text-sm font-medium">Setup token</label>
        <Input value={setupToken} onChange={(event) => setSetupToken(event.target.value)} autoComplete="one-time-code" />

        <label className="mb-2 mt-4 block text-sm font-medium">Admin username</label>
        <Input value={username} onChange={(event) => setUsername(event.target.value)} autoComplete="username" />

        <label className="mb-2 mt-4 block text-sm font-medium">Admin password</label>
        <Input
          value={password}
          onChange={(event) => setPassword(event.target.value)}
          type="password"
          autoComplete="new-password"
        />

        <label className="mb-2 mt-4 block text-sm font-medium">Repeat password</label>
        <Input
          value={repeatPassword}
          onChange={(event) => setRepeatPassword(event.target.value)}
          type="password"
          autoComplete="new-password"
        />

        {error ? <p className="mt-4 text-sm text-red-700">{error}</p> : null}

        <Button className="mt-6 w-full" disabled={loading || needsSetup === false}>
          {loading ? "Создание..." : "Создать администратора"}
        </Button>
      </form>
    </main>
  );
}
