import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "SVNET Admin Panel",
  description: "Read-only MVP dashboard for SVNET"
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ru">
      <body>{children}</body>
    </html>
  );
}
