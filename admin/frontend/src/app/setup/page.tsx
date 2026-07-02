"use client";

import { FormEvent, useEffect, useState } from "react";
import { ShieldCheck } from "lucide-react";
import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ApiError, api } from "@/lib/api";

export default function SetupPage() {
  const [username, setUsername] = useState("admin");
  const [password, setPassword] = useState("");
  const [repeatPassword, setRepeatPassword] = useState("");
  const [setupRequired, setSetupRequired] = useState<boolean | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    api<{ setupRequired: boolean; needsSetup?: boolean }>("/setup/status")
      .then((status) => {
        setSetupRequired(status.setupRequired ?? status.needsSetup ?? false);
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
      await api("/setup/create", {
        method: "POST",
        body: JSON.stringify({ username, password })
      });
      window.location.href = "/login";
    } catch (err) {
      if (err instanceof ApiError) {
        if (err.status === 403) {
          setError("Первичная настройка доступна только из локальной сети SVNET.");
          return;
        }
        if (err.status === 409) {
          setSetupRequired(false);
          setError("");
          return;
        }
        if (err.status === 429) {
          setError("Слишком много попыток. Подождите несколько минут и повторите.");
          return;
        }
        if (err.message === "invalid_username") {
          setError("Логин должен быть 3-32 символа: латиница, цифры, точка, подчёркивание или дефис.");
          return;
        }
        if (err.message === "password_too_short") {
          setError("Пароль должен быть не короче 12 символов.");
          return;
        }
      }
      setError("Не удалось создать администратора.");
    } finally {
      setLoading(false);
    }
  }

  if (setupRequired === false) {
    return (
      <main className="flex min-h-screen items-center justify-center px-4 py-10">
        <section className="w-full max-w-md rounded-lg border border-border bg-white p-6 shadow-sm">
          <div className="mb-6 flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-md bg-primary text-primary-foreground">
              <ShieldCheck className="h-5 w-5" />
            </div>
            <div>
              <h1 className="text-lg font-semibold">Администратор уже создан</h1>
              <p className="text-sm text-muted-foreground">Первичная настройка SVNET Admin Panel уже завершена.</p>
            </div>
          </div>
          <Button className="w-full" onClick={() => (window.location.href = "/login")}>
            Перейти ко входу
          </Button>
        </section>
      </main>
    );
  }

  return (
    <main className="flex min-h-screen items-center justify-center px-4 py-10">
      <form onSubmit={submit} className="w-full max-w-md rounded-lg border border-border bg-white p-6 shadow-sm">
        <div className="mb-6 flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-md bg-primary text-primary-foreground">
            <ShieldCheck className="h-5 w-5" />
          </div>
          <div>
            <h1 className="text-lg font-semibold">Первичная настройка SVNET Admin Panel</h1>
            <p className="text-sm text-muted-foreground">Создайте администратора для управления системой.</p>
          </div>
        </div>

        <Alert className="mb-5">Эта страница доступна только при первом запуске из домашней сети.</Alert>

        {setupRequired === null ? <p className="mb-4 text-sm text-muted-foreground">Проверка setup mode...</p> : null}

        <label className="mb-2 block text-sm font-medium">Admin username</label>
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

        <Button className="mt-6 w-full" disabled={loading || setupRequired !== true}>
          {loading ? "Создание..." : "Создать администратора"}
        </Button>
      </form>
    </main>
  );
}
