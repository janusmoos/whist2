import type { Metadata } from "next";
import { Anton, Archivo } from "next/font/google";
import "./globals.css";

const anton = Anton({
  weight: "400",
  subsets: ["latin"],
  variable: "--font-anton",
  display: "swap",
});

const archivo = Archivo({
  subsets: ["latin"],
  variable: "--font-archivo",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Whistklubben live",
  description: "Igangværende spilledage",
};

const themeBootScript = `(function(){try{var t=localStorage.getItem('whist-live-theme');document.documentElement.dataset.theme=(t==='light'||t==='dark')?t:'auto';}catch(e){document.documentElement.dataset.theme='auto';}})();`;

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="da" className={`${anton.variable} ${archivo.variable}`} suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeBootScript }} />
      </head>
      <body>{children}</body>
    </html>
  );
}
