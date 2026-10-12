import '../../../domain/entities/sms_import_enums.dart';
import '../bank_profile.dart';
import 'sms_template_kit.dart';

/// QNB Alahli.
///
/// SYNTHETIC and UNVERIFIED (orchestrator decision on OQ2/OQ3): built from
/// synthetic fixtures modeled on generic, public bank-SMS phrasing, never
/// on a real message. `verified: false` caps every result at Medium with
/// `SmsWarning.unverifiedProfile`; flipping it needs real anonymized
/// samples from the owner. Reference IDs are not known to be unique
/// (`refIsUnique: false`), and the default masking threshold (12) is
/// kept.
///
/// Fixtures: `test/fixtures/sms/qnb/`.
final BankProfile qnbAlahliProfile = BankProfile(
  id: 'qnb',
  version: 1,
  senders: const {'QNB', 'QNBALAHLI'},
  signatures: [
    SmsTemplateKit.signature(const ['QNB']),
  ],
  defaultCurrency: 'EGP',
  templates: [
    SmsTemplateKit.template(
      'refund_en',
      SmsKind.refund,
      credit,
      en,
      r'card {last4} refund {currency} ?{amount} from {merchant}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'refund_ar',
      SmsKind.refund,
      credit,
      ar,
      r'استرداد على البطاقة {last4} بمبلغ {amount} ?{currency} من {merchant}(?: في {date})?{end}',
    ),
    SmsTemplateKit.template(
      'salary_en',
      SmsKind.salary,
      credit,
      en,
      r'a/c {last4} credited {currency} ?{amount} salary(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'salary_ar',
      SmsKind.salary,
      credit,
      ar,
      r'إيداع في الحساب {last4} مبلغ {amount} ?{currency} راتب(?: في {date})?{end}',
    ),
    SmsTemplateKit.template(
      'fee_en',
      SmsKind.fee,
      debit,
      en,
      r'a/c {last4} debited {currency} ?{amount} fees? {merchant}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'fee_ar',
      SmsKind.fee,
      debit,
      ar,
      r'خصم من الحساب {last4} مبلغ {amount} ?{currency} رسوم {merchant}(?: في {date})?{end}',
    ),
    SmsTemplateKit.template(
      'bill_en',
      SmsKind.billPayment,
      debit,
      en,
      r'a/c {last4} debited {currency} ?{amount} bill payment {merchant}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'bill_ar',
      SmsKind.billPayment,
      debit,
      ar,
      r'خصم من الحساب {last4} مبلغ {amount} ?{currency} سداد فاتورة {merchant}(?: في {date})?{end}',
    ),
    SmsTemplateKit.template(
      'atm_en',
      SmsKind.atmWithdrawal,
      debit,
      en,
      r'card {last4} atm withdrawal {currency} ?{amount} at {merchant}(?: on {date}(?: {time})?)?{end}(?:\. fees? {feeCurrency} ?{fee})?',
    ),
    SmsTemplateKit.template(
      'atm_ar',
      SmsKind.atmWithdrawal,
      debit,
      ar,
      r'سحب نقدي بالبطاقة {last4} بمبلغ {amount} ?{currency} من {merchant}(?: في {date})?{end}',
    ),
    SmsTemplateKit.template(
      'instapay_en',
      SmsKind.transferOut,
      debit,
      en,
      r'a/c {last4} debited {currency} ?{amount} instapay to {counterparty}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'instapay_ar',
      SmsKind.transferOut,
      debit,
      ar,
      r'خصم من الحساب {last4} مبلغ {amount} ?{currency} انستاباي إلى {counterparty}(?: في {date})?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_in_en',
      SmsKind.transferIn,
      credit,
      en,
      r'a/c {last4} credited {currency} ?{amount} transfer from {counterparty}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_in_ar',
      SmsKind.transferIn,
      credit,
      ar,
      r'إيداع في الحساب {last4} مبلغ {amount} ?{currency} تحويل من {counterparty}(?: في {date})?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_out_en',
      SmsKind.transferOut,
      debit,
      en,
      r'a/c {last4} debited {currency} ?{amount} transfer to {counterparty}(?: on {date})?{end}(?:\.? ref:? {ref})?',
    ),
    SmsTemplateKit.template(
      'transfer_out_ar',
      SmsKind.transferOut,
      debit,
      ar,
      r'خصم من الحساب {last4} مبلغ {amount} ?{currency} تحويل إلى {counterparty}(?: في {date})?{end}',
    ),
    SmsTemplateKit.template(
      'purchase_en',
      SmsKind.cardPurchase,
      debit,
      en,
      r'card {last4} purchase {currency} ?{amount} at {merchant}(?: on {date}(?: {time})?)?{end}',
    ),
    SmsTemplateKit.template(
      'purchase_ar',
      SmsKind.cardPurchase,
      debit,
      ar,
      r'شراء بالبطاقة {last4} بمبلغ {amount} ?{currency} من {merchant}(?: في {date}(?: {time})?)?{end}',
    ),
  ],
);
