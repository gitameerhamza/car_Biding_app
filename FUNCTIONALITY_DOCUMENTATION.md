# Car Bazaar (CBazaar) - Functionality Documentation

## Overview
Car Bazaar is a comprehensive Flutter application for car trading with bidding functionality, event management, and admin controls. The app uses Firebase for backend services including authentication, database, and storage.

## Architecture
- **Frontend**: Flutter with GetX state management
- **Backend**: Firebase (Firestore, Auth, Storage)
- **Architecture Pattern**: Clean Architecture with feature-based structure

## Core Functionalities

### 1. Authentication System
**Location**: `lib/features/auth/`

#### Features:
- **User Registration**: Email/password registration with validation
- **User Login**: Secure authentication with Firebase Auth
- **Password Reset**: Forgot password functionality
- **Admin Authentication**: Special admin login flow
- **Session Management**: Persistent login sessions

#### Controllers:
- `LoginController`: Handles user login
- `RegisterController`: Manages user registration
- `ForgotController`: Handles password reset

#### Screens:
- `LoginScreen`: Main login interface
- `RegisterScreen`: User registration form
- `ForgotScreen`: Password reset interface

### 2. User Management
**Location**: `lib/features/user/`

#### Features:
- **Profile Management**: User profile creation and updates
- **Car Search**: Advanced search and filtering
- **Bid Management**: Place and track bids
- **Chat System**: Messaging between users
- **Event Viewing**: Browse and view events

#### Controllers:
- `UserProfileController`: Profile management
- `CarSearchController`: Search functionality
- `BidController`: Bidding operations
- `ChatController`: Messaging system
- `EventController`: Event interactions

#### Services:
- `UserService`: User data operations
- `CarService`: Car-related services
- `BidService`: Bidding operations
- `ChatService`: Chat functionality
- `EventService`: Event management

### 3. Admin Panel
**Location**: `lib/features/admin/`

#### Features:
- **Dashboard Analytics**: Real-time statistics and charts
- **User Management**: User oversight and restriction
- **Ad Management**: Car listing moderation
- **Bid Management**: Bid oversight and control
- **Event Management**: Create and manage events

#### Controllers:
- `AdminAuthController`: Admin authentication
- `AdminDashboardController`: Dashboard data

#### Services:
- `AdminAuthService`: Admin authentication logic
- `AdminDataService`: Admin data operations

#### Dashboard Features:
- **Statistics Cards**: Total users, ads, bids, events
- **Analytics Charts**: Pie charts for data visualization
- **Quick Actions**: Fast access to common tasks
- **Recent Activities**: Activity monitoring
- **User Restriction**: Suspend/ban users
- **Suspicious Activity Detection**: Automated flagging

### 4. Car Listing System
**Location**: `lib/features/profile/` and `lib/features/home/`

#### Features:
- **Add Car Listings**: Create detailed car advertisements
- **Car Details**: Comprehensive car information
- **Image Management**: Multiple car photos
- **Car Comparison**: Side-by-side comparison tool
- **Status Management**: Active/Sold/Reserved status

#### Controllers:
- `AddCarController`: Car listing creation
- `YourCarsController`: User's car management
- `HomeController`: Main feed and search

### 5. Bidding System
**Location**: `lib/features/user/models/bid_model.dart`

#### Features:
- **Place Bids**: Submit bids on car listings
- **Bid Tracking**: Monitor bid status
- **Bid History**: View bidding history
- **Auto-bidding**: Automated bidding options
- **Bid Notifications**: Real-time bid updates

### 6. Event Management
**Location**: `lib/features/home/models/event_model.dart`

#### Features:
- **Event Creation**: Admin creates car shows/events
- **Event Display**: Showcase upcoming events
- **Event Details**: Comprehensive event information
- **Location Integration**: Event venue mapping

### 7. Chat System
**Location**: `lib/features/user/presentation/chat_*.dart`

#### Features:
- **Direct Messaging**: User-to-user communication
- **Chat Lists**: Conversation management
- **Real-time Updates**: Live message delivery
- **Message History**: Persistent chat storage

### 8. Search and Filtering
**Location**: `lib/features/user/presentation/car_search_screen.dart`

#### Features:
- **Advanced Search**: Multi-criteria filtering
- **Location-based Search**: City/region filtering
- **Price Range Filters**: Budget-based search
- **Make/Model Filters**: Brand-specific search
- **Real-time Results**: Dynamic search updates

### 9. Charts and Analytics
**Location**: `lib/features/profile/presentation/widgets/`

#### Features:
- **Bar Charts**: Statistical data visualization
- **Line Charts**: Trend analysis
- **Pie Charts**: Category distribution
- **Performance Metrics**: App usage analytics

## Testing Strategy

### Unit Tests
1. **Authentication Tests** (`test/auth_test.dart`)
   - Login validation
   - Registration validation
   - Password reset functionality
   - Admin authentication

2. **User Feature Tests** (`test/user_test.dart`)
   - Profile management
   - Search functionality
   - Bid operations
   - Chat system

3. **Admin Feature Tests** (`test/admin_test.dart`)
   - Dashboard analytics
   - User management
   - Content moderation

### Integration Tests
- Complete user workflows
- Admin panel operations
- Firebase integration tests
- Payment processing tests

### Performance Tests
- App startup time
- Image loading performance
- Real-time updates
- Database query optimization

## Task Categories

### Development Tasks
1. **Flutter: Run Debug Mode** - Development testing
2. **Flutter: Run Release Mode** - Production testing
3. **Development: Hot Reload Watch** - Live development

### Build Tasks
4. **Flutter: Clean Project** - Clean build artifacts
5. **Flutter: Get Dependencies** - Update packages
6. **Flutter: Build APK** - Android release build
7. **Flutter: Build iOS** - iOS release build

### Test Tasks
8. **Flutter: Run Tests** - All unit tests
9. **Test: Authentication Flow** - Auth testing
10. **Test: User Profile Management** - Profile tests
11. **Test: Car Listing Features** - Car functionality tests
12. **Test: Bidding System** - Bidding tests
13. **Test: Chat System** - Messaging tests
14. **Test: Event Management** - Event tests
15. **Test: Admin Dashboard** - Admin tests
16. **Test: Search Functionality** - Search tests

### Code Quality Tasks
17. **Dart: Analyze Code** - Static analysis
18. **Dart: Format Code** - Code formatting

### Performance Tasks
19. **Performance: Profile App** - Performance analysis

### Maintenance Tasks
20. **Maintenance: Update Dependencies** - Package updates
21. **Maintenance: Check Outdated Packages** - Dependency audit

## Firebase Configuration
- **Authentication**: Email/password and admin auth
- **Firestore**: Real-time database for users, cars, bids, events
- **Storage**: Image and file storage
- **Security Rules**: Access control and data validation

## State Management
- **GetX**: Reactive state management
- **Controllers**: Business logic separation
- **Services**: Data layer abstraction
- **Models**: Data structure definitions

## Key Dependencies
- `firebase_core`: Firebase initialization
- `firebase_auth`: Authentication services
- `cloud_firestore`: Database operations
- `firebase_storage`: File storage
- `get`: State management and routing
- `cached_network_image`: Image optimization
- `fl_chart`: Data visualization
- `image_picker`: Image selection

## Security Features
- Firebase security rules
- Input validation
- Authentication middleware
- Admin role verification
- Data sanitization

## Future Enhancements
- Payment integration
- Push notifications
- Advanced analytics
- Machine learning recommendations
- Social features
- API integrations
