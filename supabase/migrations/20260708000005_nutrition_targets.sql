ALTER TABLE public.profiles
ADD COLUMN daily_calorie_target integer,
ADD COLUMN daily_protein_target numeric(5, 1),
ADD COLUMN daily_carbs_target numeric(5, 1),
ADD COLUMN daily_fat_target numeric(5, 1);
