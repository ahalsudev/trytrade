import { getMetadata } from "~~/utils/scaffold-eth/getMetadata";

export const metadata = getMetadata({
  title: "Browse Competitions - TryTrade",
  description: "Discover and join active fantasy trading competitions",
});

export default function BrowseCompetitionsLayout({ children }: { children: React.ReactNode }) {
  return children;
}
