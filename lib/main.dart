import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'config/env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Supabase with error handling
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );

    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Supabase initialization error: $e');
    // Continue anyway - app can still work with API calls
  }

  runApp(const SipZyApp());
}
