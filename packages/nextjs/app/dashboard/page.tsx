"use client";

import { useState } from "react";
import type { NextPage } from "next";
import { ChevronDownIcon, ChevronUpIcon, XMarkIcon } from "@heroicons/react/24/outline";
import { EtherInput, InputBase } from "~~/components/scaffold-eth";

// Mock data for leagues - replace with actual data source
const mockLeagues = [
  {
    id: 1,
    name: "Crypto Champions League",
    profitPercentage: 24.8,
    isProfit: true,
  },
  {
    id: 2,
    name: "DeFi Masters",
    profitPercentage: -12.3,
    isProfit: false,
  },
  {
    id: 3,
    name: "NFT Traders Elite",
    profitPercentage: 8.7,
    isProfit: true,
  },
  {
    id: 4,
    name: "Yield Farming Pro",
    profitPercentage: -5.2,
    isProfit: false,
  },
  {
    id: 5,
    name: "Altcoin Hunters",
    profitPercentage: 15.9,
    isProfit: true,
  },
  {
    id: 6,
    name: "Blue Chip Investors",
    profitPercentage: -3.1,
    isProfit: false,
  },
];

const LeagueCard = ({ league }: { league: (typeof mockLeagues)[0] }) => {
  return (
    <div className="bg-base-300/50 p-4 rounded-lg border border-base-300">
      <div className="mb-3">
        <h3 className="text-base font-medium text-base-content">{league.name}</h3>
      </div>
      <div className="flex items-center gap-2">
        {league.isProfit ? (
          <ChevronUpIcon className="h-4 w-4 text-success" />
        ) : (
          <ChevronDownIcon className="h-4 w-4 text-error" />
        )}
        <span className={`text-sm font-semibold ${league.isProfit ? "text-success" : "text-error"}`}>
          {league.isProfit ? "+" : ""}
          {league.profitPercentage}%
        </span>
      </div>
    </div>
  );
};

const CreateCompetitionModal = ({ isOpen, onClose }: { isOpen: boolean; onClose: () => void }) => {
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    entryFee: "",
    startDate: "",
    endDate: "",
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Handle form submission here
    console.log("Competition data:", formData);
    // Reset form and close modal
    setFormData({
      name: "",
      description: "",
      entryFee: "",
      startDate: "",
      endDate: "",
    });
    onClose();
  };

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  if (!isOpen) return null;

  return (
    <div className="modal modal-open">
      <div className="modal-box relative max-w-lg">
        {/* Header */}
        <div className="flex justify-between items-center mb-6">
          <h3 className="text-xl font-bold">Create Competition</h3>
          <button onClick={onClose} className="btn btn-ghost btn-sm btn-circle">
            <XMarkIcon className="h-5 w-5" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Competition Name */}
          <div>
            <label className="label">
              <span className="label-text font-medium">Competition Name</span>
            </label>
            <InputBase
              value={formData.name}
              onChange={value => handleInputChange("name", value)}
              placeholder="Enter competition name"
            />
          </div>

          {/* Description */}
          <div>
            <label className="label">
              <span className="label-text font-medium">Description</span>
            </label>
            <textarea
              className="textarea textarea-bordered w-full h-32 bg-base-200 border-base-300 rounded-lg"
              placeholder="Describe your competition..."
              value={formData.description}
              onChange={e => handleInputChange("description", e.target.value)}
            />
          </div>

          {/* Entry Fee */}
          <div>
            <label className="label">
              <span className="label-text font-medium">Entry Fee</span>
            </label>
            <EtherInput
              value={formData.entryFee}
              onChange={value => handleInputChange("entryFee", value)}
              placeholder="0.0"
            />
          </div>

          {/* Start Date */}
          <div>
            <label className="label">
              <span className="label-text font-medium">Start Date</span>
            </label>
            <input
              type="datetime-local"
              className="input input-bordered w-full bg-base-200 border-base-300"
              value={formData.startDate}
              onChange={e => handleInputChange("startDate", e.target.value)}
            />
          </div>

          {/* End Date */}
          <div>
            <label className="label">
              <span className="label-text font-medium">End Date</span>
            </label>
            <input
              type="datetime-local"
              className="input input-bordered w-full bg-base-200 border-base-300"
              value={formData.endDate}
              onChange={e => handleInputChange("endDate", e.target.value)}
            />
          </div>

          {/* Action Buttons */}
          <div className="modal-action">
            <button type="button" onClick={onClose} className="btn btn-ghost">
              Cancel
            </button>
            <button
              type="submit"
              className="btn btn-primary"
              disabled={!formData.name || !formData.description || !formData.startDate || !formData.endDate}
            >
              Create Competition
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

const Dashboard: NextPage = () => {
  const [totalValue] = useState("$14,892");
  const [competitions] = useState("0");
  const [rank] = useState("#42");
  const [isModalOpen, setIsModalOpen] = useState(false);

  const openModal = () => setIsModalOpen(true);
  const closeModal = () => setIsModalOpen(false);

  return (
    <div className="min-h-screen bg-base-200">
      {/* Main Content */}
      <div className="max-w-6xl mx-auto px-6 py-8">
        {/* Dashboard Title */}
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-2xl font-bold text-base-content"></h1>
          <div className="text-base-content/60 text-sm">🕐 Jul 29, 2025</div>
        </div>

        {/* Overall Performance Section */}
        <div className="mb-8">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-xl font-semibold text-base-content">Competitions Performance</h2>
          </div>

          {/* Performance Chart Replacement - Leagues Grid */}
          <div className="bg-base-100 p-6 rounded-lg mb-6">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {mockLeagues.map(league => (
                <LeagueCard key={league.id} league={league} />
              ))}
            </div>
          </div>

          {/* Performance Metrics */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="text-center">
              <h3 className="text-base-content/60 text-sm mb-1">Total Value</h3>
              <p className="text-xl font-bold text-base-content">{totalValue}</p>
            </div>
            <div className="text-center">
              <h3 className="text-base-content/60 text-sm mb-1">Competitions</h3>
              <p className="text-xl font-bold text-base-content">{competitions}</p>
            </div>
            <div className="text-center">
              <h3 className="text-base-content/60 text-sm mb-1">Rank</h3>
              <p className="text-xl font-bold text-base-content">{rank}</p>
            </div>
          </div>
        </div>

        {/* Active Competitions Section */}
        <div>
          <h2 className="text-xl font-semibold text-base-content mb-6">Your Active Competitions</h2>
          <div className="bg-base-100 p-12 rounded-lg text-center">
            <div className="mb-6">
              <button
                onClick={openModal}
                className="w-16 h-16 bg-success rounded-full flex items-center justify-center mx-auto mb-4 hover:bg-success/80 transition-colors cursor-pointer"
              >
                <span className="text-success-content text-3xl font-bold">+</span>
              </button>
              <p className="text-base-content/60 mb-6 text-lg">You haven&apos;t joined any competitions yet</p>
              <button className="text-success hover:text-success/80 font-medium flex items-center gap-2 mx-auto text-lg">
                Browse competitions →
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Create Competition Modal */}
      <CreateCompetitionModal isOpen={isModalOpen} onClose={closeModal} />
    </div>
  );
};

export default Dashboard;
