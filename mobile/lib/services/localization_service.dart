
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
      'sound_title': 'Tingog',
      'sound_sub_desc': 'Interactive nga giya sa paglituk ug tingog',
      'vowels_section': 'Mga Vowel',
      'consonants_section': 'Mga Consonant',
      'practice_sounds': 'MAGBANSAY SA TINGOG',
      'phonics_guide': 'Giya sa Phonics',
      'phonics_banner_title': 'Giya sa Phonics ug Paglituk 🗣️',
      'phonics_banner_sub': 'Bansaya ang mga tingog sa English gamit ang sakto nga porma sa baba ug audio!',
      'listen_all': 'Paminawa Tanan',
      'tap_to_hear': 'Pislita ang pulong aron paminawon',
      'mouth_position': 'Porma sa Baba',
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
      'build_the_sentence': 'PAGHIMO OG PAHAYAG',
      'your_sentence': 'Imong Pahayag:',
      'word_bank': 'BANGKO SA MGA PULONG',
      'preview_label': 'Preview:',
      'guided_translation_label': 'Giya nga Hubad:',
      'tap_words_placeholder': 'I-tap ang mga pulong gikan sa bangko sa ubos aron maporma ang pahayag…',
      'prompt_sentence_select': 'Pilia ang husto nga pulong sa blangko.',
      'instruction_sentence_select': 'Pilia ang pulong nga nagpuno sa blangko.',
      'prompt_sentence_build': 'Han-aya ang mga pulong aron maporma ang pahayag.',
      'instruction_sentence_drag': 'I-tap o i-drag ang mga pulong aron maporma ang pahayag.',
      'prompt_sentence_type': 'I-type ang nawala nga pulong sa blangko.',
      'instruction_sentence_type': 'I-type ang husto nga pulong.',
      'prompt_sentence_review': 'Rebyuha kining pahayag aron mas mahinumdoman.',
      'instruction_tof_match': 'Tama ba ang Iningles nga pahayag para sa Sinugboanon sa ibabaw?',
      'tof_correct': '✅ TAMA',
      'tof_wrong': '❌ SAYOP',
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
      'cebuano_english_mixed': 'Bislish (Sinagol)',
      'cebuano_english_mixed_subtitle': 'Natural nga sinagol nga Cebuano ug English sa mga menu ug tips.',
      'save_changes': 'I-SAVE ANG PAGBAG-O',
      'choose_avatar': 'Pilia ang Imong Avatar',
      'choose_avatar_desc': 'Pilia ang imong paboritong hulagway para sa imong profile.',
      'randomize': 'Sulagma',
      'save_avatar': 'ITAGO ANG PROFILE PICTURE',
      'change_avatar': 'Usba ang Profile Picture',
      'avatar_updated': 'Nabag-o ang imong profile picture!',
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

      // Navigation
      'nav_learn': 'Kat-on',
      'nav_ranking': 'Ranggo',
      'nav_profile': 'Profile',
      'nav_more': 'Dugang',

      // More Options Sheet
      'more_options': 'Dugang nga mga Pagpili',
      'learning_and_progress': 'PAGKAT-ON UG PAG-USWAG',
      'full_progress_title': 'Tibuok nga Pag-uswag',
      'full_progress_sub_desc': 'Tan-awa ang detalyado nga puntos ug graph',
      'word_practice_title': 'Pagbansay sa Pulong',
      'word_practice_sub_desc': 'Rebyuha ang mga pulong nga nasaypan',
      'preferences_and_settings': 'MGA GIPALABI UG SETTINGS',
      'change_pin_desc': 'Bag-oha ang imong 4-digit nga PIN',
      'reset_progress_desc': 'Papasa ang tanang nahuman nga leksyon ug puntos',
      'logout_title': 'Mopahawa sa Akawnt',
      'logout_confirm_body': 'Sigurado ka ba nga mogawas sa imong akawnt?',

      // M2 Activity Instructions
      'instruction_mc': 'Pilia ang husto nga Iningles nga pulong para sa Sinugboanon sa ubos.',
      'instruction_image': 'Tan-awa ang hulagway ug pilia ang husto nga pulong.',
      'instruction_tf': 'Husto ba kini nga hubad? Pilia ang Tinuod o Sayop.',
      'instruction_matching': 'Tabangi ang mga mascot pagpares sa mga pulong! I-tap ang Sinugboanon, dayon ang Iningles.',
      'instruction_fitb': 'Pilia ang nawala nga pulong aron makompleto ang pahayag.',
      'instruction_listening': 'Paminawa og maayo, i-type ang imong nadungog, unya i-check.',
      'instruction_flashcard': 'Hunahunaa una, dayon i-flip aron makita ang tubag ug kumpirmahon.',
      'instruction_rearrangement': 'Han-aya ang mga pulong aron maporma ang husto nga pahayag.',
      'instruction_word_scramble': 'Han-aya ang mga letra aron ma-spell ang Iningles nga pulong.',

      // Review & Diagnostic & General
      'your_answer': 'Imong tubag:',
      'correct_answer_label': 'Husto nga tubag:',
      'contrastive_exercise': 'Pagbansay sa Kalainan',
      'contrastive_sentences': 'Pahayag sa Pagtandi',
      'bonus_word': 'Bonus nga Pulong',
      'listen': 'Paminaw',
      'understand_distinction': 'Nasabtan Nako ang Kalainan',
      'submit_answers': 'ISUMITE ANG MGA TUBAG',
      'pos_focus_title': 'Unsa imong gustong tutokan?',
      'focus_all_words': '🌟 Tanan Pulong',
      'focus_all_words_desc': 'Pagbansay sa tanang pulong niining leksyon',
      'focus_nouns': '🏷️ Mga Pangngalan (Nouns)',
      'focus_nouns_desc': 'Tutoki ang mga butang, dapit, ug ngalan',
      'focus_verbs': '⚡ Mga Pandiwa (Verbs)',
      'focus_verbs_desc': 'Tutoki ang mga pulong sa lihok',
      'focus_adjectives': '🎨 Mga Panghulagway (Adjectives)',
      'focus_adjectives_desc': 'Tutoki ang mga pulong nga naghulagway',
      'start_lesson': 'SUGDI ANG LEKSYON',
      'stage_learning': 'Pagkat-on',
      'stage_familiar': 'Pamilyar',
      'stage_proficient': 'Bansay',
      'stage_mastered': 'Na-master',
      'learning': 'Pagkat-on',
      'mastered': 'Na-master',
      'proficient': 'Bansay',
      'familiar': 'Pamilyar',
      'stage_novice': 'Pagkat-on',
      'novice': 'Pagkat-on',
      'needs_review': 'Kinahanglan Rebyuhon',
      'done': 'HUMAN NA',
      
      // Sandbox Mode
      'sandbox_title': 'Sandbox Mode',
      'sandbox_subtitle': 'Paghimo og kaugalingon nga learning path',
      'sandbox_input_prompt': 'Unsang mga pulong o topiko ang gusto nimong bansayon?',
      'sandbox_input_hint': 'e.g. Outer Space, Dinosaurs, Animals, o apple, star, moon',
      'sandbox_generate_btn': 'HIMOAG LEARNING PATH',
      'sandbox_history_btn': 'Past Sandbox Words',
      'sandbox_history_title': 'Mga Naaging Sandbox Words',
      'sandbox_history_empty_title': 'Wala Pay Naaging Sandbox Paths',
      'sandbox_history_empty_desc': 'Pagsugod pinaagi sa paghimo sa imong unang custom learning path karon!',
      'sandbox_replay_btn': 'ABLIHI ANG PATH',
      'sandbox_new_path': 'BAG-ONG PATH',
      'sandbox_topic': 'Topiko',
      'sandbox_created_on': 'Gihimo sa',
      'sandbox_delete_confirm_title': 'Papasa ang Session',
      'sandbox_delete_confirm_body': 'Sigurado ka ba nga tangtangon kini nga sandbox path?',
      'sandbox_path_title': 'Custom Learning Path',
      'sandbox_path_subtitle': 'I-master ang imong mga pulong lakang sa lakang',
    },
    'CEBUANO_ENGLISH_MIXED': {
      // Welcome Screen
      'get_started': 'SUGDAN NATO!',
      'already_have_account': 'NAA NA KOY ACCOUNT',
      'welcome_subtitle': 'Mag-learn og English gamit ang Cebuano!',
      
      // Profile Setup Screen
      'step_1_of_3': 'STEP 1 OF 3',
      'profile_title': 'Paila-ila sa imong self!',
      'profile_subtitle': 'I-enter imong details para mahimo imong Vocaboo learning profile.',
      'name_prompt': 'UNSA IMONG NAME?',
      'name_hint': 'I-type imong name',
      'age_prompt': 'PILA IMONG AGE?',
      'age_hint': 'I-enter imong age (9-12)',
      'next': 'NEXT NA',

      // PIN Setup Screen
      'step_2_of_3': 'STEP 2 OF 3',
      'pin_title': 'Paghimo og imong PIN',
      'pin_subtitle': 'Paghimo og 4-digit PIN para safe pirmi imong learning progress.',
      'pin_prompt': 'I-ENTER IMONG 4-DIGIT PIN',
      'confirm_pin_prompt': 'I-CONFIRM IMONG PIN',

      // Language Preference Screen
      'step_3_of_3': 'STEP 3 OF 3',
      'language_title': 'Pili og language preference',
      'language_subtitle': 'Pilia unsa nga language style imong ganahan para sa mga buttons ug menus.',

      // Success Screen
      'profile_success': 'Success! Nahimo na\nimong profile!',
      'success_subtitle': 'Pwede na nimo gamiton imong Name ug 4-digit PIN para mag-login. Enjoy learning!',
      'copy_id': 'I-COPY ANG NAME',
      'start_learning': 'START LEARNING NA!',

      // Login Screen
      'welcome_back': 'Welcome back!',
      'login_subtitle': 'I-enter imong Name ug PIN para maka-login dayon.',
      'learner_id': 'IMONG NAME',
      'pin_4_digit': '4-DIGIT PIN',
      'log_in': 'LOG IN NA',

      // Home Screen
      'app_title': 'Vocaboo',
      'hello': 'Hello',
      'your_categories': 'Imong mga Categories',
      'dashboard': 'Dashboard',
      'logout': 'Logout',
      'sandbox_mode': 'Sandbox Mode',
      'sandbox_desc': 'I-practice bisan unsa nga custom words ug topics!',
      
      // Dashboard Metrics
      'lessons_completed_metric': 'Lessons nga Nahuman',
      'avg_mastery_metric': 'Average Mastery Score',
      'pronunciation_correct_metric': 'Sakto nga Pronunciation',
      'cumulative_reviews_completed': 'Completed Reviews',
      'view_full_progress': 'Tan-awa Imong Full Progress',
      'view_full_progress_sub': 'Tan-awa imong detailed stats ug badges',
      'words_need_help_title': 'Mga Words nga I-practice',
      'words_need_help_subtitle': 'Pabaskoga pa imong vocabulary!',
      'words_to_practice_title': 'Mga Words nga Bansayon',
      'practice_together_title': 'Mag-practice ta karon! 🌟',
      'practice_together_sub': 'Naay pipila ka words nga i-master nato karon. Nice kaayo imong progress!',
      'todays_picks': "Today's Picks",
      'all_words': 'All Words',
      'in_practice': 'Gipractice pa ✨',
      'you_got_this': 'Kaya kaayo nimo! 🌟',
      'practice_btn': 'I-practice na',
      'sound_title': 'Sound',
      'sound_sub_desc': 'Interactive pronunciation ug sound guide',
      'vowels_section': 'Mga Vowel',
      'consonants_section': 'Mga Consonant',
      'practice_sounds': 'PRACTICE SOUNDS',
      'phonics_guide': 'Phonics Guide',
      'phonics_banner_title': 'Phonics & Pronunciation Guide 🗣️',
      'phonics_banner_sub': 'Master English sounds with clear mouth positions, audio, ug examples!',
      'listen_all': 'Listen All',
      'tap_to_hear': 'Tap word to listen',
      'mouth_position': 'Mouth Position',
      'all_caught_up_title': 'Nahuman na nimo tanan! 🌟',
      'all_caught_up_desc': 'Walay words nga nag-need og practice karon. Good job kaayo!',
      'past_cumulative_sessions': 'Past Cumulative Sessions',
      'no_cumulative_sessions': 'Wala pa kay previous sessions',
      'recent_sandbox_sessions': 'Recent Sandbox Sessions',
      'no_sandbox_sessions': 'Wala pa kay sandbox sessions',
      'badge_perfect_gold': 'PERFECT GOLD',
      'badge_gold': 'GOLD',
      'badge_silver': 'SILVER',
      'badge_bronze': 'BRONZE',
      'badge_perfect_gold_sub': 'Hingpit — na-master tanan words with zero mistakes!',
      'badge_gold_sub': 'Galing — maximum 2 mistakes ra sa tanan words!',
      'badge_silver_sub': 'Nice job — padayon og practice para ma-Gold!',
      'badge_bronze_sub': 'Nahuman nimo ang lesson — keep going!',
      'lesson_badges': 'Imong Lesson Badges',
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
      'know_word_prompt': 'Kaila ba ka ani nga word?',
      'yes_know': 'OO, KAILA NA KO',
      'no_dont_know': 'DILI PA KO SURE',
      'saving_results': 'Gisave pa ang results...',

      // Diagnostic Summary Screen
      'diagnostic_summary': 'Diagnostic Summary',
      'diagnostic_complete': 'Humana ang Diagnostic!',
      'know_ratio': 'Nakahibalo ka og {} out of {} ka words.',
      'i_know': 'KAILA NA KO ({})',
      'to_learn': 'TUN-ANAN PA ({})',
      'start_module_1': 'START MODULE 1 NA',

      // Vocabulary Intro Screen
      'learning_progress': 'Gat-on: {} of {}',
      'cebuano_meaning': 'CEBUANO MEANING',
      'english_example': 'ENGLISH EXAMPLE',
      'cebuano_translation': 'BISLISH TRANSLATION',
      'how_to_pronounce': 'UNSAON PAG-PRONOUNCE',
      'mic_prompt_idle': 'I-tap ang mic unya i-pronounce ang word.',
      'mic_prompt_recording': 'Gapaminaw... Isulti na!',
      'tap_to_stop': 'I-TAP PARA MO-STOP',
      'evaluating': 'Gi-check pa imong pronunciation...',
      'pronunciation_excellent': 'Nice kaayo imong pronunciation!',
      'pronunciation_try_again': 'Sulayan nato og balik ha?',
      'target_word': 'Target Word',
      'you_said': 'Imong Gisulti',
      'try_again': 'SULAYI PAG-USAB',
      'got_it': 'NAKUHA NA NAKO',
      'practice_pronunciation': 'I-PRACTICE ANG PRONUNCIATION',
      'continue': 'PADAYON NA',
      'listen_again': 'Paminawa og balik',
      
      // Guides
      'word_guide': 'Word Guide',
      'sentence_guide': 'Sentence Guide',
      'cumulative_review': 'Cumulative Review',

      // Sentence Building Screen (Module 3)
      'build_the_sentence': 'BUILD THE SENTENCE',
      'your_sentence': 'Your Sentence:',
      'word_bank': 'WORD BANK',
      'preview_label': 'Preview:',
      'guided_translation_label': 'Guided Translation:',
      'tap_words_placeholder': 'I-tap ang words gikan sa bank sa ubos para ma-build imong sentence…',
      'prompt_sentence_select': 'Pilia ang sakto nga word para sa blank.',
      'instruction_sentence_select': 'Pilia ang word nga mo-fit sa blank.',
      'prompt_sentence_build': 'I-arrange ang mga words para maporma ang sentence.',
      'instruction_sentence_drag': 'I-tap o i-drag ang words para mahimong sentence.',
      'prompt_sentence_type': 'I-type ang missing word sa blank.',
      'instruction_sentence_type': 'I-type ang sakto nga word.',
      'prompt_sentence_review': 'I-review ni nga sentence para mas ma-remember nimo.',
      'instruction_tof_match': 'Tama ba ang English sentence para sa Cebuano sa ibabaw?',
      'tof_correct': '✅ TAMA (Correct)',
      'tof_wrong': '❌ SAYOP (Wrong)',
      'lesson_context_title': 'Lesson Context',
      'lesson_context_desc': 'Basaha ang short story aron masabtan unsaon paggamit ang words.',
      'time_remaining': 'Nabilin nga Time',
      'feedback_correct': 'Sakto! Nice one!',
      'feedback_incorrect': 'Sayop gamay, pero kaya na nimo!',

      // Round One Completed Screen
      'lesson_completed': 'Nahuman na ang Lesson!',
      'round_completed_subtitle': 'Great job! Nahuman na nimo ang Module 1: Vocabulary Introduction.',
      'introduced': 'NA-INTRODUCE NA',
      'diagnostic_known': 'NAHIBAL-AN SA DIAGNOSTIC',
      'back_to_path': 'BALIK SA LESSON PATH',
      'back_to_dashboard': 'BALIK SA DASHBOARD',
      'practice_more': 'MAG-PRACTICE PA (MODULE 2)',

      // Lesson Score Screen
      'all_words_mastered_msg': 'Na-master tanan words! Excellent job kaayo!',
      'keep_practising_msg': 'Padayon og practice para mas daghan pa kag ma-master nga words!',
      'bonus': 'Bonus',
      'words_mastered': 'Words nga Na-master',
      'still_needs_practice': 'Kinahanglan pa og Practice',

      // Leaderboard
      'this_week': 'This Week',
      'all_time': 'All Time',
      'leaderboard_title': 'Leaderboard',
      'no_leaderboard_data': 'Wala pay leaderboard data karon.',

      // Settings Screen
      'edit_profile': 'I-EDIT ANG PROFILE',
      'display_name': 'NAME',
      'age': 'AGE',
      'change_pin': 'USBA ANG PIN',
      'current_pin': 'CURRENT PIN',
      'new_pin': 'BAG-ONG PIN',
      'confirm_new_pin': 'I-CONFIRM ANG NEW PIN',
      'theme_mode': 'THEME',
      'theme_light': 'LIGHT MODE',
      'theme_dark': 'DARK MODE',
      'notifications': 'NOTIFICATIONS',
      'account_section': 'ACCOUNT SETTINGS',
      'learning_section': 'LEARNING PREFERENCES',
      'apply_immediately': 'I-apply Dayon ang Mastered Words',
      'apply_immediately_desc': 'I-apply immediately kaysa mag-batch',
      'progress_summary': 'PROGRESS SUMMARY',
      'progress_summary_desc': 'Tan-awa imong stats, badges, ug history',
      'sandbox_mode_desc': 'I-practice imong custom words ug topics',
      'app_preferences_section': 'APP PREFERENCES',
      'language_preference': 'Language Preference',
      'cebuano_to_english': 'Cebuano',
      'cebuano_to_english_subtitle': 'Pure Cebuano translations para sa interface ug buttons.',
      'full_english': 'Full English',
      'full_english_subtitle': 'English-only display para sa tanan menus ug buttons.',
      'cebuano_english_mixed': 'Bislish (Mixed)',
      'cebuano_english_mixed_subtitle': 'Natural Cebuano-English code-switching sa tanan menus ug tips.',
      'save_changes': 'I-SAVE ANG CHANGES',
      'choose_avatar': 'Pili og Avatar',
      'choose_avatar_desc': 'Pilia imong favorite character avatar.',
      'randomize': 'Random',
      'save_avatar': 'I-SAVE ANG AVATAR',
      'change_avatar': 'Usba ang Avatar',
      'avatar_updated': 'Na-update na imong avatar!',
      'pin_changed': 'Na-change na imong PIN successfully.',
      'profile_updated': 'Na-update na imong profile.',
      'reset_progress': 'I-RESET ANG PROGRESS',
      'progress_reset': 'Na-reset na imong scores, history, ug points.',
      'confirm_reset_title': 'I-reset gyud imong Progress?',
      'confirm_reset_body': 'Mawala tanan nimong progress, scores, ug badges. Dili na ni mabalik.',
      'cancel': 'CANCEL',
      'confirm': 'I-CONFIRM',
      'pin_mismatch': 'Dili pareho ang bag-ong PIN ug ang confirmation.',
      'pin_wrong': 'Sayop imong current PIN.',
      'name_empty': 'Dili pwede nga blank ang Name.',
      'age_invalid': 'Ang age dapat between 9 ug 12 years old.',
      
      // Activity Buttons
      'true': 'TRUE',
      'false': 'FALSE',
      'check': 'CHECK',

      // Navigation
      'nav_learn': 'Learn',
      'nav_ranking': 'Ranking',
      'nav_profile': 'Profile',
      'nav_more': 'More',

      // More Options Sheet
      'more_options': 'More Options',
      'learning_and_progress': 'LEARNING & PROGRESS',
      'full_progress_title': 'Full Progress',
      'full_progress_sub_desc': 'Tan-awa imong detailed scores ug accuracy graphs',
      'word_practice_title': 'Word Practice',
      'word_practice_sub_desc': 'I-review ang mga words nga nasaypan',
      'preferences_and_settings': 'PREFERENCES & SETTINGS',
      'change_pin_desc': 'I-update imong 4-digit security PIN',
      'reset_progress_desc': 'I-clear ang tanan lesson progress ug scores',
      'logout_title': 'Log Out',
      'logout_confirm_body': 'Sigurado ka nga mo-log out sa imong account?',

      // M2 Activity Instructions
      'instruction_mc': 'Pilia ang sakto nga English word para sa Cebuano word sa ubos.',
      'instruction_image': 'Tan-awa ang image unya choose the correct word.',
      'instruction_tf': 'Sakto ba ni nga translation? Select True or False.',
      'instruction_matching': 'I-match ang mga pairs! I-tap ang Cebuano word, then its English match.',
      'instruction_fitb': 'Pilia ang missing word para makompleto ang sentence.',
      'instruction_listening': 'Paminawa og maayo ang audio, i-type imong nadungog, then check.',
      'instruction_flashcard': 'Think sa answer una, then i-flip ang card para ma-check.',
      'instruction_rearrangement': 'I-arrange ang words para maporma ang sentence.',
      'instruction_word_scramble': 'I-arrange ang letters para ma-spell ang English word.',

      // Review & Diagnostic & General
      'your_answer': 'Imong tubag:',
      'correct_answer_label': 'Sakto nga tubag:',
      'contrastive_exercise': 'Contrastive Exercise',
      'contrastive_sentences': 'Contrastive Sentences',
      'bonus_word': 'Bonus Word',
      'listen': 'Listen',
      'understand_distinction': 'Nakasabot na ko sa Distinction',
      'submit_answers': 'I-SUBMIT ANG ANSWERS',
      'pos_focus_title': 'Unsa imong ganahan i-focus?',
      'focus_all_words': '🌟 All Words',
      'focus_all_words_desc': 'I-practice tanan vocabulary words sa lesson',
      'focus_nouns': '🏷️ Nouns',
      'focus_nouns_desc': 'Focus sa mga objects, places, ug names',
      'focus_verbs': '⚡ Verbs',
      'focus_verbs_desc': 'Focus sa mga action words',
      'focus_adjectives': '🎨 Adjectives',
      'focus_adjectives_desc': 'Focus sa mga descriptive words',
      'start_lesson': 'SUGDI ANG LESSON',
      'stage_learning': 'Learning',
      'stage_familiar': 'Familiar',
      'stage_proficient': 'Proficient',
      'stage_mastered': 'Mastered',
      'learning': 'Learning',
      'mastered': 'Mastered',
      'proficient': 'Proficient',
      'familiar': 'Familiar',
      'stage_novice': 'Learning',
      'novice': 'Learning',
      'needs_review': 'Needs Review',
      'done': 'DONE NA',
      
      // Sandbox Mode
      'sandbox_title': 'Sandbox Mode',
      'sandbox_subtitle': 'Create og imong custom learning path',
      'sandbox_input_prompt': 'Unsa nga words or topic imong ganahan i-practice?',
      'sandbox_input_hint': 'e.g. Outer Space, Dinosaurs, Animals, or apple, star, moon',
      'sandbox_generate_btn': 'GENERATE LEARNING PATH',
      'sandbox_history_btn': 'Past Sandbox Words',
      'sandbox_history_title': 'Past Sandbox Words',
      'sandbox_history_empty_title': 'Wala pa kay Sandbox Paths',
      'sandbox_history_empty_desc': 'Sugod og himo sa imong first custom learning path karon!',
      'sandbox_replay_btn': 'OPEN PATH',
      'sandbox_new_path': 'NEW PATH',
      'sandbox_topic': 'Topic',
      'sandbox_created_on': 'Created on',
      'sandbox_delete_confirm_title': 'Delete Session',
      'sandbox_delete_confirm_body': 'Sigurado ka nga i-delete kini nga sandbox path?',
      'sandbox_path_title': 'Custom Learning Path',
      'sandbox_path_subtitle': 'I-master imong custom words step-by-step',
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
      'sound_title': 'Sound',
      'sound_sub_desc': 'Interactive pronunciation and sound guide',
      'vowels_section': 'Vowels',
      'consonants_section': 'Consonants',
      'practice_sounds': 'PRACTICE SOUNDS',
      'phonics_guide': 'Phonics Guide',
      'phonics_banner_title': 'Phonics & Pronunciation Guide 🗣️',
      'phonics_banner_sub': 'Master challenging English sounds with clear mouth positions, audio, and examples!',
      'listen_all': 'Listen All',
      'tap_to_hear': 'Tap word to listen',
      'mouth_position': 'Mouth Position',
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
      'build_the_sentence': 'BUILD THE SENTENCE',
      'your_sentence': 'Your Sentence:',
      'word_bank': 'WORD BANK',
      'preview_label': 'Preview:',
      'guided_translation_label': 'Guided Translation:',
      'tap_words_placeholder': 'Tap words from the bank below to build your sentence…',
      'prompt_sentence_select': 'Choose the word that completes the sentence.',
      'instruction_sentence_select': 'Select the correct word for the blank.',
      'prompt_sentence_build': 'Arrange the words to form the correct sentence.',
      'instruction_sentence_drag': 'Drag or tap words below to build your sentence.',
      'prompt_sentence_type': 'Type the missing word in the blank.',
      'instruction_sentence_type': 'Type the correct word to complete the sentence.',
      'prompt_sentence_review': 'Review this sentence to reinforce your learning.',
      'instruction_tof_match': 'Does this English sentence correctly match the Cebuano above?',
      'tof_correct': '✅ CORRECT',
      'tof_wrong': '❌ WRONG',
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
      'cebuano_english_mixed': 'Bislish (Mixed)',
      'cebuano_english_mixed_subtitle': 'Natural Cebuano-English code-switching for menus and tips.',
      'save_changes': 'SAVE CHANGES',
      'choose_avatar': 'Choose Your Avatar',
      'choose_avatar_desc': 'Pick your favorite character for your profile picture.',
      'randomize': 'Random',
      'save_avatar': 'SAVE PROFILE PICTURE',
      'change_avatar': 'Change Profile Picture',
      'avatar_updated': 'Profile picture updated successfully!',
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

      // Navigation
      'nav_learn': 'Learn',
      'nav_ranking': 'Ranking',
      'nav_profile': 'Profile',
      'nav_more': 'More',

      // More Options Sheet
      'more_options': 'More Options',
      'learning_and_progress': 'LEARNING & PROGRESS',
      'full_progress_title': 'Full Progress',
      'full_progress_sub_desc': 'View detailed lesson scores and accuracy graphs',
      'word_practice_title': 'Word Practice',
      'word_practice_sub_desc': 'Review missed words and weak vocabulary',
      'preferences_and_settings': 'PREFERENCES & SETTINGS',
      'change_pin_desc': 'Update your 4-digit security PIN',
      'reset_progress_desc': 'Clear all lesson completion and reset scores',
      'logout_title': 'Log Out',
      'logout_confirm_body': 'Are you sure you want to log out of your account?',

      // M2 Activity Instructions
      'instruction_mc': 'Select the correct English word for the Cebuano word below.',
      'instruction_image': 'Look at the image and choose the correct word.',
      'instruction_tf': 'Is this translation correct? Select True or False.',
      'instruction_matching': 'Help our mascots find the matching words! Tap a Cebuano word, then its English match.',
      'instruction_fitb': 'Select the missing word to complete the sentence.',
      'instruction_listening': 'Listen carefully, type what you hear, then check your answer.',
      'instruction_flashcard': 'Think first, then flip to reveal the answer and confirm you know it.',
      'instruction_rearrangement': 'Arrange the words to form the correct sentence.',
      'instruction_word_scramble': 'Unscramble the letters to spell the English word.',

      // Review & Diagnostic & General
      'your_answer': 'Your answer:',
      'correct_answer_label': 'Correct answer:',
      'contrastive_exercise': 'Contrastive Exercise',
      'contrastive_sentences': 'Contrastive Sentences',
      'bonus_word': 'Bonus Word',
      'listen': 'Listen',
      'understand_distinction': 'I Understand the Distinction',
      'submit_answers': 'SUBMIT ANSWERS',
      'pos_focus_title': 'What would you like to focus on?',
      'focus_all_words': '🌟 All Words',
      'focus_all_words_desc': 'Practice all vocabulary words in this lesson',
      'focus_nouns': '🏷️ Nouns',
      'focus_nouns_desc': 'Focus on objects, places, and names',
      'focus_verbs': '⚡ Verbs',
      'focus_verbs_desc': 'Focus on action words',
      'focus_adjectives': '🎨 Adjectives',
      'focus_adjectives_desc': 'Focus on descriptive words',
      'start_lesson': 'START LESSON',
      'stage_learning': 'Learning',
      'stage_familiar': 'Familiar',
      'stage_proficient': 'Proficient',
      'stage_mastered': 'Mastered',
      'learning': 'Learning',
      'mastered': 'Mastered',
      'proficient': 'Proficient',
      'familiar': 'Familiar',
      'stage_novice': 'Learning',
      'novice': 'Learning',
      'needs_review': 'Needs Review',
      'done': 'DONE',
      
      // Sandbox Mode
      'sandbox_title': 'Sandbox Mode',
      'sandbox_subtitle': 'Create your custom learning path',
      'sandbox_input_prompt': 'What words or topic do you want to practice?',
      'sandbox_input_hint': 'e.g. Outer Space, Dinosaurs, Animals, or apple, star, moon',
      'sandbox_generate_btn': 'GENERATE LEARNING PATH',
      'sandbox_history_btn': 'Past Sandbox Words',
      'sandbox_history_title': 'Past Sandbox Words',
      'sandbox_history_empty_title': 'No Sandbox Paths Yet',
      'sandbox_history_empty_desc': 'Start by creating your first custom learning path today!',
      'sandbox_replay_btn': 'OPEN PATH',
      'sandbox_new_path': 'NEW PATH',
      'sandbox_topic': 'Topic',
      'sandbox_created_on': 'Created on',
      'sandbox_delete_confirm_title': 'Delete Session',
      'sandbox_delete_confirm_body': 'Are you sure you want to delete this sandbox path?',
      'sandbox_path_title': 'Custom Learning Path',
      'sandbox_path_subtitle': 'Master your custom words step-by-step',
    }
  };

  static String _normalizeLanguage(String? preference) {
    if (preference == null || preference.trim().isEmpty) {
      return 'FULL_ENGLISH';
    }
    final clean = preference.trim().toUpperCase();
    if (clean == 'CEBUANO' ||
        clean == 'BISAYA' ||
        clean == 'CB' ||
        clean == 'CEBUANO_TO_ENGLISH') {
      return 'CEBUANO_TO_ENGLISH';
    }
    if (clean == 'MIXED' ||
        clean == 'TAGLISH' ||
        clean == 'CEBUANO_ENGLISH_MIXED') {
      return 'CEBUANO_ENGLISH_MIXED';
    }
    return 'FULL_ENGLISH';
  }

  static String _formatFallbackKey(String key) {
    // Safety map for essential instructions and prompts
    switch (key) {
      case 'prompt_sentence_build':
        return 'Arrange the words to form the correct sentence.';
      case 'instruction_sentence_drag':
        return 'Drag or tap words below to build your sentence.';
      case 'prompt_sentence_select':
        return 'Choose the word that completes the sentence.';
      case 'instruction_sentence_select':
        return 'Select the correct word for the blank.';
      case 'prompt_sentence_type':
        return 'Type the missing word in the blank.';
      case 'instruction_sentence_type':
        return 'Type the correct word to complete the sentence.';
      case 'instruction_tof_match':
        return 'Does this English sentence correctly match the Cebuano?';
      case 'prompt_sentence_review':
        return 'Review this sentence to reinforce your learning.';
      case 'stage_learning':
      case 'learning':
      case 'novice':
        return 'Learning';
      case 'stage_familiar':
      case 'familiar':
        return 'Familiar';
      case 'stage_proficient':
      case 'proficient':
        return 'Proficient';
      case 'stage_mastered':
      case 'mastered':
        return 'Mastered';
      case 'build_the_sentence':
        return 'Build the Sentence';
      case 'your_sentence':
        return 'Your Sentence:';
      case 'word_bank':
        return 'WORD BANK';
      case 'tap_words_placeholder':
        return 'Tap words from the bank below to build your sentence…';
      default:
        // Convert any raw snake_case string into readable sentence / title case
        if (key.contains('_')) {
          final words = key.split('_').where((w) => w.isNotEmpty).map((w) {
            return w[0].toUpperCase() + w.substring(1).toLowerCase();
          }).join(' ');
          return words;
        }
        return key;
    }
  }

  static String translate(String? preference, String key, {List<String>? args}) {
    final language = _normalizeLanguage(preference);
    final languageTranslations =
        _translations[language] ?? _translations['FULL_ENGLISH']!;

    final String? raw = languageTranslations[key] ??
        _translations['FULL_ENGLISH']?[key];

    String translatedText;
    if (raw == null || (raw == key && key.contains('_'))) {
      translatedText = _formatFallbackKey(key);
    } else {
      translatedText = raw;
    }

    if (args != null && args.isNotEmpty) {
      for (var arg in args) {
        translatedText = translatedText.replaceFirst('{}', arg);
      }
    }

    return translatedText;
  }
}

