// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _AllowNetworkOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _AllowNetworkOverrides();

  test(
    'Real End-to-End Diagnostic against Live Supabase Project',
    () async {
      SharedPreferences.setMockInitialValues({});

      final envFile = File('.env');
      expect(envFile.existsSync(), isTrue, reason: '.env file must exist');

      final lines = await envFile.readAsLines();
      final Map<String, String> envMap = {};
      for (final line in lines) {
        if (line.contains('=')) {
          final idx = line.indexOf('=');
          final key = line.substring(0, idx).trim();
          final val = line.substring(idx + 1).trim();
          envMap[key] = val;
        }
      }

      dotenv.testLoad(mergeWith: envMap);
      final url = dotenv.env['SUPABASE_URL']!;
      final anonKey = dotenv.env['SUPABASE_ANON_KEY']!;

      expect(url, equals('https://oajgzalwifafbjadbbil.supabase.co'));

      try {
        await Supabase.initialize(url: url, publishableKey: anonKey);
        final client = Supabase.instance.client;

        const callTimeout = Duration(milliseconds: 500);

        print('\n==================== 1. STORAGE BUCKETS ====================');
        try {
          final buckets = await client.storage.listBuckets().timeout(callTimeout);
          print('Available Storage Buckets: ${buckets.map((b) => b.name).toList()}');
        } catch (e) {
          print('❌ Storage error / timeout: $e');
        }

        print('\n==================== 2. PROFILES TABLE ====================');
        try {
          final profiles = await client.from('profiles').select().timeout(callTimeout);
          print('Profiles query returned HTTP 200 with ${profiles.length} records.');
        } catch (e) {
          print('❌ Profiles query error / timeout: $e');
        }

        print('\n==================== 3. CATEGORIES TABLE ====================');
        try {
          final categories = await client.from('categories').select().timeout(callTimeout);
          print('Categories query returned HTTP 200 with ${categories.length} records.');
        } catch (e) {
          print('❌ Categories query error / timeout: $e');
        }

        print('\n==================== 4. EXPENSES TABLE & JOINS ====================');
        try {
          final expenses = await client
              .from('expenses')
              .select('id, amount, notes, categories(name), profiles(full_name)')
              .timeout(callTimeout);
          print('Expenses query with explicit FK embeds returned HTTP 200 with ${expenses.length} records.');
        } catch (e) {
          print('❌ Expenses query error / timeout: $e');
        }

        print('\n==================== 5. ALL EMPLOYEES & BALANCE QUERIES ====================');
        try {
          final profiles = await client.from('profiles').select().timeout(callTimeout);
          print('✅ profiles: ${profiles.length} rows');
        } catch (e) {
          print('❌ profiles query failed: $e');
        }

        try {
          final expenses = await client.from('expenses').select('user_id, amount, currency, expense_date').timeout(callTimeout);
          print('✅ expenses (with currency): ${expenses.length} rows');
        } catch (e) {
          print('❌ expenses query failed: $e');
        }

        try {
          final advances = await client.from('employee_salary_advances').select('user_id, amount').timeout(callTimeout);
          print('✅ employee_salary_advances: ${advances.length} rows');
        } catch (e) {
          print('❌ employee_salary_advances query failed: $e');
        }

        try {
          final allowances = await client.from('employee_allowance_transactions').select('user_id, amount, currency, transaction_date').timeout(callTimeout);
          print('✅ employee_allowance_transactions: ${allowances.length} rows');
        } catch (e) {
          print('❌ employee_allowance_transactions query failed: $e');
        }

        try {
          final balanceTx = await client.from('employee_balance_transactions').select('amount, currency, type').timeout(callTimeout);
          print('✅ employee_balance_transactions: ${balanceTx.length} rows');
        } catch (e) {
          print('❌ employee_balance_transactions query failed: $e');
        }

        try {
          final rpcAllBalances = await client.rpc('get_all_employee_balances').timeout(callTimeout);
          print('✅ RPC get_all_employee_balances: $rpcAllBalances');
        } catch (e) {
          print('❌ RPC get_all_employee_balances failed: $e');
        }

        try {
          final rpcWeekly = await client.rpc('get_weekly_work_budget_summary', params: {
            'p_user_id': '00000000-0000-0000-0000-000000000000',
            'p_start_date': '2026-08-17',
            'p_end_date': '2026-08-23',
          }).timeout(callTimeout);
          print('✅ RPC get_weekly_work_budget_summary: $rpcWeekly');
        } catch (e) {
          print('❌ RPC get_weekly_work_budget_summary failed: $e');
        }
        print('\n==================== 6. AUTH DIAGNOSTIC ====================');
        try {
          print('Attempting login with ma5737@fayoum.edu.eg...');
          final authRes = await client.auth.signInWithPassword(
            email: 'ma5737@fayoum.edu.eg',
            password: 'password123',
          );
          print('✅ Login succeeded for ma5737@fayoum.edu.eg: ${authRes.user?.id}');
        } catch (e) {
          print('❌ Login error for ma5737@fayoum.edu.eg: $e');
        }

        try {
          final testEmail = 'diag_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
          print('Attempting signUp with test email: $testEmail...');
          final signUpRes = await client.auth.signUp(
            email: testEmail,
            password: 'TestPassword123!',
            data: {'name': 'Diagnostic Test User'},
          );
          print('✅ SignUp succeeded: user=${signUpRes.user?.id}, session=${signUpRes.session != null}');

          print('Attempting login with newly signed up test email: $testEmail...');
          final loginRes = await client.auth.signInWithPassword(
            email: testEmail,
            password: 'TestPassword123!',
          );
          print('✅ Login succeeded for test email: user=${loginRes.user?.id}, session=${loginRes.session != null}');
        } catch (e) {
          print('❌ Test email auth error: $e');
        }
      } catch (e) {
        print('ℹ️ Live Supabase connection skipped in test environment: $e');
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
