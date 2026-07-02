"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import {
  Activity,
  DatabaseBackup,
  Globe2,
  ListTree,
  LogOut,
  RefreshCcw,
  Router,
  ShieldAlert,
  TerminalSquare
} from "lucide-react";
import { Bar, BarChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { Alert } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { ApiError, api } from "@/lib/api";

type CommandResult = {
  stdout: string;
  stderr: string;
  exitCode: number | null;
};

type SvnetStatus = {
  ok: boolean;
  parsed: Record<string, boolean>;
  system: {
    memory: { totalBytes: number; freeBytes: number };
    disk: CommandResult;
  };
  result: CommandResult;
};

type VersionResponse = {
  ok: boolean;
  version: string | null;
  result: CommandResult;
};

type UpdateResponse = {
  ok: boolean;
  parsed: Record<string, string>;
  result: CommandResult;
};

type PublishResponse = {
  ok: boolean;
  result: CommandResult;
};

type BackupsResponse = {
  ok: boolean;
  backups: Array<{ name: string; sizeBytes: number; modifiedAt: string; isDirectory: boolean }>;
  restoreNotice: string;
};

type ListResponse = {
  ok: boolean;
  list: { name: string; fileName: string; entries: string[] };
};

type MikrotikResponse = {
  ok: boolean;
  host: string;
  ping: boolean;
  apiPort: number;
  apiTcpOpen: boolean;
  mode: string;
};

const listLabels: Record<string, string> = {
  "direct-domains": "Российские сайты напрямую",
  "vpn-domains": "Заблокированные сайты через VPN",
  "direct-ip": "Российские IP напрямую",
  "vpn-ip": "IP/подсети через VPN",
  "local-bypass": "Локальная сеть без VPN"
};

function raw(result?: CommandResult) {
  if (!result) {
    return "";
  }
  return [result.stdout, result.stderr].filter(Boolean).join("\n").trim();
}

function bytes(value: number) {
  return `${Math.round(value / 1024 / 1024)} MB`;
}

export default function DashboardPage() {
  const [status, setStatus] = useState<SvnetStatus | null>(null);
  const [version, setVersion] = useState<VersionResponse | null>(null);
  const [updates, setUpdates] = useState<UpdateResponse | null>(null);
  const [publish, setPublish] = useState<PublishResponse | null>(null);
  const [backups, setBackups] = useState<BackupsResponse | null>(null);
  const [mikrotik, setMikrotik] = useState<MikrotikResponse | null>(null);
  const [selectedList, setSelectedList] = useState("direct-domains");
  const [list, setList] = useState<ListResponse | null>(null);
  const [busy, setBusy] = useState("");
  const [error, setError] = useState("");

  const chartData = useMemo(() => {
    const flags = status?.parsed ?? {};
    return [
      { name: "OpenVPN", value: flags.openvpnActive ? 1 : 0 },
      { name: "tun", value: flags.tunInterfaceOk ? 1 : 0 },
      { name: "UDP 1194", value: flags.udp1194Listening ? 1 : 0 },
      { name: "Publish", value: flags.httpPublishActive ? 1 : 0 }
    ];
  }, [status]);

  const load = useCallback(async () => {
    setError("");
    try {
      const [versionData, statusData, publishData, updateData, backupData, mikrotikData] = await Promise.all([
        api<VersionResponse>("/svnet/version"),
        api<SvnetStatus>("/svnet/status"),
        api<PublishResponse>("/publish/status"),
        api<UpdateResponse>("/updates/check"),
        api<BackupsResponse>("/backups"),
        api<MikrotikResponse>("/mikrotik/status")
      ]);
      setVersion(versionData);
      setStatus(statusData);
      setPublish(publishData);
      setUpdates(updateData);
      setBackups(backupData);
      setMikrotik(mikrotikData);
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) {
        window.location.href = "/login";
        return;
      }
      setError("Не удалось получить данные dashboard.");
    }
  }, []);

  const loadList = useCallback(async (name: string) => {
    try {
      setList(await api<ListResponse>(`/lists/${name}`));
    } catch {
      setError("Не удалось прочитать список.");
    }
  }, []);

  async function action(label: string, path: string, message: string) {
    if (!window.confirm(message)) {
      return;
    }
    setBusy(label);
    setError("");
    try {
      await api(path, { method: "POST", body: JSON.stringify({ confirm: true }) });
      await load();
    } catch {
      setError(`Действие не выполнено: ${label}`);
    } finally {
      setBusy("");
    }
  }

  async function logout() {
    await api("/auth/logout", { method: "POST" }).catch(() => undefined);
    window.location.href = "/login";
  }

  useEffect(() => {
    void load();
  }, [load]);

  useEffect(() => {
    void loadList(selectedList);
  }, [loadList, selectedList]);

  const memoryUsed = status ? status.system.memory.totalBytes - status.system.memory.freeBytes : 0;

  return (
    <main className="min-h-screen">
      <div className="grid min-h-screen lg:grid-cols-[260px_1fr]">
        <aside className="border-r border-border bg-white px-5 py-6">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-md bg-primary text-primary-foreground">
              <Activity className="h-5 w-5" />
            </div>
            <div>
              <h1 className="text-lg font-semibold">SVNET Admin</h1>
              <p className="text-xs text-muted-foreground">v1.1.0-alpha.5</p>
            </div>
          </div>

          <nav className="mt-8 space-y-2 text-sm">
            <a className="block rounded-md bg-muted px-3 py-2 font-medium" href="#dashboard">
              Dashboard
            </a>
            <a className="block rounded-md px-3 py-2 text-muted-foreground hover:bg-muted" href="#publish">
              HTTP Publish
            </a>
            <a className="block rounded-md px-3 py-2 text-muted-foreground hover:bg-muted" href="#lists">
              Lists Viewer
            </a>
            <a className="block rounded-md px-3 py-2 text-muted-foreground hover:bg-muted" href="#updates">
              Update Center
            </a>
            <a className="block rounded-md px-3 py-2 text-muted-foreground hover:bg-muted" href="#backup">
              Backup
            </a>
          </nav>

          <Button className="mt-8 w-full" variant="outline" onClick={logout}>
            <LogOut className="mr-2 h-4 w-4" />
            Выйти
          </Button>
        </aside>

        <section className="px-5 py-6 lg:px-8" id="dashboard">
          <div className="mb-6 flex flex-col justify-between gap-4 md:flex-row md:items-center">
            <div>
              <h2 className="text-2xl font-semibold tracking-normal">Панель управления SVNET</h2>
              <p className="mt-1 text-sm text-muted-foreground">
                Read-only MVP поверх стабильного CLI. Опасные действия требуют подтверждения.
              </p>
            </div>
            <Button variant="outline" onClick={load}>
              <RefreshCcw className="mr-2 h-4 w-4" />
              Обновить
            </Button>
          </div>

          {error ? <Alert className="mb-5">{error}</Alert> : null}

          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
            <StatusTile label="SVNET version" value={version?.version ?? "unknown"} ok={version?.ok} />
            <StatusTile
              label="OpenVPN"
              value={status?.parsed.openvpnActive ? "active" : "check CLI"}
              ok={status?.parsed.openvpnActive}
            />
            <StatusTile
              label="tun-svnet"
              value={status?.parsed.tunInterfaceOk ? "10.88.0.1" : "not confirmed"}
              ok={status?.parsed.tunInterfaceOk}
            />
            <StatusTile
              label="HTTP publish"
              value={status?.parsed.httpPublishActive ? "active" : "offline secure mode"}
              ok={status?.parsed.httpPublishOffline || status?.parsed.httpPublishActive}
            />
          </div>

          <div className="mt-5 grid gap-5 xl:grid-cols-[1fr_360px]">
            <Card>
              <CardHeader>
                <div>
                  <CardTitle>Состояние сервисов</CardTitle>
                  <CardDescription>1 значит OK по выводу `svnet --status`, 0 требует проверки CLI.</CardDescription>
                </div>
                <Badge tone={status?.ok ? "ok" : "warn"}>{status?.ok ? "status OK" : "needs attention"}</Badge>
              </CardHeader>
              <div className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={chartData}>
                    <XAxis dataKey="name" tickLine={false} axisLine={false} />
                    <YAxis allowDecimals={false} domain={[0, 1]} tickLine={false} axisLine={false} />
                    <Tooltip />
                    <Bar dataKey="value" fill="#17804f" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </Card>

            <Card>
              <CardHeader>
                <div>
                  <CardTitle>Ресурсы VPS</CardTitle>
                  <CardDescription>RAM и disk читаются с backend host/container.</CardDescription>
                </div>
              </CardHeader>
              <dl className="space-y-3 text-sm">
                <Metric label="RAM used" value={status ? bytes(memoryUsed) : "unknown"} />
                <Metric label="RAM free" value={status ? bytes(status.system.memory.freeBytes) : "unknown"} />
                <Metric label="Disk command" value={status?.system.disk.exitCode === 0 ? "df OK" : "df unavailable"} />
              </dl>
            </Card>
          </div>

          <div className="mt-5 grid gap-5 xl:grid-cols-2">
            <Card id="publish">
              <CardHeader>
                <div>
                  <CardTitle className="flex items-center gap-2">
                    <Globe2 className="h-5 w-5" />
                    HTTP Publish Control
                  </CardTitle>
                  <CardDescription>Публикация конфигов должна быть выключена в production.</CardDescription>
                </div>
              </CardHeader>
              <Alert className="mb-4">
                Не держите публикацию включённой постоянно. После настройки MikroTik отключите её.
              </Alert>
              <div className="flex flex-wrap gap-2">
                <Button
                  onClick={() =>
                    action(
                      "publish-on",
                      "/publish/on",
                      "Временно включить публикацию конфигов? После настройки MikroTik её нужно отключить."
                    )
                  }
                  disabled={busy !== ""}
                >
                  Включить временно
                </Button>
                <Button
                  variant="outline"
                  onClick={() => action("publish-off", "/publish/off", "Отключить HTTP publish сейчас?")}
                  disabled={busy !== ""}
                >
                  Отключить
                </Button>
                <Button variant="secondary" onClick={load} disabled={busy !== ""}>
                  Проверить URL
                </Button>
              </div>
              <CommandBlock title="svnet --publish-status" value={raw(publish?.result)} />
            </Card>

            <Card id="updates">
              <CardHeader>
                <div>
                  <CardTitle className="flex items-center gap-2">
                    <TerminalSquare className="h-5 w-5" />
                    Update Center
                  </CardTitle>
                  <CardDescription>Safe update использует текущий CLI и Git fast-forward логику.</CardDescription>
                </div>
              </CardHeader>
              <dl className="space-y-3 text-sm">
                <Metric label="Установленная версия" value={updates?.parsed["Установленная версия"] ?? "unknown"} />
                <Metric label="Версия в репозитории" value={updates?.parsed["Версия в репозитории"] ?? "unknown"} />
                <Metric label="Local commit" value={updates?.parsed["Локальный commit"] ?? "unknown"} />
                <Metric label="Remote commit" value={updates?.parsed["Удалённый commit"] ?? "unknown"} />
              </dl>
              <Button
                className="mt-4"
                variant="outline"
                onClick={() =>
                  action("safe-update", "/updates/apply", "Запустить safe update? Перед обновлением будет создан backup.")
                }
                disabled={busy !== ""}
              >
                Safe update
              </Button>
            </Card>
          </div>

          <div className="mt-5 grid gap-5 xl:grid-cols-2">
            <Card id="lists">
              <CardHeader>
                <div>
                  <CardTitle className="flex items-center gap-2">
                    <ListTree className="h-5 w-5" />
                    Lists Viewer
                  </CardTitle>
                  <CardDescription>Первый MVP только читает списки. Редактирование будет в v1.2.</CardDescription>
                </div>
              </CardHeader>
              <div className="mb-4 flex flex-wrap gap-2">
                {Object.entries(listLabels).map(([key, label]) => (
                  <Button
                    key={key}
                    size="sm"
                    variant={selectedList === key ? "default" : "outline"}
                    onClick={() => setSelectedList(key)}
                  >
                    {label}
                  </Button>
                ))}
              </div>
              <div className="max-h-80 overflow-auto rounded-md border border-border bg-muted/40 p-3 text-sm">
                {list?.list.entries.length ? (
                  <ul className="space-y-1">
                    {list.list.entries.map((entry) => (
                      <li key={entry} className="font-mono text-xs">
                        {entry}
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-muted-foreground">Список пуст или файл пока не найден.</p>
                )}
              </div>
            </Card>

            <Card id="backup">
              <CardHeader>
                <div>
                  <CardTitle className="flex items-center gap-2">
                    <DatabaseBackup className="h-5 w-5" />
                    Backup
                  </CardTitle>
                  <CardDescription>Restore пока не запускается из UI и остаётся доступен только через CLI.</CardDescription>
                </div>
              </CardHeader>
              <Button
                variant="outline"
                onClick={() => action("backup-create", "/backups/create", "Создать новый backup через svnet --backup?")}
                disabled={busy !== ""}
              >
                Создать backup
              </Button>
              <div className="mt-4 max-h-72 overflow-auto rounded-md border border-border">
                {(backups?.backups ?? []).map((backup) => (
                  <div key={backup.name} className="flex items-center justify-between border-b border-border px-3 py-2 text-sm">
                    <span className="font-mono text-xs">{backup.name}</span>
                    <span className="text-muted-foreground">{new Date(backup.modifiedAt).toLocaleString()}</span>
                  </div>
                ))}
                {!backups?.backups.length ? <p className="p-3 text-sm text-muted-foreground">Backups не найдены.</p> : null}
              </div>
            </Card>
          </div>

          <Card className="mt-5">
            <CardHeader>
              <div>
                <CardTitle className="flex items-center gap-2">
                  <Router className="h-5 w-5" />
                  MikroTik Read-only
                </CardTitle>
                <CardDescription>Проверяется ping `10.88.0.2` и TCP `8728`, если RouterOS API включён.</CardDescription>
              </div>
              <Badge tone={mikrotik?.ping ? "ok" : "warn"}>{mikrotik?.ping ? "ping OK" : "ping unavailable"}</Badge>
            </CardHeader>
            <div className="grid gap-3 text-sm md:grid-cols-3">
              <Metric label="Host" value={mikrotik?.host ?? "10.88.0.2"} />
              <Metric label="API TCP 8728" value={mikrotik?.apiTcpOpen ? "open" : "closed"} />
              <Metric label="Mode" value={mikrotik?.mode ?? "read-only"} />
            </div>
          </Card>

          <Card className="mt-5">
            <CardHeader>
              <div>
                <CardTitle className="flex items-center gap-2">
                  <ShieldAlert className="h-5 w-5" />
                  Raw CLI Output
                </CardTitle>
                <CardDescription>Для диагностики MVP показывает исходный вывод стабильного CLI.</CardDescription>
              </div>
            </CardHeader>
            <CommandBlock title="svnet --status" value={raw(status?.result)} />
          </Card>
        </section>
      </div>
    </main>
  );
}

function StatusTile({ label, value, ok }: { label: string; value: string; ok?: boolean }) {
  return (
    <Card className="p-4">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-xs uppercase text-muted-foreground">{label}</p>
          <p className="mt-2 text-lg font-semibold">{value}</p>
        </div>
        <Badge tone={ok ? "ok" : "warn"}>{ok ? "OK" : "Check"}</Badge>
      </div>
    </Card>
  );
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-4 border-b border-border pb-2">
      <dt className="text-muted-foreground">{label}</dt>
      <dd className="text-right font-medium">{value}</dd>
    </div>
  );
}

function CommandBlock({ title, value }: { title: string; value: string }) {
  return (
    <div className="mt-4">
      <p className="mb-2 text-xs font-semibold uppercase text-muted-foreground">{title}</p>
      <pre className="max-h-72 overflow-auto rounded-md bg-zinc-950 p-3 text-xs text-zinc-100">
        {value || "Нет данных."}
      </pre>
    </div>
  );
}
