export function parseSvnetVersion(output: string): string | null {
  const match = output.match(/v([0-9A-Za-z.-]+)/);
  return match?.[1] ?? null;
}

export function parseUpdateCheck(output: string): Record<string, string> {
  const result: Record<string, string> = {};
  for (const line of output.split(/\r?\n/)) {
    const [rawKey, ...rest] = line.split(":");
    if (!rawKey || rest.length === 0) {
      continue;
    }
    result[rawKey.trim()] = rest.join(":").trim();
  }
  return result;
}

export function parseStatusFlags(output: string): Record<string, boolean> {
  return {
    openvpnActive: /\[OK\].*OpenVPN service: active/.test(output),
    tunInterfaceOk: /\[OK\].*tun-svnet/.test(output),
    udp1194Listening: /\[OK\].*UDP port 1194: listening/.test(output),
    httpPublishActive: /\[OK\].*HTTP publish service: active/.test(output),
    httpPublishOffline: /\[OK\].*HTTP publish: offline secure mode/.test(output)
  };
}
