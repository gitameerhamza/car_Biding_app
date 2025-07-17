import 'package:cbazaar/features/auth/presentation/login_screen.dart';
import 'package:cbazaar/core/widgets/main_navigation.dart';
import 'package:cbazaar/features/admin/presentation/admin_login_screen.dart';
import 'package:cbazaar/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:cbazaar/features/admin/presentation/admin_user_management_screen.dart';
import 'package:cbazaar/features/admin/presentation/admin_event_management_screen.dart';
import 'package:cbazaar/features/admin/presentation/admin_ad_management_screen.dart';
import 'package:cbazaar/features/admin/presentation/admin_setup_screen.dart';
import 'package:cbazaar/features/admin/controllers/admin_auth_controller.dart';
import 'package:cbazaar/features/admin/controllers/admin_dashboard_controller.dart';
import 'package:cbazaar/features/admin/services/admin_auth_service.dart';
import 'package:cbazaar/features/user/presentation/user_profile_screen.dart';
import 'package:cbazaar/features/user/presentation/car_search_screen.dart';
import 'package:cbazaar/features/user/presentation/bid_management_screen.dart';
import 'package:cbazaar/features/user/presentation/notification_screen.dart';
import 'package:cbazaar/features/user/presentation/event_view_screen.dart';
import 'package:cbazaar/features/user/presentation/chat_screen.dart';
import 'package:cbazaar/features/user/presentation/chat_list_screen.dart';
import 'package:cbazaar/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Handle OpenGL ES errors gracefully
  FlutterError.onError = (FlutterErrorDetails details) {
    // Filter out OpenGL ES errors that don't affect functionality
    if (details.exception.toString().contains('OpenGL ES API')) {
      // Log the error but don't crash the app
      print('OpenGL ES API warning: ${details.exception}');
      return;
    }
    // Handle other errors normally
    FlutterError.presentError(details);
  };
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'C-Bazaar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        // Add visual density for better mobile experience
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Add global overflow prevention
      builder: (context, child) {
        return MediaQuery(
          // Ensure text scaling doesn't break layouts
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      onReady: () async {
        await Future.delayed(const Duration(milliseconds: 2000));
        FlutterNativeSplash.remove();
      },
      // Add routes for admin functionality
      getPages: [
        GetPage(name: '/', page: () => const AuthWrapper()),
        GetPage(name: '/admin/setup', page: () => const AdminSetupScreen()),
        GetPage(name: '/admin/login', page: () => const AdminLoginScreen()),
        GetPage(
          name: '/admin/dashboard', 
          page: () => const AdminDashboardScreen(),
          middlewares: [AdminAuthMiddleware()],
        ),
        GetPage(
          name: '/admin/users', 
          page: () => const AdminUserManagementScreen(),
          middlewares: [AdminAuthMiddleware()],
        ),
        GetPage(
          name: '/admin/events', 
          page: () => const AdminEventManagementScreen(),
          middlewares: [AdminAuthMiddleware()],
        ),
        GetPage(
          name: '/admin/ads', 
          page: () => const AdminAdManagementScreen(),
          middlewares: [AdminAuthMiddleware()],
        ),
        // User routes
        GetPage(name: '/user/profile', page: () => const UserProfileScreen()),
        GetPage(name: '/user/search', page: () => const CarSearchScreen()),
        GetPage(name: '/user/bids', page: () => const BidManagementScreen()),
        GetPage(name: '/user/notifications', page: () => const NotificationScreen()),
        GetPage(name: '/user/events', page: () => const EventViewScreen()),
        GetPage(name: '/user/chats', page: () => const ChatListScreen()),
        GetPage(
          name: '/user/chat/:chatId/:sellerName', 
          page: () => ChatScreen(
            chatId: Get.parameters['chatId']!,
            sellerName: Get.parameters['sellerName']!,
          ),
        ),
      ],
      home: const AuthWrapper(),
    );
  }
}

// Wrapper widget to handle authentication routing
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('Auth State changed');
        if (snapshot.hasData) {
          // Check if user is admin
          final user = snapshot.data!;
          final adminService = AdminAuthService();
          
          if (adminService.isAdminEmail(user.email ?? '')) {
            // Check if we're already on an admin route to avoid conflicts
            final currentRoute = Get.currentRoute;
            if (currentRoute.startsWith('/admin/')) {
              // If already on admin route, don't interfere
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            
            // Initialize admin controller and redirect to admin dashboard
            Get.put(AdminAuthController());
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Get.offAllNamed('/admin/dashboard');
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          return const MainNavigation();
        }
        return const LoginScreen();
      },
    );
  }
}

// Middleware to protect admin routes
class AdminAuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    try {
      // Try to find existing controller or create one
      final authController = Get.isRegistered<AdminAuthController>() 
          ? Get.find<AdminAuthController>()
          : Get.put(AdminAuthController());
      
      if (!authController.isAuthenticated) {
        return const RouteSettings(name: '/admin/login');
      }
      
      // Ensure AdminDashboardController is available for all admin routes
      if (!Get.isRegistered<AdminDashboardController>()) {
        Get.put(AdminDashboardController(), permanent: true);
      }
      
      return null;
    } catch (e) {
      // If there's any error, redirect to admin login
      return const RouteSettings(name: '/admin/login');
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
