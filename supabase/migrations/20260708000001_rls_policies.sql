-- Enable Row Level Security (RLS) on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.body_measurements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.progress_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nutrition_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.streaks ENABLE ROW LEVEL SECURITY;

-- 1. PROFILES POLICIES
CREATE POLICY "profiles_select_policy" ON public.profiles
    FOR SELECT TO authenticated USING (auth.uid() = id);

CREATE POLICY "profiles_insert_policy" ON public.profiles
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_policy" ON public.profiles
    FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_delete_policy" ON public.profiles
    FOR DELETE TO authenticated USING (auth.uid() = id);

-- 2. EXERCISES POLICIES
-- Everyone can read exercises (both default library and custom ones)
CREATE POLICY "exercises_select_policy" ON public.exercises
    FOR SELECT TO authenticated USING (true);

-- Users can only insert/update/delete their own custom exercises
CREATE POLICY "exercises_insert_policy" ON public.exercises
    FOR INSERT TO authenticated WITH CHECK (is_custom = true AND created_by = auth.uid());

CREATE POLICY "exercises_update_policy" ON public.exercises
    FOR UPDATE TO authenticated USING (is_custom = true AND created_by = auth.uid()) WITH CHECK (is_custom = true AND created_by = auth.uid());

CREATE POLICY "exercises_delete_policy" ON public.exercises
    FOR DELETE TO authenticated USING (is_custom = true AND created_by = auth.uid());

-- 3. WORKOUTS POLICIES
CREATE POLICY "workouts_all_policy" ON public.workouts
    FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 4. WORKOUT EXERCISES POLICIES
-- Checks ownership through the parent workout_id
CREATE POLICY "workout_exercises_all_policy" ON public.workout_exercises
    FOR ALL TO authenticated 
    USING (
        EXISTS (
            SELECT 1 FROM public.workouts w 
            WHERE w.id = workout_exercises.workout_id AND w.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.workouts w 
            WHERE w.id = workout_exercises.workout_id AND w.user_id = auth.uid()
        )
    );

-- 5. SETS POLICIES
-- Checks ownership through workout_exercise_id -> workout_id -> user_id
CREATE POLICY "sets_all_policy" ON public.sets
    FOR ALL TO authenticated 
    USING (
        EXISTS (
            SELECT 1 FROM public.workout_exercises we
            JOIN public.workouts w ON w.id = we.workout_id
            WHERE we.id = sets.workout_exercise_id AND w.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.workout_exercises we
            JOIN public.workouts w ON w.id = we.workout_id
            WHERE we.id = sets.workout_exercise_id AND w.user_id = auth.uid()
        )
    );

-- 6. BODY MEASUREMENTS POLICIES
CREATE POLICY "body_measurements_all_policy" ON public.body_measurements
    FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 7. PROGRESS PHOTOS POLICIES
CREATE POLICY "progress_photos_all_policy" ON public.progress_photos
    FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 8. GOALS POLICIES
CREATE POLICY "goals_all_policy" ON public.goals
    FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 9. NUTRITION LOGS POLICIES
CREATE POLICY "nutrition_logs_all_policy" ON public.nutrition_logs
    FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 10. STREAKS POLICIES
CREATE POLICY "streaks_all_policy" ON public.streaks
    FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
