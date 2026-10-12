import '../../../domain/entities/sms_import_enums.dart';
import '../bank_profile.dart';
import 'sms_template_kit.dart';

/// Commercial International Bank (CIB).
///
/// SYNTHETIC and UNVERIFIED (orchestrator decision on OQ2/OQ3): built from
/// synthetic fixtures modeled on generic, public bank-SMS phrasing, never
/// on a real message. `verified: false` caps every result at Medium with
/// `SmsWarning.unverifiedProfile`; flipping it needs real anonymized
/// samples from the owner. Reference IDs are not known to be unique
/// (`refIsUnique: false`), and the default masking threshold (12) is
/// kept.
///
/// Fixtures: `test/fixtures/sms/cib/`.
final BankProfile cibProfile = BankProfile(
  id: 'cib',
  version: 1,
  senders: const {'CIB', 'CIBEGYPT'},
  signatures: [
    SmsTemplateKit.signature(const ['CIB', 'البنك التجاري الدولي']),
  ],
  defaultCurrency: 'EGP',
  templates: [
    SmsTemplateKit.template(
      'refund_en',
      SmsKind.refund,
      credit,
      en,
      r'refund of {currency} ?{amount} from {merchant} to your card ending {last4}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'refund_ar',
      SmsKind.refund,
      credit,
      ar,
      r'استرداد بمبلغ {amount} ?{currency} من {merchant} إلى بطاقتك المنتهية ب ?{last4}(?: في {date})?{end}',
    ),
    SmsTemplateKit.template(
      'salary_en',
      SmsKind.salary,
      credit,
      en,
      r'payroll credit of {currency} ?{amount} to account {last4}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'salary_ar',
      SmsKind.salary,
      credit,
      ar,
      r'إيداع مرتب بمبلغ {amount} ?{currency} إلى حساب {last4}(?: في {date})?{end}',
    ),
    SmsTemplateKit.template(
      'fee_en',
      SmsKind.fee,
      debit,
      en,
      r'charges of {currency} ?{amount} for {merchant} were debited from account {last4}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'fee_ar',
      SmsKind.fee,
      debit,
      ar,
      r'خصم رسوم {merchant} بمبلغ {amount} ?{currency} من حساب {last4}(?: في {date})?{end}',
    ),
    SmsTemplateKit.template(
      'bill_en',
      SmsKind.billPayment,
      debit,
      en,
      r'bill payment of {currency} ?{amount} for {merchant} from account {last4}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'bill_ar',
      SmsKind.billPayment,
      debit,
      ar,
      r'سداد فاتورة {merchant} بمبلغ {amount} ?{currency} من حساب {last4}(?: في {date})?{end}',
    ),
    SmsTemplateKit.template(
      'atm_en',
      SmsKind.atmWithdrawal,
      debit,
      en,
      r'cash withdrawal of {currency} ?{amount} using card ending {last4} at atm {merchant}(?: on {date}(?: {time})?)?{end}(?:\. fees? {feeCurrency} ?{fee})?',
    ),
    SmsTemplateKit.template(
      'atm_ar',
      SmsKind.atmWithdrawal,
      debit,
      ar,
      r'سحب نقدي بمبلغ {amount} ?{currency} ببطاقتك المنتهية ب ?{last4} من ماكينة {merchant}(?: في {date})?{end}',
    ),
    SmsTemplateKit.template(
      'instapay_en',
      SmsKind.transferOut,
      debit,
      en,
      r'instapay payment of {currency} ?{amount} from account {last4} to {counterparty}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'instapay_ar',
      SmsKind.transferOut,
      debit,
      ar,
      r'دفع انستاباي بمبلغ {amount} ?{currency} من حساب {last4} إلى {counterparty}(?: في {date})?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_in_en',
      SmsKind.transferIn,
      credit,
      en,
      r'incoming transfer of {currency} ?{amount} to account {last4} from {counterparty}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_in_ar',
      SmsKind.transferIn,
      credit,
      ar,
      r'تحويل وارد بمبلغ {amount} ?{currency} إلى حساب {last4} من {counterparty}(?: في {date})?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_out_en',
      SmsKind.transferOut,
      debit,
      en,
      r'outgoing transfer of {currency} ?{amount} from account {last4} to {counterparty}(?: on {date})?{end}(?:\.? ref:? {ref})?',
    ),
    SmsTemplateKit.template(
      'transfer_out_ar',
      SmsKind.transferOut,
      debit,
      ar,
      r'تحويل صادر بمبلغ {amount} ?{currency} من حساب {last4} إلى {counterparty}(?: في {date})?{end}',
    ),
    SmsTemplateKit.template(
      'purchase_en',
      SmsKind.cardPurchase,
      debit,
      en,
      r'purchase transaction of {currency} ?{amount} on your (?:credit|debit) card ending {last4} at {merchant}(?: on {date}(?: {time})?)?{end}',
    ),
    SmsTemplateKit.template(
      'purchase_ar',
      SmsKind.cardPurchase,
      debit,
      ar,
      r'تمت عملية شراء بمبلغ {amount} ?{currency} على بطاقتك المنتهية ب ?{last4} لدى {merchant}(?: في {date}(?: {time})?)?{end}',
    ),
  ],
);
