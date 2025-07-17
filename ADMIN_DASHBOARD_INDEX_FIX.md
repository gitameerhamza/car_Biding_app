# Admin Dashboard Firestore Index Fix

## Issue Description
The admin dashboard was failing to load statistics with the error:
```
Failed to load users: [cloud_firestore/failed-precondition] The query requires an index. You can create it here: https://console.firebase.google.com/v1/r/project/carbazar-a656d/firestore/indexes?create_composite=...
```

## Root Cause
The `AdminDataService.getAllUsers()` method was making compound queries that combined:
1. `.where()` clauses with `.orderBy()` clauses
2. Specifically:
   - `users.where('isRestricted', isEqualTo: value).orderBy('createdAt', descending: true)`
   - `users.where('accountStatus', isEqualTo: value).orderBy('createdAt', descending: true)`

Firestore requires composite indexes for queries that combine filtering and ordering on different fields.

## Solution Applied
Added the following composite indexes to `firestore.indexes.json`:

### Users Collection Indexes
```json
{
  "collectionGroup": "users",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "isRestricted",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "createdAt",
      "order": "DESCENDING"
    }
  ]
},
{
  "collectionGroup": "users",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "accountStatus",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "createdAt",
      "order": "DESCENDING"
    }
  ]
}
```

### Additional Indexes Added for Consistency
Also added indexes for bids collection queries:
```json
{
  "collectionGroup": "bids",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "car_id",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "bid_time",
      "order": "DESCENDING"
    }
  ]
},
{
  "collectionGroup": "bids",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "status",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "bid_time",
      "order": "DESCENDING"
    }
  ]
}
```

## Deployment
Indexes were successfully deployed using:
```bash
firebase deploy --only firestore:indexes
```

## Result
- Admin dashboard should now load successfully
- User management queries will work properly
- Statistics will display correctly
- No more "failed-precondition" errors

## Prevention
In the future, when adding new Firestore queries that combine:
- Multiple `.where()` clauses
- `.where()` + `.orderBy()` on different fields
- Complex filtering and sorting

Remember to:
1. Add the appropriate composite indexes to `firestore.indexes.json`
2. Deploy the indexes before deploying the code
3. Test in development environment first

## Files Modified
- `firestore.indexes.json` - Added missing composite indexes
- This documentation file for future reference
