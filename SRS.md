# Software Requirements Specification (SRS)
## Vocaboo: English Vocabulary Learning Application for Grade 4-6 Learners

---

## Table of Contents
1. Introduction
2. Overall Description
3. Functional Requirements
4. Feature Specifications
5. Appendices

---

## 1. Introduction

### 1.1 Purpose
This document specifies the functional and non-functional requirements for Vocaboo, an English vocabulary learning application designed specifically for Grade 4-6 learners in the Philippines using Cebuano-English language support.

### 1.2 Scope
Vocaboo is a mobile application (Android and iOS) that delivers:
- Interactive vocabulary lessons aligned to DepEd Grade 4-6 curriculum
- Adaptive learning paths based on learner performance
- Multiple language medium preferences (Cebuano, English, Mixed)
- Gamified progression system with badges and unlock mechanisms
- Sandbox mode for vocabulary exploration

### 1.3 Target Users
- Primary: Students in Grade 4, 5, and 6
- Secondary: Teachers monitoring learner progress
- Tertiary: Parents/Guardians viewing achievement data

---

## 2. Overall Description

### 2.1 Product Perspective
Vocaboo operates as a standalone mobile application with backend support via Spring Boot REST API and Supabase for data persistence.

### 2.2 Product Features
- User onboarding and profile management
- Lesson progression and vocabulary instruction
- Performance-based unlock system
- Gamification elements (badges, points, streaks)
- Sandbox mode for exploration
- Admin panel for content management
- Confusable word pair management

### 2.3 Technology Stack
- Frontend: Flutter (mobile)
- Backend: Spring Boot (REST API)
- Database: Supabase (PostgreSQL)
- Authentication: PIN-based for learners, credential-based for admins

---

## 3. Functional Requirements

### 3.1 Learner Management
- FR-3.1: System shall support learner account creation during onboarding
- FR-3.2: System shall support PIN verification for returning learners
- FR-3.3: System shall store learner profiles in Supabase with encrypted PIN storage
- FR-3.4: System shall allow learners to update language medium preference anytime

### 3.2 Lesson Management
- FR-3.5: System shall organize vocabulary lessons by grade level (4, 5, 6)
- FR-3.6: System shall display lessons in sequence aligned to DepEd scope and sequence
- FR-3.7: System shall track learner progress within each lesson
- FR-3.8: System shall calculate accuracy and completion metrics

### 3.3 Gamification
- FR-3.9: System shall award badges upon lesson completion
- FR-3.10: System shall track learner streaks (consecutive daily sessions)
- FR-3.11: System shall display points earned per activity
- FR-3.12: System shall unlock new lessons based on mastery criteria

### 3.4 Admin Functions
- FR-3.13: Admin shall manage vocabulary content
- FR-3.14: Admin shall configure confusable word pairs
- FR-3.15: Admin shall view analytics on learner performance

---

## 4. Feature Specifications

### 4.1 Onboarding and Profile Setup

#### Use Case: UC-1.1 — Onboarding and Profile Setup

**Use Case ID:** UC-1.1  
**Actor:** Child Learner  
**Precondition:** The application is installed on an Android device and is being launched for the first time. No learner profile exists on the device.

**Main Flow:**
1. The system displays the welcome screen showing the Vocaboo application name and a brief description of the app.
2. The system prompts the learner to enter their name.
3. The learner enters their name.
4. The system prompts the learner to enter their age.
5. The learner enters their age.
6. The system prompts the learner to set an account PIN or password to secure their profile.
7. The learner enters a PIN or password.
8. The system prompts the learner to confirm the PIN or password.
9. The learner confirms the PIN or password.
10. The system presents the three Language Medium Preference options: Cebuano-to-English, Full English, and Cebuano/English Mixed.
11. The learner selects one Language Medium Preference option.
12. The system saves the learner profile including name, age, PIN, and language preference to local storage.
13. The system loads the home screen displaying all available lessons aligned to the DepEd Grade 4 through Grade 6 vocabulary scope and sequence.

**Alternative Flow A — PIN Mismatch:**
- A1. At step 9, if the confirmed PIN does not match the entered PIN, the system displays an error message indicating the PINs do not match.
- A2. The system clears both PIN fields and prompts the learner to re-enter and confirm the PIN.
- A3. Flow returns to step 7.

**Alternative Flow B — Missing Required Fields:**
- B1. At step 3 or step 5, if the learner attempts to proceed without entering a name or age, the system displays a validation message indicating the field is required.
- B2. The system does not advance until all required fields are filled.
- B3. Flow returns to the incomplete field.

**Alternative Flow C — Returning User:**
- C1. If a learner profile already exists on the device, the system skips the onboarding flow entirely.
- C2. The system displays the PIN or password entry screen.
- C3. The learner enters their PIN or password.
- C4. If correct, the system loads the home screen directly.
- C5. If incorrect, the system displays an error and prompts the learner to try again.

**Postcondition:** A learner profile is created and saved locally. The Language Medium Preference is set. The home screen is displayed with all available lessons.

---

### 4.2 Lesson Progression and Display

#### Use Case: UC-2.1 — View Lessons and Select Difficulty

**Use Case ID:** UC-2.1  
**Actor:** Child Learner  
**Precondition:** Learner has completed onboarding and is authenticated.

**Main Flow:**
1. The system displays the home screen with all available lessons organized by grade level.
2. The system shows lesson status (locked, in-progress, completed) with visual indicators.
3. The learner browses lessons aligned to their current grade level.
4. The learner selects a lesson.
5. The system displays the lesson detail screen with vocabulary items.
6. The learner begins the lesson activities.

**Postcondition:** Learner is engaged with lesson content.

---

### 4.3 Lesson Progression and Unlock System

#### Use Case: UC-3.1 — Lesson Unlock Based on Mastery

**Use Case ID:** UC-3.1  
**Actor:** Child Learner  
**Precondition:** Learner has completed a lesson.

**Main Flow:**
1. The system evaluates learner performance in the completed lesson.
2. If accuracy is ≥75%, the system marks the lesson as "Mastered."
3. The system unlocks the next lesson in sequence.
4. The system awards the learner a badge and points.
5. The system displays a congratulations screen.

**Alternative Flow — Below Mastery Threshold:**
- A1. If accuracy is <75%, the system marks the lesson as "In Progress."
- A2. The system recommends the learner review the lesson.
- A3. The system allows the learner to replay the lesson.

**Postcondition:** Learner progress is updated. Next lesson is unlocked if mastery achieved.

---

### 4.4 Sandbox Mode

#### Use Case: UC-4.1 — Explore Vocabulary in Sandbox

**Use Case ID:** UC-4.1  
**Actor:** Child Learner  
**Precondition:** Learner has authenticated and is on the home screen.

**Main Flow:**
1. The system displays a "Sandbox Mode" button on the home screen.
2. The learner taps Sandbox Mode.
3. The system displays all vocabulary words across all grades without lesson structure.
4. The learner can search or filter vocabulary by grade or category.
5. The learner selects a word to view its definition, pronunciation, example, and confusable pairs.
6. The system does not award points or affect progression when in Sandbox Mode.
7. The learner can return to home screen by tapping a back button.

**Postcondition:** Learner has explored vocabulary without affecting progression.

---

### 4.5 Gamification and Badges

#### Use Case: UC-5.1 — Earn Badges and Track Achievements

**Use Case ID:** UC-5.1  
**Actor:** Child Learner  
**Precondition:** Learner has completed lessons.

**Main Flow:**
1. The system tracks learner achievements (lessons completed, accuracy, streak).
2. Upon reaching milestones (e.g., 3 consecutive days, 10 lessons completed), the system awards a badge.
3. The system displays the badge achievement screen with animation.
4. The learner is redirected to the achievements/badges screen.
5. The system displays all earned and locked badges.

**Postcondition:** Learner's badge collection is updated.

---

### 4.6 Admin Content Management

#### Use Case: UC-6.1 — Manage Vocabulary Content

**Use Case ID:** UC-6.1  
**Actor:** Administrator  
**Precondition:** Admin is authenticated via credentials.

**Main Flow:**
1. The system displays the admin dashboard.
2. Admin navigates to Vocabulary Management.
3. Admin can add, edit, or delete vocabulary items.
4. Admin associates vocabulary with grade levels and lessons.
5. Admin specifies example sentences and pronunciation guides.
6. The system saves changes to Supabase.

**Postcondition:** Vocabulary content is updated in the system.

---

## 5. Appendices

### A.1 Language Preferences

| Preference | Description |
|---|---|
| Cebuano-to-English | Instructions appear in Cebuano first, followed by English. Optimal for learners fluent in Cebuano starting English learning. |
| Full English | All instructions are in English only. For learners with intermediate to advanced English proficiency. |
| Cebuano/English Mixed | Cebuano for explanations and context, English for task directions. Balanced support for language transition. |

### A.2 Learner Profile Schema

| Field | Type | Description |
|---|---|---|
| id | INTEGER | Unique identifier (Primary Key) |
| name | TEXT | Learner's name |
| age | INTEGER | Learner's age |
| pin | TEXT | Encrypted PIN for account security |
| language_preference | TEXT | Preferred language mode |
| created_at | TIMESTAMP | Account creation timestamp |
| grade_level | INTEGER | Current grade (4, 5, or 6) |

### A.3 Confusable Word Pair Management

Confusable word pairs are sets of words that learners commonly confuse due to similar spelling, pronunciation, or meaning. The Admin shall manage these pairs to support instruction.

**Confusable Pair Schema:**

| Field | Type | Description |
|---|---|---|
| id | INTEGER | Unique identifier |
| word_1 | TEXT | First word in the pair |
| word_2 | TEXT | Second word in the pair |
| difference_explanation | TEXT | Explanation of how the words differ |
| example_1 | TEXT | Example using word_1 |
| example_2 | TEXT | Example using word_2 |

**Example Pairs:**
- "Accept" vs. "Except"
- "Affect" vs. "Effect"
- "Their" vs. "There" vs. "They're"

### A.4 Glossary

- **Mastery:** Learner achieves ≥75% accuracy in a lesson.
- **Streak:** Consecutive days of active learning sessions.
- **Badge:** Digital achievement awarded for completing milestones.
- **Sandbox Mode:** Unrestricted vocabulary exploration without progression impact.
- **DepEd:** Philippine Department of Education curriculum standards.

---

## Document History

| Version | Date | Author | Changes |
|---|---|---|---|
| 1.0 | 2026-04-29 | Project Team | Initial SRS with Use Cases |

---

**End of Document**
