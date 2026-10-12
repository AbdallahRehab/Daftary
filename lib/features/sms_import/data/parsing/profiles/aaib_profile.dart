import '../../../domain/entities/sms_import_enums.dart';
import '../bank_profile.dart';
import 'sms_template_kit.dart';

/// Arab African International Bank (AAIB).
///
/// SYNTHETIC and UNVERIFIED (orchestrator decision on OQ2/OQ3): built from
/// synthetic fixtures modeled on generic, public bank-SMS phrasing, never
/// on a real message. `verified: false` caps every result at Medium with
/// `SmsWarning.unverifiedProfile`; flipping it needs real anonymized
/// samples from the owner. Reference IDs are not known to be unique
/// (`refIsUnique: false`), and the default masking threshold (12) is
/// kept.
///
/// Fixtures: `test/fixtures/sms/aaib/`.
final BankProfile aaibProfile = BankProfile(
  id: 'aaib',
  version: 1,
  senders: const {'AAIB'},
  signatures: [
    SmsTemplateKit.signature(const ['AAIB', 'البنك العربي الأفريقي']),
  ],
  defaultCurrency: 'EGP',
  templates: [
    SmsTemplateKit.template(
      'refund_en',
      SmsKind.refund,
      credit,
      en,
      r'refund {currency} ?{amount} card ending {last4} from {merchant}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'refund_ar',
      SmsKind.refund,
      credit,
      ar,
      r'استرداد {amount} ?{currency} بطاقة رقم {last4} من {merchant}(?: يوم {date})?{end}',
    ),
    SmsTemplateKit.template(
      'salary_en',
      SmsKind.salary,
      credit,
      en,
      r'salary credit {currency} ?{amount} to a/c {last4}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'salary_ar',
      SmsKind.salary,
      credit,
      ar,
      r'إيداع راتب {amount} ?{currency} إلى حساب رقم {last4}(?: يوم {date})?{end}',
    ),
    SmsTemplateKit.template(
      'fee_en',
      SmsKind.fee,
      debit,
      en,
      r'service charge {currency} ?{amount} from a/c {last4} for {merchant}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'fee_ar',
      SmsKind.fee,
      debit,
      ar,
      r'رسوم خدمة {amount} ?{currency} من حساب رقم {last4} مقابل {merchant}(?: يوم {date})?{end}',
    ),
    SmsTemplateKit.template(
      'bill_en',
      SmsKind.billPayment,
      debit,
      en,
      r'bill payment {currency} ?{amount} from a/c {last4} for {merchant}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'bill_ar',
      SmsKind.billPayment,
      debit,
      ar,
      r'سداد فاتورة {amount} ?{currency} من حساب رقم {last4} لصالح {merchant}(?: يوم {date})?{end}',
    ),
    SmsTemplateKit.template(
      'atm_en',
      SmsKind.atmWithdrawal,
      debit,
      en,
      r'atm cash withdrawal {currency} ?{amount} card ending {last4} at {merchant}(?: on {date}(?: {time})?)?{end}(?:\. fees? {feeCurrency} ?{fee})?',
    ),
    SmsTemplateKit.template(
      'atm_ar',
      SmsKind.atmWithdrawal,
      debit,
      ar,
      r'سحب نقدي {amount} ?{currency} بطاقة رقم {last4} من {merchant}(?: يوم {date})?{end}',
    ),
    SmsTemplateKit.template(
      'instapay_en',
      SmsKind.transferOut,
      debit,
      en,
      r'instapay transfer {currency} ?{amount} from a/c {last4} to {counterparty}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'instapay_ar',
      SmsKind.transferOut,
      debit,
      ar,
      r'تحويل انستاباي {amount} ?{currency} من حساب رقم {last4} إلى {counterparty}(?: يوم {date})?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_in_en',
      SmsKind.transferIn,
      credit,
      en,
      r'inward transfer {currency} ?{amount} to a/c {last4} from {counterparty}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_in_ar',
      SmsKind.transferIn,
      credit,
      ar,
      r'حوالة واردة {amount} ?{currency} إلى حساب رقم {last4} من {counterparty}(?: يوم {date})?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_out_en',
      SmsKind.transferOut,
      debit,
      en,
      r'outward transfer {currency} ?{amount} from a/c {last4} to {counterparty}(?: on {date})?{end}(?:\.? ref:? {ref})?',
    ),
    SmsTemplateKit.template(
      'transfer_out_ar',
      SmsKind.transferOut,
      debit,
      ar,
      r'حوالة صادرة {amount} ?{currency} من حساب رقم {last4} إلى {counterparty}(?: يوم {date})?{end}',
    ),
    SmsTemplateKit.template(
      'purchase_en',
      SmsKind.cardPurchase,
      debit,
      en,
      r'debit card purchase {currency} ?{amount} card ending {last4} at {merchant}(?: on {date}(?: {time})?)?{end}',
    ),
    SmsTemplateKit.template(
      'purchase_ar',
      SmsKind.cardPurchase,
      debit,
      ar,
      r'عملية شراء {amount} ?{currency} بطاقة رقم {last4} لدى {merchant}(?: يوم {date}(?: {time})?)?{end}',
    ),
  ],
);
