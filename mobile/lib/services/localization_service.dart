
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
      'logout': 'Gawas',
      'sandbox_mode': 'Sandbox Mode',

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

      // Round One Completed Screen
      'lesson_completed': 'Nahuman ang Leksyon!',
      'round_completed_subtitle': 'Maayong trabaho! Nahuman nimo ang Modyul 1: Pasiuna sa Bokabularyo.',
      'introduced': 'NAPAILA',
      'diagnostic_known': 'DIAGNOSTIC NAKASABTAN',
      'back_to_path': 'BALIK SA LEKSYON',
      'practice_more': 'PRACTICE PA (MODYUL 2)',

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
      'app_preferences_section': 'KAGUSTUHAN SA APP',
      'save_changes': 'I-SAVE ANG PAGBAG-O',
      'pin_changed': 'Malampuson nga nabag-o ang PIN.',
      'profile_updated': 'Malampuson nga naupdate ang profile.',
      'reset_progress': 'I-RESET ANG PAUGMAD',
      'progress_reset': 'Na-reset na ang imong paugmad.',
      'confirm_reset_title': 'I-reset ang Paugmad?',
      'confirm_reset_body': 'Mawala ang tanan nimong paugmad. Dili kini mabawi.',
      'cancel': 'KANSELAHON',
      'confirm': 'KUMPIRMAHON',
      'pin_mismatch': 'Ang bag-ong PIN ug kumpirmasyon dili magkatugma.',
      'pin_wrong': 'Sayop ang kasamtangang PIN.',
      'name_empty': 'Ang ngalan dili mahimong blangko.',
      'age_invalid': 'Ang edad kinahanglan tali sa 9 ug 12.',
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
      'logout': 'Logout',
      'sandbox_mode': 'Sandbox Mode',

      // Lesson Path Screen
      'lessons': 'Lessons / Leksyon',
      'words_count': 'words',
      'score': 'Score',

      // Diagnostic Screen
      'diagnostic_check': 'Diagnostic Check',
      'card_indicator': 'CARD {} OF {}',
      'know_word_prompt': 'Do you know this word? / Kaila ka ba?',
      'yes_know': 'YES, I KNOW IT',
      'no_dont_know': "NO, I DON'T KNOW IT",
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

      // Round One Completed Screen
      'lesson_completed': 'Lesson Completed!',
      'round_completed_subtitle': 'Nice work! You have finished Module 1: Vocabulary Introduction.',
      'introduced': 'INTRODUCED',
      'diagnostic_known': 'DIAGNOSTIC KNOWN',
      'back_to_path': 'BACK TO PATH',
      'practice_more': 'PRACTICE MORE (MODULE 2)',

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
      'app_preferences_section': 'APP PREFERENCES / KAGUSTUHAN',
      'save_changes': 'SAVE CHANGES / I-SAVE',
      'pin_changed': 'PIN changed successfully.',
      'profile_updated': 'Profile updated successfully.',
      'reset_progress': 'RESET PROGRESS / I-RESET',
      'progress_reset': 'Your progress has been reset. / Na-reset na.',
      'confirm_reset_title': 'Reset Progress?',
      'confirm_reset_body': 'All your progress will be lost. This cannot be undone.',
      'cancel': 'CANCEL / KANSELAHON',
      'confirm': 'CONFIRM / KUMPIRMAHON',
      'pin_mismatch': 'New PIN and confirmation do not match.',
      'pin_wrong': 'Current PIN is incorrect.',
      'name_empty': 'Name cannot be empty.',
      'age_invalid': 'Age must be between 9 and 12.',
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
      'logout': 'Logout',
      'sandbox_mode': 'Sandbox Mode',

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

      // Round One Completed Screen
      'lesson_completed': 'Lesson Completed!',
      'round_completed_subtitle': 'Nice work! You have finished Module 1: Vocabulary Introduction.',
      'introduced': 'INTRODUCED',
      'diagnostic_known': 'DIAGNOSTIC KNOWN',
      'back_to_path': 'BACK TO PATH',
      'practice_more': 'PRACTICE MORE (MODULE 2)',

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
      'app_preferences_section': 'APP PREFERENCES',
      'save_changes': 'SAVE CHANGES',
      'pin_changed': 'PIN changed successfully.',
      'profile_updated': 'Profile updated successfully.',
      'reset_progress': 'RESET PROGRESS',
      'progress_reset': 'Your progress has been reset.',
      'confirm_reset_title': 'Reset Progress?',
      'confirm_reset_body': 'All your progress will be lost. This cannot be undone.',
      'cancel': 'CANCEL',
      'confirm': 'CONFIRM',
      'pin_mismatch': 'New PIN and confirmation do not match.',
      'pin_wrong': 'Current PIN is incorrect.',
      'name_empty': 'Name cannot be empty.',
      'age_invalid': 'Age must be between 9 and 12.',
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
