"use client";

import { useState } from "react";
import Link from "next/link";
import type { NextPage } from "next";
import { CalendarIcon, ChevronDownIcon, ChevronUpIcon, TrophyIcon, UserGroupIcon } from "@heroicons/react/24/outline";

// Mock data for user's competitions - replace with actual data source
const mockUserCompetitions = [
  {
    id: 1,
    name: "Crypto Champions League",
    profitPercentage: 24.8,
    isProfit: true,
    status: "active",
    rank: 3,
    participants: 156,
    endDate: "2024-02-15",
    entryFee: "0.1 ETH",
    prize: "5.0 ETH",
  },
  {
    id: 2,
    name: "DeFi Masters",
    profitPercentage: -12.3,
    isProfit: false,
    status: "active",
    rank: 89,
    participants: 245,
    endDate: "2024-02-20",
    entryFee: "0.05 ETH",
    prize: "2.5 ETH",
  },
  {
    id: 3,
    name: "NFT Traders Elite",
    profitPercentage: 8.7,
    isProfit: true,
    status: "ended",
    rank: 12,
    participants: 78,
    endDate: "2024-01-30",
    entryFee: "0.2 ETH",
    prize: "3.0 ETH",
  },
  {
    id: 4,
    name: "Yield Farming Pro",
    profitPercentage: -5.2,
    isProfit: false,
    status: "active",
    rank: 34,
    participants: 123,
    endDate: "2024-02-25",
    entryFee: "0.08 ETH",
    prize: "1.8 ETH",
  },
];

const CompetitionCard = ({ competition }: { competition: (typeof mockUserCompetitions)[0] }) => {
  const getStatusColor = (status: string) => {
    switch (status) {
      case "active":
        return "badge-success";
      case "ended":
        return "badge-neutral";
      default:
        return "badge-neutral";
    }
  };

  const getRankColor = (rank: number) => {
    if (rank <= 3) return "text-warning";
    if (rank <= 10) return "text-success";
    return "text-base-content";
  };

  return (
    <div className="bg-base-100 p-6 rounded-lg border border-base-300 hover:shadow-lg transition-shadow">
      <div className="flex justify-between items-start mb-4">
        <div>
          <h3 className="text-lg font-semibold text-base-content mb-2">{competition.name}</h3>
          <div className="flex items-center gap-2 mb-2">
            <span className={`badge ${getStatusColor(competition.status)} badge-sm`}>
              {competition.status.toUpperCase()}
            </span>
          </div>
        </div>
        <div className="text-right">
          <div className="flex items-center gap-1 mb-1">
            {competition.isProfit ? (
              <ChevronUpIcon className="h-4 w-4 text-success" />
            ) : (
              <ChevronDownIcon className="h-4 w-4 text-error" />
            )}
            <span className={`text-lg font-bold ${competition.isProfit ? "text-success" : "text-error"}`}>
              {competition.isProfit ? "+" : ""}
              {competition.profitPercentage}%
            </span>
          </div>
          <div className={`text-sm font-medium ${getRankColor(competition.rank)}`}>Rank #{competition.rank}</div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4 text-sm text-base-content/70">
        <div className="flex items-center gap-2">
          <UserGroupIcon className="h-4 w-4" />
          <span>{competition.participants} participants</span>
        </div>
        <div className="flex items-center gap-2">
          <CalendarIcon className="h-4 w-4" />
          <span>Ends {competition.endDate}</span>
        </div>
        <div className="flex items-center gap-2">
          <TrophyIcon className="h-4 w-4" />
          <span>Prize: {competition.prize}</span>
        </div>
        <div>
          <span>Entry: {competition.entryFee}</span>
        </div>
      </div>

      <div className="mt-4 pt-4 border-t border-base-300">
        <div className="flex justify-between items-center">
          {/* <Link
            href={`/competition/${competition.id}`}
            className="btn btn-primary btn-sm"
          >
            View Details
          </Link> */}
          {/* {competition.status === "active" && (
            <Link
              href={`/competition/${competition.id}/trade`}
              className="btn btn-outline btn-sm"
            >
              Trade Now
            </Link>
          )} */}
        </div>
      </div>
    </div>
  );
};

const MyCompetitions: NextPage = () => {
  const [activeCompetitions] = useState(mockUserCompetitions.filter(comp => comp.status === "active"));
  const [endedCompetitions] = useState(mockUserCompetitions.filter(comp => comp.status === "ended"));

  // Calculate overall stats
  const totalCompetitions = mockUserCompetitions.length;
  const averageRank = Math.round(mockUserCompetitions.reduce((sum, comp) => sum + comp.rank, 0) / totalCompetitions);
  const overallPerformance =
    mockUserCompetitions.reduce((sum, comp) => sum + comp.profitPercentage, 0) / totalCompetitions;

  return (
    <div className="min-h-screen bg-base-200">
      <div className="max-w-6xl mx-auto px-6 py-8">
        {/* Header */}
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-bold text-base-content">My Competitions</h1>
          <div className="text-base-content/60 text-sm">
            🕐{" "}
            {new Date().toLocaleDateString("en-US", {
              month: "short",
              day: "numeric",
              year: "numeric",
            })}
          </div>
        </div>

        {/* Overview Stats */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div className="bg-base-100 p-6 rounded-lg text-center">
            <h3 className="text-base-content/60 text-sm mb-1">Total Competitions</h3>
            <p className="text-2xl font-bold text-base-content">{totalCompetitions}</p>
          </div>
          <div className="bg-base-100 p-6 rounded-lg text-center">
            <h3 className="text-base-content/60 text-sm mb-1">Average Rank</h3>
            <p className="text-2xl font-bold text-base-content">#{averageRank}</p>
          </div>
          <div className="bg-base-100 p-6 rounded-lg text-center">
            <h3 className="text-base-content/60 text-sm mb-1">Overall Performance</h3>
            <p className={`text-2xl font-bold ${overallPerformance >= 0 ? "text-success" : "text-error"}`}>
              {overallPerformance >= 0 ? "+" : ""}
              {overallPerformance.toFixed(1)}%
            </p>
          </div>
        </div>

        {/* Active Competitions */}
        <div className="mb-8">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-xl font-semibold text-base-content">
              Active Competitions ({activeCompetitions.length})
            </h2>
            <Link href="/browse-active-competitions" className="btn btn-primary btn-sm">
              Join More
            </Link>
          </div>

          {activeCompetitions.length > 0 ? (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {activeCompetitions.map(competition => (
                <CompetitionCard key={competition.id} competition={competition} />
              ))}
            </div>
          ) : (
            <div className="bg-base-100 p-12 rounded-lg text-center">
              <div className="mb-6">
                <TrophyIcon className="h-16 w-16 text-base-content/30 mx-auto mb-4" />
                <p className="text-base-content/60 mb-6 text-lg">
                  You&apos;re not participating in any active competitions
                </p>
                <Link href="/browse-active-competitions" className="btn btn-primary">
                  Browse Active Competitions
                </Link>
              </div>
            </div>
          )}
        </div>

        {/* Ended Competitions */}
        <div>
          <h2 className="text-xl font-semibold text-base-content mb-6">
            Past Competitions ({endedCompetitions.length})
          </h2>

          {endedCompetitions.length > 0 ? (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {endedCompetitions.map(competition => (
                <CompetitionCard key={competition.id} competition={competition} />
              ))}
            </div>
          ) : (
            <div className="bg-base-100 p-8 rounded-lg text-center">
              <p className="text-base-content/60">No past competitions yet</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default MyCompetitions;
