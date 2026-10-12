import '../../../domain/entities/sms_import_enums.dart';
import '../bank_profile.dart';
import 'sms_template_kit.dart';

/// InstaPay (the instant payment network app).
///
/// SYNTHETIC and UNVERIFIED (orchestrator decision on OQ2/OQ3): built from
/// synthetic fixtures modeled on generic, public bank-SMS phrasing, never
/// on a real message. `verified: false` caps every result at Medium with
/// `SmsWarning.unverifiedProfile`; flipping it needs real anonymized
/// samples from the owner. Reference IDs are not known to be unique
/// (`refIsUnique: false`), and the default masking threshold (12) is
/// kept.
///
/// The signature must OPEN the message (`atStart`): other banks mention
/// InstaPay inside their own messages. Fixtures: `test/fixtures/sms/instapay/`.
final BankProfile instapayProfile = BankProfile(
  id: 'instapay',
  version: 1,
  senders: const {'INSTAPAY'},
  signatures: [
    SmsTemplateKit.signature(const ['InstaPay', 'انستاباي'], atStart: true),
  ],
  defaultCurrency: 'EGP',
  templates: [
    SmsTemplateKit.template(
      'bill_en',
      SmsKind.billPayment,
      debit,
      en,
      r'you have paid {currency} ?{amount} for {merchant} bill(?: on {date}(?: at {time})?)?{end}',
    ),
    SmsTemplateKit.template(
      'bill_ar',
      SmsKind.billPayment,
      debit,
      ar,
      r'تم دفع {amount} ?{currency} لفاتورة {merchant}(?: بتاريخ {date})?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_in_en',
      SmsKind.transferIn,
      credit,
      en,
      r'you have received {currency} ?{amount} from {counterparty}(?: on {date}(?: at {time})?)?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_in_ar',
      SmsKind.transferIn,
      credit,
      ar,
      r'تم استلام {amount} ?{currency} من {counterparty}(?: بتاريخ {date}(?: الساعة {time})?)?{end}',
    ),
    SmsTemplateKit.template(
      'transfer_out_en',
      SmsKind.transferOut,
      debit,
      en,
      r'you have sent {currency} ?{amount} to {counterparty}(?: on {date}(?: at {time})?)?{end}(?:\.? ref:? {ref})?',
    ),
    SmsTemplateKit.template(
      'transfer_out_ar',
      SmsKind.transferOut,
      debit,
      ar,
      r'تم إرسال {amount} ?{currency} إلى {counterparty}(?: بتاريخ {date}(?: الساعة {time})?)?{end}',
    ),
  ],
);
