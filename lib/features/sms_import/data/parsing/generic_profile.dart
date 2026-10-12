import '../../domain/entities/sms_import_enums.dart';
import 'bank_profile.dart';

/// The generic fallback profile (FR-028, FR-041): no senders, no
/// signatures, no templates. It is used when no bank profile matches, and
/// every field it reads is capped at Medium with the `genericParser`
/// warning. It assumes day-month order (Egyptian convention, FR-036) and
/// no default currency.
final BankProfile genericProfile = BankProfile(
  id: genericProfileId,
  version: 1,
  isGeneric: true,
  dateOrder: DateOrder.dayMonth,
  refIsUnique: false,
);

/// The generic profile id.
const String genericProfileId = 'generic';

/// The shared Arabic and English keyword tables (parser-contract §5, §8).
///
/// Bank profiles run their own rules first; these apply to every message.
/// Phrases are folded on construction, so they are written naturally.
/// Arabic phrases match as substrings (attached prefixes and suffixes);
/// Latin phrases match on word boundaries.
class GenericRules {
  GenericRules._();

  static final GenericRules instance = GenericRules._();

  // --- Eligibility (parser-contract §5) -----------------------------------

  /// Step 1: OTP. Wins over everything. These phrases alone are enough.
  final KeywordSet otp = KeywordSet(const [
    'otp',
    'one time password',
    'one-time password',
    'one time pin',
    'one-time pin',
    'one time code',
    'one-time code',
    'verification code',
    'activation code',
    'security code',
    'passcode',
    'رمز التحقق',
    'رمز التفعيل',
    'رمز المرور',
    'كود التحقق',
    'كود التفعيل',
    'كلمة المرور المؤقتة',
    'كلمة المرور لمرة واحدة',
    'كلمة السر لمرة واحدة',
    'الرقم السري المؤقت',
  ]);

  /// Step 1, weak: a safety reminder or a bare "code" word. It means OTP
  /// only together with a standalone 4-8 digit code (`Your code is 482913.
  /// Do not share it.`); a purchase that ends with "Never share your card
  /// details" or pays "using a QR code" (`رمز QR`) is not an OTP.
  final KeywordSet otpWeak = KeywordSet(const [
    'do not share',
    "don't share",
    'never share',
    'code',
    'pin',
    'لا تشارك',
    'رمز',
    'رمزك',
    'كود',
  ], arabicWordStart: true);

  /// Step 2: declined or failed.
  final KeywordSet declined = KeywordSet(const [
    'declined',
    'failed',
    'insufficient',
    'unsuccessful',
    'rejected',
    'not approved',
    'could not be completed',
    'was not completed',
    'مرفوض',
    'مرفوضة',
    'تم رفض',
    'فشل',
    'فشلت',
    'غير ناجحة',
    'لم تتم',
    'رصيد غير كاف',
    'رصيدك غير كاف',
  ]);

  /// Step 3: pending authorization (only without a posted verb).
  final KeywordSet pendingAuthorization = KeywordSet(const [
    'authorization',
    'authorisation',
    'authorized',
    'pre-auth',
    'preauth',
    'pre-authorization',
    'on hold',
    'pending',
    'قيد التنفيذ',
    'حجز',
    'معلقة',
    'تفويض',
  ]);

  /// Step 4: authorization reversal of money that never posted (FR-024b).
  final KeywordSet authorizationReversal = KeywordSet(const [
    'authorization reversed',
    'authorisation reversed',
    'authorization reversal',
    'reversal of authorization',
    'authorization cancelled',
    'authorization canceled',
    'authorization has been cancelled',
    'hold released',
    'hold has been released',
    'released the hold',
    'pre-auth released',
    'preauth released',
    'إلغاء الحجز',
    'فك الحجز',
    'تحرير الحجز',
    'إلغاء التفويض',
  ]);

  /// Step 5: promotion (only without a posted verb). Marketing words
  /// that mark a promotion even when transaction vocabulary is present
  /// (`0% installment on purchases`). Arabic words must start a word
  /// (`عرض` never matches `معرض`).
  final KeywordSet promotion = KeywordSet(const [
    'offer',
    'offers',
    'discount',
    'cashback',
    'promo',
    'promotion',
    'win',
    'limited time',
    'get up to',
    'apply now',
    '%',
    'عرض',
    'عروض',
    'تخفيض',
    'خصومات',
    'اربح',
    'استمتع',
    'لفترة محدودة',
    'كاش باك',
    'هدية',
  ], arabicWordStart: true);

  /// Step 5, weak: a link or soft marketing word. A promotion only when no
  /// transaction kind matched either (`Purchase of EGP 250.00 at Example
  /// Cafe. Visit www.example.com` is a purchase).
  final KeywordSet promotionWeak = KeywordSet(const [
    'deal',
    'enjoy',
    'visit',
    'http',
    'www',
    'زوروا',
    'تفضل بزيارة',
  ], arabicWordStart: true);

  /// A posted refund or reversal: such a message mentioning a failed
  /// transaction is a refund, not a decline.
  final KeywordSet refundPosted = KeywordSet(const [
    'refunded',
    'has been credited',
    'have been credited',
    'was credited',
    'credited to your',
    'تم استرداد',
    'تم رد',
    'تم استرجاع',
    'تم إيداع',
    'تمت إضافة',
    'تم إضافة',
  ]);

  /// Step 5b: a due-date or installment reminder (only without a posted
  /// verb): `NonTransactional(other)`. `statement` / `كشف حساب` alone are
  /// not listed: a statement fee is a real debit.
  final KeywordSet dueReminder = KeywordSet(
    const [
      'reminder',
      'is due',
      'due on',
      'due by',
      'due date',
      'total due',
      'amount due',
      'payment due',
      'تذكير',
      'مستحق',
      'مستحقة',
      'تاريخ الاستحقاق',
      'موعد السداد',
      'موعد سداد',
    ],
    arabicWordStart: true,
    arabicWordEnd: true,
  );

  /// Step 6 and amount tagging: balance and limit vocabulary. A money
  /// token right after one of these is never the transaction amount.
  final KeywordSet balance = KeywordSet(const [
    'balance',
    'bal',
    'available',
    'avl',
    'avail',
    'ledger',
    'limit',
    'رصيد',
    'المتاح',
    'الحد الائتماني',
    'حد الائتمان',
  ]);

  /// Amount tagging: fee vocabulary (FR-030a).
  final KeywordSet fee = KeywordSet(const [
    'fee',
    'fees',
    'commission',
    'charges',
    'service charge',
    'رسوم',
    'رسم',
    'عمولة',
    'مصاريف',
  ]);

  /// Posted debit verbs.
  final KeywordSet debitVerbs = KeywordSet.merge([
    KeywordSet(const [
      'debited',
      'deducted',
      'withdrawn',
      'charged',
      'spent',
      'paid',
      'debit of',
      'تم خصم',
      'خصم مبلغ',
      'تم الخصم',
      'تم سحب',
      'سحب مبلغ',
      'تم دفع',
      'تم الدفع',
      'تمت عملية سحب',
      'تمت عملية خصم',
      'تمت عملية دفع',
      'تمت عملية الدفع',
      'تمت عملية الخصم',
      'تمت عملية السحب',
      'عملية مدينة',
      'حركة مدينة',
      'معاملة مدينة',
    ]),
    // A whole word: `مدينة` alone is also "city" (`فرع مدينة نصر`).
    KeywordSet(const ['مدين'], arabicWordStart: true, arabicWordEnd: true),
  ]);

  /// Posted credit verbs.
  final KeywordSet creditVerbs = KeywordSet(const [
    'credited',
    'deposited',
    'received',
    'credit of',
    'added to your account',
    'تم إيداع',
    'إيداع',
    'تم إضافة',
    'تمت إضافة',
    'تمت عملية إيداع',
    'تمت عملية إضافة',
    'إضافة مبلغ',
    'أضيف',
    'دائن',
    'تم استلام',
  ]);

  /// Words right before a currency-less amount (`debited with 250.00`).
  final KeywordSet amountLead = KeywordSet(const [
    'amount',
    'amt',
    'with',
    'by',
    'of',
    'value',
    'debited',
    'credited',
    'deducted',
    'charged',
    'withdrawn',
    'deposited',
    'مبلغ',
    'بمبلغ',
    'المبلغ',
    'قيمة',
    'بقيمة',
  ]);

  // --- Kind rules, in priority order (parser-contract §8) -----------------

  late final List<KindRule> kindRules = [
    KindRule(
      SmsKind.refund,
      SmsDirection.credit,
      KeywordSet(const [
        'refund',
        'refunded',
        'chargeback',
        'returned to your account',
        'استرداد',
        'مرتجع',
        'رد مبلغ',
        'استرجاع',
      ]),
    ),
    KindRule(
      SmsKind.ownAccountTransfer,
      SmsDirection.unknown,
      KeywordSet(const [
        'own account',
        'between your accounts',
        'between accounts',
        'to your savings',
        'from your savings',
        'to your own account',
        'بين حساباتك',
        'إلى حسابك الآخر',
        'من حسابك الآخر',
        'إلى حساب التوفير',
        'من حساب التوفير',
      ]),
    ),
    KindRule(
      SmsKind.cardOrLoanSettlement,
      SmsDirection.debit,
      KeywordSet(const [
        'credit card payment',
        'card bill payment',
        'installment',
        'instalment',
        'loan payment',
        'loan installment',
        'minimum payment',
        'converted to installments',
        'سداد البطاقة',
        'سداد بطاقة',
        'سداد مستحقات',
        'قسط',
        'أقساط',
        'سداد القرض',
        'تقسيط',
      ]),
    ),
    KindRule(
      SmsKind.salary,
      SmsDirection.credit,
      KeywordSet(const ['salary', 'payroll', 'wages', 'راتب', 'مرتب', 'رواتب']),
    ),
    KindRule(
      SmsKind.atmWithdrawal,
      SmsDirection.debit,
      KeywordSet(const [
        'atm',
        'cash withdrawal',
        'صراف',
        'ماكينة',
        'سحب نقدي',
        'سحب نقدى',
      ]),
    ),
    KindRule(
      SmsKind.billPayment,
      SmsDirection.debit,
      KeywordSet(const ['bill payment', 'bill', 'utility', 'فاتورة', 'فواتير']),
    ),
    KindRule(
      SmsKind.transferIn,
      SmsDirection.credit,
      KeywordSet(const [
        'transfer received',
        'received a transfer',
        'received from',
        'incoming transfer',
        'transferred to your account',
        'تحويل وارد',
        'استلام تحويل',
        'حوالة واردة',
        'إلى حسابك',
        'لحسابك',
      ]),
    ),
    KindRule(
      SmsKind.transferOut,
      SmsDirection.debit,
      KeywordSet(const [
        'transfer to',
        'transferred to',
        'sent to',
        'outgoing transfer',
        'تحويل صادر',
        'تم تحويل',
        'حوالة صادرة',
        'إرسال',
      ]),
    ),
    KindRule(
      SmsKind.cardPurchase,
      SmsDirection.debit,
      KeywordSet(const [
        'purchase',
        'purchased',
        'pos',
        'payment at',
        'paid at',
        'transaction at',
        'شراء',
        'مشتريات',
      ]),
    ),
  ];

  // --- Extraction anchors -------------------------------------------------

  /// Before a merchant name.
  final KeywordSet merchantLead = KeywordSet(const ['at', '@', 'لدى', 'عند']);

  /// Before a transfer-out counterparty.
  final KeywordSet counterpartyTo = KeywordSet(const ['to', 'إلى', 'الى']);

  /// Before a transfer-in counterparty.
  final KeywordSet counterpartyFrom = KeywordSet(const ['from', 'من']);

  /// Where a captured merchant or counterparty ends (a leading space is
  /// part of each phrase so it ends at a word).
  final List<String> nameStops = const [
    ' on ',
    ' using ',
    ' via ',
    ' عبر',
    ' with ',
    ' ref',
    ' card',
    ' from ',
    ' for ',
    ' to ',
    ' at ',
    ' avl',
    ' available',
    ' balance',
    ' بتاريخ',
    ' يوم',
    ' في ',
    ' رقم',
    ' الرصيد',
    ' رصيد',
    ' من ',
    ' إلى ',
    ' الى ',
    ' بمبلغ',
    ' مبلغ',
  ];

  /// A counterparty that is really the user's own account.
  final KeywordSet ownAccountTarget = KeywordSet(const [
    'your',
    'ur',
    'account',
    'a/c',
    'card',
    'حساب',
    'حسابك',
    'بطاقة',
  ]);

  /// Card or account words near a last-four token.
  final KeywordSet cardWords = KeywordSet(const [
    'card',
    'account',
    'acc',
    'a/c',
    'ending',
    'بطاقة',
    'بطاقتك',
    'حساب',
    'حسابك',
    'المنتهية',
    'المنتهي',
  ]);

  /// The shared merchant keyword table: keyword -> seed key (FR-055).
  late final List<MerchantKeywordRule> merchantKeywordRules = [
    MerchantKeywordRule(
      KeywordSet(const [
        'cafe',
        'coffee',
        'restaurant',
        'pizza',
        'burger',
        'grill',
        'مطعم',
        'كافيه',
        'قهوة',
        'مشويات',
      ]),
      'restaurants',
    ),
    MerchantKeywordRule(
      KeywordSet(const [
        'supermarket',
        'hypermarket',
        'grocery',
        'market',
        'سوبر ماركت',
        'ماركت',
        'بقالة',
      ]),
      'groceries',
    ),
    MerchantKeywordRule(
      KeywordSet(const ['fuel', 'petrol', 'gas station', 'وقود', 'بنزين']),
      'fuel',
    ),
    MerchantKeywordRule(
      KeywordSet(const [
        'pharmacy',
        'hospital',
        'clinic',
        'صيدلية',
        'مستشفى',
        'عيادة',
      ]),
      'medical',
    ),
    MerchantKeywordRule(
      KeywordSet(const ['taxi', 'metro', 'ride', 'مترو', 'تاكسي']),
      'transportation',
    ),
    MerchantKeywordRule(
      KeywordSet(const ['subscription', 'اشتراك']),
      'subscriptions',
    ),
  ];

  /// Bill keyword -> seed key, for bill payments.
  late final List<MerchantKeywordRule> billKeywordRules = [
    MerchantKeywordRule(
      KeywordSet(const ['electricity', 'electric', 'كهرباء']),
      'electricity',
    ),
    MerchantKeywordRule(KeywordSet(const ['water', 'مياه']), 'water'),
    MerchantKeywordRule(
      KeywordSet(const ['internet', 'adsl', 'broadband', 'إنترنت', 'انترنت']),
      'internet',
    ),
    MerchantKeywordRule(
      KeywordSet(const [
        'phone',
        'mobile',
        'landline',
        'recharge',
        'تليفون',
        'موبايل',
        'هاتف',
        'شحن رصيد',
      ]),
      'phone',
    ),
  ];
}

/// A generic kind rule: matching keywords fix the kind and direction.
class KindRule {
  KindRule(this.kind, this.direction, this.keywords);

  final SmsKind kind;

  /// [SmsDirection.unknown] means "from the posted verbs".
  final SmsDirection direction;
  final KeywordSet keywords;
}
