-- Lets a signed-in user delete their own account, login included.
-- Deleting from auth.users cascades to profiles and everything below it.
CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not signed in';
  END IF;
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;

REVOKE ALL ON FUNCTION public.delete_my_account() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.delete_my_account() TO authenticated;

-- Custom exercises were readable by every user. Limit them to their owner.
DROP POLICY IF EXISTS "exercises_select_policy" ON public.exercises;
CREATE POLICY "exercises_select_policy" ON public.exercises
    FOR SELECT TO authenticated USING (is_custom = false OR created_by = auth.uid());
