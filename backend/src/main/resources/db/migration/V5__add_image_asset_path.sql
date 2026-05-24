-- Add image_asset_path column to vocabulary_words table and populate with image paths

-- Add the column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'vocabulary_words' 
        AND column_name = 'image_asset_path'
    ) THEN
        ALTER TABLE vocabulary_words ADD COLUMN image_asset_path TEXT;
    END IF;
END $$;

-- Update existing vocabulary words with their corresponding image paths
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson01_img01.png' WHERE word_id = 'c1000000-0000-0000-0000-000000000001';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson01_img02.png' WHERE word_id = 'c1000000-0000-0000-0000-000000000002';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson01_img03.png' WHERE word_id = 'c1000000-0000-0000-0000-000000000003';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson01_img04.png' WHERE word_id = 'c1000000-0000-0000-0000-000000000004';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson01_img05.png' WHERE word_id = 'c1000000-0000-0000-0000-000000000005';

UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson02_img01.png' WHERE word_id = 'c2000000-0000-0000-0000-000000000001';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson02_img02.png' WHERE word_id = 'c2000000-0000-0000-0000-000000000002';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson02_img03.png' WHERE word_id = 'c2000000-0000-0000-0000-000000000003';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson02_img04.png' WHERE word_id = 'c2000000-0000-0000-0000-000000000004';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson02_img05.png' WHERE word_id = 'c2000000-0000-0000-0000-000000000005';

UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson03_img01.png' WHERE word_id = 'c3000000-0000-0000-0000-000000000001';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson03_img02.png' WHERE word_id = 'c3000000-0000-0000-0000-000000000002';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson03_img03.png' WHERE word_id = 'c3000000-0000-0000-0000-000000000003';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson03_img04.png' WHERE word_id = 'c3000000-0000-0000-0000-000000000004';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson03_img05.png' WHERE word_id = 'c3000000-0000-0000-0000-000000000005';

UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson04_img01.png' WHERE word_id = 'c4000000-0000-0000-0000-000000000001';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson04_img02.png' WHERE word_id = 'c4000000-0000-0000-0000-000000000002';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson04_img03.png' WHERE word_id = 'c4000000-0000-0000-0000-000000000003';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson04_img04.png' WHERE word_id = 'c4000000-0000-0000-0000-000000000004';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson04_img05.png' WHERE word_id = 'c4000000-0000-0000-0000-000000000005';

UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson05_img01.png' WHERE word_id = 'c5000000-0000-0000-0000-000000000001';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson05_img02.png' WHERE word_id = 'c5000000-0000-0000-0000-000000000002';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson05_img03.png' WHERE word_id = 'c5000000-0000-0000-0000-000000000003';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson05_img04.png' WHERE word_id = 'c5000000-0000-0000-0000-000000000004';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson05_img05.png' WHERE word_id = 'c5000000-0000-0000-0000-000000000005';

UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson06_img01.png' WHERE word_id = 'c1000000-0000-0000-0000-000000000006';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson06_img02.png' WHERE word_id = 'c1000000-0000-0000-0000-000000000007';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson06_img03.png' WHERE word_id = 'c1000000-0000-0000-0000-000000000008';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson06_img04.png' WHERE word_id = 'c1000000-0000-0000-0000-000000000009';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson06_img05.png' WHERE word_id = 'c1000000-0000-0000-0000-000000000010';

UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson07_img01.png' WHERE word_id = 'c2000000-0000-0000-0000-000000000006';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson07_img02.png' WHERE word_id = 'c2000000-0000-0000-0000-000000000007';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson07_img03.png' WHERE word_id = 'c2000000-0000-0000-0000-000000000008';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson07_img04.png' WHERE word_id = 'c2000000-0000-0000-0000-000000000009';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson07_img05.png' WHERE word_id = 'c2000000-0000-0000-0000-000000000010';

UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson08_img01.png' WHERE word_id = 'c3000000-0000-0000-0000-000000000006';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson08_img02.png' WHERE word_id = 'c3000000-0000-0000-0000-000000000007';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson08_img03.png' WHERE word_id = 'c3000000-0000-0000-0000-000000000008';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson08_img04.png' WHERE word_id = 'c3000000-0000-0000-0000-000000000009';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson08_img05.png' WHERE word_id = 'c3000000-0000-0000-0000-000000000010';

UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson09_img01.png' WHERE word_id = 'c4000000-0000-0000-0000-000000000006';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson09_img02.png' WHERE word_id = 'c4000000-0000-0000-0000-000000000007';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson09_img03.png' WHERE word_id = 'c4000000-0000-0000-0000-000000000008';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson09_img04.png' WHERE word_id = 'c4000000-0000-0000-0000-000000000009';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson09_img05.png' WHERE word_id = 'c4000000-0000-0000-0000-000000000010';

UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson10_img01.png' WHERE word_id = 'c5000000-0000-0000-0000-000000000006';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson10_img02.png' WHERE word_id = 'c5000000-0000-0000-0000-000000000007';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson10_img03.png' WHERE word_id = 'c5000000-0000-0000-0000-000000000008';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson10_img04.png' WHERE word_id = 'c5000000-0000-0000-0000-000000000009';
UPDATE vocabulary_words SET image_asset_path = 'assets/images/lesson10_img05.png' WHERE word_id = 'c5000000-0000-0000-0000-000000000010';
