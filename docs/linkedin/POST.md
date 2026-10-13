# LinkedIn post: Daftary

Two posts are below. Use **A** if you haven't announced Daftary yet. Use **B** if the launch post is already out and you want to share v1.2. Both share the same first comment.

---

## A. Launch post (English)

In Egypt, a lot of money moves between people, not categories. 💸

A loan to a friend. Rent a cousin covered. A wedding gift you'll return one day.
Most of it lives in our heads or in a paper notebook, a "daftar".

So I built Daftary (دفتري): a people-first personal finance app for Arabic-speaking users.

📱 What it does
• A running two-way balance per person: they owe you, you owe them, or settled, with partial repayments
• Occasions (weddings, births): who gave and who received what
• Income & expenses, monthly budgets, savings goals with a "what if" calculator
• Bank SMS import: your bank messages become suggested entries you review before adding
• Scan an old paper notebook: on-device OCR turns it into entries
• A change history on every financial record, so you can see what was edited and when
• Reports, full CSV export, and reminders based on your real data
• Arabic-first RTL + English, light/dark themes, multi-currency

🔒 Private by design
No account needed. Your data lives on your phone and works fully offline. Bank messages are read on the device by fixed rules, with no AI and no server, and are deleted once you decide. Cloud sync is optional, and the app locks with a PIN or fingerprint.

🛠 How it's built
• Flutter & Dart 3, Clean Architecture across 19 feature modules
• BLoC/Cubit, go_router, get_it + injectable
• Offline-first: Drift (SQLite) is the source of truth, synced to Supabase (Postgres + RLS) through a transactional outbox with conflict resolution
• Money stored as integer minor units with ISO 4217 currencies. No guessed exchange rates.
• 4,000+ automated tests, CI, and signed APK releases on GitHub Actions
• Every feature written as a spec first, then planned, then built

The hardest part wasn't a screen. It was trust. I ran a full accounting audit of my own app and fixed what it found: a repayment now shows what's left before you save it, paying more than is owed asks you to confirm, and a sync conflict on money is never resolved silently.

👉 Try it on Android today (link in the first comment). The iPhone version is coming soon.

What would you add to it? I'd really appreciate your feedback 🙏

#Flutter #MobileDevelopment #CleanArchitecture #OfflineFirst #FinTech

---

## B. Update post: v1.2 (English)

Daftary v1.2 is out. 🚀

Most Egyptians get a bank SMS for every card payment, transfer and salary. Until now, you still had to type each one into Daftary yourself.

Not anymore:

🏦 Bank SMS import
• Daftary turns your bank messages into suggested entries
• Nothing is saved until you check it and tap Add
• Parsing runs on your phone by fixed rules: no AI, no server
• Message text is masked, encrypted on the device and deleted once you decide
• Works by inbox scan, paste or share on Android, and by paste on iPhone

🧾 Change history
Every edit and delete of a transaction, an income or expense entry, or a savings contribution is logged. Open the record and see what changed and when.

✅ Money you can trust
I audited the whole app the way an accountant would, then fixed what I found:
• A repayment shows what's left before you save it
• Paying back more than is owed asks you to confirm
• A possible duplicate entry gets a warning
• A sync conflict on money is never resolved silently

The hardest engineering call: reading SMS is a sensitive permission. Daftary asks for it only when you turn the feature on, asks only to read (never send), and everything still works without it.

👉 Android APK in the first comment. Feedback welcome 🙏

#Flutter #FinTech #Privacy #MobileDevelopment #OfflineFirst

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
• رصيد لكل شخص في الاتجاهين: ليك عنده، عليك له، أو متسوّي، مع السداد على دفعات
• المناسبات (أفراح، مواليد): مين إدّى ومين أخد
• دخل ومصروفات، ميزانية شهرية، أهداف ادخار وتقارير
• رسايل البنك: بتتحول لعمليات مقترحة تراجعها قبل ما تضيفها
• تصوير الدفتر الورق وتحويله لعمليات بـ OCR على الموبايل نفسه
• سجل تعديلات لكل عملية: تعرف إيه اللي اتغير وإمتى
• عربي RTL حقيقي + إنجليزي، وضع فاتح وداكن، وعملات متعددة

🔒 خصوصيتك الأول
مش محتاج حساب، وبياناتك على موبايلك وشغالة من غير نت. رسايل البنك بتتقري على الموبايل بقواعد ثابتة، من غير ذكاء اصطناعي ومن غير سيرفر، وبتتمسح أول ما تقرر. والمزامنة مع السحابة اختيارية.

🛠 اتبنى إزاي
• Flutter و Dart 3 و Clean Architecture متقسمة لـ 19 feature module
• BLoC/Cubit و go_router و get_it + injectable
• Offline-first: قاعدة Drift (SQLite) على الموبايل هي المصدر الأساسي، ومزامنة مع Supabase عن طريق outbox وحل التعارضات
• أمان: PIN متشفّر بـ PBKDF2، بصمة، وتشفير AES-GCM لرسايل البنك
• أكتر من 4,000 تست، و CI وإصدار APK أوتوماتيك على GitHub Actions

أصعب حاجة ما كانتش شاشة، كانت الثقة في الأرقام. عملت مراجعة محاسبية كاملة للتطبيق وصلّحت اللي طلع: السداد بيوريك الباقي قبل الحفظ، والسداد الزيادة بيطلب تأكيد، وأي تعارض في الفلوس عمره ما بيتحل من غير ما تشوفه.

جرّبه بنفسك 👇
🤖 أندرويد: متاح دلوقتي (اللينك في أول كومنت)
🍎 آيفون: قريب

رأيكم يفرق معايا جدًا 🙏

#Flutter #Dart #MobileDevelopment #CleanArchitecture #Supabase

---

## LinkedIn profile → Projects section

**Name:** Daftary (دفتري): People-first Personal Finance App
**Skills:** Flutter · Dart · BLoC · Clean Architecture · SQLite · Supabase · PostgreSQL · Offline-first sync · Localization (RTL) · On-device ML (OCR) · Mobile security · GitHub Actions
**Media:** cover-1200x627.png + Daftary-carousel.pdf + docs/screenshots/en_bank_messages.png + docs/screenshots/en_change_history.png
**Link:** GitHub repo
**Description:**
A bilingual (Arabic RTL / English), offline-first Flutter app for Egyptian users. It tracks two-way money balances between people, along with occasions, income and expenses, budgets, savings goals and reports.

What's new in v1.2:
• Bank SMS import: bank messages become suggested entries the user reviews before adding. Parsing is rule-based and runs on the device, and message text is masked and encrypted (AES-GCM).
• Change history: every edit and delete of a financial record is logged and can be viewed from the record.
• Money checks: a full financial audit of the app led to a preview of what's left before a repayment, a confirmation for overpayments, possible-duplicate warnings and safer sync conflict handling.

Built with Clean Architecture across 19 feature modules, BLoC, Drift (SQLite) and Supabase sync through a transactional outbox with conflict resolution. It also includes on-device ML Kit OCR, a PBKDF2 app lock, multi-currency support, 4,000+ automated tests and signed APK releases on GitHub Actions. Every feature was built spec-first.
