# LearnCodz

## Current release: 1.0.11 (build 12)

Includes an immediate startup screen while storage and authentication initialize, removal of the second timed splash, an Android launch logo, and deliberate pull-to-refresh gestures that ignore accidental touches. Also includes the redesigned learning screens, coding missions, smart review, achievements, bundled animations and expanded quizzes.

Validation: Android release build and APK signature/package/asset checks passed; 21 startup, account and mission tests passed; code analysis reported no issues. Physical phone startup timing still needs device testing. APKs and local caches are excluded from this source repository.

A playful, single-user Flutter programming tutor by **Zulkifal Khan & Jamal Akbar Khan**.

## November 3 design update

The home screen now has a personal greeting, a continue-learning card, daily goals and medal previews. Practice uses a responsive colored card grid. The Learning Room has an original code illustration, section icons and mini tasks; the quiz mode picker uses a bottom sheet. Profile has its own overview and separate editing route. Progress shows five mastery topics initially, with See All for the complete list.

There are 22 achievement medals with progress indicators and All / Unlocked filters. Medals derive from existing saved learning data, including XP, perfect lessons, historical streaks, bookmarks, study time, challenges and languages learned. No new account or database setup is required for the design update. No APK was built for this update; use Chrome during development.

## Run on this PC

Open D:\QuizQuest in VS Code, then run:

    cd D:\QuizQuest
    powershell -ExecutionPolicy Bypass -File .\run.ps1

Stop an older running version with q before restarting. The launcher directs project dependency downloads, temporary files and Gradle cache to D:. The existing Flutter SDK stays in its existing location. The browser and OS manage their own profiles. A fixed web port preserves browser progress between launches.

## Your first visit

An animated QuizQuest logo and original cartoon buddy welcome you. Choose C++, Python, Java or C before entering the learning path. Use the language chip on Overview, Learn or Progress to switch later. Each path retains its own scores, bookmarks, mistake IDs and mastery records. Global XP includes all earned chapter XP. The previous Dart course data is retained internally for migration and regression testing.

## Courses and activities

Each language has 18 chapters across three stages, starting with: Hello World, variables, decisions, loops, functions and lists/arrays. Lessons explain how to run the first full program, include short examples, and give mini tasks. Later snippets identify where statements belong. Each chapter has three Easy questions and three separate Difficult questions: 72 lessons and 720 course question variants across four languages, plus 32 coding lab activities.

The language-specific Coding lab adds eight exercises per language (32 total), covering Output Detective, Fill the Gap, Code Shuffle and Bug Hunt. Reorder with drag handles or accessible up/down buttons. Code examples are educational; the app does not execute arbitrary user code.

Pass 2 of 3 questions to unlock the next chapter. A chapter's best score contributes 20 XP per correct answer. Repeating an unchanged best score does not farm XP. The daily challenge gives five current-language questions, with a 30-second timer and a 30-XP completion bonus once per language per local calendar day.

## Pacing and animation

Choose Easy (core basics, untimed) or Difficult (code reasoning, 30 seconds per question) before a chapter quiz. Coding-lab mode changes timing; its hands-on question set remains the same. The daily challenge is always timed. Settings are remembered.

Optional Auto-next waits five seconds after checked feedback or a timeout, then advances to the next question/results. The visible countdown has Pause and Enable controls. Pause to read longer; manual Next also works. Auto-next does not skip lesson reading or automatically save final results. It pauses while an exit dialog is open or the app is backgrounded. Normal question timers can continue while an exit dialog is open, as explained in that dialog.

Finite entrance bounces, tactile buttons, smooth progress, answer pops/shakes, completion buddies and confetti make feedback clear. Reduced-motion preferences disable decorative entrance, shake and confetti animations. No animation service or paid API is required.

## Profile and credits

Use Edit profile to save a name, @gmail.com address and one of four original cartoon buddies. This is a device-local profile, not Google login or email verification. Developer credits appear on the splash and profile screens: Zulkifal Khan & Jamal Akbar Khan.

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

## Expanded roadmap and Code Playground â€” version 1.0.2 (3)

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

## Google sign-in - 1.0.4 (5)

The sign-in screen now includes Continue with Google. Supabase opens an external
browser on Android, then handles the PKCE callback through app_links. Android
registers com.learncodz.app://login-callback/ and opts out of Flutter's competing
default deep-link handler. CloudGate waits for a real Auth session event and
prepares/restores the account before showing the learning screens. Email/password
login continues to work. Browser launch success is not a successful login.

Enable the Google provider and configure the Web OAuth client and redirect URLs
using supabase/GOOGLE-SIGN-IN-SETUP.md. Client secrets belong only in Supabase.
A public settings check gives a clear message while the provider is disabled.
Real Google login remains unverified until the owner completes provider setup.


## Profile cleanup - 1.0.5 (6)

Google sign-in seeds missing profile name and email from the authenticated Google
account after existing cloud progress loads. Edited profile fields are preserved,
and new defaults are uploaded to the same private backup. Google metadata is used
for display only; database authorization continues to use the Supabase user ID.
Overview now has no edit-profile shortcut. Profile editing remains in Profile.


## Sign-in icons and motion - 1.0.6 (7)

Google sign-in uses the official Google G image; Name, Email and Password fields
have matching person, envelope and lock icons. The password eye toggle remains.
Sign-in and Profile enter with finite fade/slide/scale motion, buttons have press
feedback, and sign-in has a loading transition. Device reduced-motion settings
disable entrance/press movement and replace the loading spinner with a static icon.
Name personalizes the profile; Google fills missing name/email automatically.
Email/password is an alternative sign-in method, not required for Google sign-in.


## Quiz Arcade, sound refresh and reminders - 1.0.7 (8)

- Four new questions per chapter across the four languages: 288 additional
  questions, 720 course question variants in total (plus the coding labs).
- Practice > Quiz Arcade: choose an unlocked chapter and a 5/10-question round.
  Save a completed round to claim 10 XP per newly correct question. Repeat answers
  do not pay twice. Reward IDs persist locally and in Supabase backups. Original
  three-question lesson scores and roadmap unlocks are unchanged.
- Original soft keyboard/chime audio replaces the previous WAV files. Profile
  offers previews for Tap, Correct, Retry, Lesson done and XP reward.
- Google/person/email/lock icons and sign-in/Profile entrance, press and loading
  effects are included; reduced-motion settings are respected.
- Android reminders use a high-importance channel, explicit permission checks,
  queued-schedule verification, and a notification-settings shortcut. Release
  shrinking now applies the notification/Gson keep rules. No exact-alarm access,
  full-screen alarm or Firebase setup is required for these local reminders.
- Normal reminder UI stays simple. Diagnostics/test/settings are collapsed under
  Having trouble?; there is no keep-the-app-open instruction in the Android flow.

Verification: 52 tests passed (one opt-in live compiler test skipped), analysis
clean, with a separate phone-sized Arcade reward/anti-duplication test. Notification
tests simulate Android plugin channels; physical phone delivery still needs testing.
OS notification permissions, DND and battery restrictions can affect delivery.

## Smart Review and answer feedback

Practice now includes Smart Review. Saved course answers schedule topic reviews at 1, 3, 7, 14 and 30 days when a round reaches 80% accuracy. Weaker rounds return the next day. Same-day repeats do not advance the spacing level. Existing studied topics without a review date appear as due. Reviews are untimed, prioritize saved mistakes, and award no extra XP or chapter unlocks. Review dates live inside existing topic mastery data and use the existing progress backup.

Answer feedback compares the selected answer with the correct answer or code order, followed by the authored question explanation. Feedback is available for all course and practice questions. Each new question opens at the top.

## Navigation cleanup

Daily Challenge has one entry under Overview â†’ Daily Goal. Practice contains Smart Review, Quiz Arcade, Code Playground and focused coding activities. The learning toolkit contains goals, bookmarks, mastery and reminder controls; its duplicate coding-lab launcher was removed.

Profile â†’ Edit Profile changes personal details and the learning buddy. Profile â†’ App Settings manages the existing account/backup controls, sound preferences, reminder access and Reset my progress. Reset is no longer on Progress. Reset still requires confirmation and clears learning progress while keeping profile details.

## Guided coding missions and lesson sandbox

Practice â†’ Coding Missions offers three beginner missions in each of C++, Python, Java and C: doubling a number, a pass-score checker, and an even/odd detector. Each mission has a three-step brief, expandable hints and three executable test cases. Check all test cases sends the current code and each test input to the existing online compiler. Completion is recorded only when every response succeeds and the actual output matches the expected output (line endings and outer whitespace are normalized). Editing code clears the displayed test results. Mission completions are practice records, with no extra XP.

Learning Room â†’ Try this code opens the lesson example in a separate sandbox draft; regular Playground work is preserved. Function and recursion examples include a demonstration entry point for C, C++ and Java. Mission and lesson drafts, mission completions, and seen achievement notifications participate in the existing progress backup. There is no database schema change.

Compiler failures include a rule-based explanation alongside raw diagnostics. Highlight line is offered only when a line can be mapped to the user's source; hints are suggestions, not guaranteed fixes. New achievement notifications are animated, nonblocking and deduplicated for saved milestones. Developer credits appear only in App Settings â†’ About developers.

## Focused screens

Profile includes identity, a course progress ring with XP/level/streak stats, editing and settings navigation. Course completion and detailed topic mastery appear in Progress, including coding-lab accuracy when there are saved lab attempts. The toolkit focuses on daily goals, bookmarks and reminders. The extra toolkit shortcut on Progress was removed. The full generated compiler program remains available under the collapsed Advanced: full program section.

## Animated navigation and refresh

The five main tabs use a curved bottom bar with a raised active icon in LearnCodz green. The active indicator slides between tabs and respects reduced-motion preferences. Wide layouts retain their sidebar.

Pull down on the main screens to reveal the learning buddy and refresh header. Short pages can also be pulled. Overview and Profile offer a Refresh progress button for mouse and keyboard users. Refresh saves local study settings and asks the existing backup service to sync when signed in. Cloud conflicts or unavailable service are reported without replacing local progress.

Profile â†’ App Settings â†’ Account & cloud backup now has a full-width Logout button. It retains the existing confirmation and account-specific sign-out behavior. This source update does not rebuild or replace the APK.

## Offline Lottie animations

LearnCodz bundles three unmodified Animated Noto Emoji Lottie files by Google (CC BY 4.0): fire for the web-only daily streak popup, a growing seedling while refreshing, and a party popper for saved achievements, quiz results and completed coding missions. The Lottie player is pinned to 3.2.0 for Flutter 3.27 compatibility. Artwork plays from local assets, at 30 fps, with static symbols when reduced motion is enabled. Refresh loops are mounted only while refreshing; celebrations play once.

Replay the effects in Profile â†’ App Settings â†’ Animation credits â†’ Preview animations. Attribution, source URLs, downloaded file hashes and the full license are stored in assets/animations. Open-source licenses are accessible from the same Settings section.

## Copyright

Copyright (c) 2026 **Zulkifal Khan and Jamal Akbar Khan**. All rights reserved.

See [COPYRIGHT](COPYRIGHT) for the notice covering original LearnCodz materials.
No open-source license is granted for those materials. Third-party assets and
dependencies retain their own licenses and notices, including the
[Animated Noto Emoji attribution](assets/animations/NOTICE.txt) and
[Google branding source](assets/branding/SOURCE.txt).

## Release code protection

The Android build script enables Dart symbol obfuscation and keeps per-build debug
symbols under the ignored `work/release-symbols/` directory on D:. Preserve these
files privately for diagnosing crashes. Android release optimization remains enabled.
These settings apply to future builds made through `build-apk.ps1`; the previously
built 1.0.11 APK has not been regenerated with them.

Obfuscation makes compiled symbols harder to interpret. It does not encrypt assets,
hide this public repository, or prevent someone from recreating visible screens.
The copyright notice states the ownership and permissions for original materials.
