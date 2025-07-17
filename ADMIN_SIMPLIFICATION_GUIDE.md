# Admin Cleanup Instructions

## Automated Cleanup (Already Done)
The app has been updated to use only a single admin role with full access:
- ✅ Updated AdminModel to reflect single admin role
- ✅ Updated AdminAuthService to only allow 'admin@cbazaar.com'
- ✅ Updated role permissions to give admin full access
- ✅ Updated UI components to show single admin role
- ✅ Added cleanup utility to remove old admin records from Firestore

## Manual Cleanup Required in Firebase Console

### 1. Remove Old Admin Accounts from Firebase Authentication
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your CBazaar project
3. Navigate to **Authentication** > **Users**
4. Find and delete these accounts:
   - `superadmin@cbazaar.com`
   - `moderator@cbazaar.com`
5. Keep only: `admin@cbazaar.com`

### 2. Update Firestore Security Rules
The Firestore rules have been updated to be more restrictive and only allow the single admin account.

### 3. Clean Firestore Admin Collection
Run the admin cleanup utility from the app:
1. Go to `/admin/setup` route in your app
2. Click "Cleanup Old Admins" button
3. This will remove old admin records from Firestore
4. Update the remaining admin record to have full permissions

### 4. Verify Cleanup
1. Click "Check Config" button in admin setup
2. Verify only one admin account exists
3. Verify it has the 'admin' role with full permissions

## Final Configuration
After cleanup, you will have:
- **Single Admin Email**: admin@cbazaar.com
- **Role**: admin
- **Permissions**: All permissions (manage_admins, manage_users, manage_ads, etc.)
- **Access**: Full system access

## Security Notes
- The admin account now has all necessary permissions
- No role hierarchy - single admin with full access
- Firebase Auth users for old admin emails need manual removal
- Firestore rules now properly restrict access to authenticated users and admin

## To Add New Admins in Future
1. Add new email to `adminEmails` list in `AdminAuthService`
2. Create the Firebase Auth account
3. The system will automatically create Firestore admin record with 'admin' role
