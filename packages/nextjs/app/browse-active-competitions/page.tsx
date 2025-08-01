"use client";

import { useState } from "react";
import Link from "next/link";
import type { NextPage } from "next";
import { useAccount } from "wagmi";
import {
  CalendarIcon,
  ClockIcon,
  CurrencyDollarIcon,
  FunnelIcon,
  MagnifyingGlassIcon,
  TrophyIcon,
  UserGroupIcon,
  XMarkIcon,
} from "@heroicons/react/24/outline";

// Mock data for available competitions - in production this would come from the contract
const mockCompetitions = [
  {
    id: 1,
    name: "Weekly Crypto Challenge",
    description: "Test your crypto trading skills in this weekly competition",
    startDate: new Date(Date.now() + 24 * 60 * 60 * 1000), // Tomorrow
    endDate: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000), // Next week
    stakeAmount: "0.05",
    maxParticipants: 100,
    currentParticipants: 67,
    prizePool: "3.35",
    status: "upcoming",
    category: "short-term",
    owner: "0x1234...5678",
  },
  {
    id: 2,
    name: "DeFi Masters Championship",
    description: "Long-term competition focusing on DeFi protocols",
    startDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // 3 days from now
    endDate: new Date(Date.now() + 33 * 24 * 60 * 60 * 1000), // 30 days competition
    stakeAmount: "0.1",
    maxParticipants: 200,
    currentParticipants: 123,
    prizePool: "12.3",
    status: "upcoming",
    category: "long-term",
    owner: "0x2345...6789",
  },
  {
    id: 3,
    name: "Beginner's Trading League",
    description: "Perfect for newcomers to crypto trading",
    startDate: new Date(Date.now() + 2 * 60 * 60 * 1000), // 2 hours from now
    endDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000), // 5 days
    stakeAmount: "0.01",
    maxParticipants: 50,
    currentParticipants: 31,
    prizePool: "0.31",
    status: "filling",
    category: "beginner",
    owner: "0x3456...7890",
  },
  {
    id: 4,
    name: "High Stakes Elite",
    description: "For experienced traders willing to risk more",
    startDate: new Date(Date.now() + 6 * 60 * 60 * 1000), // 6 hours from now
    endDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000), // 2 weeks
    stakeAmount: "0.5",
    maxParticipants: 25,
    currentParticipants: 8,
    prizePool: "4.0",
    status: "filling",
    category: "high-stakes",
    owner: "0x4567...8901",
  },
  {
    id: 5,
    name: "Daily Sprint Challenge",
    description: "Quick 24-hour trading competition",
    startDate: new Date(Date.now() + 4 * 60 * 60 * 1000), // 4 hours from now
    endDate: new Date(Date.now() + 28 * 60 * 60 * 1000), // 24 hours later
    stakeAmount: "0.02",
    maxParticipants: 150,
    currentParticipants: 89,
    prizePool: "1.78",
    status: "filling",
    category: "short-term",
    owner: "0x5678...9012",
  },
];

// Available tokens for allocation
const availableTokens = [
  { id: "ETH", name: "Ethereum", symbol: "ETH" },
  { id: "BTC", name: "Bitcoin", symbol: "BTC" },
  { id: "USDC", name: "USD Coin", symbol: "USDC" },
  { id: "UNI", name: "Uniswap", symbol: "UNI" },
  { id: "LINK", name: "Chainlink", symbol: "LINK" },
  { id: "AAVE", name: "Aave", symbol: "AAVE" },
];

interface TokenAllocation {
  tokenId: string;
  allocation: number;
}

interface JoinCompetitionModalProps {
  isOpen: boolean;
  onClose: () => void;
  competitionId: number | null;
  competitionName: string;
  stakeAmount: string;
  onJoin: (competitionId: number, allocations: TokenAllocation[]) => void;
}

const JoinCompetitionModal = ({
  isOpen,
  onClose,
  competitionId,
  competitionName,
  stakeAmount,
  onJoin,
}: JoinCompetitionModalProps) => {
  const [allocations, setAllocations] = useState<TokenAllocation[]>([]);
  const [totalAllocated, setTotalAllocated] = useState(0);

  const handleAllocationChange = (tokenId: string, value: number) => {
    const newAllocations = [...allocations];
    const existingIndex = newAllocations.findIndex(a => a.tokenId === tokenId);

    if (existingIndex >= 0) {
      if (value === 0) {
        newAllocations.splice(existingIndex, 1);
      } else {
        newAllocations[existingIndex].allocation = value;
      }
    } else if (value > 0) {
      newAllocations.push({ tokenId, allocation: value });
    }

    setAllocations(newAllocations);
    setTotalAllocated(newAllocations.reduce((sum, a) => sum + a.allocation, 0));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (totalAllocated !== 100) {
      alert("Total allocation must equal 100 points");
      return;
    }
    if (allocations.length === 0) {
      alert("You must allocate points to at least one token");
      return;
    }
    if (competitionId) {
      onJoin(competitionId, allocations);
      handleClose();
    }
  };

  const handleClose = () => {
    setAllocations([]);
    setTotalAllocated(0);
    onClose();
  };

  const getAllocation = (tokenId: string) => {
    return allocations.find(a => a.tokenId === tokenId)?.allocation || 0;
  };

  const remainingPoints = 100 - totalAllocated;

  if (!isOpen) return null;

  return (
    <div className="modal modal-open">
      <div className="modal-box relative max-w-2xl">
        {/* Header */}
        <div className="flex justify-between items-center mb-6">
          <div>
            <h3 className="text-xl font-bold">Join Competition</h3>
            <p className="text-sm text-base-content/60 mt-1">{competitionName}</p>
          </div>
          <button onClick={handleClose} className="btn btn-ghost btn-sm btn-circle">
            <XMarkIcon className="h-5 w-5" />
          </button>
        </div>

        {/* Competition Info */}
        <div className="bg-base-200 p-4 rounded-lg mb-6">
          <div className="flex justify-between items-center">
            <span className="text-sm text-base-content/70">Entry Fee:</span>
            <span className="font-semibold">{stakeAmount} ETH</span>
          </div>
        </div>

        {/* Instructions */}
        <div className="mb-6">
          <h4 className="font-semibold mb-2">Deploy Your 100 Points</h4>
          <p className="text-sm text-base-content/70 mb-4">
            Allocate your 100 available points across different tokens. Your portfolio performance will be tracked based
            on these allocations.
          </p>

          {/* Points Summary */}
          <div className="flex justify-between items-center mb-4 p-3 bg-base-200 rounded-lg">
            <span className="text-sm">Points Allocated:</span>
            <div className="flex items-center gap-2">
              <span
                className={`font-semibold ${totalAllocated === 100 ? "text-success" : totalAllocated > 100 ? "text-error" : "text-warning"}`}
              >
                {totalAllocated}/100
              </span>
              <span className="text-xs text-base-content/60">({remainingPoints} remaining)</span>
            </div>
          </div>
        </div>

        {/* Token Allocation Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-1 gap-4 max-h-64 overflow-y-auto">
            {availableTokens.map(token => (
              <div key={token.id} className="flex items-center justify-between p-3 border border-base-300 rounded-lg">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 bg-primary rounded-full flex items-center justify-center text-primary-content text-xs font-bold">
                    {token.symbol.slice(0, 2)}
                  </div>
                  <div>
                    <div className="font-medium">{token.name}</div>
                    <div className="text-xs text-base-content/60">{token.symbol}</div>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <input
                    type="number"
                    min="0"
                    max={remainingPoints + getAllocation(token.id)}
                    value={getAllocation(token.id)}
                    onChange={e => handleAllocationChange(token.id, parseInt(e.target.value) || 0)}
                    className="input input-bordered input-sm w-20 text-center"
                    placeholder="0"
                  />
                  <span className="text-xs text-base-content/60">pts</span>
                </div>
              </div>
            ))}
          </div>

          {/* Progress Bar */}
          <div className="w-full bg-base-300 rounded-full h-2 mb-4">
            <div
              className={`h-2 rounded-full transition-all ${
                totalAllocated === 100 ? "bg-success" : totalAllocated > 100 ? "bg-error" : "bg-warning"
              }`}
              style={{ width: `${Math.min(totalAllocated, 100)}%` }}
            ></div>
          </div>

          {/* Action Buttons */}
          <div className="flex justify-end gap-3 pt-4">
            <button type="button" onClick={handleClose} className="btn btn-ghost">
              Cancel
            </button>
            <button
              type="submit"
              className="btn btn-primary"
              disabled={totalAllocated !== 100 || allocations.length === 0}
            >
              Join Competition
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

const CompetitionCard = ({
  competition,
  onJoin,
}: {
  competition: (typeof mockCompetitions)[0];
  onJoin: (competitionId: number) => void;
}) => {
  const getStatusColor = (status: string) => {
    switch (status) {
      case "filling":
        return "badge-warning";
      case "upcoming":
        return "badge-info";
      case "active":
        return "badge-success";
      default:
        return "badge-neutral";
    }
  };

  const getCategoryBadge = (category: string) => {
    switch (category) {
      case "beginner":
        return "badge-success";
      case "short-term":
        return "badge-primary";
      case "long-term":
        return "badge-secondary";
      case "high-stakes":
        return "badge-error";
      default:
        return "badge-neutral";
    }
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  const getTimeUntilStart = (startDate: Date) => {
    const now = new Date();
    const diff = startDate.getTime() - now.getTime();
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}d ${hours % 24}h`;
    if (hours > 0) return `${hours}h`;
    return "Starting soon";
  };

  const participationPercentage = (competition.currentParticipants / competition.maxParticipants) * 100;

  return (
    <div className="bg-base-100 p-6 rounded-lg border border-base-300 hover:shadow-lg transition-all hover:border-primary">
      <div className="flex justify-between items-start mb-4">
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-2">
            <h3 className="text-lg font-semibold text-base-content">{competition.name}</h3>
            <span className={`badge ${getCategoryBadge(competition.category)} badge-sm`}>
              {competition.category.replace("-", " ")}
            </span>
          </div>
          <p className="text-sm text-base-content/70 mb-3">{competition.description}</p>
          <div className="flex items-center gap-2 mb-2">
            <span className={`badge ${getStatusColor(competition.status)} badge-sm`}>
              {competition.status.toUpperCase()}
            </span>
            {competition.status === "upcoming" && (
              <span className="text-xs text-base-content/60 flex items-center gap-1">
                <ClockIcon className="h-3 w-3" />
                Starts in {getTimeUntilStart(competition.startDate)}
              </span>
            )}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4 text-sm text-base-content/70 mb-4">
        <div className="flex items-center gap-2">
          <UserGroupIcon className="h-4 w-4" />
          <span>
            {competition.currentParticipants}/{competition.maxParticipants} participants
          </span>
        </div>
        <div className="flex items-center gap-2">
          <CalendarIcon className="h-4 w-4" />
          <span>Starts {formatDate(competition.startDate)}</span>
        </div>
        <div className="flex items-center gap-2">
          <TrophyIcon className="h-4 w-4" />
          <span>Prize: {competition.prizePool} ETH</span>
        </div>
        <div className="flex items-center gap-2">
          <CurrencyDollarIcon className="h-4 w-4" />
          <span>Entry: {competition.stakeAmount} ETH</span>
        </div>
      </div>

      {/* Participation Progress Bar */}
      <div className="mb-4">
        <div className="flex justify-between text-xs text-base-content/60 mb-1">
          <span>Participation</span>
          <span>{participationPercentage.toFixed(0)}% full</span>
        </div>
        <div className="w-full bg-base-300 rounded-full h-2">
          <div
            className="bg-primary h-2 rounded-full transition-all"
            style={{ width: `${participationPercentage}%` }}
          ></div>
        </div>
      </div>

      <div className="flex justify-between items-center pt-4 border-t border-base-300">
        <div className="text-xs text-base-content/50">Ends {formatDate(competition.endDate)}</div>
        <button
          onClick={() => onJoin(competition.id)}
          className="btn btn-primary btn-sm"
          disabled={competition.currentParticipants >= competition.maxParticipants}
        >
          {competition.currentParticipants >= competition.maxParticipants ? "Full" : "Join Competition"}
        </button>
      </div>
    </div>
  );
};

const BrowseCompetitions: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  const [competitions, setCompetitions] = useState(mockCompetitions);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("all");
  const [selectedStatus, setSelectedStatus] = useState("all");
  const [isJoinModalOpen, setIsJoinModalOpen] = useState(false);
  const [selectedCompetition, setSelectedCompetition] = useState<{
    id: number;
    name: string;
    stakeAmount: string;
  } | null>(null);

  // Filter competitions
  const filteredCompetitions = competitions.filter(comp => {
    const matchesSearch =
      comp.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      comp.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = selectedCategory === "all" || comp.category === selectedCategory;
    const matchesStatus = selectedStatus === "all" || comp.status === selectedStatus;

    return matchesSearch && matchesCategory && matchesStatus;
  });

  const handleJoinCompetition = async (competitionId: number) => {
    if (!connectedAddress) {
      alert("Please connect your wallet first");
      return;
    }

    // Find the competition to get its details
    const competition = competitions.find(c => c.id === competitionId);
    if (!competition) return;

    // Open the modal instead of showing alert
    setSelectedCompetition({
      id: competitionId,
      name: competition.name,
      stakeAmount: competition.stakeAmount,
    });
    setIsJoinModalOpen(true);
  };

  const handleJoinWithAllocations = async (competitionId: number, allocations: TokenAllocation[]) => {
    // In production, this would interact with the smart contract
    console.log(`Joining competition ${competitionId} with allocations:`, allocations);

    // Mock joining - update the participant count
    setCompetitions(prev =>
      prev.map(comp =>
        comp.id === competitionId ? { ...comp, currentParticipants: comp.currentParticipants + 1 } : comp,
      ),
    );

    // Show success message
    alert(`Successfully joined competition with your token allocation! (This is a demo)`);
  };

  const categories = [
    { value: "all", label: "All Categories" },
    { value: "beginner", label: "Beginner" },
    { value: "short-term", label: "Short Term" },
    { value: "long-term", label: "Long Term" },
    { value: "high-stakes", label: "High Stakes" },
  ];

  const statuses = [
    { value: "all", label: "All Status" },
    { value: "filling", label: "Filling Up" },
    { value: "upcoming", label: "Upcoming" },
    { value: "active", label: "Active" },
  ];

  return (
    <div className="min-h-screen bg-base-200">
      <div className="max-w-6xl mx-auto px-6 py-8">
        {/* Header */}
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-base-content">Browse Competitions</h1>
            <p className="text-base-content/60 mt-2">Discover and join fantasy trading competitions</p>
          </div>
          <div className="text-base-content/60 text-sm">
            🕐{" "}
            {new Date().toLocaleDateString("en-US", {
              month: "short",
              day: "numeric",
              year: "numeric",
            })}
          </div>
        </div>

        {/* Filters */}
        <div className="bg-base-100 p-6 rounded-lg mb-8 border border-base-300">
          <div className="flex flex-col lg:flex-row gap-4 items-center">
            {/* Search */}
            <div className="flex-1 w-full">
              <div className="relative">
                <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-base-content/40" />
                <input
                  type="text"
                  placeholder="Search competitions..."
                  className="input input-bordered w-full pl-10"
                  value={searchTerm}
                  onChange={e => setSearchTerm(e.target.value)}
                />
              </div>
            </div>

            {/* Category Filter */}
            <div className="w-full lg:w-48">
              <select
                className="select select-bordered w-full"
                value={selectedCategory}
                onChange={e => setSelectedCategory(e.target.value)}
              >
                {categories.map(cat => (
                  <option key={cat.value} value={cat.value}>
                    {cat.label}
                  </option>
                ))}
              </select>
            </div>

            {/* Status Filter */}
            <div className="w-full lg:w-48">
              <select
                className="select select-bordered w-full"
                value={selectedStatus}
                onChange={e => setSelectedStatus(e.target.value)}
              >
                {statuses.map(status => (
                  <option key={status.value} value={status.value}>
                    {status.label}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>

        {/* Stats Summary */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
          <div className="bg-base-100 p-4 rounded-lg text-center border border-base-300">
            <h3 className="text-base-content/60 text-sm mb-1">Total Competitions</h3>
            <p className="text-xl font-bold text-base-content">{competitions.length}</p>
          </div>
          <div className="bg-base-100 p-4 rounded-lg text-center border border-base-300">
            <h3 className="text-base-content/60 text-sm mb-1">Currently Filling</h3>
            <p className="text-xl font-bold text-warning">{competitions.filter(c => c.status === "filling").length}</p>
          </div>
          <div className="bg-base-100 p-4 rounded-lg text-center border border-base-300">
            <h3 className="text-base-content/60 text-sm mb-1">Total Prize Pool</h3>
            <p className="text-xl font-bold text-success">
              {competitions.reduce((sum, c) => sum + parseFloat(c.prizePool), 0).toFixed(2)} ETH
            </p>
          </div>
          <div className="bg-base-100 p-4 rounded-lg text-center border border-base-300">
            <h3 className="text-base-content/60 text-sm mb-1">Active Participants</h3>
            <p className="text-xl font-bold text-primary">
              {competitions.reduce((sum, c) => sum + c.currentParticipants, 0)}
            </p>
          </div>
        </div>

        {/* Competitions Grid */}
        <div className="mb-6">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-semibold text-base-content">
              Available Competitions ({filteredCompetitions.length})
            </h2>
            <div className="flex items-center gap-2 text-sm text-base-content/60">
              <FunnelIcon className="h-4 w-4" />
              {searchTerm && `"${searchTerm}" • `}
              {selectedCategory !== "all" && `${selectedCategory} • `}
              {selectedStatus !== "all" && selectedStatus}
            </div>
          </div>
        </div>

        {filteredCompetitions.length > 0 ? (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {filteredCompetitions.map(competition => (
              <CompetitionCard key={competition.id} competition={competition} onJoin={handleJoinCompetition} />
            ))}
          </div>
        ) : (
          <div className="bg-base-100 p-12 rounded-lg text-center border border-base-300">
            <div className="mb-6">
              <MagnifyingGlassIcon className="h-16 w-16 text-base-content/30 mx-auto mb-4" />
              <p className="text-base-content/60 mb-4 text-lg">No competitions found matching your criteria</p>
              <p className="text-base-content/40 text-sm mb-6">Try adjusting your search terms or filters</p>
              <button
                onClick={() => {
                  setSearchTerm("");
                  setSelectedCategory("all");
                  setSelectedStatus("all");
                }}
                className="btn btn-outline btn-sm"
              >
                Clear All Filters
              </button>
            </div>
          </div>
        )}

        {/* Quick Links */}
        <div className="mt-12 bg-base-100 p-6 rounded-lg border border-base-300">
          <h3 className="text-lg font-semibold text-base-content mb-4">Quick Actions</h3>
          <div className="flex flex-wrap gap-4">
            <Link href="/my-competitions" className="btn btn-outline btn-sm">
              View My Competitions
            </Link>
            <Link href="/dashboard" className="btn btn-outline btn-sm">
              Go to Dashboard
            </Link>
          </div>
        </div>
      </div>

      {/* Join Competition Modal */}
      <JoinCompetitionModal
        isOpen={isJoinModalOpen}
        onClose={() => setIsJoinModalOpen(false)}
        competitionId={selectedCompetition?.id || null}
        competitionName={selectedCompetition?.name || ""}
        stakeAmount={selectedCompetition?.stakeAmount || ""}
        onJoin={handleJoinWithAllocations}
      />
    </div>
  );
};

export default BrowseCompetitions;
