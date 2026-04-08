import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/buyer_controller.dart';
import 'controllers/chat_controller.dart';
import 'controllers/crop_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/equipment_controller.dart';
import 'controllers/fertilizer_controller.dart';
import 'controllers/growing_controller.dart';
import 'controllers/market_controller.dart';
import 'controllers/reports_controller.dart';
import 'controllers/resources_controller.dart';
import 'core/navigation/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'views/screens/auth/forgot_password_screen.dart';
import 'views/screens/auth/login_screen.dart';
import 'views/screens/auth/register_screen.dart';
import 'views/screens/auth/reset_password_screen.dart';
import 'views/screens/auth/verify_otp_screen.dart';
import 'views/screens/buyer/buyer_marketplace_screen.dart';
import 'views/screens/buyer/create_listing_screen.dart';
import 'views/screens/buyer/my_listings_screen.dart';
import 'views/screens/buyer/purchase_history_screen.dart';
import 'views/screens/chat/chat_assistant_screen.dart';
import 'views/screens/crop/crop_suggestion_screen.dart';
import 'views/screens/crop/disease_detection_screen.dart';
import 'views/screens/crop/start_growing_screen.dart';
import 'views/screens/equipment/equipment_create_listing_screen.dart';
import 'views/screens/equipment/equipment_list_form_screen.dart';
import 'views/screens/equipment/equipment_marketplace_screen.dart';
import 'views/screens/equipment/equipment_my_listings_screen.dart';
import 'views/screens/equipment/equipment_rental_history_screen.dart';
import 'views/screens/fertilizer/fertilizer_recommend_screen.dart';
import 'views/screens/growing/growing_activities_screen.dart';
import 'views/screens/growing/growing_view_screen.dart';
import 'views/screens/home/home_shell_screen.dart';
import 'views/screens/home/landing_screen.dart';
import 'views/screens/market/market_watch_screen.dart';
import 'views/screens/reports/reports_screen.dart';
import 'views/screens/resources/regional_calendar_screen.dart';
import 'views/screens/static/about_screen.dart';
import 'views/screens/static/features_screen.dart';
import 'services/auth_service.dart';
import 'services/buyer_service.dart';
import 'services/chat_service.dart';
import 'services/crop_service.dart';
import 'services/dashboard_service.dart';
import 'services/equipment_service.dart';
import 'services/fertilizer_service.dart';
import 'services/growing_service.dart';
import 'services/market_service.dart';
import 'services/report_service.dart';
import 'services/resources_service.dart';

class SmartFarmingMobileApp extends StatelessWidget {
  const SmartFarmingMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(AuthService())..validateSession(),
        ),
        ChangeNotifierProvider<DashboardController>(
          create: (_) => DashboardController(DashboardService()),
        ),
        ChangeNotifierProvider<CropController>(
          create: (_) => CropController(CropService()),
        ),
        ChangeNotifierProvider<GrowingController>(
          create: (_) => GrowingController(GrowingService()),
        ),
        ChangeNotifierProvider<FertilizerController>(
          create: (_) => FertilizerController(FertilizerService()),
        ),
        ChangeNotifierProvider<MarketController>(
          create: (_) => MarketController(MarketService()),
        ),
        ChangeNotifierProvider<BuyerController>(
          create: (_) => BuyerController(BuyerService()),
        ),
        ChangeNotifierProvider<EquipmentController>(
          create: (_) => EquipmentController(EquipmentService()),
        ),
        ChangeNotifierProvider<ResourcesController>(
          create: (_) => ResourcesController(ResourcesService()),
        ),
        ChangeNotifierProvider<ChatController>(
          create: (_) => ChatController(ChatService()),
        ),
        ChangeNotifierProvider<ReportsController>(
          create: (_) => ReportsController(ReportService()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Farming Assistant',
        theme: AppTheme.light,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        initialRoute: AppRoutes.landing,
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case AppRoutes.landing:
              return _route(const LandingScreen());
            case AppRoutes.login:
              return _route(const LoginScreen());
            case AppRoutes.register:
              return _route(const RegisterScreen());
            case AppRoutes.forgotPassword:
              return _route(const ForgotPasswordScreen());
            case AppRoutes.verifyOtp:
              return _route(const VerifyOtpScreen());
            case AppRoutes.resetPassword:
              return _route(const ResetPasswordScreen());
            case AppRoutes.home:
            case AppRoutes.dashboard:
              return _route(const HomeShellScreen());
            case AppRoutes.cropSuggestion:
              return _route(const CropSuggestionScreen());
            case AppRoutes.startGrowing:
              return _route(const StartGrowingScreen());
            case AppRoutes.growingActivities:
              return _route(const GrowingActivitiesScreen());
            case AppRoutes.growingView:
              return _route(const GrowingViewScreen());
            case AppRoutes.diseaseDetection:
              return _route(const DiseaseDetectionScreen());
            case AppRoutes.fertilizerRecommend:
              return _route(const FertilizerRecommendScreen());
            case AppRoutes.marketWatch:
              return _route(const MarketWatchScreen());
            case AppRoutes.buyerMarketplace:
              return _route(const BuyerMarketplaceScreen());
            case AppRoutes.createListing:
              return _route(const CreateListingScreen());
            case AppRoutes.myListings:
              return _route(const MyListingsScreen());
            case AppRoutes.purchaseHistory:
              return _route(const PurchaseHistoryScreen());
            case AppRoutes.equipmentMarketplace:
              return _route(const EquipmentMarketplaceScreen());
            case AppRoutes.equipmentCreateListing:
              return _route(const EquipmentCreateListingScreen());
            case AppRoutes.equipmentListForm:
              return _route(const EquipmentListFormScreen());
            case AppRoutes.equipmentMyListings:
              return _route(const EquipmentMyListingsScreen());
            case AppRoutes.equipmentRentalHistory:
              return _route(const EquipmentRentalHistoryScreen());
            case AppRoutes.regionalCalendar:
              return _route(const RegionalCalendarScreen());
            case AppRoutes.chat:
              return _route(const ChatAssistantScreen());
            case AppRoutes.reports:
              return _route(const ReportsScreen());
            case AppRoutes.about:
              return _route(const AboutScreen());
            case AppRoutes.features:
              return _route(const FeaturesScreen());
            default:
              return _route(const LandingScreen());
          }
        },
      ),
    );
  }

  MaterialPageRoute<void> _route(Widget child) {
    return MaterialPageRoute<void>(builder: (_) => child);
  }
}
