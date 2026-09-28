// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:flutter/services.dart' as _i281;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as _i163;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:http/http.dart' as _i519;
import 'package:image_picker/image_picker.dart' as _i183;
import 'package:injectable/injectable.dart' as _i526;
import 'package:local_auth/local_auth.dart' as _i152;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../../features/ai_assistant/data/datasources/ai_assistant_dao.dart'
    as _i931;
import '../../features/ai_assistant/data/datasources/ai_provider_catalog_impl.dart'
    as _i833;
import '../../features/ai_assistant/data/datasources/secure_credential_store_impl.dart'
    as _i370;
import '../../features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart'
    as _i988;
import '../../features/ai_assistant/data/services/ai_http_module.dart' as _i88;
import '../../features/ai_assistant/data/services/ai_service_impl.dart' as _i57;
import '../../features/ai_assistant/domain/repositories/ai_assistant_repository.dart'
    as _i754;
import '../../features/ai_assistant/domain/services/ai_provider_catalog.dart'
    as _i1023;
import '../../features/ai_assistant/domain/services/ai_service.dart' as _i238;
import '../../features/ai_assistant/domain/services/secure_credential_store.dart'
    as _i693;
import '../../features/ai_assistant/domain/services/system_prompt_builder.dart'
    as _i775;
import '../../features/ai_assistant/domain/tools/ai_tool_registry.dart'
    as _i332;
import '../../features/ai_assistant/domain/tools/compare_spending_across_periods.dart'
    as _i924;
import '../../features/ai_assistant/domain/tools/get_budget_status_tool.dart'
    as _i59;
import '../../features/ai_assistant/domain/tools/get_category_spend.dart'
    as _i917;
import '../../features/ai_assistant/domain/tools/get_occasion_totals_tool.dart'
    as _i666;
import '../../features/ai_assistant/domain/tools/get_owed_overview_tool.dart'
    as _i14;
import '../../features/ai_assistant/domain/tools/get_person_balance_tool.dart'
    as _i1049;
import '../../features/ai_assistant/domain/tools/get_proactive_observation_tool.dart'
    as _i65;
import '../../features/ai_assistant/domain/tools/get_top_spending_category.dart'
    as _i1050;
import '../../features/ai_assistant/domain/tools/tool_arguments.dart' as _i1038;
import '../../features/ai_assistant/domain/usecases/ask_financial_question.dart'
    as _i636;
import '../../features/ai_assistant/domain/usecases/clear_conversation.dart'
    as _i546;
import '../../features/ai_assistant/domain/usecases/disable_ai_assistant.dart'
    as _i803;
import '../../features/ai_assistant/domain/usecases/enable_ai_assistant.dart'
    as _i685;
import '../../features/ai_assistant/domain/usecases/get_ai_assistant_settings.dart'
    as _i359;
import '../../features/ai_assistant/domain/usecases/get_conversation.dart'
    as _i970;
import '../../features/ai_assistant/domain/usecases/get_proactive_observation.dart'
    as _i103;
import '../../features/ai_assistant/domain/usecases/purge_ai_assistant_credentials.dart'
    as _i763;
import '../../features/ai_assistant/domain/usecases/update_provider_credentials.dart'
    as _i739;
import '../../features/ai_assistant/presentation/cubit/ai_settings_cubit.dart'
    as _i742;
import '../../features/ai_assistant/presentation/cubit/chat_cubit.dart'
    as _i258;
import '../../features/app_lock/data/datasources/secure_app_lock_storage.dart'
    as _i872;
import '../../features/app_lock/data/repositories/app_lock_repository_impl.dart'
    as _i731;
import '../../features/app_lock/data/services/app_lock_module.dart' as _i849;
import '../../features/app_lock/data/services/app_lock_secure_storage_wiper.dart'
    as _i236;
import '../../features/app_lock/data/services/local_auth_biometric_service.dart'
    as _i791;
import '../../features/app_lock/data/services/repository_app_lock_status_provider.dart'
    as _i251;
import '../../features/app_lock/domain/repositories/app_lock_repository.dart'
    as _i98;
import '../../features/app_lock/domain/services/biometric_service.dart' as _i68;
import '../../features/app_lock/domain/services/lockout_policy.dart' as _i12;
import '../../features/app_lock/domain/services/pin_hasher.dart' as _i316;
import '../../features/app_lock/domain/usecases/change_pin.dart' as _i570;
import '../../features/app_lock/domain/usecases/disable_app_lock.dart' as _i643;
import '../../features/app_lock/domain/usecases/enable_app_lock.dart' as _i590;
import '../../features/app_lock/domain/usecases/get_app_lock_config.dart'
    as _i485;
import '../../features/app_lock/domain/usecases/get_lockout_state.dart'
    as _i625;
import '../../features/app_lock/domain/usecases/record_failed_pin_attempt.dart'
    as _i609;
import '../../features/app_lock/domain/usecases/recover_via_biometric.dart'
    as _i244;
import '../../features/app_lock/domain/usecases/set_biometric_enabled.dart'
    as _i561;
import '../../features/app_lock/domain/usecases/set_inactivity_timeout.dart'
    as _i252;
import '../../features/app_lock/domain/usecases/set_pin.dart' as _i557;
import '../../features/app_lock/domain/usecases/verify_biometric.dart' as _i245;
import '../../features/app_lock/domain/usecases/verify_pin.dart' as _i229;
import '../../features/app_lock/domain/usecases/wipe_all_local_data.dart'
    as _i613;
import '../../features/app_lock/presentation/cubit/app_lock_settings_cubit.dart'
    as _i942;
import '../../features/app_lock/presentation/cubit/forgot_pin_cubit.dart'
    as _i944;
import '../../features/app_lock/presentation/cubit/lock_screen_cubit.dart'
    as _i853;
import '../../features/app_lock/presentation/cubit/pin_setup_cubit.dart'
    as _i302;
import '../../features/app_lock/presentation/cubit/pin_setup_state.dart'
    as _i595;
import '../../features/budgets/data/datasources/budgets_dao.dart' as _i757;
import '../../features/budgets/data/repositories/budgets_repository_impl.dart'
    as _i249;
import '../../features/budgets/data/sync/budget_sync_mapper.dart' as _i56;
import '../../features/budgets/domain/repositories/budgets_repository.dart'
    as _i855;
import '../../features/budgets/domain/usecases/add_budget_category_allocation.dart'
    as _i552;
import '../../features/budgets/domain/usecases/copy_budget_to_month.dart'
    as _i809;
import '../../features/budgets/domain/usecases/create_budget.dart' as _i254;
import '../../features/budgets/domain/usecases/delete_budget.dart' as _i150;
import '../../features/budgets/domain/usecases/edit_budget.dart' as _i755;
import '../../features/budgets/domain/usecases/edit_budget_category_allocation.dart'
    as _i934;
import '../../features/budgets/domain/usecases/get_budget_for_month.dart'
    as _i587;
import '../../features/budgets/domain/usecases/get_budget_trend.dart' as _i438;
import '../../features/budgets/domain/usecases/get_most_recent_budget_before.dart'
    as _i654;
import '../../features/budgets/domain/usecases/remove_budget_category_allocation.dart'
    as _i317;
import '../../features/budgets/domain/usecases/watch_budget_for_month.dart'
    as _i1021;
import '../../features/budgets/domain/usecases/watch_budget_trend.dart'
    as _i621;
import '../../features/budgets/presentation/cubit/budget_form_cubit.dart'
    as _i720;
import '../../features/budgets/presentation/cubit/budget_month_cubit.dart'
    as _i1031;
import '../../features/budgets/presentation/cubit/budget_trend_cubit.dart'
    as _i179;
import '../../features/budgets/presentation/cubit/copy_budget_cubit.dart'
    as _i28;
import '../../features/cloud_sync/data/repositories/cloud_sync_repository_impl.dart'
    as _i241;
import '../../features/cloud_sync/data/services/supabase_cloud_copy_eraser.dart'
    as _i223;
import '../../features/cloud_sync/data/sync/conflict_resolution_sync_mapper.dart'
    as _i346;
import '../../features/cloud_sync/domain/repositories/cloud_sync_repository.dart'
    as _i948;
import '../../features/cloud_sync/domain/usecases/acknowledge_sync_notice.dart'
    as _i305;
import '../../features/cloud_sync/domain/usecases/confirm_email_code.dart'
    as _i394;
import '../../features/cloud_sync/domain/usecases/request_email_code.dart'
    as _i861;
import '../../features/cloud_sync/domain/usecases/resolve_sync_conflict.dart'
    as _i1030;
import '../../features/cloud_sync/domain/usecases/retry_failed_sync.dart'
    as _i259;
import '../../features/cloud_sync/domain/usecases/set_sync_enabled.dart'
    as _i676;
import '../../features/cloud_sync/domain/usecases/sync_now.dart' as _i399;
import '../../features/cloud_sync/domain/usecases/watch_failed_sync_items.dart'
    as _i389;
import '../../features/cloud_sync/domain/usecases/watch_sync_conflicts.dart'
    as _i1039;
import '../../features/cloud_sync/domain/usecases/watch_sync_status.dart'
    as _i178;
import '../../features/cloud_sync/presentation/cubit/email_link_cubit.dart'
    as _i1005;
import '../../features/cloud_sync/presentation/cubit/sync_conflicts_cubit.dart'
    as _i273;
import '../../features/cloud_sync/presentation/cubit/sync_notice_cubit.dart'
    as _i738;
import '../../features/cloud_sync/presentation/cubit/sync_settings_cubit.dart'
    as _i324;
import '../../features/currency/data/datasources/currency_dao.dart' as _i973;
import '../../features/currency/data/repositories/currency_repository_impl.dart'
    as _i751;
import '../../features/currency/data/services/drift_currency_usage_checker.dart'
    as _i941;
import '../../features/currency/data/sync/exchange_rate_sync_mapper.dart'
    as _i770;
import '../../features/currency/data/sync/primary_currency_sync_mapper.dart'
    as _i900;
import '../../features/currency/domain/ports/currency_usage_checker.dart'
    as _i289;
import '../../features/currency/domain/repositories/currency_repository.dart'
    as _i87;
import '../../features/currency/domain/services/currency_converter.dart'
    as _i966;
import '../../features/currency/domain/usecases/get_conversion_context.dart'
    as _i602;
import '../../features/currency/domain/usecases/get_exchange_rates.dart'
    as _i764;
import '../../features/currency/domain/usecases/get_primary_currency.dart'
    as _i903;
import '../../features/currency/domain/usecases/get_supported_currencies.dart'
    as _i681;
import '../../features/currency/domain/usecases/remove_exchange_rate.dart'
    as _i1025;
import '../../features/currency/domain/usecases/set_exchange_rate.dart'
    as _i486;
import '../../features/currency/domain/usecases/set_primary_currency.dart'
    as _i801;
import '../../features/currency/domain/usecases/watch_conversion_context.dart'
    as _i132;
import '../../features/currency/domain/usecases/watch_exchange_rates.dart'
    as _i166;
import '../../features/currency/domain/usecases/watch_primary_currency.dart'
    as _i1028;
import '../../features/currency/presentation/cubit/exchange_rate_form_cubit.dart'
    as _i954;
import '../../features/currency/presentation/cubit/exchange_rate_list_cubit.dart'
    as _i398;
import '../../features/currency/presentation/cubit/primary_currency_cubit.dart'
    as _i1061;
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart'
    as _i25;
import '../../features/data_privacy/data/repositories/data_wipe_repository_impl.dart'
    as _i913;
import '../../features/data_privacy/data/services/share_plus_service.dart'
    as _i664;
import '../../features/data_privacy/data/services/temporary_export_directory_provider.dart'
    as _i612;
import '../../features/data_privacy/domain/repositories/data_wipe_repository.dart'
    as _i1004;
import '../../features/data_privacy/domain/services/cloud_copy_eraser.dart'
    as _i222;
import '../../features/data_privacy/domain/services/export_directory_provider.dart'
    as _i52;
import '../../features/data_privacy/domain/services/secure_storage_wiper.dart'
    as _i193;
import '../../features/data_privacy/domain/services/share_service.dart'
    as _i939;
import '../../features/data_privacy/domain/usecases/delete_all_user_data.dart'
    as _i431;
import '../../features/data_privacy/domain/usecases/export_user_data.dart'
    as _i496;
import '../../features/data_privacy/presentation/cubit/delete_account_cubit.dart'
    as _i756;
import '../../features/data_privacy/presentation/cubit/export_cubit.dart'
    as _i782;
import '../../features/finance/data/datasources/finance_dao.dart' as _i443;
import '../../features/finance/data/repositories/category_repository_impl.dart'
    as _i816;
import '../../features/finance/data/repositories/finance_repository_impl.dart'
    as _i250;
import '../../features/finance/data/sync/finance_category_sync_mapper.dart'
    as _i539;
import '../../features/finance/data/sync/finance_entry_sync_mapper.dart'
    as _i960;
import '../../features/finance/domain/repositories/category_repository.dart'
    as _i228;
import '../../features/finance/domain/repositories/finance_repository.dart'
    as _i137;
import '../../features/finance/domain/usecases/add_finance_entry.dart' as _i159;
import '../../features/finance/domain/usecases/create_category.dart' as _i24;
import '../../features/finance/domain/usecases/delete_finance_entry.dart'
    as _i1065;
import '../../features/finance/domain/usecases/edit_category.dart' as _i611;
import '../../features/finance/domain/usecases/edit_finance_entry.dart'
    as _i416;
import '../../features/finance/domain/usecases/get_categories.dart' as _i1;
import '../../features/finance/domain/usecases/get_category_breakdown.dart'
    as _i854;
import '../../features/finance/domain/usecases/get_finance_history.dart'
    as _i27;
import '../../features/finance/domain/usecases/get_finance_summary.dart'
    as _i844;
import '../../features/finance/domain/usecases/get_spending_trend.dart'
    as _i323;
import '../../features/finance/domain/usecases/remove_category.dart' as _i490;
import '../../features/finance/domain/usecases/restore_finance_entry.dart'
    as _i1008;
import '../../features/finance/domain/usecases/seed_default_categories.dart'
    as _i717;
import '../../features/finance/domain/usecases/watch_categories.dart' as _i520;
import '../../features/finance/domain/usecases/watch_category_breakdown.dart'
    as _i74;
import '../../features/finance/domain/usecases/watch_finance_history.dart'
    as _i542;
import '../../features/finance/domain/usecases/watch_finance_summary.dart'
    as _i240;
import '../../features/finance/domain/usecases/watch_spending_trend.dart'
    as _i508;
import '../../features/finance/presentation/cubit/category_form_cubit.dart'
    as _i1033;
import '../../features/finance/presentation/cubit/category_management_cubit.dart'
    as _i109;
import '../../features/finance/presentation/cubit/finance_entry_form_cubit.dart'
    as _i505;
import '../../features/finance/presentation/cubit/finance_history_cubit.dart'
    as _i987;
import '../../features/finance/presentation/cubit/reports_cubit.dart' as _i329;
import '../../features/financial_education/data/datasources/bundled_education_content_data_source.dart'
    as _i445;
import '../../features/financial_education/data/repositories/education_content_repository_impl.dart'
    as _i549;
import '../../features/financial_education/domain/repositories/education_content_repository.dart'
    as _i1055;
import '../../features/financial_education/domain/services/compound_growth_calculator.dart'
    as _i585;
import '../../features/financial_education/domain/services/doubling_time_calculator.dart'
    as _i466;
import '../../features/financial_education/domain/services/savings_rate_calculator.dart'
    as _i35;
import '../../features/financial_education/domain/usecases/calculate_compound_growth.dart'
    as _i217;
import '../../features/financial_education/domain/usecases/calculate_doubling_time.dart'
    as _i435;
import '../../features/financial_education/domain/usecases/calculate_savings_rate.dart'
    as _i897;
import '../../features/financial_education/domain/usecases/get_article.dart'
    as _i481;
import '../../features/financial_education/domain/usecases/get_category_articles.dart'
    as _i657;
import '../../features/financial_education/domain/usecases/get_education_categories.dart'
    as _i805;
import '../../features/financial_education/domain/usecases/get_prefillable_savings_goal_amount.dart'
    as _i60;
import '../../features/financial_education/presentation/cubit/article_cubit.dart'
    as _i274;
import '../../features/financial_education/presentation/cubit/category_cubit.dart'
    as _i518;
import '../../features/financial_education/presentation/cubit/compound_growth_calculator_cubit.dart'
    as _i896;
import '../../features/financial_education/presentation/cubit/content_library_cubit.dart'
    as _i265;
import '../../features/financial_education/presentation/cubit/doubling_time_calculator_cubit.dart'
    as _i811;
import '../../features/financial_education/presentation/cubit/savings_rate_calculator_cubit.dart'
    as _i66;
import '../../features/insights_notifications/data/datasources/budgets_insights_source.dart'
    as _i582;
import '../../features/insights_notifications/data/datasources/in_memory_notification_last_run_store.dart'
    as _i771;
import '../../features/insights_notifications/data/datasources/notifications_dao.dart'
    as _i338;
import '../../features/insights_notifications/data/datasources/unavailable_savings_insights_source.dart'
    as _i386;
import '../../features/insights_notifications/data/repositories/notification_history_repository_impl.dart'
    as _i551;
import '../../features/insights_notifications/data/repositories/notification_preference_repository_impl.dart'
    as _i701;
import '../../features/insights_notifications/data/services/flutter_local_notifications_scheduler.dart'
    as _i0;
import '../../features/insights_notifications/data/services/localized_notification_composer.dart'
    as _i901;
import '../../features/insights_notifications/data/services/settings_notification_language_provider.dart'
    as _i831;
import '../../features/insights_notifications/data/services/template_notification_phrasing_service.dart'
    as _i266;
import '../../features/insights_notifications/domain/ports/budget_insights_source.dart'
    as _i423;
import '../../features/insights_notifications/domain/ports/notification_language_provider.dart'
    as _i1003;
import '../../features/insights_notifications/domain/ports/savings_insights_source.dart'
    as _i842;
import '../../features/insights_notifications/domain/repositories/notification_history_repository.dart'
    as _i13;
import '../../features/insights_notifications/domain/repositories/notification_last_run_store.dart'
    as _i220;
import '../../features/insights_notifications/domain/repositories/notification_preference_repository.dart'
    as _i162;
import '../../features/insights_notifications/domain/services/evaluate_budget_notifications.dart'
    as _i983;
import '../../features/insights_notifications/domain/services/evaluate_savings_goal_notifications.dart'
    as _i371;
import '../../features/insights_notifications/domain/services/notification_composer.dart'
    as _i104;
import '../../features/insights_notifications/domain/services/notification_phrasing_service.dart'
    as _i721;
import '../../features/insights_notifications/domain/services/notification_scheduler.dart'
    as _i209;
import '../../features/insights_notifications/domain/usecases/handle_notification_tap.dart'
    as _i480;
import '../../features/insights_notifications/domain/usecases/notification_engine.dart'
    as _i553;
import '../../features/insights_notifications/domain/usecases/request_notification_permission.dart'
    as _i639;
import '../../features/insights_notifications/domain/usecases/set_notification_preferences.dart'
    as _i203;
import '../../features/insights_notifications/presentation/cubit/notification_settings_cubit.dart'
    as _i39;
import '../../features/insights_notifications/presentation/notification_recompute_trigger.dart'
    as _i548;
import '../../features/occasions/data/datasources/occasions_dao.dart' as _i792;
import '../../features/occasions/data/repositories/occasions_repository_impl.dart'
    as _i455;
import '../../features/occasions/data/sync/occasion_sync_mapper.dart' as _i1001;
import '../../features/occasions/domain/repositories/occasions_repository.dart'
    as _i72;
import '../../features/occasions/domain/usecases/add_occasion_attachment.dart'
    as _i247;
import '../../features/occasions/domain/usecases/add_participant_contribution.dart'
    as _i415;
import '../../features/occasions/domain/usecases/archive_occasion.dart'
    as _i847;
import '../../features/occasions/domain/usecases/create_occasion.dart' as _i905;
import '../../features/occasions/domain/usecases/delete_occasion.dart'
    as _i1046;
import '../../features/occasions/domain/usecases/edit_occasion.dart' as _i712;
import '../../features/occasions/domain/usecases/edit_participant_contribution.dart'
    as _i153;
import '../../features/occasions/domain/usecases/get_occasion_detail.dart'
    as _i432;
import '../../features/occasions/domain/usecases/get_occasions_list.dart'
    as _i958;
import '../../features/occasions/domain/usecases/remove_occasion_attachment.dart'
    as _i191;
import '../../features/occasions/domain/usecases/remove_participant_contribution.dart'
    as _i192;
import '../../features/occasions/domain/usecases/restore_occasion.dart'
    as _i154;
import '../../features/occasions/domain/usecases/watch_occasion_detail.dart'
    as _i294;
import '../../features/occasions/domain/usecases/watch_occasions_list.dart'
    as _i276;
import '../../features/occasions/presentation/cubit/archived_occasions_cubit.dart'
    as _i185;
import '../../features/occasions/presentation/cubit/occasion_detail_cubit.dart'
    as _i53;
import '../../features/occasions/presentation/cubit/occasion_form_cubit.dart'
    as _i15;
import '../../features/occasions/presentation/cubit/occasions_list_cubit.dart'
    as _i194;
import '../../features/occasions/presentation/cubit/participant_form_cubit.dart'
    as _i218;
import '../../features/ocr/data/datasources/ocr_dao.dart' as _i976;
import '../../features/ocr/data/parsing/candidate_entry_parser.dart' as _i918;
import '../../features/ocr/data/preparation/image_preparation_service_impl.dart'
    as _i450;
import '../../features/ocr/data/recognition/text_recognition_service_impl.dart'
    as _i428;
import '../../features/ocr/data/repositories/ocr_repository_impl.dart' as _i457;
import '../../features/ocr/domain/repositories/image_preparation_service.dart'
    as _i235;
import '../../features/ocr/domain/repositories/ocr_repository.dart' as _i578;
import '../../features/ocr/domain/repositories/text_recognition_service.dart'
    as _i176;
import '../../features/ocr/domain/usecases/cancel_scan.dart' as _i377;
import '../../features/ocr/domain/usecases/confirm_scan_batch.dart' as _i665;
import '../../features/ocr/domain/usecases/delete_scan.dart' as _i413;
import '../../features/ocr/domain/usecases/discard_candidate_entry.dart'
    as _i256;
import '../../features/ocr/domain/usecases/edit_candidate_entry.dart' as _i506;
import '../../features/ocr/domain/usecases/get_candidate_entries.dart' as _i303;
import '../../features/ocr/domain/usecases/get_possible_duplicate_for_candidate.dart'
    as _i20;
import '../../features/ocr/domain/usecases/get_scan_detail.dart' as _i267;
import '../../features/ocr/domain/usecases/get_scan_history.dart' as _i331;
import '../../features/ocr/domain/usecases/run_ocr_extraction.dart' as _i350;
import '../../features/ocr/domain/usecases/set_batch_default_direction.dart'
    as _i1011;
import '../../features/ocr/domain/usecases/start_scan.dart' as _i856;
import '../../features/ocr/domain/usecases/tag_batch_to_occasion.dart' as _i237;
import '../../features/ocr/domain/usecases/watch_scan_detail.dart' as _i138;
import '../../features/ocr/domain/usecases/watch_scan_history.dart' as _i130;
import '../../features/ocr/presentation/cubit/image_prep_cubit.dart' as _i427;
import '../../features/ocr/presentation/cubit/scan_capture_cubit.dart' as _i354;
import '../../features/ocr/presentation/cubit/scan_detail_cubit.dart' as _i919;
import '../../features/ocr/presentation/cubit/scan_history_cubit.dart' as _i624;
import '../../features/ocr/presentation/cubit/scan_review_cubit.dart' as _i622;
import '../../features/onboarding/data/datasources/onboarding_dao.dart'
    as _i360;
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart'
    as _i452;
import '../../features/onboarding/domain/repositories/onboarding_repository.dart'
    as _i430;
import '../../features/onboarding/domain/usecases/resolve_onboarding_status.dart'
    as _i793;
import '../../features/onboarding/presentation/cubit/onboarding_cubit.dart'
    as _i807;
import '../../features/people/data/datasources/people_dao.dart' as _i735;
import '../../features/people/data/repositories/people_repository_impl.dart'
    as _i1029;
import '../../features/people/data/sync/person_sync_mapper.dart' as _i334;
import '../../features/people/domain/repositories/people_repository.dart'
    as _i646;
import '../../features/people/domain/usecases/archive_person.dart' as _i224;
import '../../features/people/domain/usecases/create_person.dart' as _i789;
import '../../features/people/domain/usecases/delete_person.dart' as _i907;
import '../../features/people/domain/usecases/edit_person.dart' as _i101;
import '../../features/people/domain/usecases/find_possible_duplicate_person.dart'
    as _i769;
import '../../features/people/domain/usecases/restore_person.dart' as _i49;
import '../../features/people/domain/usecases/watch_active_people.dart'
    as _i277;
import '../../features/people/domain/usecases/watch_archived_people.dart'
    as _i781;
import '../../features/people/domain/usecases/watch_person.dart' as _i462;
import '../../features/people/presentation/cubit/archived_people_cubit.dart'
    as _i62;
import '../../features/people/presentation/cubit/person_form_cubit.dart'
    as _i668;
import '../../features/people/presentation/cubit/person_list_cubit.dart'
    as _i1018;
import '../../features/settings/data/datasources/settings_dao.dart' as _i586;
import '../../features/settings/data/repositories/settings_repository_impl.dart'
    as _i955;
import '../../features/settings/domain/repositories/settings_repository.dart'
    as _i674;
import '../../features/settings/domain/usecases/change_glass_appearance.dart'
    as _i577;
import '../../features/settings/domain/usecases/change_language.dart' as _i90;
import '../../features/settings/domain/usecases/change_theme_mode.dart' as _i46;
import '../../features/settings/domain/usecases/get_glass_appearance_preference.dart'
    as _i499;
import '../../features/settings/domain/usecases/get_language_preference.dart'
    as _i1032;
import '../../features/settings/domain/usecases/get_theme_mode_preference.dart'
    as _i333;
import '../../features/settings/presentation/cubit/settings_cubit.dart'
    as _i794;
import '../../features/startup/presentation/cubit/app_startup_cubit.dart'
    as _i248;
import '../../features/transactions/data/datasources/transactions_dao.dart'
    as _i684;
import '../../features/transactions/data/repositories/transactions_repository_impl.dart'
    as _i373;
import '../../features/transactions/data/sync/money_transaction_sync_mapper.dart'
    as _i315;
import '../../features/transactions/data/sync/transaction_audit_sync_mapper.dart'
    as _i92;
import '../../features/transactions/domain/repositories/transactions_repository.dart'
    as _i957;
import '../../features/transactions/domain/usecases/add_transaction.dart'
    as _i5;
import '../../features/transactions/domain/usecases/delete_transaction.dart'
    as _i645;
import '../../features/transactions/domain/usecases/edit_transaction.dart'
    as _i554;
import '../../features/transactions/domain/usecases/get_overview.dart' as _i943;
import '../../features/transactions/domain/usecases/get_person_balance.dart'
    as _i750;
import '../../features/transactions/domain/usecases/get_person_balances.dart'
    as _i313;
import '../../features/transactions/domain/usecases/get_person_history.dart'
    as _i610;
import '../../features/transactions/domain/usecases/record_repayment.dart'
    as _i426;
import '../../features/transactions/domain/usecases/watch_overview.dart'
    as _i615;
import '../../features/transactions/domain/usecases/watch_person_balance.dart'
    as _i221;
import '../../features/transactions/domain/usecases/watch_person_balances.dart'
    as _i330;
import '../../features/transactions/domain/usecases/watch_person_history.dart'
    as _i210;
import '../../features/transactions/presentation/cubit/person_detail_cubit.dart'
    as _i992;
import '../../features/transactions/presentation/cubit/repayment_form_cubit.dart'
    as _i34;
import '../../features/transactions/presentation/cubit/transaction_form_cubit.dart'
    as _i593;
import '../database/app_database.dart' as _i982;
import '../date/app_clock.dart' as _i956;
import '../device/device_locale_provider.dart' as _i933;
import '../media/attachment_picker_service.dart' as _i780;
import '../media/attachment_picker_service_impl.dart' as _i157;
import '../money/egp_formatter.dart' as _i999;
import '../routing/notification_tap_router.dart' as _i172;
import '../security/app_lifecycle_observer.dart' as _i500;
import '../security/app_lock_status_provider.dart' as _i439;
import '../security/screenshot_protection_service.dart' as _i1042;
import '../sync/backoff_policy.dart' as _i902;
import '../sync/connectivity_monitor.dart' as _i972;
import '../sync/local/conflict_resolver.dart' as _i219;
import '../sync/local/sync_applier.dart' as _i623;
import '../sync/local/sync_local_store.dart' as _i339;
import '../sync/local/sync_outbox.dart' as _i840;
import '../sync/remote/cloud_auth_data_source.dart' as _i597;
import '../sync/remote/supabase_initializer.dart' as _i822;
import '../sync/remote/sync_remote_data_source.dart' as _i753;
import '../sync/sync_bootstrap.dart' as _i164;
import '../sync/sync_engine.dart' as _i846;
import '../sync/sync_logger.dart' as _i414;
import '../sync/sync_mapper_registry.dart' as _i834;
import '../sync/sync_scheduler.dart' as _i253;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    final aIHttpModule = _$AIHttpModule();
    final appLockModule = _$AppLockModule();
    gh.factory<_i775.SystemPromptBuilder>(
      () => const _i775.SystemPromptBuilder(),
    );
    gh.factory<_i1038.AIPeriodResolver>(() => _i1038.AIPeriodResolver());
    gh.factory<_i60.GetPrefillableSavingsGoalAmount>(
      () => const _i60.GetPrefillableSavingsGoalAmount(),
    );
    gh.factory<_i769.FindPossibleDuplicatePerson>(
      () => const _i769.FindPossibleDuplicatePerson(),
    );
    gh.lazySingleton<_i999.EgpFormatter>(() => registerModule.egpFormatter);
    gh.lazySingleton<_i281.AssetBundle>(() => registerModule.assetBundle);
    gh.lazySingleton<_i163.FlutterLocalNotificationsPlugin>(
      () => registerModule.localNotificationsPlugin,
    );
    gh.lazySingleton<_i895.Connectivity>(() => registerModule.connectivity);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i183.ImagePicker>(() => registerModule.imagePicker);
    gh.lazySingleton<_i780.DocumentsDirectory>(
      () => const _i780.DocumentsDirectory(),
    );
    gh.lazySingleton<_i902.BackoffPolicy>(() => _i902.BackoffPolicy());
    gh.lazySingleton<_i519.Client>(() => aIHttpModule.httpClient);
    gh.lazySingleton<_i152.LocalAuthentication>(
      () => appLockModule.localAuthentication,
    );
    gh.lazySingleton<_i56.BudgetSyncMapper>(
      () => const _i56.BudgetSyncMapper(),
    );
    gh.lazySingleton<_i56.BudgetAllocationSyncMapper>(
      () => const _i56.BudgetAllocationSyncMapper(),
    );
    gh.lazySingleton<_i346.ConflictResolutionSyncMapper>(
      () => const _i346.ConflictResolutionSyncMapper(),
    );
    gh.lazySingleton<_i770.ExchangeRateSyncMapper>(
      () => const _i770.ExchangeRateSyncMapper(),
    );
    gh.lazySingleton<_i900.PrimaryCurrencySyncMapper>(
      () => const _i900.PrimaryCurrencySyncMapper(),
    );
    gh.lazySingleton<_i539.FinanceCategorySyncMapper>(
      () => const _i539.FinanceCategorySyncMapper(),
    );
    gh.lazySingleton<_i960.FinanceEntrySyncMapper>(
      () => const _i960.FinanceEntrySyncMapper(),
    );
    gh.lazySingleton<_i1001.OccasionSyncMapper>(
      () => const _i1001.OccasionSyncMapper(),
    );
    gh.lazySingleton<_i918.CandidateEntryParser>(
      () => const _i918.CandidateEntryParser(),
    );
    gh.lazySingleton<_i450.ImageCropperClient>(
      () => const _i450.ImageCropperClient(),
    );
    gh.lazySingleton<_i334.PersonSyncMapper>(
      () => const _i334.PersonSyncMapper(),
    );
    gh.lazySingleton<_i315.MoneyTransactionSyncMapper>(
      () => const _i315.MoneyTransactionSyncMapper(),
    );
    gh.lazySingleton<_i92.TransactionAuditSyncMapper>(
      () => const _i92.TransactionAuditSyncMapper(),
    );
    gh.lazySingleton<_i721.NotificationPhrasingService>(
      () => const _i266.TemplateNotificationPhrasingService(),
    );
    gh.lazySingleton<_i983.EvaluateBudgetNotifications>(
      () => const _i983.EvaluateBudgetNotificationsImpl(),
    );
    gh.lazySingleton<_i371.EvaluateSavingsGoalNotifications>(
      () => const _i371.EvaluateSavingsGoalNotificationsImpl(),
    );
    gh.lazySingleton<_i822.SupabaseInitializer>(
      () => _i822.DefaultSupabaseInitializer(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i693.SecureCredentialStore>(
      () => _i370.SecureCredentialStoreImpl(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i35.SavingsRateCalculator>(
      () => const _i35.SavingsRateCalculatorImpl(),
    );
    gh.lazySingleton<_i1042.ScreenshotProtectionService>(
      () => _i1042.PlatformScreenshotProtectionService(),
    );
    gh.lazySingleton<_i466.DoublingTimeCalculator>(
      () => const _i466.DoublingTimeCalculatorImpl(),
    );
    gh.lazySingleton<_i52.ExportDirectoryProvider>(
      () => const _i612.TemporaryExportDirectoryProvider(),
    );
    gh.lazySingleton<_i933.DeviceLocaleProvider>(
      () => _i933.DeviceLocaleProviderImpl(),
    );
    gh.lazySingleton<_i872.SecureAppLockStorage>(
      () => _i872.SecureAppLockStorageImpl(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i176.TextRecognitionService>(
      () => _i428.TextRecognitionServiceImpl(),
    );
    gh.lazySingleton<_i316.PinHasher>(() => _i316.Pbkdf2PinHasher());
    gh.lazySingleton<_i585.CompoundGrowthCalculator>(
      () => const _i585.CompoundGrowthCalculatorImpl(),
    );
    gh.lazySingleton<_i1023.AIProviderCatalog>(
      () => const _i833.AIProviderCatalogImpl(),
    );
    gh.lazySingleton<_i104.NotificationComposer>(
      () => const _i901.LocalizedNotificationComposer(),
    );
    gh.lazySingleton<_i597.CloudAuthDataSource>(
      () => _i597.SupabaseCloudAuthDataSource(gh<_i822.SupabaseInitializer>()),
    );
    gh.lazySingleton<_i956.AppClock>(() => const _i956.SystemAppClock());
    gh.lazySingleton<_i966.CurrencyConverter>(
      () => const _i966.CurrencyConverterImpl(),
    );
    gh.lazySingleton<_i414.SyncLogger>(() => _i414.DeveloperSyncLogger());
    gh.lazySingleton<_i220.NotificationLastRunStore>(
      () => _i771.InMemoryNotificationLastRunStore(),
    );
    gh.lazySingleton<_i12.LockoutPolicy>(
      () => const _i12.EscalatingLockoutPolicy(),
    );
    gh.lazySingleton<_i842.SavingsInsightsSource>(
      () => const _i386.UnavailableSavingsInsightsSource(),
    );
    gh.factory<_i897.CalculateSavingsRate>(
      () => _i897.CalculateSavingsRate(gh<_i35.SavingsRateCalculator>()),
    );
    gh.factory<_i435.CalculateDoublingTime>(
      () => _i435.CalculateDoublingTime(gh<_i466.DoublingTimeCalculator>()),
    );
    gh.lazySingleton<_i238.AIService>(
      () => _i57.AIServiceImpl(gh<_i519.Client>()),
    );
    gh.lazySingleton<_i454.SupabaseClient>(
      () => registerModule.supabaseClient(gh<_i822.SupabaseInitializer>()),
    );
    gh.lazySingleton<_i445.BundledEducationContentDataSource>(
      () => _i445.BundledEducationContentDataSource(gh<_i281.AssetBundle>()),
    );
    gh.lazySingleton<_i753.SyncRemoteDataSource>(
      () => _i753.SupabaseSyncRemoteDataSource(gh<_i822.SupabaseInitializer>()),
    );
    gh.lazySingleton<_i68.BiometricService>(
      () => _i791.LocalAuthBiometricService(gh<_i152.LocalAuthentication>()),
    );
    gh.lazySingleton<_i834.SyncMapperRegistry>(
      () => registerModule.syncMapperRegistry(
        gh<_i334.PersonSyncMapper>(),
        gh<_i315.MoneyTransactionSyncMapper>(),
        gh<_i92.TransactionAuditSyncMapper>(),
        gh<_i539.FinanceCategorySyncMapper>(),
        gh<_i960.FinanceEntrySyncMapper>(),
        gh<_i770.ExchangeRateSyncMapper>(),
        gh<_i900.PrimaryCurrencySyncMapper>(),
        gh<_i346.ConflictResolutionSyncMapper>(),
        gh<_i1001.OccasionSyncMapper>(),
        gh<_i56.BudgetSyncMapper>(),
        gh<_i56.BudgetAllocationSyncMapper>(),
      ),
    );
    gh.lazySingleton<_i972.ConnectivityMonitor>(
      () => _i972.ConnectivityPlusMonitor(gh<_i895.Connectivity>()),
    );
    gh.lazySingleton<_i1055.EducationContentRepository>(
      () => _i549.EducationContentRepositoryImpl(
        gh<_i445.BundledEducationContentDataSource>(),
      ),
    );
    gh.factory<_i217.CalculateCompoundGrowth>(
      () => _i217.CalculateCompoundGrowth(gh<_i585.CompoundGrowthCalculator>()),
    );
    gh.factory<_i896.CompoundGrowthCalculatorCubit>(
      () => _i896.CompoundGrowthCalculatorCubit(
        gh<_i217.CalculateCompoundGrowth>(),
        gh<_i60.GetPrefillableSavingsGoalAmount>(),
        gh<_i999.EgpFormatter>(),
      ),
    );
    gh.lazySingleton<_i209.NotificationScheduler>(
      () => _i0.FlutterLocalNotificationsScheduler(
        gh<_i163.FlutterLocalNotificationsPlugin>(),
      ),
    );
    gh.lazySingleton<_i164.SyncBootstrap>(
      () => registerModule.syncBootstrap(
        gh<_i834.SyncMapperRegistry>(),
        gh<_i414.SyncLogger>(),
        gh<_i956.AppClock>(),
      ),
    );
    gh.lazySingleton<_i982.AppDatabase>(
      () => registerModule.appDatabase(gh<_i164.SyncBootstrap>()),
    );
    gh.lazySingleton<_i193.SecureStorageWiper>(
      () => _i236.AppLockSecureStorageWiper(gh<_i872.SecureAppLockStorage>()),
    );
    gh.factory<_i66.SavingsRateCalculatorCubit>(
      () => _i66.SavingsRateCalculatorCubit(
        gh<_i897.CalculateSavingsRate>(),
        gh<_i999.EgpFormatter>(),
      ),
    );
    gh.factory<_i811.DoublingTimeCalculatorCubit>(
      () => _i811.DoublingTimeCalculatorCubit(
        gh<_i435.CalculateDoublingTime>(),
        gh<_i999.EgpFormatter>(),
      ),
    );
    gh.lazySingleton<_i98.AppLockRepository>(
      () => _i731.AppLockRepositoryImpl(
        gh<_i872.SecureAppLockStorage>(),
        gh<_i316.PinHasher>(),
        gh<_i12.LockoutPolicy>(),
      ),
    );
    gh.factory<_i481.GetArticle>(
      () => _i481.GetArticle(gh<_i1055.EducationContentRepository>()),
    );
    gh.factory<_i657.GetCategoryArticles>(
      () => _i657.GetCategoryArticles(gh<_i1055.EducationContentRepository>()),
    );
    gh.factory<_i805.GetEducationCategories>(
      () =>
          _i805.GetEducationCategories(gh<_i1055.EducationContentRepository>()),
    );
    gh.lazySingleton<_i840.SyncOutbox>(
      () =>
          _i840.DriftSyncOutbox(gh<_i982.AppDatabase>(), gh<_i956.AppClock>()),
    );
    gh.factory<_i792.OccasionsDao>(
      () => _i792.OccasionsDao(
        gh<_i982.AppDatabase>(),
        gh<_i840.SyncOutbox>(),
        gh<_i1001.OccasionSyncMapper>(),
      ),
    );
    gh.factory<_i973.CurrencyDao>(
      () => _i973.CurrencyDao(
        gh<_i982.AppDatabase>(),
        gh<_i840.SyncOutbox>(),
        gh<_i770.ExchangeRateSyncMapper>(),
        gh<_i900.PrimaryCurrencySyncMapper>(),
      ),
    );
    gh.lazySingleton<_i623.SyncApplier>(
      () => registerModule.syncApplier(
        gh<_i982.AppDatabase>(),
        gh<_i834.SyncMapperRegistry>(),
        gh<_i956.AppClock>(),
      ),
    );
    gh.lazySingleton<_i439.AppLockStatusProvider>(
      () => _i251.RepositoryAppLockStatusProvider(gh<_i98.AppLockRepository>()),
    );
    gh.lazySingleton<_i289.CurrencyUsageChecker>(
      () => _i941.DriftCurrencyUsageChecker(gh<_i982.AppDatabase>()),
    );
    gh.factory<_i244.RecoverViaBiometric>(
      () => _i244.RecoverViaBiometric(
        gh<_i98.AppLockRepository>(),
        gh<_i68.BiometricService>(),
      ),
    );
    gh.factory<_i561.SetBiometricEnabled>(
      () => _i561.SetBiometricEnabled(
        gh<_i98.AppLockRepository>(),
        gh<_i68.BiometricService>(),
      ),
    );
    gh.factory<_i245.VerifyBiometric>(
      () => _i245.VerifyBiometric(
        gh<_i98.AppLockRepository>(),
        gh<_i68.BiometricService>(),
      ),
    );
    gh.lazySingleton<_i1004.DataWipeRepository>(
      () => _i913.DataWipeRepositoryImpl(gh<_i982.AppDatabase>()),
    );
    gh.factory<_i570.ChangePin>(
      () => _i570.ChangePin(gh<_i98.AppLockRepository>()),
    );
    gh.factory<_i643.DisableAppLock>(
      () => _i643.DisableAppLock(gh<_i98.AppLockRepository>()),
    );
    gh.factory<_i590.EnableAppLock>(
      () => _i590.EnableAppLock(gh<_i98.AppLockRepository>()),
    );
    gh.factory<_i485.GetAppLockConfig>(
      () => _i485.GetAppLockConfig(gh<_i98.AppLockRepository>()),
    );
    gh.factory<_i625.GetLockoutState>(
      () => _i625.GetLockoutState(gh<_i98.AppLockRepository>()),
    );
    gh.factory<_i609.RecordFailedPinAttempt>(
      () => _i609.RecordFailedPinAttempt(gh<_i98.AppLockRepository>()),
    );
    gh.factory<_i252.SetInactivityTimeout>(
      () => _i252.SetInactivityTimeout(gh<_i98.AppLockRepository>()),
    );
    gh.factory<_i557.SetPin>(() => _i557.SetPin(gh<_i98.AppLockRepository>()));
    gh.factory<_i229.VerifyPin>(
      () => _i229.VerifyPin(gh<_i98.AppLockRepository>()),
    );
    gh.factory<_i684.TransactionsDao>(
      () => _i684.TransactionsDao(
        gh<_i982.AppDatabase>(),
        gh<_i840.SyncOutbox>(),
        gh<_i315.MoneyTransactionSyncMapper>(),
        gh<_i92.TransactionAuditSyncMapper>(),
      ),
    );
    gh.factory<_i757.BudgetsDao>(
      () => _i757.BudgetsDao(
        gh<_i982.AppDatabase>(),
        gh<_i840.SyncOutbox>(),
        gh<_i56.BudgetSyncMapper>(),
        gh<_i56.BudgetAllocationSyncMapper>(),
      ),
    );
    gh.factory<_i853.LockScreenCubit>(
      () => _i853.LockScreenCubit(
        gh<_i485.GetAppLockConfig>(),
        gh<_i625.GetLockoutState>(),
        gh<_i229.VerifyPin>(),
        gh<_i609.RecordFailedPinAttempt>(),
        gh<_i245.VerifyBiometric>(),
        gh<_i68.BiometricService>(),
      ),
    );
    gh.factory<_i931.AIAssistantDao>(
      () => _i931.AIAssistantDao(gh<_i982.AppDatabase>()),
    );
    gh.factory<_i338.NotificationsDao>(
      () => _i338.NotificationsDao(gh<_i982.AppDatabase>()),
    );
    gh.factory<_i976.OcrDao>(() => _i976.OcrDao(gh<_i982.AppDatabase>()));
    gh.factory<_i360.OnboardingDao>(
      () => _i360.OnboardingDao(gh<_i982.AppDatabase>()),
    );
    gh.factory<_i586.SettingsDao>(
      () => _i586.SettingsDao(gh<_i982.AppDatabase>()),
    );
    gh.factory<_i265.ContentLibraryCubit>(
      () => _i265.ContentLibraryCubit(gh<_i805.GetEducationCategories>()),
    );
    gh.factory<_i443.FinanceDao>(
      () => _i443.FinanceDao(
        gh<_i982.AppDatabase>(),
        gh<_i840.SyncOutbox>(),
        gh<_i539.FinanceCategorySyncMapper>(),
        gh<_i960.FinanceEntrySyncMapper>(),
      ),
    );
    gh.lazySingleton<_i754.AIAssistantRepository>(
      () => _i988.AIAssistantRepositoryImpl(
        gh<_i931.AIAssistantDao>(),
        gh<_i693.SecureCredentialStore>(),
      ),
    );
    gh.lazySingleton<_i430.OnboardingRepository>(
      () => _i452.OnboardingRepositoryImpl(gh<_i360.OnboardingDao>()),
    );
    gh.factory<_i942.AppLockSettingsCubit>(
      () => _i942.AppLockSettingsCubit(
        gh<_i485.GetAppLockConfig>(),
        gh<_i68.BiometricService>(),
        gh<_i590.EnableAppLock>(),
        gh<_i643.DisableAppLock>(),
        gh<_i561.SetBiometricEnabled>(),
        gh<_i252.SetInactivityTimeout>(),
        gh<_i229.VerifyPin>(),
        gh<_i245.VerifyBiometric>(),
        gh<_i609.RecordFailedPinAttempt>(),
      ),
    );
    gh.lazySingleton<_i87.CurrencyRepository>(
      () => _i751.CurrencyRepositoryImpl(
        gh<_i973.CurrencyDao>(),
        gh<_i956.AppClock>(),
      ),
    );
    gh.factory<_i274.ArticleCubit>(
      () => _i274.ArticleCubit(gh<_i481.GetArticle>()),
    );
    gh.lazySingleton<_i339.SyncLocalStore>(
      () => _i339.DriftSyncLocalStore(
        gh<_i982.AppDatabase>(),
        gh<_i956.AppClock>(),
        gh<_i902.BackoffPolicy>(),
        gh<_i623.SyncApplier>(),
        gh<_i164.SyncBootstrap>(),
      ),
    );
    gh.factory<_i735.PeopleDao>(
      () => _i735.PeopleDao(
        gh<_i982.AppDatabase>(),
        gh<_i840.SyncOutbox>(),
        gh<_i334.PersonSyncMapper>(),
      ),
    );
    gh.factory<_i518.CategoryCubit>(
      () => _i518.CategoryCubit(gh<_i657.GetCategoryArticles>()),
    );
    gh.lazySingleton<_i500.AppLifecycleObserver>(
      () => _i500.AppLifecycleObserver(gh<_i439.AppLockStatusProvider>()),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i846.SyncEngine>(
      () => _i846.SyncEngine(
        gh<_i339.SyncLocalStore>(),
        gh<_i753.SyncRemoteDataSource>(),
        gh<_i597.CloudAuthDataSource>(),
        gh<_i822.SupabaseInitializer>(),
        gh<_i972.ConnectivityMonitor>(),
        gh<_i902.BackoffPolicy>(),
        gh<_i414.SyncLogger>(),
        gh<_i956.AppClock>(),
        gh<_i623.SyncApplier>(),
      ),
    );
    gh.lazySingleton<_i780.AttachmentPickerService>(
      () => _i157.AttachmentPickerServiceImpl(
        gh<_i183.ImagePicker>(),
        gh<_i780.DocumentsDirectory>(),
        gh<_i500.AppLifecycleObserver>(),
      ),
    );
    gh.lazySingleton<_i137.FinanceRepository>(
      () => _i250.FinanceRepositoryImpl(gh<_i443.FinanceDao>()),
    );
    gh.lazySingleton<_i219.ConflictResolver>(
      () => _i219.DriftConflictResolver(
        gh<_i982.AppDatabase>(),
        gh<_i840.SyncOutbox>(),
        gh<_i623.SyncApplier>(),
        gh<_i834.SyncMapperRegistry>(),
        gh<_i956.AppClock>(),
      ),
    );
    gh.lazySingleton<_i957.TransactionsRepository>(
      () => _i373.TransactionsRepositoryImpl(
        gh<_i684.TransactionsDao>(),
        gh<_i982.AppDatabase>(),
        getConversionContext: gh<_i602.GetConversionContext>(),
      ),
    );
    gh.lazySingleton<_i228.CategoryRepository>(
      () => _i816.CategoryRepositoryImpl(gh<_i443.FinanceDao>()),
    );
    gh.lazySingleton<_i235.ImagePreparationService>(
      () => _i450.ImagePreparationServiceImpl(
        gh<_i450.ImageCropperClient>(),
        gh<_i780.DocumentsDirectory>(),
        gh<_i500.AppLifecycleObserver>(),
      ),
    );
    gh.lazySingleton<_i674.SettingsRepository>(
      () => _i955.SettingsRepositoryImpl(gh<_i586.SettingsDao>()),
    );
    gh.factoryParam<_i302.PinSetupCubit, _i595.PinSetupMode, dynamic>(
      (mode, _) => _i302.PinSetupCubit(
        mode,
        gh<_i557.SetPin>(),
        gh<_i570.ChangePin>(),
        gh<_i229.VerifyPin>(),
        gh<_i609.RecordFailedPinAttempt>(),
        gh<_i625.GetLockoutState>(),
        gh<_i485.GetAppLockConfig>(),
        gh<_i245.VerifyBiometric>(),
        gh<_i68.BiometricService>(),
      ),
    );
    gh.factory<_i602.GetConversionContext>(
      () => _i602.GetConversionContext(gh<_i87.CurrencyRepository>()),
    );
    gh.factory<_i764.GetExchangeRates>(
      () => _i764.GetExchangeRates(gh<_i87.CurrencyRepository>()),
    );
    gh.factory<_i903.GetPrimaryCurrency>(
      () => _i903.GetPrimaryCurrency(gh<_i87.CurrencyRepository>()),
    );
    gh.factory<_i681.GetSupportedCurrencies>(
      () => _i681.GetSupportedCurrencies(gh<_i87.CurrencyRepository>()),
    );
    gh.factory<_i1025.RemoveExchangeRate>(
      () => _i1025.RemoveExchangeRate(gh<_i87.CurrencyRepository>()),
    );
    gh.factory<_i486.SetExchangeRate>(
      () => _i486.SetExchangeRate(gh<_i87.CurrencyRepository>()),
    );
    gh.factory<_i132.WatchConversionContext>(
      () => _i132.WatchConversionContext(gh<_i87.CurrencyRepository>()),
    );
    gh.factory<_i166.WatchExchangeRates>(
      () => _i166.WatchExchangeRates(gh<_i87.CurrencyRepository>()),
    );
    gh.factory<_i1028.WatchPrimaryCurrency>(
      () => _i1028.WatchPrimaryCurrency(gh<_i87.CurrencyRepository>()),
    );
    gh.factory<_i801.SetPrimaryCurrency>(
      () => _i801.SetPrimaryCurrency(
        gh<_i87.CurrencyRepository>(),
        gh<_i289.CurrencyUsageChecker>(),
        gh<_i486.SetExchangeRate>(),
      ),
    );
    gh.lazySingleton<_i939.ShareService>(
      () => _i664.SharePlusService(gh<_i500.AppLifecycleObserver>()),
    );
    gh.lazySingleton<_i253.SyncScheduler>(
      () => _i253.SyncScheduler(
        gh<_i846.SyncEngine>(),
        gh<_i339.SyncLocalStore>(),
        gh<_i822.SupabaseInitializer>(),
        gh<_i972.ConnectivityMonitor>(),
        gh<_i982.AppDatabase>(),
        gh<_i902.BackoffPolicy>(),
        gh<_i414.SyncLogger>(),
        gh<_i956.AppClock>(),
      ),
    );
    gh.factory<_i546.ClearConversation>(
      () => _i546.ClearConversation(gh<_i754.AIAssistantRepository>()),
    );
    gh.factory<_i803.DisableAIAssistant>(
      () => _i803.DisableAIAssistant(gh<_i754.AIAssistantRepository>()),
    );
    gh.factory<_i685.EnableAIAssistant>(
      () => _i685.EnableAIAssistant(gh<_i754.AIAssistantRepository>()),
    );
    gh.factory<_i359.GetAIAssistantSettings>(
      () => _i359.GetAIAssistantSettings(gh<_i754.AIAssistantRepository>()),
    );
    gh.factory<_i970.GetConversation>(
      () => _i970.GetConversation(gh<_i754.AIAssistantRepository>()),
    );
    gh.factory<_i763.PurgeAIAssistantCredentials>(
      () =>
          _i763.PurgeAIAssistantCredentials(gh<_i754.AIAssistantRepository>()),
    );
    gh.factory<_i739.UpdateProviderCredentials>(
      () => _i739.UpdateProviderCredentials(gh<_i754.AIAssistantRepository>()),
    );
    gh.factory<_i854.GetCategoryBreakdown>(
      () => _i854.GetCategoryBreakdown(
        gh<_i137.FinanceRepository>(),
        gh<_i602.GetConversionContext>(),
        gh<_i966.CurrencyConverter>(),
      ),
    );
    gh.factory<_i844.GetFinanceSummary>(
      () => _i844.GetFinanceSummary(
        gh<_i137.FinanceRepository>(),
        gh<_i602.GetConversionContext>(),
        gh<_i966.CurrencyConverter>(),
      ),
    );
    gh.factory<_i924.CompareSpendingAcrossPeriodsTool>(
      () => _i924.CompareSpendingAcrossPeriodsTool(
        gh<_i844.GetFinanceSummary>(),
        gh<_i1038.AIPeriodResolver>(),
      ),
    );
    gh.lazySingleton<_i646.PeopleRepository>(
      () => _i1029.PeopleRepositoryImpl(
        gh<_i735.PeopleDao>(),
        gh<_i769.FindPossibleDuplicatePerson>(),
        gh<_i982.AppDatabase>(),
        getConversionContext: gh<_i602.GetConversionContext>(),
      ),
    );
    gh.factory<_i954.ExchangeRateFormCubit>(
      () => _i954.ExchangeRateFormCubit(
        gh<_i903.GetPrimaryCurrency>(),
        gh<_i764.GetExchangeRates>(),
        gh<_i486.SetExchangeRate>(),
      ),
    );
    gh.factory<_i240.WatchFinanceSummary>(
      () => _i240.WatchFinanceSummary(
        gh<_i137.FinanceRepository>(),
        gh<_i132.WatchConversionContext>(),
        gh<_i844.GetFinanceSummary>(),
      ),
    );
    gh.factory<_i508.WatchSpendingTrend>(
      () => _i508.WatchSpendingTrend(
        gh<_i137.FinanceRepository>(),
        gh<_i132.WatchConversionContext>(),
        gh<_i844.GetFinanceSummary>(),
      ),
    );
    gh.lazySingleton<_i13.NotificationHistoryRepository>(
      () =>
          _i551.NotificationHistoryRepositoryImpl(gh<_i338.NotificationsDao>()),
    );
    gh.lazySingleton<_i162.NotificationPreferenceRepository>(
      () => _i701.NotificationPreferenceRepositoryImpl(
        gh<_i338.NotificationsDao>(),
      ),
    );
    gh.factory<_i5.AddTransaction>(
      () => _i5.AddTransaction(gh<_i957.TransactionsRepository>()),
    );
    gh.factory<_i645.DeleteTransaction>(
      () => _i645.DeleteTransaction(gh<_i957.TransactionsRepository>()),
    );
    gh.factory<_i554.EditTransaction>(
      () => _i554.EditTransaction(gh<_i957.TransactionsRepository>()),
    );
    gh.factory<_i943.GetOverview>(
      () => _i943.GetOverview(gh<_i957.TransactionsRepository>()),
    );
    gh.factory<_i750.GetPersonBalance>(
      () => _i750.GetPersonBalance(gh<_i957.TransactionsRepository>()),
    );
    gh.factory<_i313.GetPersonBalances>(
      () => _i313.GetPersonBalances(gh<_i957.TransactionsRepository>()),
    );
    gh.factory<_i610.GetPersonHistory>(
      () => _i610.GetPersonHistory(gh<_i957.TransactionsRepository>()),
    );
    gh.factory<_i426.RecordRepayment>(
      () => _i426.RecordRepayment(gh<_i957.TransactionsRepository>()),
    );
    gh.factory<_i615.WatchOverview>(
      () => _i615.WatchOverview(gh<_i957.TransactionsRepository>()),
    );
    gh.factory<_i221.WatchPersonBalance>(
      () => _i221.WatchPersonBalance(gh<_i957.TransactionsRepository>()),
    );
    gh.factory<_i330.WatchPersonBalances>(
      () => _i330.WatchPersonBalances(gh<_i957.TransactionsRepository>()),
    );
    gh.factory<_i210.WatchPersonHistory>(
      () => _i210.WatchPersonHistory(gh<_i957.TransactionsRepository>()),
    );
    gh.factory<_i65.GetProactiveObservationTool>(
      () => _i65.GetProactiveObservationTool(
        gh<_i924.CompareSpendingAcrossPeriodsTool>(),
        gh<_i1038.AIPeriodResolver>(),
      ),
    );
    gh.factory<_i577.ChangeGlassAppearance>(
      () => _i577.ChangeGlassAppearance(gh<_i674.SettingsRepository>()),
    );
    gh.factory<_i90.ChangeLanguage>(
      () => _i90.ChangeLanguage(gh<_i674.SettingsRepository>()),
    );
    gh.factory<_i46.ChangeThemeMode>(
      () => _i46.ChangeThemeMode(gh<_i674.SettingsRepository>()),
    );
    gh.factory<_i499.GetGlassAppearancePreference>(
      () => _i499.GetGlassAppearancePreference(gh<_i674.SettingsRepository>()),
    );
    gh.factory<_i1032.GetLanguagePreference>(
      () => _i1032.GetLanguagePreference(gh<_i674.SettingsRepository>()),
    );
    gh.factory<_i333.GetThemeModePreference>(
      () => _i333.GetThemeModePreference(gh<_i674.SettingsRepository>()),
    );
    gh.factory<_i1050.GetTopSpendingCategoryTool>(
      () => _i1050.GetTopSpendingCategoryTool(
        gh<_i854.GetCategoryBreakdown>(),
        gh<_i1038.AIPeriodResolver>(),
      ),
    );
    gh.lazySingleton<_i222.CloudCopyEraser>(
      () => _i223.SupabaseCloudCopyEraser(
        gh<_i822.SupabaseInitializer>(),
        gh<_i253.SyncScheduler>(),
        gh<_i339.SyncLocalStore>(),
        gh<_i558.FlutterSecureStorage>(),
      ),
    );
    gh.factory<_i24.CreateCategory>(
      () => _i24.CreateCategory(gh<_i228.CategoryRepository>()),
    );
    gh.factory<_i611.EditCategory>(
      () => _i611.EditCategory(gh<_i228.CategoryRepository>()),
    );
    gh.factory<_i1.GetCategories>(
      () => _i1.GetCategories(gh<_i228.CategoryRepository>()),
    );
    gh.factory<_i490.RemoveCategory>(
      () => _i490.RemoveCategory(gh<_i228.CategoryRepository>()),
    );
    gh.factory<_i717.SeedDefaultCategories>(
      () => _i717.SeedDefaultCategories(gh<_i228.CategoryRepository>()),
    );
    gh.factory<_i520.WatchCategories>(
      () => _i520.WatchCategories(gh<_i228.CategoryRepository>()),
    );
    gh.lazySingleton<_i855.BudgetsRepository>(
      () => _i249.BudgetsRepositoryImpl(
        gh<_i757.BudgetsDao>(),
        gh<_i982.AppDatabase>(),
        gh<_i137.FinanceRepository>(),
        gh<_i228.CategoryRepository>(),
        gh<_i602.GetConversionContext>(),
        gh<_i966.CurrencyConverter>(),
      ),
    );
    gh.factory<_i917.GetCategorySpendTool>(
      () => _i917.GetCategorySpendTool(
        gh<_i854.GetCategoryBreakdown>(),
        gh<_i1.GetCategories>(),
        gh<_i1038.AIPeriodResolver>(),
      ),
    );
    gh.factory<_i159.AddFinanceEntry>(
      () => _i159.AddFinanceEntry(gh<_i137.FinanceRepository>()),
    );
    gh.factory<_i1065.DeleteFinanceEntry>(
      () => _i1065.DeleteFinanceEntry(gh<_i137.FinanceRepository>()),
    );
    gh.factory<_i416.EditFinanceEntry>(
      () => _i416.EditFinanceEntry(gh<_i137.FinanceRepository>()),
    );
    gh.factory<_i27.GetFinanceHistory>(
      () => _i27.GetFinanceHistory(gh<_i137.FinanceRepository>()),
    );
    gh.factory<_i1008.RestoreFinanceEntry>(
      () => _i1008.RestoreFinanceEntry(gh<_i137.FinanceRepository>()),
    );
    gh.factory<_i542.WatchFinanceHistory>(
      () => _i542.WatchFinanceHistory(gh<_i137.FinanceRepository>()),
    );
    gh.factory<_i74.WatchCategoryBreakdown>(
      () => _i74.WatchCategoryBreakdown(
        gh<_i137.FinanceRepository>(),
        gh<_i132.WatchConversionContext>(),
        gh<_i854.GetCategoryBreakdown>(),
      ),
    );
    gh.factory<_i1061.PrimaryCurrencyCubit>(
      () => _i1061.PrimaryCurrencyCubit(
        gh<_i1028.WatchPrimaryCurrency>(),
        gh<_i801.SetPrimaryCurrency>(),
      ),
    );
    gh.factory<_i354.ScanCaptureCubit>(
      () => _i354.ScanCaptureCubit(
        gh<_i780.AttachmentPickerService>(),
        gh<_i235.ImagePreparationService>(),
        gh<_i176.TextRecognitionService>(),
      ),
    );
    gh.factory<_i203.SetNotificationPreferences>(
      () => _i203.SetNotificationPreferences(
        gh<_i162.NotificationPreferenceRepository>(),
      ),
    );
    gh.factory<_i323.GetSpendingTrend>(
      () => _i323.GetSpendingTrend(gh<_i844.GetFinanceSummary>()),
    );
    gh.lazySingleton<_i948.CloudSyncRepository>(
      () => _i241.CloudSyncRepositoryImpl(
        gh<_i982.AppDatabase>(),
        gh<_i219.ConflictResolver>(),
        gh<_i253.SyncScheduler>(),
        gh<_i339.SyncLocalStore>(),
        gh<_i597.CloudAuthDataSource>(),
        gh<_i822.SupabaseInitializer>(),
      ),
    );
    gh.lazySingleton<_i1003.NotificationLanguageProvider>(
      () => _i831.SettingsNotificationLanguageProvider(
        gh<_i1032.GetLanguagePreference>(),
        gh<_i933.DeviceLocaleProvider>(),
      ),
    );
    gh.factory<_i742.AISettingsCubit>(
      () => _i742.AISettingsCubit(
        gh<_i359.GetAIAssistantSettings>(),
        gh<_i685.EnableAIAssistant>(),
        gh<_i803.DisableAIAssistant>(),
        gh<_i739.UpdateProviderCredentials>(),
        gh<_i1023.AIProviderCatalog>(),
      ),
    );
    gh.lazySingleton<_i72.OccasionsRepository>(
      () => _i455.OccasionsRepositoryImpl(
        gh<_i792.OccasionsDao>(),
        gh<_i957.TransactionsRepository>(),
        gh<_i646.PeopleRepository>(),
        gh<_i982.AppDatabase>(),
        gh<_i602.GetConversionContext>(),
        gh<_i966.CurrencyConverter>(),
      ),
    );
    gh.factory<_i20.GetPossibleDuplicateForCandidate>(
      () => _i20.GetPossibleDuplicateForCandidate(
        gh<_i646.PeopleRepository>(),
        gh<_i769.FindPossibleDuplicatePerson>(),
      ),
    );
    gh.factory<_i109.CategoryManagementCubit>(
      () => _i109.CategoryManagementCubit(
        gh<_i520.WatchCategories>(),
        gh<_i490.RemoveCategory>(),
      ),
    );
    gh.factory<_i431.DeleteAllUserData>(
      () => _i431.DeleteAllUserData(
        gh<_i1004.DataWipeRepository>(),
        gh<_i763.PurgeAIAssistantCredentials>(),
        gh<_i193.SecureStorageWiper>(),
        gh<_i222.CloudCopyEraser>(),
      ),
    );
    gh.factory<_i103.GetProactiveObservation>(
      () => _i103.GetProactiveObservation(
        gh<_i754.AIAssistantRepository>(),
        gh<_i238.AIService>(),
        gh<_i65.GetProactiveObservationTool>(),
        gh<_i775.SystemPromptBuilder>(),
        gh<_i1038.AIPeriodResolver>(),
      ),
    );
    gh.factory<_i398.ExchangeRateListCubit>(
      () => _i398.ExchangeRateListCubit(
        gh<_i1028.WatchPrimaryCurrency>(),
        gh<_i166.WatchExchangeRates>(),
        gh<_i1025.RemoveExchangeRate>(),
      ),
    );
    gh.factory<_i1049.GetPersonBalanceTool>(
      () => _i1049.GetPersonBalanceTool(
        gh<_i750.GetPersonBalance>(),
        gh<_i646.PeopleRepository>(),
      ),
    );
    gh.factory<_i987.FinanceHistoryCubit>(
      () => _i987.FinanceHistoryCubit(
        gh<_i240.WatchFinanceSummary>(),
        gh<_i854.GetCategoryBreakdown>(),
        gh<_i542.WatchFinanceHistory>(),
        gh<_i520.WatchCategories>(),
        gh<_i1065.DeleteFinanceEntry>(),
        gh<_i1008.RestoreFinanceEntry>(),
        gh<_i137.FinanceRepository>(),
      ),
    );
    gh.lazySingleton<_i578.OcrRepository>(
      () => _i457.OcrRepositoryImpl(
        gh<_i976.OcrDao>(),
        gh<_i176.TextRecognitionService>(),
        gh<_i918.CandidateEntryParser>(),
        gh<_i957.TransactionsRepository>(),
        gh<_i72.OccasionsRepository>(),
        gh<_i646.PeopleRepository>(),
        gh<_i903.GetPrimaryCurrency>(),
        gh<_i982.AppDatabase>(),
      ),
    );
    gh.factory<_i793.ResolveOnboardingStatus>(
      () => _i793.ResolveOnboardingStatus(
        gh<_i430.OnboardingRepository>(),
        gh<_i646.PeopleRepository>(),
        gh<_i957.TransactionsRepository>(),
      ),
    );
    gh.factory<_i224.ArchivePerson>(
      () => _i224.ArchivePerson(gh<_i646.PeopleRepository>()),
    );
    gh.factory<_i789.CreatePerson>(
      () => _i789.CreatePerson(gh<_i646.PeopleRepository>()),
    );
    gh.factory<_i907.DeletePerson>(
      () => _i907.DeletePerson(gh<_i646.PeopleRepository>()),
    );
    gh.factory<_i101.EditPerson>(
      () => _i101.EditPerson(gh<_i646.PeopleRepository>()),
    );
    gh.factory<_i49.RestorePerson>(
      () => _i49.RestorePerson(gh<_i646.PeopleRepository>()),
    );
    gh.factory<_i277.WatchActivePeople>(
      () => _i277.WatchActivePeople(gh<_i646.PeopleRepository>()),
    );
    gh.factory<_i781.WatchArchivedPeople>(
      () => _i781.WatchArchivedPeople(gh<_i646.PeopleRepository>()),
    );
    gh.factory<_i462.WatchPerson>(
      () => _i462.WatchPerson(gh<_i646.PeopleRepository>()),
    );
    gh.factory<_i496.ExportUserData>(
      () => _i496.ExportUserData(
        gh<_i646.PeopleRepository>(),
        gh<_i957.TransactionsRepository>(),
        gh<_i137.FinanceRepository>(),
        gh<_i228.CategoryRepository>(),
        gh<_i674.SettingsRepository>(),
        gh<_i52.ExportDirectoryProvider>(),
      ),
    );
    gh.factory<_i1018.PersonListCubit>(
      () => _i1018.PersonListCubit(
        gh<_i277.WatchActivePeople>(),
        gh<_i330.WatchPersonBalances>(),
        gh<_i224.ArchivePerson>(),
        gh<_i49.RestorePerson>(),
      ),
    );
    gh.factory<_i639.RequestNotificationPermission>(
      () => _i639.RequestNotificationPermission(
        gh<_i209.NotificationScheduler>(),
        gh<_i162.NotificationPreferenceRepository>(),
      ),
    );
    gh.factory<_i613.WipeAllLocalData>(
      () => _i613.WipeAllLocalData(gh<_i431.DeleteAllUserData>()),
    );
    gh.lazySingleton<_i794.SettingsCubit>(
      () => _i794.SettingsCubit(
        gh<_i1032.GetLanguagePreference>(),
        gh<_i90.ChangeLanguage>(),
        gh<_i933.DeviceLocaleProvider>(),
        gh<_i333.GetThemeModePreference>(),
        gh<_i46.ChangeThemeMode>(),
        gh<_i499.GetGlassAppearancePreference>(),
        gh<_i577.ChangeGlassAppearance>(),
      ),
    );
    gh.factory<_i305.AcknowledgeSyncNotice>(
      () => _i305.AcknowledgeSyncNotice(gh<_i948.CloudSyncRepository>()),
    );
    gh.factory<_i394.ConfirmEmailCode>(
      () => _i394.ConfirmEmailCode(gh<_i948.CloudSyncRepository>()),
    );
    gh.factory<_i861.RequestEmailCode>(
      () => _i861.RequestEmailCode(gh<_i948.CloudSyncRepository>()),
    );
    gh.factory<_i1030.ResolveSyncConflict>(
      () => _i1030.ResolveSyncConflict(gh<_i948.CloudSyncRepository>()),
    );
    gh.factory<_i259.RetryFailedSync>(
      () => _i259.RetryFailedSync(gh<_i948.CloudSyncRepository>()),
    );
    gh.factory<_i676.SetSyncEnabled>(
      () => _i676.SetSyncEnabled(gh<_i948.CloudSyncRepository>()),
    );
    gh.factory<_i399.SyncNow>(
      () => _i399.SyncNow(gh<_i948.CloudSyncRepository>()),
    );
    gh.factory<_i389.WatchFailedSyncItems>(
      () => _i389.WatchFailedSyncItems(gh<_i948.CloudSyncRepository>()),
    );
    gh.factory<_i1039.WatchSyncConflicts>(
      () => _i1039.WatchSyncConflicts(gh<_i948.CloudSyncRepository>()),
    );
    gh.factory<_i178.WatchSyncStatus>(
      () => _i178.WatchSyncStatus(gh<_i948.CloudSyncRepository>()),
    );
    gh.factoryParam<_i34.RepaymentFormCubit, String, dynamic>(
      (personId, _) => _i34.RepaymentFormCubit(
        gh<_i426.RecordRepayment>(),
        gh<_i903.GetPrimaryCurrency>(),
        personId,
      ),
    );
    gh.factory<_i552.AddBudgetCategoryAllocation>(
      () => _i552.AddBudgetCategoryAllocation(gh<_i855.BudgetsRepository>()),
    );
    gh.factory<_i809.CopyBudgetToMonth>(
      () => _i809.CopyBudgetToMonth(gh<_i855.BudgetsRepository>()),
    );
    gh.factory<_i254.CreateBudget>(
      () => _i254.CreateBudget(gh<_i855.BudgetsRepository>()),
    );
    gh.factory<_i150.DeleteBudget>(
      () => _i150.DeleteBudget(gh<_i855.BudgetsRepository>()),
    );
    gh.factory<_i755.EditBudget>(
      () => _i755.EditBudget(gh<_i855.BudgetsRepository>()),
    );
    gh.factory<_i934.EditBudgetCategoryAllocation>(
      () => _i934.EditBudgetCategoryAllocation(gh<_i855.BudgetsRepository>()),
    );
    gh.factory<_i587.GetBudgetForMonth>(
      () => _i587.GetBudgetForMonth(gh<_i855.BudgetsRepository>()),
    );
    gh.factory<_i438.GetBudgetTrend>(
      () => _i438.GetBudgetTrend(gh<_i855.BudgetsRepository>()),
    );
    gh.factory<_i654.GetMostRecentBudgetBefore>(
      () => _i654.GetMostRecentBudgetBefore(gh<_i855.BudgetsRepository>()),
    );
    gh.factory<_i317.RemoveBudgetCategoryAllocation>(
      () => _i317.RemoveBudgetCategoryAllocation(gh<_i855.BudgetsRepository>()),
    );
    gh.factory<_i1021.WatchBudgetForMonth>(
      () => _i1021.WatchBudgetForMonth(gh<_i855.BudgetsRepository>()),
    );
    gh.factory<_i621.WatchBudgetTrend>(
      () => _i621.WatchBudgetTrend(gh<_i855.BudgetsRepository>()),
    );
    gh.factory<_i14.GetOwedOverviewTool>(
      () => _i14.GetOwedOverviewTool(gh<_i943.GetOverview>()),
    );
    gh.factory<_i273.SyncConflictsCubit>(
      () => _i273.SyncConflictsCubit(
        gh<_i1039.WatchSyncConflicts>(),
        gh<_i1030.ResolveSyncConflict>(),
      ),
    );
    gh.factory<_i1031.BudgetMonthCubit>(
      () => _i1031.BudgetMonthCubit(gh<_i1021.WatchBudgetForMonth>()),
    );
    gh.lazySingleton<_i423.BudgetInsightsSource>(
      () => _i582.BudgetsInsightsSource(gh<_i855.BudgetsRepository>()),
    );
    gh.factory<_i1033.CategoryFormCubit>(
      () => _i1033.CategoryFormCubit(
        gh<_i24.CreateCategory>(),
        gh<_i611.EditCategory>(),
      ),
    );
    gh.factory<_i179.BudgetTrendCubit>(
      () => _i179.BudgetTrendCubit(
        gh<_i621.WatchBudgetTrend>(),
        gh<_i520.WatchCategories>(),
      ),
    );
    gh.factory<_i505.FinanceEntryFormCubit>(
      () => _i505.FinanceEntryFormCubit(
        gh<_i159.AddFinanceEntry>(),
        gh<_i416.EditFinanceEntry>(),
        gh<_i1.GetCategories>(),
        gh<_i999.EgpFormatter>(),
        gh<_i903.GetPrimaryCurrency>(),
      ),
    );
    gh.factory<_i25.DashboardCubit>(
      () => _i25.DashboardCubit(
        gh<_i615.WatchOverview>(),
        gh<_i240.WatchFinanceSummary>(),
        gh<_i542.WatchFinanceHistory>(),
      ),
    );
    gh.factory<_i782.ExportCubit>(
      () => _i782.ExportCubit(
        gh<_i496.ExportUserData>(),
        gh<_i939.ShareService>(),
      ),
    );
    gh.factory<_i377.CancelScan>(
      () => _i377.CancelScan(gh<_i578.OcrRepository>()),
    );
    gh.factory<_i665.ConfirmScanBatch>(
      () => _i665.ConfirmScanBatch(gh<_i578.OcrRepository>()),
    );
    gh.factory<_i413.DeleteScan>(
      () => _i413.DeleteScan(gh<_i578.OcrRepository>()),
    );
    gh.factory<_i256.DiscardCandidateEntry>(
      () => _i256.DiscardCandidateEntry(gh<_i578.OcrRepository>()),
    );
    gh.factory<_i506.EditCandidateEntry>(
      () => _i506.EditCandidateEntry(gh<_i578.OcrRepository>()),
    );
    gh.factory<_i303.GetCandidateEntries>(
      () => _i303.GetCandidateEntries(gh<_i578.OcrRepository>()),
    );
    gh.factory<_i267.GetScanDetail>(
      () => _i267.GetScanDetail(gh<_i578.OcrRepository>()),
    );
    gh.factory<_i331.GetScanHistory>(
      () => _i331.GetScanHistory(gh<_i578.OcrRepository>()),
    );
    gh.factory<_i350.RunOcrExtraction>(
      () => _i350.RunOcrExtraction(gh<_i578.OcrRepository>()),
    );
    gh.factory<_i1011.SetBatchDefaultDirection>(
      () => _i1011.SetBatchDefaultDirection(gh<_i578.OcrRepository>()),
    );
    gh.factory<_i856.StartScan>(
      () => _i856.StartScan(gh<_i578.OcrRepository>()),
    );
    gh.factory<_i237.TagBatchToOccasion>(
      () => _i237.TagBatchToOccasion(gh<_i578.OcrRepository>()),
    );
    gh.factory<_i138.WatchScanDetail>(
      () => _i138.WatchScanDetail(gh<_i578.OcrRepository>()),
    );
    gh.factory<_i130.WatchScanHistory>(
      () => _i130.WatchScanHistory(gh<_i578.OcrRepository>()),
    );
    gh.factory<_i329.ReportsCubit>(
      () => _i329.ReportsCubit(
        gh<_i508.WatchSpendingTrend>(),
        gh<_i74.WatchCategoryBreakdown>(),
        gh<_i137.FinanceRepository>(),
      ),
    );
    gh.factory<_i28.CopyBudgetCubit>(
      () => _i28.CopyBudgetCubit(
        gh<_i654.GetMostRecentBudgetBefore>(),
        gh<_i809.CopyBudgetToMonth>(),
      ),
    );
    gh.factory<_i1005.EmailLinkCubit>(
      () => _i1005.EmailLinkCubit(
        gh<_i861.RequestEmailCode>(),
        gh<_i394.ConfirmEmailCode>(),
      ),
    );
    gh.factory<_i738.SyncNoticeCubit>(
      () => _i738.SyncNoticeCubit(
        gh<_i178.WatchSyncStatus>(),
        gh<_i305.AcknowledgeSyncNotice>(),
      ),
    );
    gh.factory<_i593.TransactionFormCubit>(
      () => _i593.TransactionFormCubit(
        gh<_i646.PeopleRepository>(),
        gh<_i789.CreatePerson>(),
        gh<_i5.AddTransaction>(),
        gh<_i554.EditTransaction>(),
        gh<_i903.GetPrimaryCurrency>(),
      ),
    );
    gh.lazySingleton<_i807.OnboardingCubit>(
      () => _i807.OnboardingCubit(
        gh<_i793.ResolveOnboardingStatus>(),
        gh<_i430.OnboardingRepository>(),
      ),
    );
    gh.factory<_i247.AddOccasionAttachment>(
      () => _i247.AddOccasionAttachment(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i415.AddParticipantContribution>(
      () => _i415.AddParticipantContribution(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i847.ArchiveOccasion>(
      () => _i847.ArchiveOccasion(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i905.CreateOccasion>(
      () => _i905.CreateOccasion(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i1046.DeleteOccasion>(
      () => _i1046.DeleteOccasion(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i712.EditOccasion>(
      () => _i712.EditOccasion(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i153.EditParticipantContribution>(
      () => _i153.EditParticipantContribution(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i432.GetOccasionDetail>(
      () => _i432.GetOccasionDetail(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i958.GetOccasionsList>(
      () => _i958.GetOccasionsList(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i191.RemoveOccasionAttachment>(
      () => _i191.RemoveOccasionAttachment(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i192.RemoveParticipantContribution>(
      () => _i192.RemoveParticipantContribution(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i154.RestoreOccasion>(
      () => _i154.RestoreOccasion(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i294.WatchOccasionDetail>(
      () => _i294.WatchOccasionDetail(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i276.WatchOccasionsList>(
      () => _i276.WatchOccasionsList(gh<_i72.OccasionsRepository>()),
    );
    gh.factory<_i622.ScanReviewCubit>(
      () => _i622.ScanReviewCubit(
        gh<_i267.GetScanDetail>(),
        gh<_i303.GetCandidateEntries>(),
        gh<_i506.EditCandidateEntry>(),
        gh<_i256.DiscardCandidateEntry>(),
        gh<_i665.ConfirmScanBatch>(),
        gh<_i377.CancelScan>(),
        gh<_i1011.SetBatchDefaultDirection>(),
        gh<_i237.TagBatchToOccasion>(),
        gh<_i20.GetPossibleDuplicateForCandidate>(),
        gh<_i999.EgpFormatter>(),
      ),
    );
    gh.factory<_i62.ArchivedPeopleCubit>(
      () => _i62.ArchivedPeopleCubit(
        gh<_i781.WatchArchivedPeople>(),
        gh<_i49.RestorePerson>(),
      ),
    );
    gh.lazySingleton<_i553.NotificationEngine>(
      () => _i553.NotificationEngineImpl(
        gh<_i162.NotificationPreferenceRepository>(),
        gh<_i13.NotificationHistoryRepository>(),
        gh<_i423.BudgetInsightsSource>(),
        gh<_i842.SavingsInsightsSource>(),
        gh<_i983.EvaluateBudgetNotifications>(),
        gh<_i371.EvaluateSavingsGoalNotifications>(),
        gh<_i104.NotificationComposer>(),
        gh<_i721.NotificationPhrasingService>(),
        gh<_i209.NotificationScheduler>(),
        gh<_i956.AppClock>(),
        gh<_i1003.NotificationLanguageProvider>(),
        gh<_i220.NotificationLastRunStore>(),
      ),
    );
    gh.factory<_i668.PersonFormCubit>(
      () => _i668.PersonFormCubit(
        gh<_i646.PeopleRepository>(),
        gh<_i789.CreatePerson>(),
        gh<_i101.EditPerson>(),
        gh<_i224.ArchivePerson>(),
        gh<_i907.DeletePerson>(),
      ),
    );
    gh.factory<_i185.ArchivedOccasionsCubit>(
      () => _i185.ArchivedOccasionsCubit(
        gh<_i276.WatchOccasionsList>(),
        gh<_i154.RestoreOccasion>(),
      ),
    );
    gh.lazySingleton<_i548.NotificationRecomputeTrigger>(
      () => _i548.NotificationRecomputeTrigger(
        gh<_i553.NotificationEngine>(),
        gh<_i220.NotificationLastRunStore>(),
        gh<_i956.AppClock>(),
      ),
    );
    gh.factory<_i666.GetOccasionTotalsTool>(
      () => _i666.GetOccasionTotalsTool(
        gh<_i432.GetOccasionDetail>(),
        gh<_i958.GetOccasionsList>(),
      ),
    );
    gh.factory<_i39.NotificationSettingsCubit>(
      () => _i39.NotificationSettingsCubit(
        gh<_i203.SetNotificationPreferences>(),
        gh<_i639.RequestNotificationPermission>(),
      ),
    );
    gh.factory<_i944.ForgotPinCubit>(
      () => _i944.ForgotPinCubit(
        gh<_i244.RecoverViaBiometric>(),
        gh<_i613.WipeAllLocalData>(),
        gh<_i807.OnboardingCubit>(),
      ),
    );
    gh.factory<_i992.PersonDetailCubit>(
      () => _i992.PersonDetailCubit(
        gh<_i462.WatchPerson>(),
        gh<_i221.WatchPersonBalance>(),
        gh<_i210.WatchPersonHistory>(),
        gh<_i645.DeleteTransaction>(),
        gh<_i1028.WatchPrimaryCurrency>(),
        gh<_i957.TransactionsRepository>(),
      ),
    );
    gh.factory<_i59.GetBudgetStatusTool>(
      () => _i59.GetBudgetStatusTool(
        gh<_i587.GetBudgetForMonth>(),
        gh<_i1038.AIPeriodResolver>(),
      ),
    );
    gh.factory<_i324.SyncSettingsCubit>(
      () => _i324.SyncSettingsCubit(
        gh<_i178.WatchSyncStatus>(),
        gh<_i389.WatchFailedSyncItems>(),
        gh<_i399.SyncNow>(),
        gh<_i676.SetSyncEnabled>(),
        gh<_i259.RetryFailedSync>(),
      ),
    );
    gh.factory<_i720.BudgetFormCubit>(
      () => _i720.BudgetFormCubit(
        gh<_i587.GetBudgetForMonth>(),
        gh<_i254.CreateBudget>(),
        gh<_i755.EditBudget>(),
        gh<_i150.DeleteBudget>(),
        gh<_i552.AddBudgetCategoryAllocation>(),
        gh<_i934.EditBudgetCategoryAllocation>(),
        gh<_i317.RemoveBudgetCategoryAllocation>(),
        gh<_i1.GetCategories>(),
        gh<_i999.EgpFormatter>(),
        gh<_i903.GetPrimaryCurrency>(),
      ),
    );
    gh.factory<_i194.OccasionsListCubit>(
      () => _i194.OccasionsListCubit(gh<_i276.WatchOccasionsList>()),
    );
    gh.factory<_i218.ParticipantFormCubit>(
      () => _i218.ParticipantFormCubit(
        gh<_i646.PeopleRepository>(),
        gh<_i789.CreatePerson>(),
        gh<_i415.AddParticipantContribution>(),
        gh<_i153.EditParticipantContribution>(),
        gh<_i999.EgpFormatter>(),
        gh<_i903.GetPrimaryCurrency>(),
      ),
    );
    gh.factory<_i624.ScanHistoryCubit>(
      () => _i624.ScanHistoryCubit(
        gh<_i130.WatchScanHistory>(),
        gh<_i413.DeleteScan>(),
      ),
    );
    gh.factory<_i756.DeleteAccountCubit>(
      () => _i756.DeleteAccountCubit(
        gh<_i431.DeleteAllUserData>(),
        gh<_i807.OnboardingCubit>(),
      ),
    );
    gh.factory<_i480.HandleNotificationTap>(
      () => _i480.HandleNotificationTap(
        gh<_i423.BudgetInsightsSource>(),
        gh<_i842.SavingsInsightsSource>(),
        gh<_i956.AppClock>(),
      ),
    );
    gh.lazySingleton<_i172.NotificationTapRouter>(
      () => _i172.NotificationTapRouter(
        gh<_i209.NotificationScheduler>(),
        gh<_i480.HandleNotificationTap>(),
      ),
    );
    gh.factory<_i427.ImagePrepCubit>(
      () => _i427.ImagePrepCubit(
        gh<_i235.ImagePreparationService>(),
        gh<_i856.StartScan>(),
        gh<_i350.RunOcrExtraction>(),
        gh<_i1011.SetBatchDefaultDirection>(),
        gh<_i377.CancelScan>(),
      ),
    );
    gh.factory<_i919.ScanDetailCubit>(
      () => _i919.ScanDetailCubit(
        gh<_i138.WatchScanDetail>(),
        gh<_i413.DeleteScan>(),
      ),
    );
    gh.factory<_i15.OccasionFormCubit>(
      () => _i15.OccasionFormCubit(
        gh<_i905.CreateOccasion>(),
        gh<_i712.EditOccasion>(),
      ),
    );
    gh.lazySingleton<_i248.AppStartupCubit>(
      () => _i248.AppStartupCubit(
        gh<_i794.SettingsCubit>(),
        gh<_i807.OnboardingCubit>(),
        gh<_i500.AppLifecycleObserver>(),
      ),
    );
    gh.factory<_i53.OccasionDetailCubit>(
      () => _i53.OccasionDetailCubit(
        gh<_i294.WatchOccasionDetail>(),
        gh<_i192.RemoveParticipantContribution>(),
        gh<_i247.AddOccasionAttachment>(),
        gh<_i191.RemoveOccasionAttachment>(),
        gh<_i847.ArchiveOccasion>(),
        gh<_i154.RestoreOccasion>(),
        gh<_i1046.DeleteOccasion>(),
        gh<_i780.AttachmentPickerService>(),
      ),
    );
    gh.factory<_i332.AIToolRegistry>(
      () => _i332.AIToolRegistry(
        gh<_i917.GetCategorySpendTool>(),
        gh<_i1050.GetTopSpendingCategoryTool>(),
        gh<_i924.CompareSpendingAcrossPeriodsTool>(),
        gh<_i1049.GetPersonBalanceTool>(),
        gh<_i14.GetOwedOverviewTool>(),
        gh<_i59.GetBudgetStatusTool>(),
        gh<_i666.GetOccasionTotalsTool>(),
      ),
    );
    gh.factory<_i636.AskFinancialQuestion>(
      () => _i636.AskFinancialQuestion(
        gh<_i754.AIAssistantRepository>(),
        gh<_i238.AIService>(),
        gh<_i332.AIToolRegistry>(),
        gh<_i775.SystemPromptBuilder>(),
        gh<_i1038.AIPeriodResolver>(),
      ),
    );
    gh.factory<_i258.ChatCubit>(
      () => _i258.ChatCubit(
        gh<_i359.GetAIAssistantSettings>(),
        gh<_i970.GetConversation>(),
        gh<_i636.AskFinancialQuestion>(),
        gh<_i546.ClearConversation>(),
        gh<_i103.GetProactiveObservation>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}

class _$AIHttpModule extends _i88.AIHttpModule {}

class _$AppLockModule extends _i849.AppLockModule {}
