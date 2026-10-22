// Port of src/utils/validation.js. Each validate* function returns an empty
// string when the value is valid, otherwise the error message.

String _str(Object? v) => (v ?? '').toString();

String validateJobRole(Object? value) {
  final role = _str(value).trim();

  if (role.isEmpty) return 'Job role is required.';
  if (role.length < 2) return 'Please enter a valid job role.';
  if (role.length > 120) return 'Job role is too long.';

  if (!RegExp(r'^[A-Za-z0-9&/().,+\- ]+$').hasMatch(role)) {
    return 'Please enter a valid job role.';
  }

  final normalized = role.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  final words = normalized.split(' ').where((w) => w.isNotEmpty).toList();
  final lettersOnly = normalized.replaceAll(RegExp(r'[^a-z]'), '');
  final vowelCount = RegExp(r'[aeiou]').allMatches(lettersOnly).length;

  const roleTerms = [
    'engineer',
    'engineering',
    'developer',
    'development',
    'programmer',
    'programming',
    'software',
    'frontend',
    'front-end',
    'backend',
    'back-end',
    'fullstack',
    'full-stack',
    'web',
    'mobile',
    'android',
    'ios',
    'qa',
    'tester',
    'testing',
    'quality',
    'devops',
    'cloud',
    'data',
    'analyst',
    'analytics',
    'scientist',
    'machine learning',
    'ai',
    'artificial intelligence',
    'ml',
    'security',
    'cybersecurity',
    'database',
    'dba',
    'designer',
    'design',
    'ui',
    'ux',
    'product',
    'manager',
    'management',
    'consultant',
    'consulting',
    'architect',
    'administrator',
    'admin',
    'support',
    'intern',
    'internship',
    'trainee',
    'associate',
    'specialist',
    'lead',
    'director',
    'developer',
    'sde',
    'sdet',
    'dev',
    'technical',
    'technology',
    'technologist',
    'researcher',
    'scientist',
  ];

  final hasRoleTerm = roleTerms.any(
    (term) =>
        term.contains(' ') ? normalized.contains(term) : words.contains(term),
  );
  if (hasRoleTerm) return '';

  const knownAcronyms = {
    'sde',
    'sdet',
    'swe',
    'qa',
    'dba',
    'devops',
    'ml',
    'ai',
    'ui',
    'ux',
    'pm',
    'ba',
  };
  if (words.length == 1 && knownAcronyms.contains(normalized)) return '';

  if (RegExp(r'(.)\1{3,}', caseSensitive: false).hasMatch(lettersOnly)) {
    return 'Please enter a meaningful job role.';
  }

  if (words.length == 1 && lettersOnly.length >= 6) {
    if (vowelCount < 2) {
      return 'Please enter a valid job role (for example, Software Engineer).';
    }
  }

  if (words.length >= 2 && lettersOnly.length >= 4 && vowelCount >= 1) {
    return '';
  }

  return 'Please enter a valid job role (for example, Software Engineer).';
}

String validateCompanyName(Object? value) {
  final company = _str(value).trim();

  if (company.isEmpty) return 'Company name is required.';
  if (company.length < 2) return 'Please enter a valid company name.';
  if (company.length > 100) return 'Company name is too long.';

  if (!RegExp(r"^[A-Za-z0-9&.,'()\- ]+$").hasMatch(company)) {
    return 'Please enter a valid company name.';
  }

  final normalized = company
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  const knownCompanies = {
    'google',
    'microsoft',
    'amazon',
    'apple',
    'meta',
    'adobe',
    'ibm',
    'oracle',
    'infosys',
    'tcs',
    'wipro',
    'accenture',
    'deloitte',
    'cognizant',
    'capgemini',
    'flipkart',
    'zoho',
    'salesforce',
    'intel',
    'nvidia',
    'netflix',
    'uber',
    'paypal',
    'visa',
    'mastercard',
    'tesla',
  };
  if (knownCompanies.contains(normalized)) return '';

  final companySuffix = RegExp(
    r'\b(technologies|technology|solutions|systems|software|labs|lab|services|consulting|digital|industries|limited|ltd|inc|corp|corporation|pvt|private|group|enterprises|enterprise|ventures|works|studio|studios|ai)\b',
    caseSensitive: false,
  );
  if (companySuffix.hasMatch(company)) return '';

  final words = normalized
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  final lettersOnly = normalized.replaceAll(RegExp(r'[^a-z]'), '');
  final vowelCount = RegExp(r'[aeiou]').allMatches(lettersOnly).length;
  final consonantCount = RegExp(r'[bcdfghjklmnpqrstvwxyz]')
      .allMatches(lettersOnly)
      .length;

  if (RegExp(r'(.)\1{3,}', caseSensitive: false).hasMatch(lettersOnly)) {
    return 'Please enter a meaningful company name.';
  }

  if (words.length == 1 && lettersOnly.length >= 6) {
    final looksLikeAcronym = lettersOnly.length <= 5 && vowelCount == 0;
    final looksMeaningful =
        vowelCount >= 2 &&
        consonantCount >= 2 &&
        !RegExp(r'(.)\1{2,}', caseSensitive: false).hasMatch(lettersOnly);

    if (!looksMeaningful && !looksLikeAcronym) {
      return 'Please enter a meaningful company name (for example, ABC Technologies).';
    }
  }

  if (words.length >= 2 &&
      lettersOnly.length >= 3 &&
      (vowelCount >= 1 || company.length <= 5)) {
    return '';
  }

  return 'Please enter a meaningful company name.';
}

String validateJD(Object? text) {
  final value = _str(text).trim();
  if (value.isEmpty) return 'Job description is required.';
  if (value.length < 30) return 'Job Description Too Short';

  final words = RegExp(r'[a-z][a-z+#.\-]*')
      .allMatches(value.toLowerCase())
      .map((m) => m.group(0)!)
      .toList();
  final meaningfulWords = words.where((w) => w.length >= 2).toList();
  if (meaningfulWords.length < 8) {
    return 'Please enter a complete and meaningful job description.';
  }

  const jobTerms = [
    'job',
    'role',
    'position',
    'engineer',
    'developer',
    'candidate',
    'responsibilities',
    'responsibility',
    'requirements',
    'requirement',
    'experience',
    'skills',
    'skill',
    'team',
    'work',
    'working',
    'build',
    'develop',
    'design',
    'maintain',
    'implement',
    'knowledge',
    'qualification',
    'qualifications',
    'hiring',
    'looking',
    'years',
    'degree',
    'bachelor',
    'master',
    'intern',
    'internship',
    'software',
    'technology',
    'technologies',
    'project',
  ];

  const skillTerms = [
    'java',
    'python',
    'javascript',
    'typescript',
    'c',
    'c++',
    'sql',
    'html',
    'css',
    'react',
    'node',
    'rest',
    'api',
    'arrays',
    'array',
    'strings',
    'string',
    'linked',
    'list',
    'stack',
    'queue',
    'trees',
    'tree',
    'graphs',
    'graph',
    'hashmap',
    'database',
    'mysql',
    'postgresql',
    'mongodb',
    'machine',
    'learning',
    'deep',
    'nlp',
    'generative',
    'aws',
    'azure',
    'cloud',
    'git',
    'github',
    'docker',
    'linux',
    'communication',
    'problem',
    'solving',
    'teamwork',
    'collaboration',
    'leadership',
  ];

  final hasJobLanguage = jobTerms.any(meaningfulWords.contains);
  final hasSkill = skillTerms.any(meaningfulWords.contains);

  if (!hasJobLanguage && !hasSkill) {
    return 'Please enter a meaningful job description with job responsibilities, requirements, experience, or skills.';
  }

  return '';
}

/// Returns a map of field name -> error message. Empty map means valid.
Map<String, String> validateApplication(Map<String, dynamic> form) {
  final errors = <String, String>{};

  final companyError = validateCompanyName(form['company']);
  if (companyError.isNotEmpty) errors['company'] = companyError;

  final roleError = validateJobRole(form['role']);
  if (roleError.isNotEmpty) errors['role'] = roleError;

  final date = _str(form['interviewDate']).trim();
  if (date.isEmpty) {
    errors['interviewDate'] = 'Interview date is required.';
  } else if (DateTime.tryParse('${date}T00:00:00') == null) {
    errors['interviewDate'] = 'Enter a valid interview date.';
  }

  final prepText = _str(form['preparationHours']).trim();
  final prep = prepText.isEmpty
      ? 0.0
      : (double.tryParse(prepText) ?? double.nan);
  if (!prep.isFinite ||
      prep <= 0 ||
      prep > 24 ||
      !RegExp(r'^\d+(\.\d+)?$').hasMatch(prepText)) {
    errors['preparationHours'] = 'Enter a valid positive preparation time.';
  }

  if (_str(form['experience']).isEmpty)
    errors['experience'] = 'Select an experience level.';
  if (_str(form['status']).isEmpty)
    errors['status'] = 'Select an application status.';

  final jdError = validateJD(form['jd']);
  if (jdError.isNotEmpty) {
    errors['jd'] = jdError == 'Job Description Too Short'
        ? 'Job description is too short.'
        : jdError;
  }

  return errors;
}
