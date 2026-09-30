# LinkedIn post: Daftary

## English (main post)

In Egypt, a lot of money moves between people, not categories. 💸

A loan to a friend. Rent a cousin covered. A wedding gift you'll return one day.
Most of it lives in our heads or in a paper notebook, a "daftar".

So I built Daftary (دفتري): a people-first personal finance app for Arabic-speaking users.

📱 What it does
• A running two-way balance per person: they owe you, you owe them, or settled, with partial repayments
• Occasions (weddings, births): who gave and who received what
• Income & expenses, monthly budgets, savings goals with a "what if" calculator
• Reports and CSV export
• Scan an old paper notebook: on-device OCR turns it into entries
• Smart reminders based on your real data, not generic tips
• Optional AI assistant that uses your own API key
• Arabic-first RTL + English, light/dark themes, multi-currency

🔒 Private by design
No account needed. Your data lives on your phone and works fully offline. Cloud backup and sync are optional, and the app is protected by a PIN or fingerprint.

🛠 How it's built
• Flutter & Dart 3, Clean Architecture split into 18 feature modules
• BLoC/Cubit, go_router, get_it + injectable
• Offline-first: Drift (SQLite) is the source of truth, synced to Supabase (Postgres + RLS) through a transactional outbox with conflict resolution
• Money stored as integer minor units with ISO 4217 currencies. No guessed exchange rates.
• 3,600+ unit, widget and bloc tests, plus CI and automated APK releases on GitHub Actions

The hardest (and most fun) part was offline-first sync for financial data. When two devices edit the same record, "last write wins" isn't acceptable when it's someone's money.

👉 Try it on Android today (link in the first comment). The iPhone version is coming soon.

What would you add to it? I'd really appreciate your feedback 🙏

#Flutter #MobileDevelopment #CleanArchitecture #OfflineFirst #FinTech

---

## First comment (post it right after publishing)

🤖 Android: https://github.com/AbdallahRehab/Daftary/releases/latest
Download the file ending in -arm64.apk, open it and allow "Install unknown apps".

💻 Source code: https://github.com/AbdallahRehab/Daftary

---

## Arabic version (optional)

في مصر، فلوس كتير بتتحرك بين الناس، مش بين "تصنيفات مصاريف". 💸

سلفة لصاحبك، إيجار دفعهولك ابن عمك، نقطة فرح هترجعها في يوم.
وأغلب ده متسجل في دماغنا أو في دفتر ورق.

عشان كده عملت دفتري (Daftary): تطبيق مالية شخصية بيبدأ من الناس.

📱 التطبيق بيعمل إيه
• رصيد لكل شخص في الاتجاهين: ليك عنده، عليك له، أو متسوّي
• المناسبات (أفراح، مواليد): مين إدّى ومين أخد
• دخل ومصروفات، ميزانية شهرية، أهداف ادخار وتقارير
• تصوير الدفتر الورق وتحويله لعمليات بـ OCR على الموبايل نفسه
• مساعد ذكاء اصطناعي اختياري بمفتاحك الخاص
• عربي RTL حقيقي + إنجليزي، وضع فاتح وداكن، وعملات متعددة

🛠 اتبنى إزاي
• Flutter و Dart 3 و Clean Architecture متقسمة لـ 18 feature module
• BLoC/Cubit و go_router و get_it + injectable
• Offline-first: قاعدة Drift (SQLite) على الموبايل هي المصدر الأساسي، ومزامنة مع Supabase عن طريق outbox وحل التعارضات
• أمان: PIN متشفّر بـ PBKDF2 وبصمة و secure storage
• أكتر من 3,600 تست، و CI وإصدار APK أوتوماتيك على GitHub Actions

جرّبه بنفسك 👇
🤖 أندرويد: متاح دلوقتي (اللينك في أول كومنت)
🍎 آيفون: قريب

رأيكم يفرق معايا جدًا 🙏

#Flutter #Dart #MobileDevelopment #CleanArchitecture #Supabase

---

## LinkedIn profile → Projects section

**Name:** Daftary (دفتري): People-first Personal Finance App
**Skills:** Flutter · Dart · BLoC · Clean Architecture · SQLite · Supabase · PostgreSQL · Offline-first sync · Localization (RTL)
**Media:** cover-1200x627.png + Daftary-carousel.pdf
**Link:** GitHub repo
**Description:**
A bilingual (Arabic RTL / English), offline-first Flutter app that tracks two-way money balances between people, along with income, budgets, savings goals and reports. It's built with Clean Architecture across 18 feature modules, BLoC, Drift (SQLite) and Supabase sync through a transactional outbox with conflict resolution. It also includes on-device ML Kit OCR, a PBKDF2 app lock, multi-currency support and 3,600+ automated tests.
