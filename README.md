
# C-Bazaar

C-Bazaar is a comprehensive Flutter application for car trading, featuring user authentication, car management, bidding, events, chat, and a robust admin dashboard. The app is built with Firebase, GetX, and modern Flutter best practices.

## Features

### User System
- Secure authentication (register, login, forgot password)
- User profiles with editable personal info, stats, and preferences
- Car management: add, edit, delete, and search car ads
- Advanced car search and comparison (by make, year, price, etc.)
- Bidding system: place, withdraw, and manage bids
- Event system: browse, join, and view events
- Real-time chat and messaging between users

### Admin System
- Admin authentication and setup utility
- Admin dashboard with analytics and stats
- User management: view, edit, suspend, or delete users
- Car, ad, bid, and event moderation
- Role-based permissions for super admins

### Bidding System
- Place bids on cars with validation and constraints
- Seller can view and manage bids on their cars
- Bid notifications and status updates

### Events & Chat
- Event creation, management, and participation
- Real-time chat with unread message tracking

## Project Structure

- `lib/` - Main app source code
  - `core/` - Core utilities, widgets, and navigation
  - `features/` - Feature modules (auth, user, admin, home, etc.)
  - `main.dart` - App entry point
- `test/` - Unit and widget tests
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` - Platform-specific code

## Getting Started

1. **Clone the repository:**
   ```sh
   git clone <repo-url>
   cd cbazaar
   ```
2. **Install dependencies:**
   ```sh
   flutter pub get
   ```
3. **Configure Firebase:**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the respective folders.
   - Update `firebase_options.dart` if needed.
4. **Run the app:**
   ```sh
   flutter run
   ```

## Testing

Run all tests:
```sh
flutter test
```

## Scripts

- `validate_bidding.sh` - Script to check bidding system integration and features

## Contribution

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## Documentation

- See `USER_SYSTEM_DOCUMENTATION.md` and other `*_DOCUMENTATION.md` files for detailed feature documentation.

## License

This project is licensed under the MIT License.
