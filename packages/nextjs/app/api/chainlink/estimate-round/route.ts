import { NextRequest, NextResponse } from "next/server";
import { createPublicClient, http } from "viem";
import { sepolia } from "viem/chains";

// Chainlink AggregatorV3Interface ABI (minimal)
const AGGREGATOR_ABI = [
  {
    inputs: [],
    name: "latestRoundData",
    outputs: [
      { name: "roundId", type: "uint80" },
      { name: "answer", type: "int256" },
      { name: "startedAt", type: "uint256" },
      { name: "updatedAt", type: "uint256" },
      { name: "answeredInRound", type: "uint80" },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ name: "_roundId", type: "uint80" }],
    name: "getRoundData",
    outputs: [
      { name: "roundId", type: "uint80" },
      { name: "answer", type: "int256" },
      { name: "startedAt", type: "uint256" },
      { name: "updatedAt", type: "uint256" },
      { name: "answeredInRound", type: "uint80" },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

// Sepolia testnet price feed addresses
const PRICE_FEEDS = {
  ETH: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
  BTC: "0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43",
  WBTC: "0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43",
} as const;

type AssetSymbol = keyof typeof PRICE_FEEDS;

// Create viem client for Sepolia
const client = createPublicClient({
  chain: sepolia,
  transport: http(),
});

/**
 * Estimates the round ID for a given timestamp using sampling approach
 */
async function estimateRoundIdForTimestamp(
  feedAddress: string,
  targetTimestamp: number,
): Promise<{ estimatedRoundId: number; confidence: "high" | "medium" | "low" }> {
  try {
    // Get latest round data
    const latestRoundData = await client.readContract({
      address: feedAddress as `0x${string}`,
      abi: AGGREGATOR_ABI,
      functionName: "latestRoundData",
    });

    const latestRoundId = Number(latestRoundData[0]);
    const latestTimestamp = Number(latestRoundData[3]);

    // If target timestamp is newer than latest, return latest
    if (targetTimestamp >= latestTimestamp) {
      return {
        estimatedRoundId: latestRoundId,
        confidence: "high",
      };
    }

    // Sample a few rounds to estimate the average time between rounds
    const sampleSize = Math.min(10, Math.floor(latestRoundId / 10));
    const sampleRounds = [];

    for (let i = 0; i < sampleSize; i++) {
      const sampleRoundId = latestRoundId - i * Math.floor(latestRoundId / sampleSize);

      try {
        const roundData = await client.readContract({
          address: feedAddress as `0x${string}`,
          abi: AGGREGATOR_ABI,
          functionName: "getRoundData",
          args: [BigInt(sampleRoundId)],
        });

        if (Number(roundData[1]) > 0) {
          // Valid price
          sampleRounds.push({
            roundId: sampleRoundId,
            timestamp: Number(roundData[3]),
          });
        }
      } catch (error) {
        // Skip invalid rounds
        console.log("Skipping invalid rounds:", error);
        continue;
      }
    }

    if (sampleRounds.length < 2) {
      // Fallback: assume roughly 1 round per hour for Chainlink feeds
      const timeDiff = latestTimestamp - targetTimestamp;
      const estimatedRoundsBack = Math.floor(timeDiff / 3600); // 1 hour average

      return {
        estimatedRoundId: Math.max(1, latestRoundId - estimatedRoundsBack),
        confidence: "low",
      };
    }

    // Calculate average time between rounds
    sampleRounds.sort((a, b) => a.timestamp - b.timestamp);

    let totalTimeDiff = 0;
    let totalRoundDiff = 0;

    for (let i = 1; i < sampleRounds.length; i++) {
      const timeDiff = sampleRounds[i].timestamp - sampleRounds[i - 1].timestamp;
      const roundDiff = sampleRounds[i].roundId - sampleRounds[i - 1].roundId;

      if (timeDiff > 0 && roundDiff > 0) {
        totalTimeDiff += timeDiff;
        totalRoundDiff += roundDiff;
      }
    }

    if (totalRoundDiff === 0) {
      // Fallback
      const timeDiff = latestTimestamp - targetTimestamp;
      const estimatedRoundsBack = Math.floor(timeDiff / 3600);

      return {
        estimatedRoundId: Math.max(1, latestRoundId - estimatedRoundsBack),
        confidence: "low",
      };
    }

    // Average time per round
    const avgTimePerRound = totalTimeDiff / totalRoundDiff;

    // Estimate rounds back from target timestamp
    const timeDiffFromLatest = latestTimestamp - targetTimestamp;
    const estimatedRoundsBack = Math.floor(timeDiffFromLatest / avgTimePerRound);

    const estimatedRoundId = Math.max(1, latestRoundId - estimatedRoundsBack);

    // Determine confidence based on sample size and consistency
    let confidence: "high" | "medium" | "low" = "medium";

    if (sampleRounds.length >= 8) {
      confidence = "high";
    } else if (sampleRounds.length >= 4) {
      confidence = "medium";
    } else {
      confidence = "low";
    }

    return {
      estimatedRoundId,
      confidence,
    };
  } catch (error) {
    console.error("Error estimating round ID:", error);
    // Return a very rough estimate
    return {
      estimatedRoundId: 1,
      confidence: "low",
    };
  }
}

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const asset = searchParams.get("asset")?.toUpperCase() as AssetSymbol;
    const timestamp = searchParams.get("timestamp");

    // Validation
    if (!asset || !timestamp) {
      return NextResponse.json({ error: "Missing required parameters: asset and timestamp" }, { status: 400 });
    }

    if (!PRICE_FEEDS[asset]) {
      return NextResponse.json(
        { error: `Unsupported asset: ${asset}. Supported assets: ${Object.keys(PRICE_FEEDS).join(", ")}` },
        { status: 400 },
      );
    }

    const targetTimestamp = parseInt(timestamp);
    if (isNaN(targetTimestamp) || targetTimestamp <= 0) {
      return NextResponse.json({ error: "Invalid timestamp format" }, { status: 400 });
    }

    // Get the price feed address
    const feedAddress = PRICE_FEEDS[asset];

    // Estimate the round ID
    const result = await estimateRoundIdForTimestamp(feedAddress, targetTimestamp);

    return NextResponse.json({
      success: true,
      data: {
        asset,
        targetTimestamp,
        feedAddress,
        estimatedRoundId: result.estimatedRoundId,
        confidence: result.confidence,
        estimatedAt: Math.floor(Date.now() / 1000),
      },
    });
  } catch (error) {
    console.error("API Error:", error);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { asset, timestamp } = body;

    // Validation
    if (!asset || !timestamp) {
      return NextResponse.json({ error: "Missing required parameters: asset and timestamp" }, { status: 400 });
    }

    const assetUpper = asset.toUpperCase() as AssetSymbol;

    if (!PRICE_FEEDS[assetUpper]) {
      return NextResponse.json(
        { error: `Unsupported asset: ${asset}. Supported assets: ${Object.keys(PRICE_FEEDS).join(", ")}` },
        { status: 400 },
      );
    }

    const targetTimestamp = parseInt(timestamp);
    if (isNaN(targetTimestamp) || targetTimestamp <= 0) {
      return NextResponse.json({ error: "Invalid timestamp format" }, { status: 400 });
    }

    // Get the price feed address
    const feedAddress = PRICE_FEEDS[assetUpper];

    // Estimate the round ID
    const result = await estimateRoundIdForTimestamp(feedAddress, targetTimestamp);

    return NextResponse.json({
      success: true,
      data: {
        asset: assetUpper,
        targetTimestamp,
        feedAddress,
        estimatedRoundId: result.estimatedRoundId,
        confidence: result.confidence,
        estimatedAt: Math.floor(Date.now() / 1000),
      },
    });
  } catch (error) {
    console.error("API Error:", error);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}
