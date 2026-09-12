/// Comprehensive Phonetic and Phonological Guidance Service for Vocaboo.
///
/// Tailored for Cebuano-speaking Filipino learners aged 9–12 transitioning to English.
/// Focuses on English phonemes absent in Cebuano phonology:
/// - /v/ (voiced labiodental fricative) vs Cebuano /b/
/// - /f/ (voiceless labiodental fricative) vs Cebuano /p/
/// - /θ/ & /ð/ (dental fricatives 'th') vs Cebuano /t/ or /d/
/// - /ʃ/ (sh), /tʃ/ (ch), /dʒ/ (j/dg), and English /r/ vs rolled /r/
class PhoneticService {
  static const Map<String, String> _ipaDictionary = {
    // School / Stationery
    'pencil': '/ˈpɛn.səl/',
    'notebook': '/ˈnoʊt.bʊk/',
    'eraser': '/ɪˈreɪ.sər/',
    'bag': '/bæɡ/',
    'ruler': '/ˈruː.lər/',
    'book': '/bʊk/',
    'paper': '/ˈpeɪ.pər/',
    'desk': '/dɛsk/',
    'crayon': '/ˈkreɪ.ɒn/',
    'scissors': '/ˈsɪz.ərz/',
    'glue': '/ɡluː/',
    'chair': '/tʃɛər/',
    'table': '/ˈteɪ.bəl/',
    'classroom': '/ˈklæs.ruːm/',
    'teacher': '/ˈtiː.tʃər/',
    'student': '/ˈstjuː.dənt/',

    // Family
    'mother': '/ˈmʌð.ər/',
    'father': '/ˈfɑː.ðər/',
    'sister': '/ˈsɪs.tər/',
    'brother': '/ˈbrʌð.ər/',
    'grandmother': '/ˈɡrændˌmʌð.ər/',
    'grandfather': '/ˈɡrændˌfɑː.ðər/',
    'baby': '/ˈbeɪ.bi/',
    'family': '/ˈfæm.əl.i/',
    'son': '/sʌn/',
    'daughter': '/ˈdɔː.tər/',

    // Animals
    'dog': '/dɔːɡ/',
    'cat': '/kæt/',
    'bird': '/bɜːrd/',
    'fish': '/fɪʃ/',
    'horse': '/hɔːrs/',
    'cow': '/kaʊ/',
    'pig': '/pɪɡ/',
    'chicken': '/ˈtʃɪk.ɪn/',
    'duck': '/dʌk/',
    'goat': '/ɡoʊt/',
    'rabbit': '/ˈræb.ɪt/',
    'sheep': '/ʃiːp/',
    'monkey': '/ˈmʌŋ.ki/',
    'elephant': '/ˈɛl.ɪ.fənt/',
    'frog': '/frɒɡ/',
    'turtle': '/ˈtɜːr.təl/',

    // Food & Kitchen
    'rice': '/raɪs/',
    'water': '/ˈwɔː.tər/',
    'bread': '/brɛd/',
    'milk': '/mɪlk/',
    'apple': '/ˈæp.əl/',
    'banana': '/bəˈnæn.ə/',
    'fruit': '/fruːt/',
    'vegetable': '/ˈvɛdʒ.tə.bəl/',
    'vegetables': '/ˈvɛdʒ.tə.bəlz/',
    'egg': '/ɛɡ/',
    'meat': '/miːt/',
    'fish_food': '/fɪʃ/',
    'spoon': '/spuːn/',
    'fork': '/fɔːrk/',
    'knife': '/naɪf/',
    'plate': '/pleɪt/',
    'cup': '/kʌp/',
    'bowl': '/boʊl/',
    'glass': '/ɡlæs/',
    'pot': '/pɒt/',
    'pan': '/pæn/',
    'stove': '/stoʊv/',
    'refrigerator': '/rɪˈfrɪdʒ.ə.reɪ.tər/',

    // Body
    'head': '/hɛd/',
    'hair': '/hɛər/',
    'eye': '/aɪ/',
    'eyes': '/aɪz/',
    'ear': '/ɪər/',
    'ears': '/ɪərz/',
    'nose': '/noʊz/',
    'mouth': '/maʊθ/',
    'tooth': '/tuːθ/',
    'teeth': '/tiːθ/',
    'throat': '/θroʊt/',
    'hand': '/hænd/',
    'hands': '/hændz/',
    'foot': '/fʊt/',
    'feet': '/fiːt/',
    'finger': '/ˈfɪŋ.ɡər/',
    'arm': '/ɑːrm/',
    'leg': '/lɛɡ/',
    'shoulder': '/ˈʃoʊl.dər/',

    // Colors & Shapes
    'red': '/rɛd/',
    'blue': '/bluː/',
    'green': '/ɡriːn/',
    'yellow': '/ˈjɛl.oʊ/',
    'black': '/blæk/',
    'white': '/waɪt/',
    'orange': '/ˈɒr.ɪndʒ/',
    'purple': '/ˈpɜːr.pəl/',
    'pink': '/pɪŋk/',
    'brown': '/braʊn/',
    'circle': '/ˈsɜːr.kəl/',
    'square': '/skwɛər/',
    'triangle': '/ˈtraɪ.æŋ.ɡəl/',

    // Places / Community
    'school_place': '/skuːl/',
    'hospital': '/ˈhɒs.pɪ.təl/',
    'market': '/ˈmɑːr.kɪt/',
    'church': '/tʃɜːrtʃ/',
    'park': '/pɑːrk/',
    'house': '/haʊs/',
    'street': '/striːt/',
    'bridge': '/brɪdʒ/',
    'store': '/stɔːr/',
  };

  /// Returns the IPA transcription for a given word.
  static String getIPA(String word) {
    final clean = word.trim().toLowerCase();
    if (_ipaDictionary.containsKey(clean)) {
      return _ipaDictionary[clean]!;
    }
    return '/$clean/';
  }

  /// Identifies the primary phonological sound category for absent English sounds in Cebuano.
  static String detectSoundKey(String? explicitTipKey, String word) {
    if (explicitTipKey != null && explicitTipKey.trim().isNotEmpty) {
      return explicitTipKey.trim();
    }

    final lower = word.trim().toLowerCase();

    // Voiceless TH (/θ/) or Voiced TH (/ð/)
    if (lower.contains('th')) {
      if (lower == 'the' ||
          lower == 'this' ||
          lower == 'that' ||
          lower == 'mother' ||
          lower == 'father' ||
          lower == 'brother' ||
          lower == 'grandmother' ||
          lower == 'grandfather' ||
          lower == 'together' ||
          lower == 'weather' ||
          lower == 'feather') {
        return 'th_voiced';
      }
      return 'th_sound';
    }

    // /v/ sound (absent in Cebuano, often substituted with /b/)
    if (lower.contains('v')) {
      return 'v_sound';
    }

    // /f/ sound (absent in Cebuano, often substituted with /p/)
    if (lower.contains('f') || lower.contains('ph')) {
      return 'f_sound';
    }

    // /ʃ/ (sh sound)
    if (lower.contains('sh')) {
      return 'sh_sound';
    }

    // /tʃ/ (ch sound)
    if (lower.contains('ch')) {
      return 'ch_sound';
    }

    // /dʒ/ (j / dge sound)
    if (lower.contains('j') || lower.contains('dge') || lower.contains('ge')) {
      return 'j_sound';
    }

    // /z/ sound
    if (lower.contains('z')) {
      return 'z_sound';
    }

    // English /r/ vs rolled Cebuano /r/
    if (lower.contains('r')) {
      return 'r_sound';
    }

    return 'general';
  }

  /// Returns a rich, localized phonological articulation tip for Cebuano learners.
  static String getPhonologicalTip({
    String? tipKey,
    required String word,
    String? languagePreference,
  }) {
    final key = detectSoundKey(tipKey, word);
    final pref = (languagePreference ?? 'CEBUANO_TO_ENGLISH').toUpperCase();

    if (pref == 'CEBUANO_TO_ENGLISH') {
      switch (key) {
        case 'v_sound':
          return "Ang /v/ nga tingog wala sa Cebuano (kanunay madungog sama sa /b/). "
              "Ibutang ang imong ibabaw nga ngipon sa imong ubos nga ngabil, unya pag-hum samtang nagpagawas og hangin aron mag-vibrate. "
              "Ehemplo: 'stove' (dili 'stob'), 'vegetable' (dili 'begetable').";
        case 'f_sound':
          return "Ang /f/ nga tingog wala sa Cebuano (kanunay mapulihan og /p/). "
              "Ipatong ang imong ibabaw nga ngipon sa ubos nga ngabil ug pagbuga og hangin nga walay tingog sa tutunlan. "
              "Ehemplo: 'fork' (dili 'pork'), 'knife' (dili 'nayp').";
        case 'th_sound':
          return "Ang /θ/ (TH) nga tingog wala sa Cebuano (kasagaran masaypan og /t/). "
              "Ibutang ang tumoy sa imong dila taliwala sa imong ibabaw ug ubos nga ngipon, unya hinayhi pagbuga ang hangin. "
              "Ehemplo: 'teeth' (dili 'tit'), 'mouth' (dili 'mawt'), 'throat'.";
        case 'th_voiced':
          return "Ang voiced /ð/ (TH) sama sa 'mother' o 'this'. "
              "Ibutang ang tumoy sa dila taliwala sa mga ngipon ug pag-hum aron maramdam ang tingog (dili /d/). "
              "Ehemplo: 'mother' (dili 'mader'), 'father' (dili 'pader').";
        case 'sh_sound':
          return "Ang /ʃ/ (SH) nga tingog: I-porma ang imong mga ngabil nga lingin ug pagbuga og humok nga hangin (sama sa pag-ingon og 'shhh'). "
              "Ehemplo: 'fish', 'dishes', 'shoulder'.";
        case 'ch_sound':
          return "Ang /tʃ/ (CH) nga tingog: Sugdi sa /t/ dayon paspas nga sundi sa /sh/. "
              "Ehemplo: 'chair', 'church', 'chicken', 'kitchen'.";
        case 'j_sound':
          return "Ang /dʒ/ (J) nga tingog: Sama sa /ch/ apan gamita ang imong tingog aron mag-vibrate ang tutunlan. "
              "Ehemplo: 'juice', 'orange', 'bridge'.";
        case 'z_sound':
          return "Ang /z/ nga tingog: Pormaon ang baba sama sa /s/ apan mag-hum aron mag-vibrate (sama sa tingog sa putyokan). "
              "Ehemplo: 'eyes', 'nose', 'scissors'.";
        case 'r_sound':
          return "Ang English /r/ dili linukot (dili rolled). "
              "Ikurba ang imong dila pabalik sa sulod sa baba nga dili makatandog sa atop sa imong alingagngag. "
              "Ehemplo: 'rice', 'red', 'ruler'.";
        default:
          return "Paminawa og maayo ang audio playback. I-kopya ang porma sa baba ug lituka ang matag syllable nga hinay ug klaro.";
      }
    } else if (pref == 'CEBUANO_ENGLISH_MIXED') {
      switch (key) {
        case 'v_sound':
          return "Tip (V): Ang /v/ sound kay wala sa Cebuano (often masaypan og /b/). "
              "I-touch lang imong upper teeth sa lower lip unya i-vibrate imong voice. "
              "Example: 'stove' (dili 'stob'), 'vegetable' (dili 'begetable').";
        case 'f_sound':
          return "Tip (F): Ang /f/ sound kay dili /p/. "
              "I-rest lang imong upper teeth sa lower lip unya blow og air without using your voice. "
              "Example: 'fork' (dili 'pork'), 'knife' (dili 'nayp').";
        case 'th_sound':
          return "Tip (TH): Ang /θ/ sound kay absent sa Cebuano (dili /t/). "
              "Ibutang gamay ang tip sa imong tongue between sa upper ug lower teeth, unya blow og air smoothly. "
              "Example: 'teeth' (dili 'tit'), 'mouth' (dili 'mawt'), 'throat'.";
        case 'th_voiced':
          return "Tip (Voiced TH): Sama sa 'mother' or 'this'. "
              "Ibutang imong tongue between sa teeth unya pag-hum aron mo-buzz imong throat (dili /d/ like 'mader'). "
              "Example: 'mother' (dili 'mader'), 'father' (dili 'pader').";
        case 'sh_sound':
          return "Tip (SH): I-round gamay imong lips unya blow og gentle air mura kag nag-ingon og 'shhh' (e.g. 'fish', 'dishes').";
        case 'ch_sound':
          return "Tip (CH): Start sa /t/ sound dayon quick release ngadto sa /sh/ (e.g. 'chair', 'kitchen').";
        case 'j_sound':
          return "Tip (J): Himoa ang /ch/ sound pero i-turn on imong voice aron mo-vibrate imong tutunlan (e.g. 'juice', 'orange').";
        case 'z_sound':
          return "Tip (Z): I-shape imong mouth like /s/ pero pag-hum aron mag-buzz mura og bee (e.g. 'eyes', 'nose').";
        case 'r_sound':
          return "Tip (R): Don't roll your tongue! I-curve lang pabalik sulod sa baba nga dili mo-touch sa roof sa mouth (e.g. 'rice', 'red').";
        default:
          return "Paminawa og usab ang audio unya i-copy ang mouth shape ug rhythm pag-ayo.";
      }
    } else {
      // FULL_ENGLISH
      switch (key) {
        case 'v_sound':
          return "The /v/ sound does not exist in Cebuano and is often confused with /b/. "
              "Gently place your upper front teeth on your lower lip and turn your voice on to feel the vibration. "
              "Practice: 'stove', 'vegetable', 'voice'.";
        case 'f_sound':
          return "The /f/ sound is absent in Cebuano and is often substituted with /p/. "
              "Rest your upper front teeth on your lower lip and push air out without vocal vibration. "
              "Practice: 'fork' (not 'pork'), 'knife', 'fish'.";
        case 'th_sound':
          return "The voiceless /θ/ (TH) sound is absent in Cebuano (often heard as /t/). "
              "Place the tip of your tongue gently between your upper and lower front teeth, then blow air out smoothly. "
              "Practice: 'teeth', 'mouth', 'think'.";
        case 'th_voiced':
          return "The voiced /ð/ (TH) sound is heard in 'mother' and 'this' (different from /d/). "
              "Put your tongue between your teeth and vibrate your vocal cords. "
              "Practice: 'mother', 'father', 'brother'.";
        case 'sh_sound':
          return "For the /ʃ/ (SH) sound, round your lips slightly and blow gentle air out like saying 'shhh'. "
              "Practice: 'fish', 'dishes', 'shoulder'.";
        case 'ch_sound':
          return "For the /tʃ/ (CH) sound, start with /t/ and immediately release into /sh/. "
              "Practice: 'chair', 'kitchen', 'church'.";
        case 'j_sound':
          return "For the /dʒ/ (J) sound, make the /ch/ sound while buzzing your vocal cords. "
              "Practice: 'juice', 'orange', 'bridge'.";
        case 'z_sound':
          return "For the /z/ sound, make an /s/ shape with your mouth and hum like a buzzing bee. "
              "Practice: 'eyes', 'nose', 'scissors'.";
        case 'r_sound':
          return "English /r/ is not rolled. Keep your tongue curled slightly back without touching the roof of your mouth. "
              "Practice: 'rice', 'red', 'ruler'.";
        default:
          return "Listen to the correct pronunciation audio again. Match the mouth shape and speak clearly syllable by syllable.";
      }
    }
  }

  /// Formats comparison between what the student pronounced and the correct IPA target.
  static String formatPhoneticComparison({
    required String targetWord,
    String? transcribedText,
  }) {
    final targetIpa = getIPA(targetWord);
    if (transcribedText != null && transcribedText.trim().isNotEmpty) {
      final heardClean = transcribedText.trim().toLowerCase();
      final heardIpa = getIPA(heardClean);
      return 'Target: $targetIpa  •  Heard: $heardIpa ("$transcribedText")';
    }
    return 'Target: $targetIpa';
  }
}
