import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Whist — live overblik",
  description: "Igangværende spilledage",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="da">
      <body>{children}</body>
    </html>
  );
}
