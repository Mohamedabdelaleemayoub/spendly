-- ==============================================================================
-- Migration: 014_allow_negative_balance_expenses.sql
-- Description: Remove restrictive balance enforcement triggers on expenses to
--              allow employees and admins to create expenses even when available
--              balance is insufficient (yielding a negative available balance).
-- ==============================================================================

-- 1. Safely drop balance-restricting triggers on public.expenses
DROP TRIGGER IF EXISTS on_enforce_employee_expense_balance ON public.expenses;
DROP TRIGGER IF EXISTS tr_enforce_expense_balance ON public.expenses;

-- 2. Safely drop obsolete balance enforcement functions
DROP FUNCTION IF EXISTS public.enforce_employee_expense_balance();
DROP FUNCTION IF EXISTS public.enforce_expense_balance_limit();

-- 3. Ensure balance calculation functions remain accessible and correctly return negative values
-- (get_employee_available_balance, get_employee_balance_summary, and get_all_employee_balances
-- compute available_balance = total_received - total_spent without clamping to 0).
GRANT EXECUTE ON FUNCTION public.get_employee_available_balance(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_employee_balance_summary(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_all_employee_balances() TO authenticated;

-- 4. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
