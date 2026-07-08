-- Create user_favorites table linking profiles and exercises
CREATE TABLE public.user_favorites (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    exercise_id uuid NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    UNIQUE(user_id, exercise_id)
);

-- Enable RLS
ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only select, insert, and delete their own favorites
CREATE POLICY "Users can manage their own favorites"
ON public.user_favorites
FOR ALL
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
