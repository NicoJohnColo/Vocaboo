-- V43: Randomize existing learner avatars across all 9 profile options
UPDATE learners
SET avatar = (ARRAY['prof1.jpg', 'prof2.jpg', 'prof3.jpg', 'prof4.jpg', 'prof5.jpg', 'prof6.jpg', 'prof7.jpg', 'prof8.jpg', 'prof9.jpg'])[
    (abs(hashtext(learner_id::text)) % 9) + 1
]
WHERE avatar IS NULL OR avatar = 'prof1.jpg';
