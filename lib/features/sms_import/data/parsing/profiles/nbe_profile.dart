import '../../../domain/entities/sms_import_enums.dart';
import '../bank_profile.dart';
import 'sms_template_kit.dart';

/// National Bank of Egypt (NBE).
///
/// SYNTHETIC and UNVERIFIED (orchestrator decision on OQ2/OQ3): built from
/// synthetic fixtures (`test/fixtures/sms/nbe/`) modeled on generic,
/// public bank-SMS phrasing, never on a real message. `verified: false`
/// caps every result at Medium with `SmsWarning.unverifiedProfile`.
/// Flipping it needs real anonymized samples from the owner.
///
/// Reference IDs are not known to be unique (`refIsUnique: false`), and the
/// default masking threshold (12) is kept.
final BankProfile nbeProfile = BankProfile(
  id: 'nbe',
  version: 1,
  senders: const {'NBE', 'NBEGYPT'},
  signatures: [
    SmsTemplateKit.signature(const ['NBE', 'البنك الأهلي المصري']),
  ],
  defaultCurrency: 'EGP',
  templates: [
    // Refund.
    SmsTemplateKit.template(
      'refund_en',
      SmsKind.refund,
      credit,
      en,
      'refund of {currency} ?{amount} from {merchant} has been credited to '
          'your card ending {last4}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'refund_ar',
      SmsKind.refund,
      credit,
      ar,
      'تم رد مبلغ {amount} ?{currency} من {merchant} إلى بطاقتك المنتهية '
          'ب ?{last4}(?: يوم {date})?{end}',
    ),
    // Salary.
    SmsTemplateKit.template(
      'salary_en',
      SmsKind.salary,
      credit,
      en,
      'salary of {currency} ?{amount} has been credited to your account '
          '{last4}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'salary_ar',
      SmsKind.salary,
      credit,
      ar,
      'تم إيداع راتب بمبلغ {amount} ?{currency} في حسابك {last4}'
          '(?: يوم {date})?{end}',
    ),
    // Fee.
    SmsTemplateKit.template(
      'fee_en',
      SmsKind.fee,
      debit,
      en,
      'a fee of {currency} ?{amount} for {merchant} has been debited from '
          'your account {last4}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'fee_ar',
      SmsKind.fee,
      debit,
      ar,
      'تم خصم رسوم {merchant} بمبلغ {amount} ?{currency} من حسابك {last4}'
          '(?: يوم {date})?{end}',
    ),
    // Bill payment.
    SmsTemplateKit.template(
      'bill_en',
      SmsKind.billPayment,
      debit,
      en,
      'bill payment of {currency} ?{amount} to {merchant} was debited from '
          'your account {last4}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'bill_ar',
      SmsKind.billPayment,
      debit,
      ar,
      'تم سداد فاتورة {merchant} بمبلغ {amount} ?{currency} من حسابك '
          '{last4}(?: يوم {date})?{end}',
    ),
    // ATM withdrawal (with an optional in-message fee, FR-030a).
    SmsTemplateKit.template(
      'atm_en',
      SmsKind.atmWithdrawal,
      debit,
      en,
      'cash withdrawal of {currency} ?{amount} from atm {merchant}'
          '(?: on {date}(?: at {time})?)?{end}'
          r'(?:\. fees? {feeCurrency} ?{fee})?',
    ),
    SmsTemplateKit.template(
      'atm_ar',
      SmsKind.atmWithdrawal,
      debit,
      ar,
      'تم سحب {amount} ?{currency} نقدا من ماكينة {merchant}'
          '(?: يوم {date}(?: الساعة {time})?)?{end}',
    ),
    // InstaPay transfer sent from an NBE account.
    SmsTemplateKit.template(
      'instapay_en',
      SmsKind.transferOut,
      debit,
      en,
      'instapay transfer of {currency} ?{amount} sent to {counterparty}'
          '(?: on {date}(?: at {time})?)?{end}',
    ),
    SmsTemplateKit.template(
      'instapay_ar',
      SmsKind.transferOut,
      debit,
      ar,
      'تحويل انستاباي بمبلغ {amount} ?{currency} إلى {counterparty}'
          '(?: يوم {date})?{end}',
    ),
    // Transfers.
    SmsTemplateKit.template(
      'transfer_in_en',
      SmsKind.transferIn,
      credit,
      en,
      'your account {last4} was credited with {currency} ?{amount} from '
          '{counterparty}(?: on {date})?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_in_ar',
      SmsKind.transferIn,
      credit,
      ar,
      'تم إيداع {amount} ?{currency} في حسابك {last4} من {counterparty}'
          '(?: يوم {date})?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_out_en',
      SmsKind.transferOut,
      debit,
      en,
      'transfer of {currency} ?{amount} to {counterparty} from your account '
          r'{last4}(?: on {date})?{end}(?:\.? ref:? {ref})?',
    ),
    SmsTemplateKit.template(
      'transfer_out_ar',
      SmsKind.transferOut,
      debit,
      ar,
      'تم تحويل {amount} ?{currency} إلى {counterparty} من حسابك(?: رقم)? '
          '{last4}(?: يوم {date})?{end}',
    ),
    // Card purchase.
    SmsTemplateKit.template(
      'purchase_en',
      SmsKind.cardPurchase,
      debit,
      en,
      'your card ending {last4} was charged {currency} ?{amount} at '
          '{merchant}(?: on {date}(?: at {time})?)?{end}',
    ),
    SmsTemplateKit.template(
      'purchase_ar',
      SmsKind.cardPurchase,
      debit,
      ar,
      'تم خصم {amount} ?{currency} من بطاقتك المنتهية ب ?{last4} لدى '
          '{merchant}(?: يوم {date}(?: الساعة {time})?)?{end}',
    ),
  ],
);
