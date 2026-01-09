import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'config/env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check configuration
  if (!EnvConfig.isConfigured) {
    throw Exception(
        'Please configure your Supabase credentials in lib/config/env_config.dart');
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );

  runApp(const SipZyApp());
}
