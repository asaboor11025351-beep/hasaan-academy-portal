# HASAAN Academy App (PWA + Android)

HASAAN SCIENCE & ENGLISH LANGUAGE ACADEMY, Mubarakpur — mobile-first management app source.

## Included in this project
- Installable Progressive Web App (PWA): manifest, service-worker generation, app icons made from the academy logo, standalone display, auto-update.
- Android project configuration using Capacitor. The `android/` native project is generated locally with the command below.
- Supabase Auth and Postgres database integration from the web starter.
- Classes 6th–12th, class/date attendance, student register, administrator-only monthly fee records, absent/unpaid report PNG exports.
- Role-based database security via Row Level Security policies in `supabase/schema.sql`.
- Responsive UI and logo.

## Important status
This is the app source project, not an already-published app. It has not been connected to a live Supabase project, hosted domain, Google Play account, or signed APK. Those steps require the academy owner's accounts and secrets. Do not put a Supabase service-role key in the app.

The Android native folder is intentionally generated on your machine by Capacitor; this avoids shipping machine-specific Gradle files. Running `npm run android:add` creates it.

## A. Configure the online backend
1. Create a Supabase project at https://supabase.com/.
2. Open Supabase SQL Editor and run all of `supabase/schema.sql`.
3. Disable public sign-ups in Supabase Auth.
4. Copy `.env.example` to `.env` and set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` to your project URL and public anon/publishable key.
5. Create staff accounts in Supabase Authentication. Add corresponding `profiles` rows and `teacher_classes` rows as explained below.

### First administrator
Create an auth user in Supabase Dashboard → Authentication → Users, copy its UUID, then run:
```sql
insert into public.profiles (id, display_name, role)
values ('AUTH-USER-UUID', 'Academy Administrator', 'admin');
```

### Teacher account and class assignment
Create each teacher as an Auth user, then:
```sql
insert into public.profiles (id, display_name, role)
values ('TEACHER-AUTH-UUID', 'Teacher Name', 'teacher');

insert into public.teacher_classes (profile_id, class_name)
values ('TEACHER-AUTH-UUID', '6th'),
       ('TEACHER-AUTH-UUID', '7th');
```
Use only the classes assigned to the teacher. Fee records are restricted by database policy to administrators.

## B. Run as an installable web app (PWA)
Requirements: Node.js 20+ recommended.
```bash
npm install
npm run dev
```
For a production build:
```bash
npm run build
npm run preview
```
Deploy the `dist/` directory to an HTTPS host such as Vercel or Netlify. Set the two Vite environment variables in the hosting provider. Then open the HTTPS website on Android Chrome and choose **Install app** / **Add to Home screen**. PWA installation requires HTTPS (localhost is allowed for development).

## C. Generate Android Studio project and APK
Install Node.js and Android Studio on a computer. Android SDK and a compatible JDK must be installed through Android Studio.
```bash
npm install
npm run build
npm run android:add
npm run cap:sync
npm run android:open
```
Android Studio opens the generated `android/` project. Let Gradle sync finish, select a device/emulator, then Run. To generate an installable APK, use **Build → Build Bundle(s) / APK(s) → Build APK(s)**. For distribution, create a signed Android App Bundle/APK using **Build → Generate Signed Bundle / APK** and keep the signing key private.

After any web code changes, run:
```bash
npm run build
npm run cap:sync
```
Do not use a development server URL for a production release. The app uses bundled assets and the Supabase HTTPS API.

## D. Test before real student data
- Test the PWA install flow on Android Chrome.
- Test Android build on a physical phone.
- Create at least two teachers assigned to different classes; verify each cannot query another class.
- Verify a teacher cannot read fee rows through the API, not just through the UI.
- Test absent/unpaid report images and month/date selection.
- Enable MFA for admin, use strong passwords, keep public sign-ups off, configure backups, and review privacy requirements.
- Fee tracking records payments; it does not process online payments.
- Offline shell assets may load, but attendance and fee operations require network connectivity to Supabase. Student/fee API responses are intentionally not cached.
