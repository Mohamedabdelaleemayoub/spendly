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

  test('Real End-to-End Diagnostic against Live Supabase Project', () async {
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

    await Supabase.initialize(url: url, publishableKey: anonKey);
    final client = Supabase.instance.client;

    print('\n==================== 1. STORAGE BUCKETS ====================');
    final buckets = await client.storage.listBuckets();
    print('Available Storage Buckets: ${buckets.map((b) => b.name).toList()}');

    print('\n==================== 2. PROFILES TABLE ====================');
    final profiles = await client.from('profiles').select('*').limit(5);
    print('Profiles query returned HTTP 200 with ${profiles.length} records.');

    print('\n==================== 3. CATEGORIES TABLE ====================');
    final categories = await client.from('categories').select('id, name, icon, color').limit(5);
    print('Categories query returned HTTP 200 with ${categories.length} records.');

    print('\n==================== 4. EXPENSES TABLE & JOINS ====================');
    const selectQuery = '''
      *,
      categories:categories!expenses_category_id_fkey(
        id,
        name,
        icon,
        color
      ),
      profiles:profiles!expenses_user_id_fkey(
        id,
        full_name,
        email,
        role
      )
    ''';
    try {
      final expenses = await client.from('expenses').select(selectQuery).limit(5);
      print('Expenses query with explicit FK embeds returned HTTP 200 with ${expenses.length} records.');
    } catch (e) {
      print('ℹ️ expenses join query: $e');
    }
    print('\n==================== 5. ALL EMPLOYEES & BALANCE QUERIES ====================');
    try {
      final profiles = await client.from('profiles').select().order('full_name', ascending: true);
      print('✅ profiles: ${profiles.length} rows');
    } catch (e) {
      print('❌ profiles query failed: $e');
    }

    try {
      final expenses = await client.from('expenses').select('user_id, amount, currency, expense_date');
      print('✅ expenses (with currency): ${expenses.length} rows');
    } catch (e) {
      print('❌ expenses query failed: $e');
    }

    try {
      final advances = await client.from('employee_salary_advances').select('user_id, amount');
      print('✅ employee_salary_advances: ${advances.length} rows');
    } catch (e) {
      print('❌ employee_salary_advances query failed: $e');
    }

    try {
      final allowances = await client.from('employee_allowance_transactions').select('user_id, amount, currency, transaction_date');
      print('✅ employee_allowance_transactions: ${allowances.length} rows');
    } catch (e) {
      print('❌ employee_allowance_transactions query failed: $e');
    }

    try {
      final balanceTx = await client.from('employee_balance_transactions').select('amount, currency, type');
      print('✅ employee_balance_transactions: ${balanceTx.length} rows');
    } catch (e) {
      print('❌ employee_balance_transactions query failed: $e');
    }

    try {
      final rpcAllBalances = await client.rpc('get_all_employee_balances');
      print('✅ RPC get_all_employee_balances: $rpcAllBalances');
    } catch (e) {
      print('❌ RPC get_all_employee_balances failed: $e');
    }

    try {
      final rpcWeekly = await client.rpc('get_weekly_work_budget_summary', params: {
        'p_user_id': '00000000-0000-0000-0000-000000000000',
        'p_start_date': '2026-08-17',
        'p_end_date': '2026-08-23',
      });
      print('✅ RPC get_weekly_work_budget_summary: $rpcWeekly');
    } catch (e) {
      print('❌ RPC get_weekly_work_budget_summary failed: $e');
    }
  });
}
