#!/usr/bin/env bash
set -euo pipefail
# Dry run
for x in 'Canon_Maintenance_Kit_v1.1_to_v1.1.15_with_CompositeSchema.zip' 'Canon_Maintenance_Kit_v1.1_to_v1.1.8.zip' 'DecisionHubConfig_Schema_v1_0.json' 'DecisionHub_Feature_Contract_v1_0.md' 'EH1003006_All_PDFs_v1_1.pdf' 'EH1003006_DecisionHub_index_v2_2_9.html' 'EH1003006_DecisionHub_index_v2_3_2.html' 'EH1003006_DecisionHub_index_v3_2_1.html' 'EH1003006_FieldIntake_v1_3_3 (1).html' 'EH1003006_PDRNavigator_v0_3_2 (1).html' 'Missal_of_Static_Rooster.pdf' 'Missal_of_Static_Rooster_v1_1_2_Complete.pdf' 'Missal_of_Static_Rooster_v1_1_3_Illuminated_FULL.pdf' 'PipBoy_Tool_Skeleton_v1_0.html' 'StaticRooster_Ark_v1_2.zip' 'StaticRooster_UIKit_v1_0.md' 'The_History_of_the_Decline_and_Fall_of_t.pdf' 'eh1003006_online_planner_v5_2_8 (4).html' ; do echo DRY: mv "$x" ; done

# Apply
mv -v -- 'Canon_Maintenance_Kit_v1.1_to_v1.1.15_with_CompositeSchema.zip' 'canon_maintenance_kit_v1.1_to_v1.1.15_with_composite_schema.zip'
mv -v -- 'Canon_Maintenance_Kit_v1.1_to_v1.1.8.zip' 'canon_maintenance_kit_v1.1_to_v1.1.8.zip'
mv -v -- 'DecisionHubConfig_Schema_v1_0.json' 'decision_hub_config_schema_v1_0.json'
mv -v -- 'DecisionHub_Feature_Contract_v1_0.md' 'decision_hub_feature_contract_v1_0.md'
mv -v -- 'EH1003006_All_PDFs_v1_1.pdf' 'e_h1003006_all_pd_fs_v1_1.pdf'
mv -v -- 'EH1003006_DecisionHub_index_v2_2_9.html' 'e_h1003006_decision_hub_index_v2_2_9.html'
mv -v -- 'EH1003006_DecisionHub_index_v2_3_2.html' 'e_h1003006_decision_hub_index_v2_3_2.html'
mv -v -- 'EH1003006_DecisionHub_index_v3_2_1.html' 'e_h1003006_decision_hub_index_v3_2_1.html'
mv -v -- 'EH1003006_FieldIntake_v1_3_3 (1).html' 'e_h1003006_field_intake_v1_3_3_1.html'
mv -v -- 'EH1003006_PDRNavigator_v0_3_2 (1).html' 'e_h1003006_pdr_navigator_v0_3_2_1.html'
mv -v -- 'Missal_of_Static_Rooster.pdf' 'missal_of_static_rooster.pdf'
mv -v -- 'Missal_of_Static_Rooster_v1_1_2_Complete.pdf' 'missal_of_static_rooster_v1_1_2_complete.pdf'
mv -v -- 'Missal_of_Static_Rooster_v1_1_3_Illuminated_FULL.pdf' 'missal_of_static_rooster_v1_1_3_illuminated_full.pdf'
mv -v -- 'PipBoy_Tool_Skeleton_v1_0.html' 'pip_boy_tool_skeleton_v1_0.html'
mv -v -- 'StaticRooster_Ark_v1_2.zip' 'static_rooster_ark_v1_2.zip'
mv -v -- 'StaticRooster_UIKit_v1_0.md' 'static_rooster_ui_kit_v1_0.md'
mv -v -- 'The_History_of_the_Decline_and_Fall_of_t.pdf' 'the_history_of_the_decline_and_fall_of_t.pdf'
mv -v -- 'eh1003006_online_planner_v5_2_8 (4).html' 'eh1003006_online_planner_v5_2_8_4.html'
