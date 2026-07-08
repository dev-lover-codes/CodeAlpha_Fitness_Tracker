-- Create Fitness Enums
CREATE TYPE public.fitness_goal_type AS ENUM ('lose_weight', 'build_muscle', 'maintain', 'endurance');
CREATE TYPE public.exercise_category AS ENUM ('strength', 'cardio', 'flexibility', 'sports');
CREATE TYPE public.muscle_group AS ENUM ('chest', 'back', 'legs', 'shoulders', 'arms', 'core', 'full_body', 'cardio');
CREATE TYPE public.difficulty_level AS ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE public.goal_type AS ENUM ('weight', 'workout_frequency', 'strength_pr', 'custom');
CREATE TYPE public.goal_status AS ENUM ('active', 'completed', 'abandoned');
CREATE TYPE public.meal_type AS ENUM ('breakfast', 'lunch', 'dinner', 'snack');

-- 1. PROFILES TABLE
CREATE TABLE public.profiles (
    id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
    full_name text,
    username text UNIQUE,
    avatar_url text,
    height_cm numeric(5, 2),
    weight_kg numeric(5, 2),
    date_of_birth date,
    gender text,
    fitness_goal public.fitness_goal_type,
    activity_level text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- 2. EXERCISES TABLE
CREATE TABLE public.exercises (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    category public.exercise_category NOT NULL,
    muscle_group public.muscle_group NOT NULL,
    equipment text,
    difficulty public.difficulty_level NOT NULL,
    instructions text,
    video_url text,
    is_custom boolean DEFAULT false NOT NULL,
    created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- 3. WORKOUTS TABLE
CREATE TABLE public.workouts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name text NOT NULL,
    notes text,
    started_at timestamp with time zone NOT NULL,
    completed_at timestamp with time zone,
    duration_seconds integer,
    total_volume_kg numeric(10, 2) DEFAULT 0.00 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

-- 4. WORKOUT EXERCISES TABLE
CREATE TABLE public.workout_exercises (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_id uuid NOT NULL REFERENCES public.workouts(id) ON DELETE CASCADE,
    exercise_id uuid NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
    order_index integer NOT NULL,
    notes text
);

-- 5. SETS TABLE
CREATE TABLE public.sets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_exercise_id uuid NOT NULL REFERENCES public.workout_exercises(id) ON DELETE CASCADE,
    set_number integer NOT NULL,
    reps integer,
    weight_kg numeric(6, 2),
    duration_seconds integer,
    distance_meters numeric(8, 2),
    rpe integer CHECK (rpe >= 1 AND rpe <= 10),
    is_warmup boolean DEFAULT false NOT NULL,
    completed boolean DEFAULT false NOT NULL
);

-- 6. BODY MEASUREMENTS TABLE
CREATE TABLE public.body_measurements (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    logged_at timestamp with time zone DEFAULT now() NOT NULL,
    weight_kg numeric(5, 2),
    body_fat_percent numeric(4, 2),
    chest_cm numeric(5, 2),
    waist_cm numeric(5, 2),
    hips_cm numeric(5, 2),
    arms_cm numeric(4, 2),
    thighs_cm numeric(5, 2),
    notes text
);

-- 7. PROGRESS PHOTOS TABLE
CREATE TABLE public.progress_photos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    photo_url text NOT NULL,
    logged_at timestamp with time zone DEFAULT now() NOT NULL,
    notes text
);

-- 8. GOALS TABLE
CREATE TABLE public.goals (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    goal_type public.goal_type NOT NULL,
    target_value numeric(8, 2) NOT NULL,
    current_value numeric(8, 2) NOT NULL,
    unit text NOT NULL,
    target_date date,
    status public.goal_status DEFAULT 'active'::public.goal_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

-- 9. NUTRITION LOGS TABLE
CREATE TABLE public.nutrition_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    logged_at timestamp with time zone DEFAULT now() NOT NULL,
    meal_type public.meal_type NOT NULL,
    food_name text NOT NULL,
    calories integer NOT NULL,
    protein_g numeric(5, 1),
    carbs_g numeric(5, 1),
    fat_g numeric(5, 1)
);

-- 10. STREAKS TABLE
CREATE TABLE public.streaks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    current_streak integer DEFAULT 0 NOT NULL,
    longest_streak integer DEFAULT 0 NOT NULL,
    last_workout_date date
);

-- FUNCTIONS AND TRIGGERS

-- Automatically update updated_at timestamps
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS trigger AS $$
BEGIN
  new.updated_at = now();
  RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_profile_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER on_exercise_updated
  BEFORE UPDATE ON public.exercises
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Auto-insert a profile when a new user signs up in auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, username, avatar_url)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', ''),
    COALESCE(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1) || '_' || substr(md5(random()::text), 1, 5)),
    COALESCE(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture', '')
  );
  
  -- Seed an initial streak row for the user
  INSERT INTO public.streaks (user_id, current_streak, longest_streak)
  VALUES (new.id, 0, 0);
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
