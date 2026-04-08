# Smart Farming Assistant Mobile (Flutter)

Flutter conversion of the Smart Farming Assistant web platform, connected to:

- Backend API: https://smartfarmingassistant-pw45.onrender.com

## Architecture

This project follows an MVC-style modular structure:

- `models/`: typed app data models
- `services/`: backend API integrations with Dio
- `controllers/`: ChangeNotifier-based business logic and screen state
- `views/`: all Flutter UI screens (mapped from web pages)
- `core/`: shared config, theme, navigation, widgets, and network layer

## Folder Structure

```text
lib/
	app.dart
	main.dart
	controllers/
		auth_controller.dart
		buyer_controller.dart
		chat_controller.dart
		crop_controller.dart
		dashboard_controller.dart
		equipment_controller.dart
		fertilizer_controller.dart
		growing_controller.dart
		market_controller.dart
		reports_controller.dart
		resources_controller.dart
		base_controller.dart
	core/
		config/app_config.dart
		navigation/app_routes.dart
		network/
			api_client.dart
			api_result.dart
		theme/app_theme.dart
		utils/validators.dart
		widgets/
			app_drawer.dart
			app_scaffold.dart
			app_text_field.dart
			error_banner.dart
			feature_placeholder.dart
			loading_state.dart
			primary_button.dart
			section_card.dart
	models/
		app_user.dart
		chat_message.dart
		list_item.dart
		market_record.dart
	services/
		auth_service.dart
		base_service.dart
		buyer_service.dart
		chat_service.dart
		crop_service.dart
		dashboard_service.dart
		equipment_service.dart
		fertilizer_service.dart
		growing_service.dart
		market_service.dart
		report_service.dart
		resources_service.dart
	views/screens/
		auth/
			login_screen.dart
			register_screen.dart
			forgot_password_screen.dart
			verify_otp_screen.dart
			reset_password_screen.dart
		home/
			landing_screen.dart
			home_shell_screen.dart
			dashboard_screen.dart
		crop/
			crop_suggestion_screen.dart
			start_growing_screen.dart
			disease_detection_screen.dart
		growing/
			growing_activities_screen.dart
			growing_view_screen.dart
		fertilizer/
			fertilizer_recommend_screen.dart
		market/
			market_watch_screen.dart
		buyer/
			buyer_marketplace_screen.dart
			create_listing_screen.dart
			my_listings_screen.dart
			purchase_history_screen.dart
		equipment/
			equipment_marketplace_screen.dart
			equipment_create_listing_screen.dart
			equipment_list_form_screen.dart
			equipment_my_listings_screen.dart
			equipment_rental_history_screen.dart
		resources/
			regional_calendar_screen.dart
		chat/
			chat_assistant_screen.dart
		reports/
			reports_screen.dart
		static/
			about_screen.dart
			features_screen.dart
```

## Screen Coverage (Web to Flutter)

Converted web pages/screens include:

- `index.html` -> `LandingScreen`
- `login.html`, `register.html`, `forgot_password.html`, `verify_otp.html`, `reset_password.html`
- `dashboard.html`
- `crop_suggestion.html`, `start_growing.html`, `disease_detection.html`
- `growing_view.html` + activities view
- `fertilizer_recommend.html`
- `market_watch.html`
- `buyer_marketplace.html`, `create_listing.html`, `my_listings.html`, `purchase_history.html`
- `equipment_marketplace.html`, `equipment_create_listing.html`, `equipment_list_form.html`, `equipment_my_listings.html`, `equipment_rental_history.html`
- `regional_calendar.html`
- `about.html`, `features.html`

## API Integration Notes

- Networking stack uses `Dio` with persisted cookies (session auth support).
- Login/Register use form-post workflows and session cookies.
- OTP, reports, market APIs, chat, resources, and action endpoints are JSON-backed and integrated.
- Some listing/history pages in backend are HTML-template responses only. Flutter screens for those are created and wired for navigation and action APIs, with placeholders indicating where JSON list endpoints can be added.

## Run in VS Code (Windows)

1. Open folder:
	 - `smart_farming_mobile`
2. Ensure Flutter SDK is installed and visible:
	 - `flutter --version`
3. Important for Windows plugin builds:
	 - Enable Developer Mode: run `start ms-settings:developers` and enable it.
4. Install dependencies:
	 - `flutter pub get`
5. Verify environment:
	 - `flutter doctor`
6. Run app on Android device/emulator:
	 - `flutter run`

## Useful Commands

- Analyze code: `flutter analyze`
- Run tests: `flutter test`
- Format: `dart format lib test`

## Backend Base URL

Configured in:

- `lib/core/config/app_config.dart`

Change `baseUrl` there if you deploy a new backend instance.
