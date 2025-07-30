import React, { useCallback, useState } from "react";
import {
  RoundEstimationResult,
  estimateLeagueRounds,
  estimateMultipleRoundIds,
  estimateRoundId,
} from "../utils/chainlink/roundEstimation";

interface UseRoundEstimationState {
  isLoading: boolean;
  error: string | null;
  result: RoundEstimationResult | null;
}

interface UseMultipleRoundEstimationState {
  isLoading: boolean;
  error: string | null;
  results: RoundEstimationResult[];
}

interface UseLeagueRoundEstimationState {
  isLoading: boolean;
  error: string | null;
  startRounds: Record<string, RoundEstimationResult>;
  endRounds: Record<string, RoundEstimationResult>;
}

/**
 * Hook for estimating a single round ID
 */
export function useRoundEstimation() {
  const [state, setState] = useState<UseRoundEstimationState>({
    isLoading: false,
    error: null,
    result: null,
  });

  const estimate = useCallback(async (asset: string, timestamp: number) => {
    setState({ isLoading: true, error: null, result: null });

    try {
      const result = await estimateRoundId(asset, timestamp);
      setState({ isLoading: false, error: null, result });
      return result;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : "Unknown error occurred";
      setState({ isLoading: false, error: errorMessage, result: null });
      throw error;
    }
  }, []);

  const reset = useCallback(() => {
    setState({ isLoading: false, error: null, result: null });
  }, []);

  return {
    ...state,
    estimate,
    reset,
  };
}

/**
 * Hook for estimating multiple round IDs
 */
export function useMultipleRoundEstimation() {
  const [state, setState] = useState<UseMultipleRoundEstimationState>({
    isLoading: false,
    error: null,
    results: [],
  });

  const estimate = useCallback(async (requests: Array<{ asset: string; timestamp: number }>) => {
    setState({ isLoading: true, error: null, results: [] });

    try {
      const results = await estimateMultipleRoundIds(requests);
      setState({ isLoading: false, error: null, results });
      return results;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : "Unknown error occurred";
      setState({ isLoading: false, error: errorMessage, results: [] });
      throw error;
    }
  }, []);

  const reset = useCallback(() => {
    setState({ isLoading: false, error: null, results: [] });
  }, []);

  return {
    ...state,
    estimate,
    reset,
  };
}

/**
 * Hook for estimating round IDs for a league (start and end times for multiple assets)
 */
export function useLeagueRoundEstimation() {
  const [state, setState] = useState<UseLeagueRoundEstimationState>({
    isLoading: false,
    error: null,
    startRounds: {},
    endRounds: {},
  });

  const estimate = useCallback(async (assets: string[], startTime: number, endTime: number) => {
    setState({
      isLoading: true,
      error: null,
      startRounds: {},
      endRounds: {},
    });

    try {
      const { startRounds, endRounds } = await estimateLeagueRounds(assets, startTime, endTime);
      setState({
        isLoading: false,
        error: null,
        startRounds,
        endRounds,
      });
      return { startRounds, endRounds };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : "Unknown error occurred";
      setState({
        isLoading: false,
        error: errorMessage,
        startRounds: {},
        endRounds: {},
      });
      throw error;
    }
  }, []);

  const reset = useCallback(() => {
    setState({
      isLoading: false,
      error: null,
      startRounds: {},
      endRounds: {},
    });
  }, []);

  return {
    ...state,
    estimate,
    reset,
  };
}

/**
 * Hook for getting real-time round estimation with auto-refresh capability
 */
export function useRealtimeRoundEstimation(
  asset: string | null,
  timestamp: number | null,
  autoRefresh = false,
  refreshInterval = 60000, // 1 minute
) {
  const [state, setState] = useState<UseRoundEstimationState>({
    isLoading: false,
    error: null,
    result: null,
  });

  const estimate = useCallback(async () => {
    if (!asset || !timestamp) return;

    setState(prev => ({ ...prev, isLoading: true, error: null }));

    try {
      const result = await estimateRoundId(asset, timestamp);
      setState({ isLoading: false, error: null, result });
      return result;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : "Unknown error occurred";
      setState({ isLoading: false, error: errorMessage, result: null });
      throw error;
    }
  }, [asset, timestamp]);

  // Auto-refresh logic
  React.useEffect(() => {
    if (!autoRefresh || !asset || !timestamp) return;

    // Initial estimation
    estimate();

    // Set up interval for auto-refresh
    const interval = setInterval(estimate, refreshInterval);

    return () => clearInterval(interval);
  }, [asset, timestamp, autoRefresh, refreshInterval, estimate]);

  const reset = useCallback(() => {
    setState({ isLoading: false, error: null, result: null });
  }, []);

  return {
    ...state,
    estimate,
    reset,
  };
}

// Re-export utility functions for convenience
export {
  dateToTimestamp,
  timestampToDate,
  getConfidenceColor,
  formatConfidence,
  isValidAsset,
  isValidTimestamp,
} from "../utils/chainlink/roundEstimation";
