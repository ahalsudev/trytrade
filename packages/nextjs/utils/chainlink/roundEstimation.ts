/**
 * Utility functions for Chainlink round ID estimation
 */

export interface RoundEstimationResult {
  asset: string;
  targetTimestamp: number;
  feedAddress: string;
  estimatedRoundId: number;
  confidence: "high" | "medium" | "low";
  estimatedAt: number;
}

export interface RoundEstimationResponse {
  success: boolean;
  data?: RoundEstimationResult;
  error?: string;
}

/**
 * Estimates the round ID for a given asset and timestamp
 * @param asset - Asset symbol (ETH, BTC, WBTC)
 * @param timestamp - Target timestamp (Unix timestamp in seconds)
 * @returns Promise with estimation result
 */
export async function estimateRoundId(asset: string, timestamp: number): Promise<RoundEstimationResult> {
  try {
    const response = await fetch(`/api/chainlink/estimate-round?asset=${asset}&timestamp=${timestamp}`);

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
    }

    const result: RoundEstimationResponse = await response.json();

    if (!result.success || !result.data) {
      throw new Error(result.error || "Failed to estimate round ID");
    }

    return result.data;
  } catch (error) {
    console.error("Error estimating round ID:", error);
    throw error;
  }
}

/**
 * Estimates round IDs for multiple assets and timestamps
 * @param requests - Array of {asset, timestamp} objects
 * @returns Promise with array of estimation results
 */
export async function estimateMultipleRoundIds(
  requests: Array<{ asset: string; timestamp: number }>,
): Promise<RoundEstimationResult[]> {
  try {
    const promises = requests.map(({ asset, timestamp }) => estimateRoundId(asset, timestamp));

    const results = await Promise.allSettled(promises);

    return results.map((result, index) => {
      if (result.status === "fulfilled") {
        return result.value;
      } else {
        console.error(`Failed to estimate round for ${requests[index].asset}:`, result.reason);
        // Return a fallback result
        return {
          asset: requests[index].asset,
          targetTimestamp: requests[index].timestamp,
          feedAddress: "",
          estimatedRoundId: 1,
          confidence: "low" as const,
          estimatedAt: Math.floor(Date.now() / 1000),
        };
      }
    });
  } catch (error) {
    console.error("Error estimating multiple round IDs:", error);
    throw error;
  }
}

/**
 * Helper to convert Date to Unix timestamp
 * @param date - Date object
 * @returns Unix timestamp in seconds
 */
export function dateToTimestamp(date: Date): number {
  return Math.floor(date.getTime() / 1000);
}

/**
 * Helper to convert Unix timestamp to Date
 * @param timestamp - Unix timestamp in seconds
 * @returns Date object
 */
export function timestampToDate(timestamp: number): Date {
  return new Date(timestamp * 1000);
}

/**
 * Get confidence color for UI display
 * @param confidence - Confidence level
 * @returns CSS color class or hex color
 */
export function getConfidenceColor(confidence: "high" | "medium" | "low"): string {
  switch (confidence) {
    case "high":
      return "#10B981"; // green-500
    case "medium":
      return "#F59E0B"; // yellow-500
    case "low":
      return "#EF4444"; // red-500
    default:
      return "#6B7280"; // gray-500
  }
}

/**
 * Format confidence for display
 * @param confidence - Confidence level
 * @returns Formatted string
 */
export function formatConfidence(confidence: "high" | "medium" | "low"): string {
  return confidence.charAt(0).toUpperCase() + confidence.slice(1);
}

/**
 * Validate asset symbol
 * @param asset - Asset symbol to validate
 * @returns boolean indicating if asset is supported
 */
export function isValidAsset(asset: string): boolean {
  const supportedAssets = ["ETH", "BTC", "WBTC"];
  return supportedAssets.includes(asset.toUpperCase());
}

/**
 * Validate timestamp
 * @param timestamp - Timestamp to validate
 * @returns boolean indicating if timestamp is valid
 */
export function isValidTimestamp(timestamp: number): boolean {
  // Check if it's a reasonable timestamp (after 2020 and not too far in the future)
  const minTimestamp = 1577836800; // 2020-01-01
  const maxTimestamp = Math.floor(Date.now() / 1000) + 365 * 24 * 60 * 60; // 1 year from now

  return timestamp >= minTimestamp && timestamp <= maxTimestamp;
}

/**
 * Create a round estimation request for a league's start and end times
 * @param assets - Array of asset symbols
 * @param startTime - League start timestamp
 * @param endTime - League end timestamp
 * @returns Array of estimation requests
 */
export function createLeagueRoundRequests(
  assets: string[],
  startTime: number,
  endTime: number,
): Array<{ asset: string; timestamp: number; type: "start" | "end" }> {
  const requests: Array<{ asset: string; timestamp: number; type: "start" | "end" }> = [];

  for (const asset of assets) {
    if (isValidAsset(asset)) {
      requests.push(
        { asset: asset.toUpperCase(), timestamp: startTime, type: "start" },
        { asset: asset.toUpperCase(), timestamp: endTime, type: "end" },
      );
    }
  }

  return requests;
}

/**
 * Batch estimate rounds for a league
 * @param assets - Array of asset symbols
 * @param startTime - League start timestamp
 * @param endTime - League end timestamp
 * @returns Promise with organized estimation results
 */
export async function estimateLeagueRounds(
  assets: string[],
  startTime: number,
  endTime: number,
): Promise<{
  startRounds: Record<string, RoundEstimationResult>;
  endRounds: Record<string, RoundEstimationResult>;
}> {
  const requests = createLeagueRoundRequests(assets, startTime, endTime);
  const basicRequests = requests.map(({ asset, timestamp }) => ({ asset, timestamp }));

  const results = await estimateMultipleRoundIds(basicRequests);

  const startRounds: Record<string, RoundEstimationResult> = {};
  const endRounds: Record<string, RoundEstimationResult> = {};

  requests.forEach((request, index) => {
    const result = results[index];
    if (request.type === "start") {
      startRounds[request.asset] = result;
    } else {
      endRounds[request.asset] = result;
    }
  });

  return { startRounds, endRounds };
}
