
class LocalizationService {
  static const Map<String, Map<String, String>> _translations = {
    'CEBUANO_TO_ENGLISH': {
      // Welcome Screen
      'get_started': 'SUGDI',
      'already_have_account': 'NAA NAKOY AKAWNT',
      'welcome_subtitle': 'Pagkat-on og Iningles pinaagi sa Sinugboanon',
      
      // Profile Setup Screen
      'step_1_of_3': 'ANG-ANG 1 SA 3',
      'profile_title': 'Isulti kanamo ang bahin sa imong kaugalingon!',
      'profile_subtitle': 'Isulod ang imong mga detalye aron mahimo ang imong Vocaboo profile.',
      'name_prompt': 'UNSA IMONG NGALAN?',
      'name_hint': 'Isulod ang ngalan',
      'age_prompt': 'PILA IMONG EDAD?',
      'age_hint': 'Isulod ang edad (9-12)',
      'next': 'SUNOD',

      // PIN Setup Screen
      'step_2_of_3': 'ANG-ANG 2 SA 3',
      'pin_title': 'Paghimo og imong PIN',
      'pin_subtitle': 'Paghimo og imong sigurado nga 4-digit PIN aron maprotektahan ang imong pag-uswag.',
      'pin_prompt': 'HIMOA IMONG PIN',
      'confirm_pin_prompt': 'KUMPIRMAHA IMONG PIN',

      // Language Preference Screen
      'step_3_of_3': 'ANG-ANG 3 SA 3',
      'language_title': 'Pilia ang imong lengguwahe',
      'language_subtitle': 'Pilia ang imong gipalabi nga lengguwahe sa hubad para sa mga buton ug menu sa app.',

      // Success Screen
      'profile_success': 'Malamposong Nahimo\nang Profile!',
      'success_subtitle': 'Mahimo na nimo gamiton ang imong Ngalan ug 4-digit PIN sa pag-log in sa sunod nga higayon. Paglingaw sa pagkat-on!',
      'copy_id': 'KOPYAHA ANG NGALAN',
      'start_learning': 'SUGDI ANG PAGKAT-ON',

      // Login Screen
      'welcome_back': 'Malipayong Pagbalik!',
      'login_subtitle': 'Log in gamit ang imong Ngalan ug PIN.',
      'learner_id': 'NGALAN',
      'pin_4_digit': '4-DIGIT PIN',
      'log_in': 'LOG IN',

      // Home Screen
      'app_title': 'Vocaboo',
      'hello': 'Kumusta',
      'your_categories': 'Imong mga Kategoriya',
      'dashboard': 'Dashboard',
      'logout': 'Gawas',
      'sandbox_mode': 'Sandbox Mode',
      'sandbox_desc': 'Pag-practice og mga custom nga pulong ug topiko',
      
      // Dashboard Metrics
      'lessons_completed_metric': 'Mga Leksyon Nahuman',
      'avg_mastery_metric': 'Average nga Mastery',
      'pronunciation_correct_metric': 'Sakto nga Paglitok',
      'cumulative_reviews_completed': 'Cumulative Reviews Nahuman',
      'view_full_progress': 'Tan-awa ang Full Progress',
      'view_full_progress_sub': 'Tan-awa ang imong detalyado nga stats',
      'words_need_help_title': 'Mga Pulong nga Bansayon',
      'words_need_help_subtitle': 'Pabaskoga ang imong bokabularyo sa dali nga pagbansay',
      'words_to_practice_title': 'Mga Pulong nga Bansayon',
      'practice_together_title': 'Magbansay Kita Karon! 🌟',
      'practice_together_sub': 'Pipila ka pulong nga atong palambuon karon. Maayo kaayo ang imong pag-uswag!',
      'todays_picks': 'Gipili Karon',
      'all_words': 'Tanan Pulong',
      'in_practice': 'Gibansay ✨',
      'you_got_this': 'Nakuha na nimo! 🌟',
      'practice_btn': 'Bansaya',
      'all_caught_up_title': 'Nahuman na ang Tanan! 🌟',
      'all_caught_up_desc': 'Walay pulong nga naghulat sa pagbansay karon. Maayong trabaho!',
      'past_cumulative_sessions': 'Mga Past Cumulative Sessions',
      'no_cumulative_sessions': 'Wala pay cumulative sessions',
      'recent_sandbox_sessions': 'Mga Recent Sandbox Sessions',
      'no_sandbox_sessions': 'Wala pay sandbox sessions',
      'badge_perfect_gold': 'PERFECT GOLD',
      'badge_gold': 'GOLD',
      'badge_silver': 'SILVER',
      'badge_bronze': 'BRONZE',
      'badge_perfect_gold_sub': 'Hingpit — ang tanan nga pulong na-master nga walay sayop!',
      'badge_gold_sub': 'Maayo kaayo — labing daghan 2 ka sayop sa tanang pulong.',
      'badge_silver_sub': 'Maayong trabaho — padayon sa pag-practice aron maka-Gold!',
      'badge_bronze_sub': 'Nahuman nimo ang leksyon — padayon sa pagkat-on!',
      'lesson_badges': 'Mga Badge sa Leksyon',
      'lesson_badge': 'BADGE SA LEKSYON',
      'word_breakdown': 'Breakdown sa mga Pulong',
      
      // Settings
      'settings': 'MGA SETTINGS',

      // Lesson Path Screen
      'lessons': 'Mga Leksyon',
      'words_count': 'mga pulong',
      'score': 'Puntos',

      // Diagnostic Screen
      'diagnostic_check': 'Pagsusi sa Diagnostic',
      'card_indicator': 'KARD {} SA {}',
      'know_word_prompt': 'Kaila ka ba niini nga pulong?',
      'yes_know': 'OO, KAILA KO NIINI',
      'no_dont_know': 'DILI, WALA KO KAILA NIINI',
      'saving_results': 'Galuwas sa mga resulta...',

      // Diagnostic Summary Screen
      'diagnostic_summary': 'Summary sa Diagnostic',
      'diagnostic_complete': 'Malamposon ang Diagnostic!',
      'know_ratio': 'Kaila ka og {} sa {} ka mga pulong.',
      'i_know': 'KAILA KO ({})',
      'to_learn': 'KAT-ONANAN ({})',
      'start_module_1': 'SUGDI ANG MODYUL 1',

      // Vocabulary Intro Screen
      'learning_progress': 'Nagkat-on: {} sa {}',
      'cebuano_meaning': 'KAHULOGAN SA SINUGBOANON',
      'english_example': 'EKSAMPUL SA ININGLES',
      'cebuano_translation': 'HUBAD SA SINUGBOANON',
      'how_to_pronounce': 'UNSAON PAGLITOK',
      'mic_prompt_idle': 'I-tap ang mikropono ug isulti ang pulong.',
      'mic_prompt_recording': 'Naminaw... Isulti na!',
      'tap_to_stop': 'I-TAP ARON MOHUNONG',
      'evaluating': 'Gatimbang-timbang sa imong tingog...',
      'pronunciation_excellent': 'Nindot kaayo nga pagkalitok!',
      'pronunciation_try_again': 'Sulayan nato pag-usab!',
      'target_word': 'Target nga Pulong',
      'you_said': 'Imong Gisulti',
      'try_again': 'SULAYI PAG-USAB',
      'got_it': 'NAKUHA NAKO',
      'practice_pronunciation': 'PRACTICE PAGLITOK',
      'continue': 'PADAYON',
      
      // Guides
      'word_guide': 'Giya sa Pulong',
      'sentence_guide': 'Giya sa Pahayag',
      'cumulative_review': 'Cumulative Review',

      // Sentence Building Screen (Module 3)
      'prompt_sentence_select': 'Pilia ang husto nga pulong sa blangko.',
      'instruction_sentence_select': 'Pilia ang pulong nga nagpuno sa blangko.',
      'prompt_sentence_build': 'Han-aya ang mga pulong aron maporma ang pahayag.',
      'instruction_sentence_drag': 'I-tap o i-drag ang mga pulong aron maporma ang pahayag.',
      'prompt_sentence_type': 'I-type ang nawala nga pulong sa blangko.',
      'instruction_sentence_type': 'I-type ang husto nga pulong.',
      'prompt_sentence_review': 'Rebyuha kining pahayag aron mas mahinumdoman.',
      'lesson_context_title': 'Konteksto sa Leksyon',
      'lesson_context_desc': 'Basaha ang istorya aron masabtan ang konteksto sa mga pulong.',
      'time_remaining': 'Nabilin nga Oras',
      'feedback_correct': 'Husto! Maayong trabaho!',
      'feedback_incorrect': 'Sayop! Sulayi pag-usab.',

      // Round One Completed Screen
      'lesson_completed': 'Nahuman ang Leksyon!',
      'round_completed_subtitle': 'Maayong trabaho! Nahuman nimo ang Modyul 1: Pasiuna sa Bokabularyo.',
      'introduced': 'NAPAILA',
      'diagnostic_known': 'DIAGNOSTIC NAKASABTAN',
      'back_to_path': 'BALIK SA LEKSYON',
      'back_to_dashboard': 'BALIK SA DASHBOARD',
      'practice_more': 'PRACTICE PA (MODYUL 2)',

      // Lesson Score Screen
      'all_words_mastered_msg': 'Nahanas ang tanang mga pulong! Maayong trabaho!',
      'keep_practising_msg': 'Padayon sa pag-practice aron mas mahanas!',
      'bonus': 'Bonus',
      'words_mastered': 'Mga Pulong nga Nahanas',
      'still_needs_practice': 'Nanginahanglan pa og Practice',

      // Leaderboard
      'this_week': 'Kini nga Semana',
      'all_time': 'Tanan nga Panahon',
      'leaderboard_title': 'Leaderboard',
      'no_leaderboard_data': 'Wala pay leaderboard data.',

      // Settings Screen
      'edit_profile': 'USBA ANG PROFILE',
      'display_name': 'NGALAN',
      'age': 'EDAD',
      'change_pin': 'USBA ANG PIN',
      'current_pin': 'KASAMTANGANG PIN',
      'new_pin': 'BAG-ONG PIN',
      'confirm_new_pin': 'KUMPIRMAHA ANG BAG-ONG PIN',
      'theme_mode': 'HITSURA SA APP',
      'theme_light': 'HAYAG',
      'theme_dark': 'NGITNGIT',
      'notifications': 'MGA ABISO',
      'account_section': 'AKAWNT',
      'learning_section': 'PAGKAT-ON',
      'apply_immediately': 'I-apply Dayon ang Mastered Words',
      'apply_immediately_desc': 'I-apply dayon imbis nga i-batch',
      'progress_summary': 'SUMMARY SA PAUGMAD',
      'progress_summary_desc': 'Tan-awa ang stats, badges, ug history',
      'sandbox_mode_desc': 'Pag-practice og mga custom nga pulong ug topiko',
      'app_preferences_section': 'KAGUSTUHAN SA APP',
      'language_preference': 'Gipalabing Pinulongan',
      'cebuano_to_english': 'Cebuano',
      'cebuano_to_english_subtitle': 'Naghubad sa mga buton sa interface, settings, ug home page.',
      'full_english': 'Full English',
      'full_english_subtitle': 'Nagpabilin sa mga buton, settings, ug home page sa Iningles lang.',
      'cebuano_english_mixed': 'Cebuano/English Mixed',
      'cebuano_english_mixed_subtitle': 'Mixed nga hubad para sa mga menu ug buton.',
      'save_changes': 'I-SAVE ANG PAGBAG-O',
      'pin_changed': 'Malampuson nga nabag-o ang PIN.',
      'profile_updated': 'Profile updated successfully.',
      'reset_progress': 'I-RESET ANG PAUGMAD',
      'progress_reset': 'Na-reset na ang imong paugmad, score, history, ug points.',
      'confirm_reset_title': 'I-reset ang Paugmad?',
      'confirm_reset_body': 'Mawala ang tanan nimong paugmad, score, history, ug points. Dili kini mabawi.',
      'cancel': 'KANSELAHON',
      'confirm': 'KUMPIRMAHON',
      'pin_mismatch': 'Ang bag-ong PIN ug kumpirmasyon dili magkatugma.',
      'pin_wrong': 'Sayop ang kasamtangang PIN.',
      'name_empty': 'Ang ngalan dili mahimong blangko.',
      'age_invalid': 'Ang edad kinahanglan tali sa 9 ug 12.',
      
      // Activity Buttons
      'true': 'TINUOD',
      'false': 'SAYOP',
      'check': 'CHECK',
    },
    'CEBUANO_ENGLISH_MIXED': {
      // Welcome Screen
      'get_started': 'SUGDI / GET STARTED',
      'already_have_account': 'I ALREADY HAVE AN ACCOUNT',
      'welcome_subtitle': 'Learn English through Cebuano',
      
      // Profile Setup Screen
      'step_1_of_3': 'STEP 1 OF 3',
      'profile_title': 'Tell us about yourself!',
      'profile_subtitle': 'Enter your details to create your Vocaboo learning profile.',
      'name_prompt': 'WHAT IS YOUR NAME? / UNSA IMONG NGALAN?',
      'name_hint': 'Enter name',
      'age_prompt': 'HOW OLD ARE YOU? / PILA IMONG EDAD?',
      'age_hint': 'Enter age (9-12)',
      'next': 'NEXT / SUNOD',

      // PIN Setup Screen
      'step_2_of_3': 'STEP 2 OF 3',
      'pin_title': 'Create your PIN',
      'pin_subtitle': 'Paghimo og imong sigurado nga 4-digit PIN aron maprotektahan ang imong progress.',
      'pin_prompt': 'CREATE YOUR PIN / HIMOA IMONG PIN',
      'confirm_pin_prompt': 'CONFIRM YOUR PIN / KUMPIRMAHA IMONG PIN',

      // Language Preference Screen
      'step_3_of_3': 'STEP 3 OF 3',
      'language_title': 'Choose your language',
      'language_subtitle': 'Select preferred translation language for app menus. Teaching is Cebuano-first.',

      // Success Screen
      'profile_success': 'Profile Created\nSuccessfully!',
      'success_subtitle': 'You can now use your Name and 4-digit PIN to log in next time. Paglingaw sa pagkat-on!',
      'copy_id': 'COPY NAME / KOPYAHA',
      'start_learning': 'START LEARNING / SUGDI',

      // Login Screen
      'welcome_back': 'Welcome Back!',
      'login_subtitle': 'Log in using your Name and PIN.',
      'learner_id': 'NAME / NGALAN',
      'pin_4_digit': '4-DIGIT PIN',
      'log_in': 'LOG IN',

      // Home Screen
      'app_title': 'Vocaboo',
      'hello': 'Kumusta / Hello',
      'your_categories': 'Your Categories / Kategoriya',
      'dashboard': 'Dashboard',
      'logout': 'Logout',
      'sandbox_mode': 'Sandbox Mode',
      'sandbox_desc': 'Practice custom words and topics / Pag-practice og mga pulong',
      
      // Dashboard Metrics
      'lessons_completed_metric': 'Lessons Completed / Mga Leksyon Nahuman',
      'avg_mastery_metric': 'Average Mastery / Average nga Mastery',
      'pronunciation_correct_metric': 'Correct Pronunciation / Sakto nga Paglitok',
      'cumulative_reviews_completed': 'Cumulative Reviews Completed / Nahuman',
      'view_full_progress': 'View Full Progress / Tan-awa',
      'view_full_progress_sub': 'View detailed stats / Tan-awa ang stats',
      'words_need_help_title': 'Words to Practice / Mga Pulong nga Bansayon',
      'words_need_help_subtitle': 'Strengthen your vocabulary / Pabaskoga ang imong bokabularyo',
      'words_to_practice_title': 'Words to Practice / Mga Pulong nga Bansayon',
      'practice_together_title': 'Let\'s Practice Together! 🌟 / Magbansay Kita!',
      'practice_together_sub': 'A few words to strengthen and master today. Great progress! / Pipila ka pulong nga palambuon karon!',
      'todays_picks': 'Today\'s Picks / Gipili Karon',
      'all_words': 'All Words / Tanan Pulong',
      'in_practice': 'In Practice / Gibansay ✨',
      'you_got_this': 'You\'ve got this now! 🌟 / Nakuha na nimo!',
      'practice_btn': 'Practice / Bansaya',
      'all_caught_up_title': 'You\'re All Caught Up! 🌟 / Nahuman na ang Tanan!',
      'all_caught_up_desc': 'No words waiting for practice right now. Awesome work! / Walay pulong nga naghulat sa pagbansay.',
      'past_cumulative_sessions': 'Past Cumulative Sessions',
      'no_cumulative_sessions': 'No cumulative sessions yet / Wala pay sessions',
      'recent_sandbox_sessions': 'Recent Sandbox Sessions',
      'no_sandbox_sessions': 'No sandbox sessions yet / Wala pay sessions',
      'badge_perfect_gold': 'PERFECT GOLD',
      'badge_gold': 'GOLD',
      'badge_silver': 'SILVER',
      'badge_bronze': 'BRONZE',
      'badge_perfect_gold_sub': 'Flawless — all words mastered with zero errors! / Hingpit!',
      'badge_gold_sub': 'Excellent — at most 2 mistakes across all words / Maayo kaayo!',
      'badge_silver_sub': 'Good job — keep practising to reach Gold! / Padayon!',
      'badge_bronze_sub': 'You completed the lesson — keep going! / Nahuman nimo!',
      'lesson_badges': 'Lesson Badges / Mga Badge sa Leksyon',
      'lesson_badge': 'LESSON BADGE / BADGE SA LEKSYON',
      'word_breakdown': 'Word Breakdown / Breakdown sa mga Pulong',
      
      // Settings
      'settings': 'SETTINGS / MGA SETTINGS',

      // Lesson Path Screen
      'lessons': 'Lessons / Leksyon',
      'words_count': 'words',
      'score': 'Score / Puntos',

      // Diagnostic Screen
      'diagnostic_check': 'Diagnostic Check',
      'card_indicator': 'CARD {} OF {}',
      'know_word_prompt': 'Do you know this word? / Kaila ka ba?',
      'yes_know': 'YES, I KNOW IT / OO',
      'no_dont_know': "NO, I DON'T KNOW IT / DILI",
      'saving_results': 'Saving results...',

      // Diagnostic Summary Screen
      'diagnostic_summary': 'Diagnostic Summary',
      'diagnostic_complete': 'Diagnostic Complete!',
      'know_ratio': 'You know {} out of {} words.',
      'i_know': 'I KNOW ({})',
      'to_learn': 'TO LEARN ({})',
      'start_module_1': 'START MODULE 1 / SUGDI',

      // Vocabulary Intro Screen
      'learning_progress': 'Learning: {} of {}',
      'cebuano_meaning': 'CEBUANO MEANING',
      'english_example': 'ENGLISH EXAMPLE',
      'cebuano_translation': 'CEBUANO TRANSLATION',
      'how_to_pronounce': 'HOW TO PRONOUNCE',
      'mic_prompt_idle': 'Tap the microphone and say the word.',
      'mic_prompt_recording': 'Listening... Speak now!',
      'tap_to_stop': 'TAP TO STOP',
      'evaluating': 'Evaluating...',
      'pronunciation_excellent': 'Excellent pronunciation!',
      'pronunciation_try_again': 'Let\'s try that again!',
      'target_word': 'Target Word',
      'you_said': 'You Said',
      'try_again': 'TRY AGAIN / SULAYI PAG-USAB',
      'got_it': 'GOT IT / NAKUHA NAKO',
      'practice_pronunciation': 'PRACTICE PRONUNCIATION',
      'continue': 'CONTINUE / PADAYON',
      
      // Guides
      'word_guide': 'Word Guide / Giya sa Pulong',
      'sentence_guide': 'Sentence Guide / Giya sa Pahayag',
      'cumulative_review': 'Cumulative Review',

      // Sentence Building Screen (Module 3)
      'prompt_sentence_select': 'Select the correct word for the blank.',
      'instruction_sentence_select': 'Choose the word that fills the blank.',
      'prompt_sentence_build': 'Arrange the words to build the sentence.',
      'instruction_sentence_drag': 'Drag words to form the sentence.',
      'prompt_sentence_type': 'Type the missing word in the blank.',
      'instruction_sentence_type': 'Type the correct word.',
      'prompt_sentence_review': 'Review this sentence to reinforce learning.',
      'lesson_context_title': 'Lesson Context',
      'lesson_context_desc': 'Read the story to understand the context of the words.',
      'time_remaining': 'Time Remaining / Nabilin nga Oras',
      'feedback_correct': 'Correct! / Husto!',
      'feedback_incorrect': 'Incorrect! / Sayop!',

      // Round One Completed Screen
      'lesson_completed': 'Lesson Completed!',
      'round_completed_subtitle': 'Nice work! You have finished Module 1: Vocabulary Introduction.',
      'introduced': 'INTRODUCED',
      'diagnostic_known': 'DIAGNOSTIC KNOWN',
      'back_to_path': 'BACK TO PATH',
      'back_to_dashboard': 'BACK TO DASHBOARD',
      'practice_more': 'PRACTICE MORE (MODULE 2)',

      // Lesson Score Screen
      'all_words_mastered_msg': 'All words mastered! Excellent job!',
      'keep_practising_msg': 'Keep practicing to master more words!',
      'bonus': 'Bonus',
      'words_mastered': 'Words Mastered',
      'still_needs_practice': 'Still Needs Practice',

      // Leaderboard
      'this_week': 'This Week',
      'all_time': 'All Time',
      'leaderboard_title': 'Leaderboard',
      'no_leaderboard_data': 'No leaderboard data available yet.',

      // Settings Screen
      'edit_profile': 'EDIT PROFILE / USBA',
      'display_name': 'NAME / NGALAN',
      'age': 'AGE / EDAD',
      'change_pin': 'CHANGE PIN / USBA ANG PIN',
      'current_pin': 'CURRENT PIN',
      'new_pin': 'NEW PIN / BAG-ONG PIN',
      'confirm_new_pin': 'CONFIRM NEW PIN',
      'theme_mode': 'THEME / HITSURA',
      'theme_light': 'LIGHT / HAYAG',
      'theme_dark': 'DARK / NGITNGIT',
      'notifications': 'NOTIFICATIONS / MGA ABISO',
      'account_section': 'ACCOUNT / AKAWNT',
      'learning_section': 'LEARNING / PAGKAT-ON',
      'apply_immediately': 'I-apply Dayon ang Mastered Words',
      'apply_immediately_desc': 'I-apply immediately instead of batched',
      'progress_summary': 'PROGRESS SUMMARY',
      'progress_summary_desc': 'View stats, badges, and history',
      'sandbox_mode_desc': 'Practice custom words and topics',
      'app_preferences_section': 'APP PREFERENCES / KAGUSTUHAN',
      'language_preference': 'Language Preference / Gipalabing Pinulongan',
      'cebuano_to_english': 'Cebuano',
      'cebuano_to_english_subtitle': 'Translates interface buttons, settings, and home page.',
      'full_english': 'Full English',
      'full_english_subtitle': 'Keeps buttons, settings, and home page in English only.',
      'cebuano_english_mixed': 'Cebuano/English Mixed',
      'cebuano_english_mixed_subtitle': 'Mixed translation for menus and buttons.',
      'save_changes': 'SAVE CHANGES / I-SAVE',
      'pin_changed': 'PIN changed successfully.',
      'profile_updated': 'Profile updated successfully.',
      'reset_progress': 'RESET PROGRESS / I-RESET',
      'progress_reset': 'Your progress, score, history, and points have been reset. / Na-reset na.',
      'confirm_reset_title': 'Reset Progress?',
      'confirm_reset_body': 'All your progress, score, history, and points will be lost. This cannot be undone.',
      'cancel': 'CANCEL / KANSELAHON',
      'confirm': 'CONFIRM / KUMPIRMAHON',
      'pin_mismatch': 'New PIN and confirmation do not match.',
      'pin_wrong': 'Current PIN is incorrect.',
      'name_empty': 'Name cannot be empty.',
      'age_invalid': 'Age must be between 9 and 12.',
      
      // Activity Buttons
      'true': 'TRUE / TINUOD',
      'false': 'FALSE / SAYOP',
      'check': 'CHECK',
    },
    'FULL_ENGLISH': {
      // Welcome Screen
      'get_started': 'GET STARTED',
      'already_have_account': 'I ALREADY HAVE AN ACCOUNT',
      'welcome_subtitle': 'Learning English through Cebuano',
      
      // Profile Setup Screen
      'step_1_of_3': 'STEP 1 OF 3',
      'profile_title': 'Tell us about yourself!',
      'profile_subtitle': 'Enter your details to create your Vocaboo learning profile.',
      'name_prompt': 'WHAT IS YOUR NAME?',
      'name_hint': 'Enter name',
      'age_prompt': 'HOW OLD ARE YOU?',
      'age_hint': 'Enter age (9-12)',
      'next': 'NEXT',

      // PIN Setup Screen
      'step_2_of_3': 'STEP 2 OF 3',
      'pin_title': 'Create your PIN',
      'pin_subtitle': 'Create your secure 4-digit PIN to protect your progress.',
      'pin_prompt': 'CREATE YOUR PIN',
      'confirm_pin_prompt': 'CONFIRM YOUR PIN',

      // Language Preference Screen
      'step_3_of_3': 'STEP 3 OF 3',
      'language_title': 'Choose your language',
      'language_subtitle': 'Select your preferred translation language for the app buttons and menus.',

      // Success Screen
      'profile_success': 'Profile Created\nSuccessfully!',
      'success_subtitle': 'You can now use your Name and 4-digit PIN to log in next time. Have fun learning!',
      'copy_id': 'COPY NAME',
      'start_learning': 'START LEARNING',

      // Login Screen
      'welcome_back': 'Welcome Back!',
      'login_subtitle': 'Log in using your Name and PIN.',
      'learner_id': 'NAME',
      'pin_4_digit': '4-DIGIT PIN',
      'log_in': 'LOG IN',

      // Home Screen
      'app_title': 'Vocaboo',
      'hello': 'Hello',
      'your_categories': 'Your Categories',
      'dashboard': 'Dashboard',
      'logout': 'Logout',
      'sandbox_mode': 'Sandbox Mode',
      'sandbox_desc': 'Practice custom words and topics',
      
      // Dashboard Metrics
      'lessons_completed_metric': 'Lessons Completed',
      'avg_mastery_metric': 'Average Mastery',
      'pronunciation_correct_metric': 'Correct Pronunciation',
      'cumulative_reviews_completed': 'Cumulative Reviews Completed',
      'view_full_progress': 'View Full Progress',
      'view_full_progress_sub': 'View your detailed stats',
      'words_need_help_title': 'Words to Practice',
      'words_need_help_subtitle': 'Strengthen your vocabulary with quick practice picks',
      'words_to_practice_title': 'Words to Practice',
      'practice_together_title': 'Let\'s Practice Together! 🌟',
      'practice_together_sub': 'A few words to strengthen and master today. You\'re making great progress!',
      'todays_picks': 'Today\'s Picks',
      'all_words': 'All Words',
      'in_practice': 'In Practice ✨',
      'you_got_this': 'You\'ve got this now! 🌟',
      'practice_btn': 'Practice',
      'all_caught_up_title': 'You\'re All Caught Up! 🌟',
      'all_caught_up_desc': 'No words waiting for practice right now. Awesome work!',
      'past_cumulative_sessions': 'Past Cumulative Sessions',
      'no_cumulative_sessions': 'No cumulative sessions yet',
      'recent_sandbox_sessions': 'Recent Sandbox Sessions',
      'no_sandbox_sessions': 'No sandbox sessions yet',
      'badge_perfect_gold': 'PERFECT GOLD',
      'badge_gold': 'GOLD',
      'badge_silver': 'SILVER',
      'badge_bronze': 'BRONZE',
      'badge_perfect_gold_sub': 'Flawless — all words mastered with zero errors!',
      'badge_gold_sub': 'Excellent — at most 2 mistakes across all words.',
      'badge_silver_sub': 'Good job — keep practising to reach Gold!',
      'badge_bronze_sub': 'You completed the lesson — keep going!',
      'lesson_badges': 'Lesson Badges',
      'lesson_badge': 'LESSON BADGE',
      'word_breakdown': 'Word Breakdown',
      
      // Settings
      'settings': 'SETTINGS',

      // Lesson Path Screen
      'lessons': 'Lessons',
      'words_count': 'words',
      'score': 'Score',

      // Diagnostic Screen
      'diagnostic_check': 'Diagnostic Check',
      'card_indicator': 'CARD {} OF {}',
      'know_word_prompt': 'Do you know this word?',
      'yes_know': 'YES, I KNOW IT',
      'no_dont_know': "NO, I DON'T KNOW IT",
      'saving_results': 'Saving results...',

      // Diagnostic Summary Screen
      'diagnostic_summary': 'Diagnostic Summary',
      'diagnostic_complete': 'Diagnostic Complete!',
      'know_ratio': 'You know {} out of {} words.',
      'i_know': 'I KNOW ({})',
      'to_learn': 'TO LEARN ({})',
      'start_module_1': 'START MODULE 1',

      // Vocabulary Intro Screen
      'learning_progress': 'Learning: {} of {}',
      'cebuano_meaning': 'CEBUANO MEANING',
      'english_example': 'ENGLISH EXAMPLE',
      'cebuano_translation': 'CEBUANO TRANSLATION',
      'how_to_pronounce': 'HOW TO PRONOUNCE',
      'mic_prompt_idle': 'Tap the microphone and say the word.',
      'mic_prompt_recording': 'Listening... Speak now!',
      'tap_to_stop': 'TAP TO STOP',
      'evaluating': 'Evaluating...',
      'pronunciation_excellent': 'Excellent pronunciation!',
      'pronunciation_try_again': 'Let\'s try that again!',
      'target_word': 'Target Word',
      'you_said': 'You Said',
      'try_again': 'TRY AGAIN',
      'got_it': 'GOT IT',
      'practice_pronunciation': 'PRACTICE PRONUNCIATION',
      'continue': 'CONTINUE',
      
      // Guides
      'word_guide': 'Word Guide',
      'sentence_guide': 'Sentence Guide',
      'cumulative_review': 'Cumulative Review',

      // Sentence Building Screen (Module 3)
      'prompt_sentence_select': 'Choose the word that completes the sentence.',
      'instruction_sentence_select': 'Select the correct word for the blank.',
      'prompt_sentence_build': 'Arrange the words to form the correct sentence.',
      'instruction_sentence_drag': 'Drag or tap words to form the sentence.',
      'prompt_sentence_type': 'Type the missing word in the blank.',
      'instruction_sentence_type': 'Type the correct word to complete the sentence.',
      'prompt_sentence_review': 'Review this sentence to reinforce your learning.',
      'lesson_context_title': 'Lesson Context',
      'lesson_context_desc': 'Read the story to understand the context of the words.',
      'time_remaining': 'Time Remaining',
      'feedback_correct': 'Correct!',
      'feedback_incorrect': 'Incorrect',

      // Round One Completed Screen
      'lesson_completed': 'Lesson Completed!',
      'round_completed_subtitle': 'Nice work! You have finished Module 1: Vocabulary Introduction.',
      'introduced': 'INTRODUCED',
      'diagnostic_known': 'DIAGNOSTIC KNOWN',
      'back_to_path': 'BACK TO PATH',
      'back_to_dashboard': 'BACK TO DASHBOARD',
      'practice_more': 'PRACTICE MORE (MODULE 2)',

      // Lesson Score Screen
      'all_words_mastered_msg': 'All words mastered! Excellent job!',
      'keep_practising_msg': 'Keep practicing to master more words!',
      'bonus': 'Bonus',
      'words_mastered': 'Words Mastered',
      'still_needs_practice': 'Still Needs Practice',

      // Leaderboard
      'this_week': 'This Week',
      'all_time': 'All Time',
      'leaderboard_title': 'Leaderboard',
      'no_leaderboard_data': 'No leaderboard data available yet.',

      // Settings Screen
      'edit_profile': 'EDIT PROFILE',
      'display_name': 'DISPLAY NAME',
      'age': 'AGE',
      'change_pin': 'CHANGE PIN',
      'current_pin': 'CURRENT PIN',
      'new_pin': 'NEW PIN',
      'confirm_new_pin': 'CONFIRM NEW PIN',
      'theme_mode': 'THEME MODE',
      'theme_light': 'LIGHT',
      'theme_dark': 'DARK',
      'notifications': 'NOTIFICATIONS',
      'account_section': 'ACCOUNT',
      'learning_section': 'LEARNING',
      'apply_immediately': 'Apply Mastered Words Immediately',
      'apply_immediately_desc': 'Apply immediately instead of batched',
      'progress_summary': 'PROGRESS SUMMARY',
      'progress_summary_desc': 'View stats, badges, and history',
      'sandbox_mode_desc': 'Practice custom words and topics',
      'app_preferences_section': 'APP PREFERENCES',
      'language_preference': 'Language Preference',
      'cebuano_to_english': 'Cebuano',
      'cebuano_to_english_subtitle': 'Translates interface buttons, settings, and home page.',
      'full_english': 'Full English',
      'full_english_subtitle': 'Keeps buttons, settings, and home page in English only.',
      'cebuano_english_mixed': 'Cebuano/English Mixed',
      'cebuano_english_mixed_subtitle': 'Mixed translation for menus and buttons.',
      'save_changes': 'SAVE CHANGES',
      'pin_changed': 'PIN changed successfully.',
      'profile_updated': 'Profile updated successfully.',
      'reset_progress': 'RESET PROGRESS',
      'progress_reset': 'Your progress, score, history, and points have been reset.',
      'confirm_reset_title': 'Reset Progress?',
      'confirm_reset_body': 'All your progress, score, history, and points will be lost. This cannot be undone.',
      'cancel': 'CANCEL',
      'confirm': 'CONFIRM',
      'pin_mismatch': 'New PIN and confirmation do not match.',
      'pin_wrong': 'Current PIN is incorrect.',
      'name_empty': 'Name cannot be empty.',
      'age_invalid': 'Age must be between 9 and 12.',
      
      // Activity Buttons
      'true': 'TRUE',
      'false': 'FALSE',
      'check': 'CHECK',
    }
  };

  static String translate(String? preference, String key, {List<String>? args}) {
    final language = preference ?? 'FULL_ENGLISH';
    final languageTranslations = _translations[language] ?? _translations['FULL_ENGLISH']!;
    String translatedText = languageTranslations[key] ?? _translations['FULL_ENGLISH']![key] ?? key;

    if (args != null && args.isNotEmpty) {
      for (var arg in args) {
        translatedText = translatedText.replaceFirst('{}', arg);
      }
    }

    return translatedText;
  }
}
