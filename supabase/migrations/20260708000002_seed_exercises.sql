-- Seed default exercise database library (is_custom = false)
INSERT INTO public.exercises (name, category, muscle_group, equipment, difficulty, instructions, video_url, is_custom, created_by)
VALUES
-- Strength - Chest
('Bench Press (Barbell)', 'strength'::public.exercise_category, 'chest'::public.muscle_group, 'Barbell, Bench', 'intermediate'::public.difficulty_level, 'Lie on a flat bench, grip the barbell slightly wider than shoulder-width, lower the bar to your chest, and push it back up.', NULL, false, NULL),
('Incline Bench Press (Barbell)', 'strength'::public.exercise_category, 'chest'::public.muscle_group, 'Barbell, Incline Bench', 'intermediate'::public.difficulty_level, 'Lie on an incline bench, grip the barbell, lower it to your upper chest, and press upwards.', NULL, false, NULL),
('Dumbbell Bench Press', 'strength'::public.exercise_category, 'chest'::public.muscle_group, 'Dumbbells, Bench', 'intermediate'::public.difficulty_level, 'Lie on a flat bench holding dumbbells at chest level, press them upwards until arms are extended, and lower back down.', NULL, false, NULL),
('Chest Fly (Dumbbell)', 'strength'::public.exercise_category, 'chest'::public.muscle_group, 'Dumbbells, Bench', 'beginner'::public.difficulty_level, 'Lie on a flat bench holding dumbbells above chest, lower arms out in a wide arc, then squeeze chest to raise back up.', NULL, false, NULL),
('Push-up', 'strength'::public.exercise_category, 'chest'::public.muscle_group, 'Bodyweight', 'beginner'::public.difficulty_level, 'Place hands shoulder-width apart, keep body in a straight line, lower chest to floor, and push back up.', NULL, false, NULL),

-- Strength - Back
('Deadlift (Barbell)', 'strength'::public.exercise_category, 'back'::public.muscle_group, 'Barbell', 'advanced'::public.difficulty_level, 'Stand with feet hip-width, bend at hips and knees, grip barbell, keep back flat, and stand up pushing hips forward.', NULL, false, NULL),
('Pull-up', 'strength'::public.exercise_category, 'back'::public.muscle_group, 'Pull-up Bar', 'intermediate'::public.difficulty_level, 'Hang from a bar with palms facing away, pull chest up to the bar, and slowly lower yourself down.', NULL, false, NULL),
('Bent Over Row (Barbell)', 'strength'::public.exercise_category, 'back'::public.muscle_group, 'Barbell', 'intermediate'::public.difficulty_level, 'Hinge at hips, keep back straight, pull the barbell to your lower chest, and extend arms fully.', NULL, false, NULL),
('Lat Pulldown (Cable)', 'strength'::public.exercise_category, 'back'::public.muscle_group, 'Cable Machine', 'beginner'::public.difficulty_level, 'Sit at a pulldown machine, pull the bar down to your upper chest, squeezing shoulder blades, and return slowly.', NULL, false, NULL),
('Single Arm Row (Dumbbell)', 'strength'::public.exercise_category, 'back'::public.muscle_group, 'Dumbbell, Bench', 'beginner'::public.difficulty_level, 'Place one knee and hand on a bench, pull a dumbbell up to your hip with the opposite arm, then lower.', NULL, false, NULL),

-- Strength - Legs
('Back Squat (Barbell)', 'strength'::public.exercise_category, 'legs'::public.muscle_group, 'Barbell, Squat Rack', 'intermediate'::public.difficulty_level, 'Place barbell on upper back, feet shoulder-width, lower hips back and down until thighs are parallel, and stand back up.', NULL, false, NULL),
('Front Squat (Barbell)', 'strength'::public.exercise_category, 'legs'::public.muscle_group, 'Barbell, Squat Rack', 'advanced'::public.difficulty_level, 'Rest barbell on front of shoulders, cross arms or grip bar, lower hips, keeping torso upright, and stand up.', NULL, false, NULL),
('Romanian Deadlift (Barbell)', 'strength'::public.exercise_category, 'legs'::public.muscle_group, 'Barbell', 'intermediate'::public.difficulty_level, 'Stand straight, hinge at hips while keeping legs relatively straight, lower barbell along legs, and squeeze hamstrings to stand.', NULL, false, NULL),
('Leg Press', 'strength'::public.exercise_category, 'legs'::public.muscle_group, 'Leg Press Machine', 'beginner'::public.difficulty_level, 'Sit in machine, place feet on sled, release safety, lower weight towards chest, and push sled away.', NULL, false, NULL),
('Lunge (Dumbbell)', 'strength'::public.exercise_category, 'legs'::public.muscle_group, 'Dumbbells', 'beginner'::public.difficulty_level, 'Hold dumbbells, step forward with one leg, lower hips until back knee is near floor, and push back to start.', NULL, false, NULL),
('Calf Raise (Standing)', 'strength'::public.exercise_category, 'legs'::public.muscle_group, 'Bodyweight or Barbell', 'beginner'::public.difficulty_level, 'Raise heels off floor, standing on balls of feet, squeeze calves, and lower heels back down.', NULL, false, NULL),

-- Strength - Shoulders
('Overhead Press (Barbell)', 'strength'::public.exercise_category, 'shoulders'::public.muscle_group, 'Barbell', 'intermediate'::public.difficulty_level, 'Stand with barbell at collarbone, press it directly overhead until arms lock, and lower to collarbone.', NULL, false, NULL),
('Lateral Raise (Dumbbell)', 'strength'::public.exercise_category, 'shoulders'::public.muscle_group, 'Dumbbells', 'beginner'::public.difficulty_level, 'Stand with dumbbells at sides, raise arms outwards to shoulder height with elbows slightly bent, and lower.', NULL, false, NULL),
('Arnold Press (Dumbbell)', 'strength'::public.exercise_category, 'shoulders'::public.muscle_group, 'Dumbbells', 'intermediate'::public.difficulty_level, 'Sit holding dumbbells at chin height with palms facing you, press overhead while rotating palms to face away.', NULL, false, NULL),
('Front Raise (Dumbbell)', 'strength'::public.exercise_category, 'shoulders'::public.muscle_group, 'Dumbbells', 'beginner'::public.difficulty_level, 'Stand holding dumbbells, raise one or both dumbbells straight forward to shoulder height, and lower.', NULL, false, NULL),

-- Strength - Arms
('Bicep Curl (Dumbbell)', 'strength'::public.exercise_category, 'arms'::public.muscle_group, 'Dumbbells', 'beginner'::public.difficulty_level, 'Hold dumbbells with palms facing up, curl them up towards shoulders, squeezing biceps, and lower slowly.', NULL, false, NULL),
('Hammer Curl (Dumbbell)', 'strength'::public.exercise_category, 'arms'::public.muscle_group, 'Dumbbells', 'beginner'::public.difficulty_level, 'Hold dumbbells with palms facing each other (neutral grip), curl towards shoulders, and lower.', NULL, false, NULL),
('Tricep Pushdown (Cable)', 'strength'::public.exercise_category, 'arms'::public.muscle_group, 'Cable Machine', 'beginner'::public.difficulty_level, 'Hold cable rope or bar at chest level, push downwards until arms are fully extended, keeping elbows close to body.', NULL, false, NULL),
('Skull Crusher (EZ Bar)', 'strength'::public.exercise_category, 'arms'::public.muscle_group, 'EZ Bar, Bench', 'intermediate'::public.difficulty_level, 'Lie on bench holding EZ bar above face, bend elbows to lower bar towards forehead, and push back up.', NULL, false, NULL),

-- Strength - Core
('Plank', 'strength'::public.exercise_category, 'core'::public.muscle_group, 'Bodyweight', 'beginner'::public.difficulty_level, 'Hold body in straight line supported by forearms and toes, contract core, and hold for time.', NULL, false, NULL),
('Crunch', 'strength'::public.exercise_category, 'core'::public.muscle_group, 'Bodyweight', 'beginner'::public.difficulty_level, 'Lie on back, knees bent, hands behind head, raise shoulders slightly off floor contracting abs, and lower.', NULL, false, NULL),
('Russian Twist', 'strength'::public.exercise_category, 'core'::public.muscle_group, 'Bodyweight or Medicine Ball', 'beginner'::public.difficulty_level, 'Sit with knees bent, feet slightly off floor, twist torso from side to side, touching floor beside hips.', NULL, false, NULL),
('Hanging Leg Raise', 'strength'::public.exercise_category, 'core'::public.muscle_group, 'Pull-up Bar', 'advanced'::public.difficulty_level, 'Hang from bar, keep legs straight, lift them up to 90 degrees or to the bar, and lower slowly.', NULL, false, NULL),
('Ab Wheel Rollout', 'strength'::public.exercise_category, 'core'::public.muscle_group, 'Ab Wheel', 'advanced'::public.difficulty_level, 'Kneel holding ab wheel, roll forward slowly extending arms and torso, contract core to pull back to start.', NULL, false, NULL),

-- Cardio
('Running (Outdoor)', 'cardio'::public.exercise_category, 'cardio'::public.muscle_group, 'Running Shoes', 'beginner'::public.difficulty_level, 'Jog or run at a steady pace outdoors for time or distance.', NULL, false, NULL),
('Treadmill Run', 'cardio'::public.exercise_category, 'cardio'::public.muscle_group, 'Treadmill', 'beginner'::public.difficulty_level, 'Run on a treadmill at a set speed and incline for time or distance.', NULL, false, NULL),
('Cycling (Outdoor)', 'cardio'::public.exercise_category, 'cardio'::public.muscle_group, 'Bicycle', 'beginner'::public.difficulty_level, 'Ride a bicycle outdoors on roads or trails for fitness.', NULL, false, NULL),
('Stationary Bike', 'cardio'::public.exercise_category, 'cardio'::public.muscle_group, 'Stationary Bike', 'beginner'::public.difficulty_level, 'Pedal on a stationary exercise bike with varying resistance.', NULL, false, NULL),
('Swimming', 'cardio'::public.exercise_category, 'cardio'::public.muscle_group, 'Pool', 'beginner'::public.difficulty_level, 'Swim laps in a pool using freestyle, breaststroke, or other strokes.', NULL, false, NULL),
('Rowing Machine', 'cardio'::public.exercise_category, 'cardio'::public.muscle_group, 'Rowing Machine', 'beginner'::public.difficulty_level, 'Sit at rowing machine, push off with legs, lean back slightly, and pull handle to abdomen.', NULL, false, NULL),
('Jump Rope', 'cardio'::public.exercise_category, 'cardio'::public.muscle_group, 'Jump Rope', 'beginner'::public.difficulty_level, 'Jump continuously over a spinning rope for coordination and cardiovascular endurance.', NULL, false, NULL),
('Elliptical', 'cardio'::public.exercise_category, 'cardio'::public.muscle_group, 'Elliptical Trainer', 'beginner'::public.difficulty_level, 'Exercise on an elliptical machine with moving foot pedals and hand levers.', NULL, false, NULL),

-- Flexibility
('Yoga (Vinyasa Flow)', 'flexibility'::public.exercise_category, 'full_body'::public.muscle_group, 'Yoga Mat', 'beginner'::public.difficulty_level, 'Perform a sequence of fluid yoga poses synchronized with breathing.', NULL, false, NULL),
('Hamstring Stretch', 'flexibility'::public.exercise_category, 'legs'::public.muscle_group, 'Bodyweight', 'beginner'::public.difficulty_level, 'Sit or stand and reach towards toes with straight legs to stretch the hamstrings.', NULL, false, NULL),
('Child''s Pose', 'flexibility'::public.exercise_category, 'back'::public.muscle_group, 'Bodyweight', 'beginner'::public.difficulty_level, 'Kneel, sit back on heels, reach arms forward on floor, and lower forehead to stretch back and shoulders.', NULL, false, NULL),
('Foam Rolling (Full Body)', 'flexibility'::public.exercise_category, 'full_body'::public.muscle_group, 'Foam Roller', 'beginner'::public.difficulty_level, 'Roll major muscle groups slowly over a foam roller to release muscle tension.', NULL, false, NULL);
