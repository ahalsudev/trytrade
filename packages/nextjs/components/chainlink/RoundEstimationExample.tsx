"use client";

import React, { useState } from "react";
import {
  formatConfidence,
  getConfidenceColor,
  isValidAsset,
  useLeagueRoundEstimation,
  useRoundEstimation,
} from "../../hooks/useChainlinkRoundEstimation";

const RoundEstimationExample: React.FC = () => {
  // Single round estimation
  const { isLoading, error, result, estimate, reset } = useRoundEstimation();

  // League round estimation
  const leagueEstimation = useLeagueRoundEstimation();

  // Form state
  const [asset, setAsset] = useState("ETH");
  const [timestamp, setTimestamp] = useState(Math.floor(Date.now() / 1000) - 86400); // 24 hours ago

  // League form state
  const [leagueAssets, setLeagueAssets] = useState(["ETH", "BTC"]);
  const [startTime, setStartTime] = useState(Math.floor(Date.now() / 1000) - 86400);
  const [endTime, setEndTime] = useState(Math.floor(Date.now() / 1000));

  const handleSingleEstimate = async () => {
    if (!isValidAsset(asset)) {
      alert("Invalid asset. Supported assets: ETH, BTC, WBTC");
      return;
    }

    try {
      await estimate(asset, timestamp);
    } catch (err) {
      console.error("Estimation failed:", err);
    }
  };

  const handleLeagueEstimate = async () => {
    try {
      await leagueEstimation.estimate(leagueAssets, startTime, endTime);
    } catch (err) {
      console.error("League estimation failed:", err);
    }
  };

  const formatTimestamp = (ts: number) => {
    return new Date(ts * 1000).toLocaleString();
  };

  return (
    <div className="max-w-4xl mx-auto p-6 space-y-8">
      <div className="bg-white rounded-lg shadow-lg p-6">
        <h1 className="text-2xl font-bold text-gray-900 mb-6">Chainlink Round ID Estimation</h1>

        {/* Single Round Estimation */}
        <div className="border-b pb-6 mb-6">
          <h2 className="text-xl font-semibold text-gray-800 mb-4">Single Round Estimation</h2>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Asset</label>
              <select
                value={asset}
                onChange={e => setAsset(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="ETH">ETH</option>
                <option value="BTC">BTC</option>
                <option value="WBTC">WBTC</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Timestamp</label>
              <input
                type="number"
                value={timestamp}
                onChange={e => setTimestamp(parseInt(e.target.value))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <p className="text-xs text-gray-500 mt-1">{formatTimestamp(timestamp)}</p>
            </div>
          </div>

          <div className="flex gap-2 mb-4">
            <button
              onClick={handleSingleEstimate}
              disabled={isLoading}
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
            >
              {isLoading ? "Estimating..." : "Estimate Round ID"}
            </button>

            <button onClick={reset} className="px-4 py-2 bg-gray-600 text-white rounded-md hover:bg-gray-700">
              Reset
            </button>
          </div>

          {error && (
            <div className="p-3 bg-red-100 border border-red-400 text-red-700 rounded-md mb-4">Error: {error}</div>
          )}

          {result && (
            <div className="p-4 bg-gray-50 rounded-md">
              <h3 className="font-medium text-gray-900 mb-2">Estimation Result:</h3>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <span className="font-medium">Asset:</span> {result.asset}
                </div>
                <div>
                  <span className="font-medium">Estimated Round ID:</span> {result.estimatedRoundId}
                </div>
                <div>
                  <span className="font-medium">Target Timestamp:</span> {formatTimestamp(result.targetTimestamp)}
                </div>
                <div className="flex items-center">
                  <span className="font-medium mr-2">Confidence:</span>
                  <span
                    className="px-2 py-1 rounded text-white text-xs"
                    style={{ backgroundColor: getConfidenceColor(result.confidence) }}
                  >
                    {formatConfidence(result.confidence)}
                  </span>
                </div>
                <div className="col-span-2">
                  <span className="font-medium">Feed Address:</span>
                  <code className="ml-2 text-xs bg-gray-200 px-1 py-0.5 rounded">{result.feedAddress}</code>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* League Round Estimation */}
        <div>
          <h2 className="text-xl font-semibold text-gray-800 mb-4">League Round Estimation</h2>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Assets (comma-separated)</label>
              <input
                type="text"
                value={leagueAssets.join(", ")}
                onChange={e => setLeagueAssets(e.target.value.split(",").map(s => s.trim().toUpperCase()))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="ETH, BTC, WBTC"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Start Time</label>
              <input
                type="number"
                value={startTime}
                onChange={e => setStartTime(parseInt(e.target.value))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <p className="text-xs text-gray-500 mt-1">{formatTimestamp(startTime)}</p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">End Time</label>
              <input
                type="number"
                value={endTime}
                onChange={e => setEndTime(parseInt(e.target.value))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <p className="text-xs text-gray-500 mt-1">{formatTimestamp(endTime)}</p>
            </div>
          </div>

          <div className="flex gap-2 mb-4">
            <button
              onClick={handleLeagueEstimate}
              disabled={leagueEstimation.isLoading}
              className="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:opacity-50"
            >
              {leagueEstimation.isLoading ? "Estimating..." : "Estimate League Rounds"}
            </button>

            <button
              onClick={leagueEstimation.reset}
              className="px-4 py-2 bg-gray-600 text-white rounded-md hover:bg-gray-700"
            >
              Reset
            </button>
          </div>

          {leagueEstimation.error && (
            <div className="p-3 bg-red-100 border border-red-400 text-red-700 rounded-md mb-4">
              Error: {leagueEstimation.error}
            </div>
          )}

          {(Object.keys(leagueEstimation.startRounds).length > 0 ||
            Object.keys(leagueEstimation.endRounds).length > 0) && (
            <div className="p-4 bg-gray-50 rounded-md">
              <h3 className="font-medium text-gray-900 mb-4">League Estimation Results:</h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Start Rounds */}
                <div>
                  <h4 className="font-medium text-gray-800 mb-2">Start Rounds:</h4>
                  <div className="space-y-2">
                    {Object.entries(leagueEstimation.startRounds).map(([asset, result]) => (
                      <div key={`start-${asset}`} className="p-2 bg-white rounded border">
                        <div className="flex justify-between items-center">
                          <span className="font-medium">{asset}</span>
                          <span
                            className="px-2 py-1 rounded text-white text-xs"
                            style={{ backgroundColor: getConfidenceColor(result.confidence) }}
                          >
                            {formatConfidence(result.confidence)}
                          </span>
                        </div>
                        <div className="text-sm text-gray-600">Round ID: {result.estimatedRoundId}</div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* End Rounds */}
                <div>
                  <h4 className="font-medium text-gray-800 mb-2">End Rounds:</h4>
                  <div className="space-y-2">
                    {Object.entries(leagueEstimation.endRounds).map(([asset, result]) => (
                      <div key={`end-${asset}`} className="p-2 bg-white rounded border">
                        <div className="flex justify-between items-center">
                          <span className="font-medium">{asset}</span>
                          <span
                            className="px-2 py-1 rounded text-white text-xs"
                            style={{ backgroundColor: getConfidenceColor(result.confidence) }}
                          >
                            {formatConfidence(result.confidence)}
                          </span>
                        </div>
                        <div className="text-sm text-gray-600">Round ID: {result.estimatedRoundId}</div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default RoundEstimationExample;
