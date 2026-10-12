import '../../../domain/entities/sms_import_enums.dart';
import '../bank_profile.dart';
import 'sms_template_kit.dart';

/// Banque Misr.
///
/// SYNTHETIC and UNVERIFIED (orchestrator decision on OQ2/OQ3): built from
/// synthetic fixtures modeled on generic, public bank-SMS phrasing, never
/// on a real message. `verified: false` caps every result at Medium with
/// `SmsWarning.unverifiedProfile`; flipping it needs real anonymized
/// samples from the owner. Reference IDs are not known to be unique
/// (`refIsUnique: false`), and the default masking threshold (12) is
/// kept.
///
/// Fixtures: `test/fixtures/sms/banque_misr/`.
final BankProfile banqueMisrProfile = BankProfile(
  id: 'banque_misr',
  version: 1,
  senders: const {'BANQUEMISR', 'BMISR'},
  signatures: [
    SmsTemplateKit.signature(const ['Banque Misr', 'بنك مصر']),
  ],
  defaultCurrency: 'EGP',
  templates: [
    SmsTemplateKit.template(
      'refund_en',
      SmsKind.refund,
      credit,
      en,
      r'{currency} ?{amount} has been refunded to your card {last4} from {merchant}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'refund_ar',
      SmsKind.refund,
      credit,
      ar,
      r'تم استرداد مبلغ {amount} ?{currency} إلى بطاقتكم رقم {last4} من {merchant}(?: بتاريخ {date})?{end}',
    ),
    SmsTemplateKit.template(
      'salary_en',
      SmsKind.salary,
      credit,
      en,
      r'your salary of {currency} ?{amount} has been credited to your account {last4}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'salary_ar',
      SmsKind.salary,
      credit,
      ar,
      r'تم إضافة راتبكم بمبلغ {amount} ?{currency} إلى حسابكم رقم {last4}(?: بتاريخ {date})?{end}',
    ),
    SmsTemplateKit.template(
      'fee_en',
      SmsKind.fee,
      debit,
      en,
      r'a service fee of {currency} ?{amount} for {merchant} was debited from your account {last4}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'fee_ar',
      SmsKind.fee,
      debit,
      ar,
      r'تم خصم رسوم {merchant} بمبلغ {amount} ?{currency} من حسابكم رقم {last4}(?: بتاريخ {date})?{end}',
    ),
    SmsTemplateKit.template(
      'bill_en',
      SmsKind.billPayment,
      debit,
      en,
      r'bill payment: {currency} ?{amount} paid to {merchant} from your account {last4}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'bill_ar',
      SmsKind.billPayment,
      debit,
      ar,
      r'تم دفع فاتورة {merchant} بمبلغ {amount} ?{currency} من حسابكم رقم {last4}(?: بتاريخ {date})?{end}',
    ),
    SmsTemplateKit.template(
      'atm_en',
      SmsKind.atmWithdrawal,
      debit,
      en,
      r'{currency} ?{amount} was withdrawn from your card {last4} at atm {merchant}(?: on {date}(?: {time})?)?{end}(?:\. fees? {feeCurrency} ?{fee})?',
    ),
    SmsTemplateKit.template(
      'atm_ar',
      SmsKind.atmWithdrawal,
      debit,
      ar,
      r'تم سحب مبلغ {amount} ?{currency} من ماكينة الصراف {merchant} ببطاقتكم رقم {last4}(?: بتاريخ {date})?{end}',
    ),
    SmsTemplateKit.template(
      'instapay_en',
      SmsKind.transferOut,
      debit,
      en,
      r'{currency} ?{amount} has been sent via instapay to {counterparty} from your account {last4}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'instapay_ar',
      SmsKind.transferOut,
      debit,
      ar,
      r'تم إرسال مبلغ {amount} ?{currency} عبر انستاباي إلى {counterparty}(?: بتاريخ {date})?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_in_en',
      SmsKind.transferIn,
      credit,
      en,
      r'{currency} ?{amount} has been credited to your account {last4} from {counterparty}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_in_ar',
      SmsKind.transferIn,
      credit,
      ar,
      r'تم إضافة مبلغ {amount} ?{currency} إلى حسابكم رقم {last4} من {counterparty}(?: بتاريخ {date})?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_out_en',
      SmsKind.transferOut,
      debit,
      en,
      r'{currency} ?{amount} has been transferred from your account {last4} to {counterparty}(?: on {date})?{end}(?:\.? ref:? {ref})?',
    ),
    SmsTemplateKit.template(
      'transfer_out_ar',
      SmsKind.transferOut,
      debit,
      ar,
      r'تم تحويل مبلغ {amount} ?{currency} من حسابكم رقم {last4} إلى {counterparty}(?: بتاريخ {date})?{end}',
    ),
    SmsTemplateKit.template(
      'purchase_en',
      SmsKind.cardPurchase,
      debit,
      en,
      r'{currency} ?{amount} was debited from your card {last4} at {merchant}(?: on {date}(?: {time})?)?{end}',
    ),
    SmsTemplateKit.template(
      'purchase_ar',
      SmsKind.cardPurchase,
      debit,
      ar,
      r'تم خصم مبلغ {amount} ?{currency} من بطاقتكم رقم {last4} لدى {merchant}(?: بتاريخ {date}(?: {time})?)?{end}',
    ),
  ],
);
