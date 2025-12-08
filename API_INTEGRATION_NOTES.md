# API Integration Issues & Solutions

## Current Problems

### 1. CORS Error (Cross-Origin Resource Sharing)
**Error**: `ERR_EMPTY_RESPONSE` / `Failed to fetch`
**Cause**: API server `https://api.bbbb.com.la` doesn't allow requests from browser (localhost)
**Impact**: Cannot test on Chrome/Web browser

**Solutions**:
- **Option A**: Ask backend team to enable CORS headers:
  ```
  Access-Control-Allow-Origin: *
  Access-Control-Allow-Methods: POST, GET, OPTIONS
  Access-Control-Allow-Headers: Content-Type, Accept
  ```
- **Option B**: Test on Android/iOS (mobile apps don't have CORS restrictions) ✅ RECOMMENDED

### 2. GraphQL Schema Mismatch
**Error**: `Cannot query field "id" on type "ResponeStockData"`
**Cause**: The GraphQL query uses wrong field names

**Current Query**:
```graphql
query StocksV2($where: StockWhereInput, $skip: Int, $limit: Int) {
  stocksV2(where: $where, skip: $skip, limit: $limit) {
    total
    data {
      id          # ❌ Field doesn't exist
      name        # ❌ Field doesn't exist  
      price       # ❌ Field doesn't exist
      image       # ❌ Field doesn't exist
      amount      # ❌ Field doesn't exist
      amountAll   # ❌ Field doesn't exist
      category {
        id
      }
    }
  }
}
```

## What We Need from Backend Team

### 1. Correct GraphQL Schema
Please provide the **correct field names** for `ResponeStockData` type:

```graphql
type ResponeStockData {
  # What are the actual field names?
  # Example:
  productId: String
  productName: String
  productPrice: Float
  productImage: String
  stockAmount: Int
  # ... etc
}
```

### 2. Example Response
Please provide a **sample successful response** from this query:
```graphql
query {
  stocksV2(skip: 0, limit: 10) {
    total
    data {
      # Include all available fields here
    }
  }
}
```

### 3. API Documentation
- GraphQL Playground URL?
- Any authentication required (API key, Bearer token)?
- Complete schema documentation?

## Testing on Android (Workaround)

Since CORS blocks web testing, test on Android instead:

```cmd
# 1. Connect your Android device via USB
# 2. Enable USB debugging
# 3. Build and install APK

flutter clean
flutter pub get
flutter build apk --debug
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

Device i80 (d998a4f) is already connected and ready to test!

## Current Code Location

GraphQL integration code:
- **File**: `lib/main.dart`
- **Class**: `ApiService`
- **Method**: `fetchProducts()`
- **Line**: ~70-150

## Next Steps

1. ✅ Get correct GraphQL schema from backend
2. ✅ Update query with correct field names
3. ✅ Test on Android device (bypass CORS)
4. ⚠️ OR: Ask backend to enable CORS for web testing

---

**Contact Backend Team**: Please provide the correct GraphQL schema and field names for `stocksV2` query!
