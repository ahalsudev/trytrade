import { getMetadata } from "~~/utils/scaffold-eth/getMetadata";

export const metadata = getMetadata({
  title: "My Competitions - FantasyInvest",
  description: "View and manage all competitions you are participating in",
});

export default function MyCompetitionsLayout({ children }: { children: React.ReactNode }) {
  return children;
}
