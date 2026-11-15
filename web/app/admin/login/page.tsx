import { redirect } from "next/navigation";
import { AdminLoginForm } from "@/components/admin/AdminLoginForm";
import { SiteHeader } from "@/components/SiteHeader";
import { isAdminAuthenticated } from "@/lib/adminAuth";

export const metadata = {
  title: "Admin-login — Whistklubben",
};

export default async function AdminLoginPage() {
  if (await isAdminAuthenticated()) redirect("/admin");

  return (
    <main>
      <SiteHeader sub="admin" />
      <section className="admin-login-card">
        <p className="stats-eyebrow">Beskyttet område</p>
        <h2>Admin-login</h2>
        <p>
          Log ind for at styre live-opdateringen og hente serverens backupfiler.
        </p>
        <AdminLoginForm />
      </section>
    </main>
  );
}
