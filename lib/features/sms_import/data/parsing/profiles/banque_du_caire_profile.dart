import '../../../domain/entities/sms_import_enums.dart';
import '../bank_profile.dart';
import 'sms_template_kit.dart';

/// Banque du Caire.
///
/// SYNTHETIC and UNVERIFIED (orchestrator decision on OQ2/OQ3): built from
/// synthetic fixtures modeled on generic, public bank-SMS phrasing, never
/// on a real message. `verified: false` caps every result at Medium with
/// `SmsWarning.unverifiedProfile`; flipping it needs real anonymized
/// samples from the owner. Reference IDs are not known to be unique
/// (`refIsUnique: false`), and the default masking threshold (12) is
/// kept.
///
/// Fixtures: `test/fixtures/sms/banque_du_caire/`.
final BankProfile banqueDuCaireProfile = BankProfile(
  id: 'banque_du_caire',
  version: 1,
  senders: const {'BDC', 'BANQUEDUCAIRE'},
  signatures: [
    SmsTemplateKit.signature(const ['Banque du Caire', 'بنك القاهرة']),
  ],
  defaultCurrency: 'EGP',
  templates: [
    SmsTemplateKit.template(
      'refund_en',
      SmsKind.refund,
      credit,
      en,
      r'{currency} ?{amount} refund from {merchant} added to your card {last4}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'refund_ar',
      SmsKind.refund,
      credit,
      ar,
      r'تم رد {amount} ?{currency} من {merchant} إلى بطاقتك {last4}(?: بتاريخ {date})?{end}',
    ),
    SmsTemplateKit.template(
      'salary_en',
      SmsKind.salary,
      credit,
      en,
      r'{currency} ?{amount} salary received in your account {last4}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'salary_ar',
      SmsKind.salary,
      credit,
      ar,
      r'تم استلام راتب بقيمة {amount} ?{currency} في حسابك {last4}(?: بتاريخ {date})?{end}',
    ),
    SmsTemplateKit.template(
      'fee_en',
      SmsKind.fee,
      debit,
      en,
      r'{currency} ?{amount} {merchant} fees? deducted from your account {last4}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'fee_ar',
      SmsKind.fee,
      debit,
      ar,
      r'تم خصم {amount} ?{currency} رسوم {merchant} من حسابك {last4}(?: بتاريخ {date})?{end}',
    ),
    SmsTemplateKit.template(
      'bill_en',
      SmsKind.billPayment,
      debit,
      en,
      r'{currency} ?{amount} paid for {merchant} bill from your account {last4}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'bill_ar',
      SmsKind.billPayment,
      debit,
      ar,
      r'تم دفع {amount} ?{currency} لفاتورة {merchant} من حسابك {last4}(?: بتاريخ {date})?{end}',
    ),
    SmsTemplateKit.template(
      'atm_en',
      SmsKind.atmWithdrawal,
      debit,
      en,
      r'{currency} ?{amount} cash withdrawn with your card {last4} at atm {merchant}(?: on {date}(?: {time})?)?{end}(?:\. fees? {feeCurrency} ?{fee})?',
    ),
    SmsTemplateKit.template(
      'atm_ar',
      SmsKind.atmWithdrawal,
      debit,
      ar,
      r'تم سحب نقدي بقيمة {amount} ?{currency} باستخدام بطاقتك {last4} من ماكينة {merchant}(?: بتاريخ {date})?{end}',
    ),
    SmsTemplateKit.template(
      'instapay_en',
      SmsKind.transferOut,
      debit,
      en,
      r'{currency} ?{amount} sent by instapay from your account {last4} to {counterparty}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'instapay_ar',
      SmsKind.transferOut,
      debit,
      ar,
      r'تم إرسال {amount} ?{currency} بانستاباي من حسابك {last4} إلى {counterparty}(?: بتاريخ {date})?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_in_en',
      SmsKind.transferIn,
      credit,
      en,
      r'{currency} ?{amount} received in your account {last4} from {counterparty}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_in_ar',
      SmsKind.transferIn,
      credit,
      ar,
      r'تم استلام {amount} ?{currency} في حسابك {last4} من {counterparty}(?: بتاريخ {date})?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_out_en',
      SmsKind.transferOut,
      debit,
      en,
      r'{currency} ?{amount} transferred from your account {last4} to {counterparty}(?: on {date})?{end}(?:\.? ref:? {ref})?',
    ),
    SmsTemplateKit.template(
      'transfer_out_ar',
      SmsKind.transferOut,
      debit,
      ar,
      r'تم تحويل {amount} ?{currency} من حسابك {last4} لصالح {counterparty}(?: بتاريخ {date})?{end}',
    ),
    SmsTemplateKit.template(
      'purchase_en',
      SmsKind.cardPurchase,
      debit,
      en,
      r'{currency} ?{amount} purchase made with your card {last4} at {merchant}(?: on {date}(?: {time})?)?{end}',
    ),
    SmsTemplateKit.template(
      'purchase_ar',
      SmsKind.cardPurchase,
      debit,
      ar,
      r'تمت عملية شراء بقيمة {amount} ?{currency} باستخدام بطاقتك {last4} لدى {merchant}(?: بتاريخ {date}(?: {time})?)?{end}',
    ),
  ],
);
