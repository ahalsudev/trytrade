import { getMetadata } from "~~/utils/scaffold-eth/getMetadata";

export const metadata = getMetadata({
  title: "Dashboard - FantasyInvest",
  description: "Your personal trading dashboard with league performance and statistics",
});

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return children;
}
