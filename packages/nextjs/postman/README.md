# TryTrade Chainlink API Postman Collection

This Postman collection provides comprehensive testing for the TryTrade Chainlink Round ID Estimation API.

## 📁 Files Included

- `TryTrade-Chainlink-API.postman_collection.json` - Main API collection
- `TryTrade-Development.postman_environment.json` - Development environment variables
- `TryTrade-Production.postman_environment.json` - Production environment variables

## 🚀 Quick Start

### 1. Import Collection

1. Open Postman
2. Click "Import" button
3. Select `TryTrade-Chainlink-API.postman_collection.json`

### 2. Import Environment

1. Import the appropriate environment file:
   - For local development: `TryTrade-Development.postman_environment.json`
   - For production: `TryTrade-Production.postman_environment.json`
2. Select the environment from the dropdown in top-right corner

### 3. Update Environment Variables

- **Development**: Ensure `base_url` is set to `http://localhost:3000`
- **Production**: Update `base_url` with your actual domain

## 📋 Collection Structure

### 🎯 Round Estimation

Core API functionality for estimating Chainlink round IDs:

- **Estimate Round ID - GET (ETH)** - GET request with query parameters
- **Estimate Round ID - GET (BTC)** - BTC price feed estimation
- **Estimate Round ID - POST (ETH)** - POST request with JSON body
- **Estimate Round ID - POST (WBTC)** - WBTC (uses BTC feed) estimation

### ❌ Error Handling

Comprehensive error scenario testing:

- **Missing Asset Parameter** - 400 error when asset is missing
- **Missing Timestamp Parameter** - 400 error when timestamp is missing
- **Unsupported Asset** - 400 error for unsupported assets (e.g., DOGE)
- **Invalid Timestamp Format** - 400 error for non-numeric timestamps
- **Negative Timestamp** - 400 error for negative timestamps

### 🔄 Edge Cases

Boundary condition testing:

- **Future Timestamp** - Should return latest round with high confidence
- **Very Old Timestamp** - Should handle gracefully with fallback
- **Case Insensitive Asset** - Asset symbols normalized to uppercase

### ⚡ Performance Tests

Load and performance validation:

- **Multiple Concurrent Requests** - Response time and reliability testing

## 🔧 Environment Variables

### Dynamic Variables (Calculated in Pre-request Scripts)

- `timestamp_24h_ago` - Automatically calculated 24 hours ago
- `timestamp_1week_ago` - Automatically calculated 1 week ago
- `future_timestamp` - Automatically calculated 1 hour in the future

### Static Variables

- `base_url` - API base URL
- `timestamp_1month_ago` - Fixed timestamp (~1 month ago)
- `eth_feed_address` - Sepolia ETH/USD feed address
- `btc_feed_address` - Sepolia BTC/USD feed address

## 🧪 Test Automation

Each request includes automated tests that verify:

### ✅ Success Scenarios

- Status code is 200
- Response has correct structure
- Required fields are present
- Data types are correct
- Asset symbols are normalized
- Round IDs are positive numbers
- Confidence levels are valid (`high`, `medium`, `low`)

### ❌ Error Scenarios

- Appropriate error status codes (400, 500)
- Error messages are descriptive
- Required parameters validation

### 🚀 Performance

- Response times are reasonable (< 30 seconds)
- JSON format validation

## 📊 API Response Format

### Success Response

```json
{
  "success": true,
  "data": {
    "asset": "ETH",
    "targetTimestamp": 1704067200,
    "feedAddress": "0x694AA1769357215DE4FAC081bf1f309aDC325306",
    "estimatedRoundId": 123456,
    "confidence": "high",
    "estimatedAt": 1704067200
  }
}
```

### Error Response

```json
{
  "error": "Missing required parameters: asset and timestamp"
}
```

## 🎯 Supported Assets

- **ETH** - Ethereum (Feed: `0x694AA1769357215DE4FAC081bf1f309aDC325306`)
- **BTC** - Bitcoin (Feed: `0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43`)
- **WBTC** - Wrapped Bitcoin (Uses BTC feed)

## 🔄 Running Tests

### Single Request

1. Select a request from the collection
2. Ensure correct environment is selected
3. Click "Send"
4. Check the "Test Results" tab

### Collection Runner

1. Click on collection name
2. Click "Run" button
3. Select environment
4. Choose requests to run
5. Click "Run TryTrade Chainlink API"

### Command Line (Newman)

```bash
# Install Newman
npm install -g newman

# Run collection with development environment
newman run TryTrade-Chainlink-API.postman_collection.json \
  -e TryTrade-Development.postman_environment.json

# Run with HTML report
newman run TryTrade-Chainlink-API.postman_collection.json \
  -e TryTrade-Development.postman_environment.json \
  -r htmlextra --reporter-htmlextra-export report.html
```

## 🐛 Troubleshooting

### Common Issues

1. **Connection Refused**

   - Ensure Next.js dev server is running (`npm run dev`)
   - Check if port 3000 is available

2. **404 Not Found**

   - Verify API route exists at `/app/api/chainlink/estimate-round/route.ts`
   - Check base_url in environment

3. **Internal Server Error**

   - Check Sepolia RPC endpoint is accessible
   - Verify price feed addresses are correct
   - Check server logs for detailed errors

4. **Rate Limiting**
   - Some RPC providers have rate limits
   - Add delays between requests if needed

### Environment Setup

```bash
# Start development server
cd packages/nextjs
npm run dev

# Run in specific port
npm run dev -- -p 3001
```

## 📝 Timestamp Reference

Common timestamp values for testing:

- `1704067200` - 2024-01-01 00:00:00 UTC
- `1703980800` - 2023-12-31 00:00:00 UTC
- `1701388800` - 2023-12-01 00:00:00 UTC
- `1640995200` - 2022-01-01 00:00:00 UTC

Use online converters like [epoch.vercel.app](https://epoch.vercel.app) for custom timestamps.

## 🔗 Related Documentation

- [Chainlink Price Feeds](https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1&search=sepolia)
- [Next.js API Routes](https://nextjs.org/docs/api-routes/introduction)
- [Postman Testing](https://learning.postman.com/docs/writing-scripts/test-scripts/)
