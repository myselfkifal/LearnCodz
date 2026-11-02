# LearnCodz

A playful, single-user Flutter programming tutor by **Zulkifal Khan & Jamal Khan**.

## Run on this PC

Open D:\QuizQuest in VS Code, then run:

    cd D:\QuizQuest
    powershell -ExecutionPolicy Bypass -File .\run.ps1

Stop an older running version with q before restarting. The launcher directs project dependency downloads, temporary files and Gradle cache to D:. The existing Flutter SDK stays in its existing location. The browser and OS manage their own profiles. A fixed web port preserves browser progress between launches.

## Your first visit

An animated QuizQuest logo and original cartoon buddy welcome you. Choose C++, Python, Java or C before entering the learning path. Use the language chip on Overview, Learn or Progress to switch later. Each path retains its own scores, bookmarks, mistake IDs and mastery records. Global XP includes all earned chapter XP. The previous Dart course data is retained internally for migration and regression testing.

## Courses and activities

Each language has six beginner chapters: Hello World, variables, decisions, loops, functions and lists/arrays. Lessons explain how to run the first full program, include short examples, and give mini tasks. Later snippets identify where statements belong. Each chapter has three Easy questions and three separate Difficult questions: 24 lessons and 144 question variants across four languages.

The language-specific Coding lab adds eight exercises per language (32 total), covering Output Detective, Fill the Gap, Code Shuffle and Bug Hunt. Reorder with drag handles or accessible up/down buttons. Code examples are educational; the app does not execute arbitrary user code.

Pass 2 of 3 questions to unlock the next chapter. A chapter's best score contributes 20 XP per correct answer. Repeating an unchanged best score does not farm XP. The daily challenge gives five current-language questions, with a 30-second timer and a 30-XP completion bonus once per language per local calendar day.

## Pacing and animation

Choose Easy (core basics, untimed) or Difficult (code reasoning, 30 seconds per question) before a chapter quiz. Coding-lab mode changes timing; its hands-on question set remains the same. The daily challenge is always timed. Settings are remembered.

Optional Auto-next waits five seconds after checked feedback or a timeout, then advances to the next question/results. The visible countdown has Pause and Enable controls. Pause to read longer; manual Next also works. Auto-next does not skip lesson reading or automatically save final results. It pauses while an exit dialog is open or the app is backgrounded. Normal question timers can continue while an exit dialog is open, as explained in that dialog.

Finite entrance bounces, tactile buttons, smooth progress, answer pops/shakes, completion buddies and confetti make feedback clear. Reduced-motion preferences disable decorative entrance, shake and confetti animations. No animation service or paid API is required.

## Profile and credits

Use Edit profile to save a name, @gmail.com address and one of four original cartoon buddies. This is a device-local profile, not Google login or email verification. Developer credits appear on the splash and profile screens: Zulkifal Khan & Jamal Khan.

## Mistake practice

Incorrect and timed-out questions enter the collection only when a completed quiz is saved. Overview and Progress show a practice card with the current language's pending count. Practice is untimed; correctly answered questions leave the collection when that completed practice attempt is saved. Incorrect answers remain. Practice records activity and mastery without changing chapter scores or awarding XP. Leaving an unfinished attempt changes no saved mistakes.

## Learning toolkit

- Daily mission: choose 5, 10 or 15 minutes; celebrate completion. Time counts while foregrounded and input occurred within the previous minute. Time is saved every 15 seconds and on lifecycle changes; abrupt termination can lose the most recent 14 seconds.
- Pocket library: bookmark a lesson in its app bar, reopen it or remove it in the toolkit.
- Skill map: cumulative correct/attempted answers by language and chapter, including practice. Historical attempts are not invented from legacy best scores.
- Learning nudge: optional daily reminder with time picker, permission handling, change-time and disable controls. Android uses inexact local-time notifications and boot receiver configuration. Battery policies can delay delivery. Browser notifications require permission and an open tab; closed-tab notifications are not supported. Native delivery requires real-device verification.

## Storage

Progress, profile and settings use shared_preferences on this device/browser. Clearing browser or app data removes them. Save & continue commits a quiz attempt. Reset learning progress clears scores, mistakes, activity, bookmarks, study time and mastery; reminder/profile/language preferences remain. No account or backend is required. Android content is offline; web needs an initial load from its host.

## Source

- lib/main.dart: navigation, dashboard, lesson/quiz flow, timers and score integration.
- lib/language_courses.dart: four course catalogs and language selection model.
- lib/lessons.dart: content models and retained legacy Dart content.
- lib/coding_questions.dart: language-specific interactive exercises and stable lab keys.
- lib/welcome_profile.dart: animated splash, original vector buddy, onboarding, profile and quiz preferences.
- lib/learning_hub.dart and learning_data.dart: goals, bookmarks, mastery and toolkit.
- lib/quest_widgets.dart and quest_motion.dart: reusable UI and finite animations.
- lib/reminders*.dart: platform-specific optional reminders.
- test/: regression tests and rendered phone/desktop previews.

The Duolingo-style learning path was independently implemented. No source code or image assets from the reference clone repositories were incorporated. Reference checkouts and backups live in work/, excluded from the source ZIP and release build. Android source is included; physical notification delivery and signed store release need device/developer setup.

## Reference-based visual redesign

The supplied six-screen reference now guides the app layout: white surfaces, near-black headings, green gradient actions, lavender buddy greeting, a two-column language picker, a connected vertical lesson path, pastel practice cards, light syntax-colored code blocks, and a progress ring with real mastery bars.

Main navigation now has five destinations: Overview, Learn, Practice, Progress and Profile. Practice cards open a filtered set for the selected exercise type. Profile editing is available directly from its tab as well as the home chip. Existing courses, persistence, bookmarks, goals, reminder settings, quiz difficulty and five-second auto-next remain connected. Progress numbers are calculated from stored data; preview test data is not shipped as user progress.

Additional UI components live in lib/reference_design.dart. Final phone renders are in test/goldens/reference_*_phone.png. All 22 regression tests pass, including navigation through the five tabs and selecting an exercise category.

## Android test APK

Display name: LearnCodz. Application ID: com.learncodz.app. Version 1.0.0 (1). Android release compilation uses a test/debug signing configuration for direct phone installation; it is not the final Play Store upload signing setup. Project folder and Dart package remain QuizQuest/quizquest internally so existing development paths stay usable.

## Sound update: LearnCodz 1.0.1 (2)

Five original synthesized PCM WAV cues are bundled offline in assets/sounds: tap, correct, incorrect, complete and achievement. No external sound samples are used. Correct/wrong checks, timeouts, completed quizzes, first chapter passes and daily goal completion trigger appropriate short feedback. Audio never blocks scoring or navigation; stale queued cues are discarded. Playback is stopped/suppressed while backgrounded and mixes without requesting audio focus from other music.

Profile > Sounds & feedback provides an on/off switch, saved volume slider and preview button. Sounds and volume are remembered locally. Browser playback can require an initial user gesture. Test playback uses an injected backend; actual device audibility should be checked after installing the update.

The updated Android APK is LearnCodz-v1.0.1.apk, version code 2, with the same package ID and test signing key as v1.0.0. Installing it as an update preserves app data. There are 26 passing tests, including mute/volume persistence, silent volume, nonfatal audio errors and background suppression.

## Expanded roadmap and Code Playground — version 1.0.2 (3)

Each of C++, Python, Java and C now has 18 chapters in three stages: Foundations, Working with Data and Problem Solving. The original six chapter IDs and questions remain unchanged; twelve chapters are appended per language. The app now includes 72 lessons, 432 Easy/Difficult question variants and 32 existing coding-lab exercises. New topics: input, operators, strings, while/nested loops, debugging, search, sorting, recursion, structured records, files and a grade-tracker mini-project. Daily challenges draw from unlocked chapters.

Practice > Code Playground runs real code online using Wandbox. C/C++ standard headers, namespace and main are supplied for statements; Java imports and entry-point scaffolding are supplied. Normal full programs with main are supported, with Java's main class adapted for the runner. Python is executed unchanged. The editor has per-language local drafts, stdin, output, compiler/runtime diagnostics, cancellation of waiting, request limits and a generated-program view. The service receives code and stdin only when Run is pressed, with public-link saving disabled. Availability and limits depend on the third-party service. No API key is embedded. Android Internet permission is included. Offline lessons and quizzes are unchanged.

Audio now uses standard MediaPlayer playback through Android's media stream, with normalized louder PCM clips and visible preview errors/retry behavior. Hardware volume buttons control media volume while this app is open. Sound failures remain nonfatal, and mute/volume preferences remain saved. Samsung A24 is the reported device; physical audibility still needs confirmation on that phone.

Overview no longer shows its profile-edit/name chip once both profile name and email are saved. The separate Profile tab remains available.

Validation: 33 regular tests passed; live compiler tests additionally ran all four languages with stdin and automatic setup, each producing 42. Code analysis passed. Native APK compilation and signing verification are recorded in deliverables/VALIDATION.txt.


## Supabase cloud accounts - 1.0.3 (4)

LearnCodz now connects to the owner-provided project tcxlovxkmnenwfaljfwy.
Email/password sign-up and login use Supabase Auth. Email confirmation follows
the project settings: confirm in email, return to the app, and sign in.

Profile > Account & cloud backup shows sync status, Sync now, Restore cloud backup,
and Sign out. Backups run every 20 seconds while the process is active.
Lessons work offline after signing in. Local progress remains when a request fails.
The first account can explicitly import the pre-cloud offline progress; it is not
automatically assigned to every new account. Account caches are isolated by user ID.

The learncodz_backups PostgreSQL table stores one JSONB state per auth user, including
profile/contact email, language, lesson scores, quiz history, bookmarks, mastery,
study time/goals, preferences and code drafts/input. XP and badges derive from
progress. Passwords are handled by Supabase Auth, not stored in this table.
An explicit preference allowlist excludes authentication sessions and cache metadata.

Supabase setup: supabase/setup.sql (already run by project owner). RLS permits only
the row matching auth.uid(); anonymous access is revoked. The client contains only
the publishable key. No service-role key is required. Revision-based conditional
updates detect concurrent device edits; conflicting local data is kept until the
user chooses Restore cloud backup. Automatic multi-device merging is not provided.

Verification: 43 tests passed, one opt-in live compiler test skipped. Cloud tests
use mocked authenticated API responses to verify isolation, restore, offline retry
and conditional updates. Real project Auth settings responded successfully and
anonymous table access was denied. Real authenticated upload/restore and cross-user
RLS still need verification with real confirmed accounts; no user password was supplied.
The current management connector is signed into a different Supabase account.

Before Play Store release, add account deletion, password recovery and production
signing, and verify database grants/RLS with two real accounts.
