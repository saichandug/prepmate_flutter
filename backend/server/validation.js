export function meaningfulText(value) {
  const text = String(value ?? "").trim();
  return text.length > 0 && /[A-Za-z]/.test(text);
}

export function validateApplication(form) {
  const errors = {};

  const companyError = validateCompanyName(form.company);
  if (companyError) {
    errors.company = companyError;
  }

  const roleError = validateJobRole(form.role);
  if (roleError) {
    errors.role = roleError;
  }

  if (!form.interviewDate) {
    errors.interviewDate = "Interview date is required.";
  } else {
    const date = new Date(`${form.interviewDate}T00:00:00`);
    if (Number.isNaN(date.getTime())) {
      errors.interviewDate = "Enter a valid interview date.";
    }
  }

  const preparation = Number(form.preparationHours);
  if (!Number.isFinite(preparation) || preparation <= 0 || preparation > 24 || !/^\d+(\.\d+)?$/.test(String(form.preparationHours).trim())) {
    errors.preparationHours = "Enter a valid positive preparation time.";
  }

  if (!form.experience) {
    errors.experience = "Select an experience level.";
  }

  if (!form.status) {
    errors.status = "Select an application status.";
  }

  const jdError = validateJD(form.jd);
  if (jdError) errors.jd = jdError === "Job Description Too Short" ? "Job description is too short." : jdError;

  return errors;
}


export function validateJobRole(value) {
  const role = String(value ?? "").trim();

  if (!role) return "Job role is required.";
  if (role.length < 2) return "Please enter a valid job role.";
  if (role.length > 120) return "Job role is too long.";

  // Allow normal role-name characters only.
  if (!/^[A-Za-z0-9&/().,+\- ]+$/.test(role)) {
    return "Please enter a valid job role.";
  }

  const normalized = role.toLowerCase().replace(/\s+/g, " ").trim();
  const words = normalized.split(" ").filter(Boolean);
  const lettersOnly = normalized.replace(/[^a-z]/g, "");
  const vowelCount = (lettersOnly.match(/[aeiou]/g) || []).length;

  // Common software/technology and business job-role terms.
  const roleTerms = [
    "engineer", "engineering", "developer", "development", "programmer", "programming",
    "software", "frontend", "front-end", "backend", "back-end", "fullstack", "full-stack",
    "web", "mobile", "android", "ios", "qa", "tester", "testing", "quality",
    "devops", "cloud", "data", "analyst", "analytics", "scientist", "machine learning",
    "ai", "artificial intelligence", "ml", "security", "cybersecurity", "database", "dba",
    "designer", "design", "ui", "ux", "product", "manager", "management", "consultant",
    "consulting", "architect", "administrator", "admin", "support", "intern", "internship",
    "trainee", "associate", "specialist", "lead", "director", "developer", "sde", "sdet",
    "dev", "technical", "technology", "technologist", "researcher", "scientist"
  ];

  const normalizedTerms = roleTerms.map((term) => term.toLowerCase());
  const hasRoleTerm = normalizedTerms.some((term) =>
    term.includes(" ") ? normalized.includes(term) : words.includes(term)
  );

  if (hasRoleTerm) return "";

  // Common short role acronyms are valid even without vowels.
  const knownAcronyms = new Set([
    "sde", "sdet", "swe", "qa", "dba", "devops", "ml", "ai", "ui", "ux", "pm", "ba"
  ]);
  if (words.length === 1 && knownAcronyms.has(normalized)) return "";

  // Reject obvious keyboard-smash/repeated-character input.
  if (/(.)\1{3,}/i.test(lettersOnly)) {
    return "Please enter a meaningful job role.";
  }

  // A single long word without a recognized role term is unlikely to be a
  // meaningful job title (for example, "sdfdsg").
  if (words.length === 1 && lettersOnly.length >= 6) {
    if (vowelCount < 2) {
      return "Please enter a valid job role (for example, Software Engineer).";
    }
  }

  // For multi-word custom titles, require reasonable alphabetic content.
  if (words.length >= 2 && lettersOnly.length >= 4 && vowelCount >= 1) {
    return "";
  }

  return "Please enter a valid job role (for example, Software Engineer).";
}


export function validateCompanyName(value) {
  const company = String(value ?? "").trim();

  if (!company) return "Company name is required.";
  if (company.length < 2) return "Please enter a valid company name.";
  if (company.length > 100) return "Company name is too long.";

  // Allow normal company-name characters only.
  if (!/^[A-Za-z0-9&.,'()\- ]+$/.test(company)) {
    return "Please enter a valid company name.";
  }

  const normalized = company.toLowerCase().replace(/\s+/g, " ").trim();

  // Common well-known companies that may not contain a normal company suffix.
  const knownCompanies = new Set([
    "google", "microsoft", "amazon", "apple", "meta", "adobe", "ibm",
    "oracle", "infosys", "tcs", "wipro", "accenture", "deloitte",
    "cognizant", "capgemini", "flipkart", "zoho", "salesforce", "intel",
    "nvidia", "netflix", "uber", "paypal", "visa", "mastercard", "tesla"
  ]);

  if (knownCompanies.has(normalized)) return "";

  // Common words used in legitimate company names.
  const companySuffix = /\b(technologies|technology|solutions|systems|software|labs|lab|services|consulting|digital|industries|limited|ltd|inc|corp|corporation|pvt|private|group|enterprises|enterprise|ventures|works|studio|studios|ai)\b/i;
  if (companySuffix.test(company)) return "";

  const words = normalized.split(/\s+/).filter(Boolean);
  const lettersOnly = normalized.replace(/[^a-z]/g, "");
  const vowelCount = (lettersOnly.match(/[aeiou]/g) || []).length;
  const consonantCount = (lettersOnly.match(/[bcdfghjklmnpqrstvwxyz]/g) || []).length;

  // Reject obvious keyboard-smash/gibberish patterns.
  if (/(.)\1{3,}/i.test(lettersOnly)) {
    return "Please enter a meaningful company name.";
  }

  // A single long word with no company suffix is likely random text unless
  // it looks like a known/acronym-style company name.
  if (words.length === 1 && lettersOnly.length >= 6) {
    const looksLikeAcronym = lettersOnly.length <= 5 && vowelCount === 0;
    const looksMeaningful = vowelCount >= 2 && consonantCount >= 2 && !/(.)\1{2,}/i.test(lettersOnly);

    if (!looksMeaningful && !looksLikeAcronym) {
      return "Please enter a meaningful company name (for example, ABC Technologies).";
    }
  }

  // A two-or-more-word name is generally acceptable when it contains
  // reasonable alphabetic content.
  if (words.length >= 2 && lettersOnly.length >= 3 && (vowelCount >= 1 || company.length <= 5)) {
    return "";
  }

  return "Please enter a meaningful company name.";
}

export function validateJD(text) {
  const value = String(text ?? "").trim();
  if (!value) return "Job description is required.";
  if (value.length < 30) return "Job Description Too Short";

  // Do not accept random/gibberish text just because it is long enough.
  const words = value.toLowerCase().match(/[a-z][a-z+#.-]*/g) || [];
  const meaningfulWords = words.filter((word) => word.length >= 2);
  if (meaningfulWords.length < 8) {
    return "Please enter a complete and meaningful job description.";
  }

  const jobTerms = [
    "job", "role", "position", "engineer", "developer", "candidate", "responsibilities",
    "responsibility", "requirements", "requirement", "experience", "skills", "skill", "team",
    "work", "working", "build", "develop", "design", "maintain", "implement", "knowledge",
    "qualification", "qualifications", "hiring", "looking", "years", "degree", "bachelor",
    "master", "intern", "internship", "software", "technology", "technologies", "project"
  ];

  const skillTerms = [
    "java", "python", "javascript", "typescript", "c", "c++", "sql", "html", "css", "react",
    "node", "rest", "api", "arrays", "array", "strings", "string", "linked", "list", "stack",
    "queue", "trees", "tree", "graphs", "graph", "hashmap", "database", "mysql", "postgresql",
    "mongodb", "machine", "learning", "deep", "nlp", "generative", "aws", "azure", "cloud",
    "git", "github", "docker", "linux", "communication", "problem", "solving", "teamwork",
    "collaboration", "leadership"
  ];

  const hasJobLanguage = jobTerms.some((term) => meaningfulWords.includes(term));
  const hasSkill = skillTerms.some((term) => meaningfulWords.includes(term));

  if (!hasJobLanguage && !hasSkill) {
    return "Please enter a meaningful job description with job responsibilities, requirements, experience, or skills.";
  }

  return "";
}
