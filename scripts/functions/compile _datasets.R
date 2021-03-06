library(dplyr)
library(sf)
library(stringr)
library(rtree)
source("scripts/functions/utils.R")
source("scripts/functions/aok_aggregation_functions.R")

# output file names -------------------------------------------------------

compilation_date<- Sys.Date() %>% str_replace_all("-","_")
compiled_file_name<- paste0(compilation_date,"_","reach_ssd_aok_clean_data_compiled.csv")

# read in and compile all csvs --------------------------------------------

input_csv_folder<- "inputs/2020_01/2020_01_base_csvs"
csv_list<- read_all_csvs(input_csv_folder = input_csv_folder)


csv_list<-purrr:::map(csv_list, function(x){
  index<-colnames(x) %in% c("Entry", "entry",".entry")==FALSE
  x[,index]})

df<-data.table::rbindlist(csv_list, fill=TRUE) %>% data.frame()
df2<-df %>% select_if(~!all(is.na(.)))

df2$all_blanks <- apply(df2, 1, function(x) all(is.na(x)))
df3<-filter(df2, all_blanks==FALSE)
# write.csv(df3, "inputs/2020_01/checking_if_AO_messed_up_cols.csv")
df3<-df3 %>% select("start_time":"X_submission_time")


# remove grouper for ease -------------------------------------------------

df4<-df3
colnames(df4)<-butteR::remove_kobo_grouper(colnames(df4))
colname_table<-data.frame(with_group=colnames(df3), without_group=colnames(df4))


# extract select multiple and replace 0s and 1s with no's and yes's -------

sm_cols_df<-butteR::extract_sm_option_columns(df = df4,name_vector=colnames(df4))

#SELECTING LOGICAL ONLY WILL REMOVE CONCATENATED STRING SELECT MULTIPLE
df_just_sm<-df4 %>% select(sm_cols_df$sm_options) %>% select_if(is.integer)

#REPLACE 1S WITH YES 0 WITH NO SM
df_just_sm<-df_just_sm %>%
  purrr::map_df(function(x)as.character(x) %>%
                  stringr::str_replace_all(c("0"="no", "1"="yes"))) %>% data.frame()

df4[,colnames(df_just_sm)]<-df_just_sm



# write out compiled csv for use later ------------------------------------

d.f <- df4
colnames(d.f)<-colname_table$with_group
write.csv(d.f,paste0("inputs/2020_01/", compiled_file_name))


# read in previous round and see whats been added to new tool ------------

#ONCE THE COMPILED DATA SET AOK SETTLEMENTS HAVE BEEN FIXED - READ IT IN
d.f<-read.csv("inputs/2020_01/REACH_SSD_AoK_January2020_duku.csv", stringsAsFactors = FALSE, na.strings=c("", " ", NA, "NA"))
df$D.info_county <-df$D.info_county

previous_round_compiled<- read.csv("inputs/2020_01//REACH_SSD_AoK_CleanedDataset_December2019.csv")
new_columns_added_from_last_round<-colnames(d.f)[colnames(d.f) %in% colnames(previous_round_compiled) ==FALSE]

## Let's remove columns we don't need. Notes first, no data in those!!
d.f <- select(d.f, everything(), -contains("note"), - contains("_other"))



# this looks like left over scrap -----------------------------------------


## CREATING THE SETTLEMENTS DATASET WOOHOO!

## Let us apply the "aok_yes" function to these set of columns
#  	F.f3.idps_returnees_push.lack_of_access_to_income_generating_activities,
# F.f3.idps_returnees_push.lack_of_food,	F.f3.idps_returnees_push.cattle_raiding,	F.f3.idps_returnees_push.lack_of_markets,	F.f3.idps_returnees_push.far_from_home,	F.f3.idps_returnees_push.no_reason,
# F.f3.idps_returnees_push.lack_of_education_services,	F.f3.idps_returnees_push.lack_of_water,	F.f3.idps_returnees_push.disease_outbreak,	F.f3.idps_returnees_push.lack_or_difficulty_to_access_land,
#F.f3.idps_returnees_push.tensions_with_host_community,	F.f3.idps_returnees_push.lack_of_shelter,	F.f3.idps_returnees_push.lack_of_healthcare_services,	F.f3.idps_returnees_push.insecurity_killing,
#F.f3.idps_returnees_push.far_from_the_family,	F.f3.idps_returnees_push.dontknow, F.f3.idp_returnees_pull.water_access,	F.f3.idp_returnees_pull.family_reunion,	F.f3.idp_returnees_pull.market_access,
#F.f3.idp_returnees_pull.health_access,	F.f3.idp_returnees_pull.humanitarian_access,	F.f3.idp_returnees_pull.no_reason,	F.f3.idp_returnees_pull.shelter_access,	F.f3.idp_returnees_pull.other,	F.f3.idp_returnees_pull.land_access,
#F.f3.idp_returnees_pull.income_access,	F.f3.idp_returnees_pull.dontknow,	F.f3.idp_returnees_pull.home,	F.f3.idp_returnees_pull.security,	F.f3.idp_returnees_pull.education_access,	F.f3.idp_returnees_pull.food_available,
#U.nfi_market_type, U.cereal_market_type,





# define columns which will be used for aggregation always ----------------


essential_cols<-c("D.info_state", "D.info_county", "D.info_settlement")

# APPLY AOK YES FUNCTION --------------------------------------------------
new_columns_added_from_last_round %>% dput()
new_aok_yes_cols

yes_analysis_added_2020_01<-c("U.market_safety","L.current_activities.pole_selling",
                              "L.current_activities.livestock", "L.current_activities.remittances",
                              "L.current_activities.casual_labour", "L.current_activities.crops_for_sustenance",
                              "L.current_activities.alcohol_brewing","U.market_now_barriers.robbery",
                              "U.market_now_barriers.SGBV", "U.market_now_barriers.conflict", "U.market_now_barriers_at.marketplace_flooded",
                              "U.market_now_barriers_at.traders_not_sell", "U.market_now_barriers_at.none",
                              "U.market_now_barriers_at.marketplace_damaged", "U.market_now_barriers_at.items_quality_low",
                              "U.market_now_barriers_at.some_items_too_expensive", "U.market_now_barriers_at.other",
                              "U.market_now_barriers_at.dontknow", "U.market_now_barriers_at.harassment",
                              "U.market_now_barriers_at.some_items_not_available")

aok_yes_cols<-c("D.info_state", "D.info_county", "D.info_settlement", "F.hc_now",
                "F.idp_now", "F.hcdisp_now", "F.f1.hc_leave", "F.refugee_return_now",
                "G.food_wild_now", "G.food_wild_emergency", "G.food_distr", "L.livestock_disease",
                "K.water_source_animals", "K.water_safety", "K.latrine_now",
                "J.shelter_open_yn", "J.shelter_damage", "J.nfi_distribution",
                "N.prot_incidence", "N.prot_looting", "N.prot_unaccompanied",
                "N.land_disputes", "O.mines", "P.supp_feeding", "G.food_coping_comsumption.none",
                "G.food_coping_comsumption.reduce_meals", "G.food_coping_comsumption.limit_meal_size",
                "G.food_coping_comsumption.only_children_eat", "G.food_coping_comsumption.dontknow",
                "G.food_coping_comsumption.other", "G.food_coping_comsumption.skip_days",
                "G.food_coping_comsumption.less_expensive_food", "G.food_coping_comsumption.other",
                "J.shelter_materials.ps", "J.shelter_materials.none", "J.shelter_materials.rope",
                "J.shelter_materials.mud", "J.shelter_materials.pole", "J.shelter_materials.other",
                "J.shelter_materials.dontknow", "J.shelter_materials.grass",
                "J.shelter_materials.timber", "L.food_coping_livelihoods.displacement_camp",
                "L.food_coping_livelihoods.gather_firewood", "L.food_coping_livelihoods.household_begs",
                "L.food_coping_livelihoods.hunting", "L.food_coping_livelihoods.borrow_money",
                "L.food_coping_livelihoods.fishing", "L.food_coping_livelihoods.none",
                "L.food_coping_livelihoods.gather_wild_food", "L.food_coping_livelihoods.other",
                "L.food_coping_livelihoods.send_children_to_neighbors", "L.food_coping_livelihoods.sell_livestock",
                "L.food_coping_livelihoods.borrow_food", "L.food_coping_livelihoods.cattle_camps",
                "L.food_coping_livelihoods.consume_seeds", "L.food_coping_livelihoods.dontknow",
                "L.food_coping_livelihoods.sell_home_assets", "L.food_coping_livelihoods.slaughter_livestock",
                "O.mine_areas.school", "O.mine_areas.water_point", "O.mine_areas.medical",
                "O.mine_areas.firewood", "O.mine_areas.crop", "O.mine_areas.dontknow",
                "O.mine_areas.graze", "O.mine_areas.other", "O.mine_areas.roads",
                "O.mine_areas.river", "O.mine_areas.housing", "O.mine_areas.other",
                "P.children_food_prep_change.not_changed", "P.children_food_prep_change.wild_foods",
                "P.children_food_prep_change.diet_part", "P.children_food_prep_change.dontknow",
                "P.children_food_prep_change.reduced_meals_number", "P.children_food_prep_change.other",
                "U.market_now_barriers.items_expensive", "U.market_now_barriers.no_means_payment",
                "U.market_now_barriers.live_far", "U.market_now_barriers.marketplace_damage",
                "U.market_now_barriers.not_available", "U.market_now_barriers.quality_items_notsufficent",
                "U.market_now_barriers.other", "U.market_now_barriers.safety",
                "U.market_now_barriers.flooding", "U.market_relevance", "P.breastfeeding_change.not_changed",
                "P.breastfeeding_change.longer", "P.breastfeeding_change.powder_milk",
                "P.breastfeeding_change.other", "P.breastfeeding_change.agri_work",
                "P.breastfeeding_change.dontknow", "P.breastfeeding_change.stopped",
                "P.breastfeeding_change.due_coping", "P.breastfeeding_change.animal_milk",
                "P.children_food_prep_change.solid_infant_meals_early", "P.children_food_prep_change.solid_infant_meals_late",
                "U.market_now_barriers.marketplace_flooded", "U.market_now_barriers.none",
                "U.market_now_barriers.no_food_water", "U.market_now_barriers.no_road",
                "U.market_now_barriers.no_shelter", "L.current_activities.charcoal_making",
                "P.children_food_prep_change.same_meal", "L.current_activities.bee_keeping",
                "J.shelter_materials.iron_sheets", "J.shelter_flooding", "F.f3.idp_returnees",
                "L.crop_distruptions", "L.cattle_disease", "I.health_now.none",
                "I.health_now.herbalist", "I.health_now.pharmarcy", "I.health_now.phc",
                "I.health_now.hospital", "I.health_now.maternity_center", "I.health_now.other",
                "I.health_now.dontknow", "I.health_now.nutrition_center", "I.health_now.ngo_clinic",
                "K.water_quality", "Q.assistance_now", "Q.most_relevant", "Q.ha_satisfied",
                "Q.complaint_awareness", "Q.ha_protection_concern",yes_analysis_added_2020_01)





aok_yes_cols<-aok_yes_cols[aok_yes_cols %in% colnames(d.f)]
aok_yes_cols<-aok_yes_cols[aok_yes_cols %in% essential_cols==FALSE]
aok_yes_cols_dropped<-aok_yes_cols[aok_yes_cols %in% colnames(d.f)==FALSE]


settlement_yes <- d.f %>%
  select(essential_cols,aok_yes_cols
  ) %>%
  group_by_(.dots = c("D.info_state", "D.info_county", "D.info_settlement")) %>%
  summarise_all(funs(aok_yes))

## Let us apply the "aok_no" function to these set of columns


aok_no_cols<-c("D.info_state", "D.info_county", "D.info_settlement", "G.food_now",
  "L.land_available", "L.ag_seeds", "L.ag_tools", "R.idp_supported",
  "R.idp_leadership", "R.local_authorities")

aok_no_cols<-aok_no_cols[aok_no_cols %in% colnames(d.f)]
aok_no_cols<-aok_no_cols[aok_no_cols %in% essential_cols==FALSE]
aok_no_cols_dropped<-aok_no_cols[aok_no_cols %in% colnames(d.f)==FALSE]

settlement_no <- d.f %>%
  select(essential_cols, aok_no_cols ) %>%
  group_by_(.dots = c("D.info_state", "D.info_county", "D.info_settlement")) %>% ## .dots basically accepts the column values for the function. In this function, we are saying group by the three columns listed!
  summarise_all(funs(aok_no))

## Let us apply the "aok_mode" function to these set of columns

mode_cols_added_2020_01<-c("P.malnourished_children_prop","P.malnourished_children_comp")
# as.character(quote(A.base, D.info_state))
# as.character(expression(A.base, D.info_state)) %>% dput()
aok_mode_cols<-c("A.base", "D.info_state", "D.info_county", "D.info_settlement",
                 "F.f1.hc_remain_perc", "F.f2.idp_source", "F.f2.idp_source_state",
                 "F.f2.idp_source_county", "F.f2.idp_perc", "F.f3.returnee_time_arrived",
                 "G.food_source", "G.food_wild_proportion", "G.meals_number",
                 "U.cerial_price_increase", "L.cattle_possession", "L.cattle_access",
                 "K.water_boreholes", "K.water_boreholes_functional", "K.water_now_how",
                 "K.water_now_time", "K.water_source_seasonal", "K.latrine_usage",
                 "K.latrine_no_usage", "K.hand_washing", "J.j2.idp_location",
                 "J.j1.hc_shelter_type1", "J.j1.hc_location", "J.j2.idp_shelter_type1",
                 "J.shelter_open", "J.shelter_destroyed_percent", "J.nfi_need1",
                 "N.prot_now", "N.prot_men_concern", "N.prot_women_concern", "N.prot_girls_concern",
                 "N.prot_boys_concern", "N.comm_relations", "S.shock_hunger",
                 "S.shock_arrival", "S.shock_cerial_price", "S.shock_health",
                 "S.shock_protection", "I.health_now", "I.health_dist", "I.health_no_reason1",
                 "I.health_problems1", "H.death_cause1", "H.mortality_increase",
                 "M.edu_now", "M.edu_no_reason", "M.edu_girl_attendance", "M.edu_boy_attendance",
                 "M.attendance_no_reason1_boys", "M.attendance_no_reason1_girls",
                 "R.community_leadership", "G.food_now_type.Meat", "G.food_now_type.Vegetables",
                 "G.food_now_type.Main_staples", "G.food_now_type.Fruit", "G.food_now_type.Pulses",
                 "G.food_now_type.dontknow", "G.food_now_type.Milk_Dairy", "L.current_activities.poultry",
                 "L.current_activities.none", "L.current_activities.Livestock",
                 "L.current_activities.hunting", "L.current_activities.Salaries",
                 "L.current_activities.Crops_for_cash", "L.current_activities.Remittances",
                 "L.current_activities.Casual_labour", "L.current_activities.other",
                 "L.current_activities.fishing", "L.current_activities.dontknow",
                 "L.current_activities.Crops_for_sustenance", "L.current_activities.market",
                 "R.info_source_who", "F.f4.refugee_return_source", "F.f4.refugee_return_source_country",
                 "T.ebola_message", "T.main_info_source", "T.who_provided", "T.seek_treatment",
                 "P.malnourished_children", "P.malnourished_elderly", "U.market_now_time",
                 "U.market_now", "U.market_where_food", "U.cereal_market_county",
                 "U.cereal_market_sett", "U.market_where_nfi", "U.nfi_market_county",
                 "U.nfi_market_sett", "F.f1.people_leaving", "F.f2.idp_push",
                 "F.f2.idp_pull", "F.f3.idp_sate_returns", "F.f3.idp_county",
                 "F.f3.returnee_time_arrived", "U.cereal_market_type", "U.nfi_market_type",
                 "F.f1.hc_leave_time", "J.j3.returnee_shelter_type1", "J.j3.returnee_location",
                 "Q.ha_mechanism", "Q.main_language", "Q.sec_language", "Q.language_humanitarians",
                 "Q.language_pref_spoken", "Q.language_pref_written", "Q.language_pref_spoken",
                 "Q.language_pref_written", "R.phone_use", "F.f3.idps_returnees_push",
                 "F.f3.idp_returnees_pull", "F.f4.refugee_returnee_push", "F.f4.refugee_returnees_pull",
                 "L.harvest_perception", "L.harvest_worse", "B.disp_status", "B.interviewed_before",
                 "B.interviewed_last_month", "Q.most_needed_ha", "Q.not_satisfied_reason",
                 "Q.ha_type_acquire", "Q.ha_inkind", "Q.ha_cash", "Q.ha_voucher",
                 "Q.ha_fear",
                 mode_cols_added_2020_01)



aok_mode_cols<-aok_mode_cols[aok_mode_cols %in% colnames(d.f)]
aok_mode_cols<-aok_mode_cols[aok_mode_cols %in% essential_cols==FALSE]
aok_mode_cols_dropped<-aok_mode_cols[aok_mode_cols %in% colnames(d.f)==FALSE]

settlement_equal <- d.f %>%
  select(essential_cols,aok_mode_cols) %>%
  group_by_(.dots = c("D.info_state", "D.info_county", "D.info_settlement")) %>% ## .dots basically accepts the column values for the function. In this function, we are saying group by the three columns listed!
  summarise_all(funs(AoK))

## Let us apply the "aok_frequency" function to these set of columns
# settlement_frequency <- d.f %>%
#  select(D.info_state,D.info_county,D.info_settlement, R.leadership_meetings) %>%
#   group_by_(.dots = c("D.info_state", "D.info_county", "D.info_settlement")) %>% ## .dots basically accepts the column values for the function. In this function, we are saying group by the three columns listed!
#   summarise_all(funs(aok_frequency))

## Let us apply the "aok_recent" function to these set of columns
aok_recent_cols<-c("D.info_state", "D.info_county", "D.info_settlement", "F.f2.idp_time_arrive",
                   "F.f4.refugee_return_time_arrive")

aok_recent_cols<-aok_recent_cols[aok_recent_cols %in% colnames(d.f)]
aok_recent_cols<-aok_recent_cols[aok_recent_cols %in% essential_cols==FALSE]
aok_recent_cols_dropped<-aok_recent_cols[aok_recent_cols %in% colnames(aok_recent_cols)==FALSE]

settlement_recent <- d.f %>%
  select(essential_cols,aok_recent_cols) %>%
  group_by_(.dots = c("D.info_state", "D.info_county", "D.info_settlement")) %>% ## .dots basically accepts the column values for the function. In this function, we are saying group by the three columns listed!
  summarise_all(funs(aok_recent))

## Let us apply the "aok_highest" function to these set of columns

aok_highest_cols<-c("O.mine_acc_numb")
aok_highest_cols<-aok_highest_cols[aok_highest_cols%in%colnames(d.f)]
aok_highest_cols<-aok_highest_cols[aok_highest_cols%in%essential_cols==FALSE]
aok_highest_cols_dropped<-aok_highest_cols[aok_highest_cols%in%colnames(d.f)==FALSE]

settlement_highest <- d.f %>%
  select(essential_cols, aok_highest_cols) %>%
  group_by_(.dots = c("D.info_state", "D.info_county", "D.info_settlement")) %>% ## .dots basically accepts the column values for the function. In this function, we are saying group by the three columns listed!
  summarise_all(funs(aok_highest))

## Let us apply the "aok_conflict" function to these set of columns
aok_conflict_cols<-c("G.food_no_reason1")
aok_conflict_cols<-aok_conflict_cols[aok_conflict_cols%in%colnames(d.f)]
aok_conflict_cols<-aok_conflict_cols[aok_conflict_cols%in%essential_cols==FALSE]
aok_conflict_cols_dropped<-aok_conflict_cols[aok_highest_cols%in%colnames(d.f)==FALSE]


settlement_conflict <- d.f %>%
  select(essential_cols, aok_conflict_cols) %>%
  group_by_(.dots = c("D.info_state", "D.info_county", "D.info_settlement")) %>% ## .dots basically accepts the column values for the function. In this function, we are saying group by the three columns listed!
  summarise_all(funs(aok_conflict))


#table join. Let us merge all these columns/fields into one database
analysis_df_list<-list(settlement_yes, settlement_no,settlement_equal,settlement_recent, settlement_highest,settlement_conflict)
# settlement_joined<-purrr::reduce(analysis_df_list, left_join(by= c("D.info_state","D.info_county", "D.info_settlement")))
settlement_joined<-purrr::reduce(analysis_df_list, left_join)


settlement<-settlement_joined
# #Let us rearrange the columns in our database inthe same order appear on the tool
settlement <- settlement %>% select(order(match(names(settlement), names(d.f))))

#check missing column names

missing_columns<-colnames(d.f)[colnames(d.f)%in% colnames(settlement)==FALSE] %>% dput()

columns_not_needed<- c("month", "today", "deviceid", "A.type_visit", "B.ki_gender",
                       "B.D_startTime", "D.info_settlement_final", "D.info_payam", "D.type_contact",
                       "D.d1.remotely_how", "D.d1.remotely_how.s_phone", "D.d1.remotely_how.mob_app",
                       "D.d1.remotely_how.m_phone", "D.d1.remotely_how.other", "D.d1.remotely_how.radio",
                       "D.d1.remotely_how.internet", "D.d1.remotely_how.dontknow", "D.ki_recent",
                       "D.F_startTme", "F.f2.other", "F.f2.other_idp", "F.f3.other_returnees_push",
                       "F.f3.other_returnees_pull", "F.f4.other_refugee_returnee_push",
                       "F.f4.other_refugee_returnees_pull", "G.G_startTme_1", "G.food_now_type",
                       "G.food_enough_fewmeals", "G.food_coping_comsumption", "G.P_startTme",
                       "P.breastfeeding_change", "P.children_food_prep_change", "P.L_startTme",
                       "L.food_coping_livelihoods", "L.current_activities", "L.cutlivation_yes_land_no",
                       "L.crops_yes_tools_no", "L.U_startTme", "U.market_now_barriers",
                       "U.market_now_barriers.dontknow", "I.I_startTime", "T.T_startTime",
                       "T.key_meaasage", "T.key_signs", "T.get_ebola", "T.everyone_risk",
                       "T.prevent_ebola", "T.hand_wash", "T.wild_animals", "T.bush_meat",
                       "T.no_fruits", "T.no_sharp_object", "T.protective_clothes", "T.seek_medical",
                       "H.H_startTme", "N.N_startTime", "N.safe_yes_incident_yes", "N.S_startTime",
                       "J.j1.J_startTime", "J.shelter_materials", "K.K_startTime", "M.M_startTme",
                       "R.R_startTme", "O.O_startTme", "O.mine_areas", "Z.Z_startTme",
                       "Z.end_survey_protection", "LE_1_remote", "LE_2_unpopulated",
                       "LE_3_nohostcommunity", "LE_4_food_enough_fewmeals", "LE_5_food_insufficient_manymeals",
                       "LE_7_food_enough_malnutritiondeath", "LE_8_food_enough_hungersevere",
                       "LE_9_cutlivation_yes_land_no", "LE_10_crops_yes_seedstools_no",
                       "LE_11_forage_yes_wildfoods_no", "LE_12_morehalf_wildfood_morethan_3meals",
                       "LE_13_hunting_source_yes_activity_no", "LE_14_fishing_source_yes_activity_no",
                       "LE_15_market_source_yes_access_no", "LE_16_assist_source_yes_no_distribution",
                       "LE_17_safe_but_serious_concerns_women", "LE_18_safe_but_serious_concerns_men",
                       "LE_19_safe_but_serious_concerns_girls", "LE_20_safe_but_serious_concerns_boys",
                       "LE_26_safe_yes_incident_yes", "LE_21_mainshelter_HC_permanent",
                       "LE_22_mainshelter_IDP_permanent", "LE_23_IDP_bush_yes_open_no",
                       "LE_24_water_borehole_no_borehole", "X_id", "X_uuid")


check_these<-missing_columns[missing_columns %in% columns_not_needed ==FALSE]

if(length(check_these>0)){
  print(paste0("you missed these: ", check_these))
}


# ## Now we want to clean the dataset for some skiplogic errors and some NAs that have appeared after our settlement
## aggregation has finished. This looks long, but it's very simple! Then we can save it, print it, and BAM! Done.

#interviewed last month
settlement$B.interviewed_last_month [settlement$B.interviewed_before != "yes"] <- "SL"


## No host community


settlement$F.f1.hc_remain_perc[settlement$F.hc_now != "yes"] <- "SL"
settlement$F.f1.hc_leave[settlement$F.hc_now != "yes"] <- "SL"

settlement$F.f1.hc_leave_time[settlement$F.f1.hc_leave != "yes" | settlement$F.hc_now != "yes"] <- "SL"
settlement$F.f1.people_leaving[settlement$F.f1.hc_leave != "yes" | settlement$F.hc_now != "yes"] <- "SL"

## SKIP LOGIC
# The following sets ensure that when data is aggregated to the settlement level, if there are a mix of yes/no, that the consensus response respects the skip logic
# if a question is supposd to be skipped after selecting "no" to a previous question, ensure it remains blank
# if a question is supposd to be skipped after selecting "yes" to a previous question, ensure it remains blank

#No HC left
#settlement$F.f1.hc_time_leave[settlement$F.f1.hc_leave !="yes"]<- "SL"


## No IDPs
settlement$F.f2.idp_perc[settlement$F.idp_now != "yes"] <- "SL"
settlement$F.f2.idp_push[settlement$F.idp_now != "yes"] <- "SL"
settlement$F.f2.idp_pull[settlement$F.idp_now != "yes"] <- "SL"

settlement$F.f2.idp_time_arrive[settlement$F.idp_now != "yes"] <- "SL"

settlement$F.f2.idp_source[settlement$F.idp_now != "yes"] <- "SL"
settlement$F.f2.idp_source_state[settlement$F.idp_now != "yes"] <- "SL"
settlement$F.f2.idp_source_county[settlement$F.idp_now != "yes"] <- "SL"

## No returnees
settlement$F.f3.idp_returnees[settlement$F.hcdisp_now != "yes"] <- "SL"
settlement$F.f3.idp_sate_returns[settlement$F.hcdisp_now != "yes"] <- "SL"
settlement$F.f3.idp_county[settlement$F.hcdisp_now != "yes"] <- "SL"
settlement$F.f3.returnee_time_arrived[settlement$F.hcdisp_now != "yes"] <- "SL"


settlement$F.f3.idps_returnees_push[settlement$F.hcdisp_now != "yes"] <- "SL"

settlement$F.f3.idp_returnees_pull[settlement$F.hcdisp_now != "yes"] <- "SL"


#No Refugee returnees source
settlement$F.f4.refugee_return_source[settlement$F.refugee_return_now!= "yes"] <- "SL"
settlement$F.f4.refugee_return_source_country[settlement$F.f4.refugee_return_source != "yes"]<- "SL"
settlement$F.f4.refugee_return_time_arrive[settlement$F.refugee_return_now!= "yes"] <- "SL"

settlement$F.f4.refugee_returnee_push[settlement$F.refugee_return_now != "yes"] <- "SL"
settlement$F.f4.refugee_returnees_pull[settlement$F.refugee_return_now != "yes"] <- "SL"



## Yes food
settlement$G.food_wild_proportion[settlement$G.food_wild_now != "yes"] <- "SL"

##Livelihood: bad harvest perception
settlement$L.harvest_worse[settlement$L.harvest_perception != "worse"] <- "SL"



## No health
settlement$I.health_dist[settlement$I.health_now != "yes"] <- "SL"

## Yes health
settlement$I.health_no_reason1[settlement$I.health_now != "no"] <- "SL"

## No IDP (protection)
settlement$N.comm_relations[settlement$F.idp_now != "yes"] <- "SL"

## Shocks
settlement$S.shock_arrival[settlement$F.idp_now != "yes" & settlement$F.hcdisp_now != "yes"] <- "SL"
settlement$S.shock_hunger[settlement$G.food_now != "no"] <- "SL"

#NOT IN  NEW DATA SET
settlement$S.shock_cerial_price[settlement$U.cerial_price_increase != "yes"] <- "SL"
#settlement$S.shock_livestock[settlement$L.livestock_disease != "yes"] <- "SL"
settlement$S.shock_protection[settlement$N.prot_incidence != "yes" & settlement$N.prot_looting != "yes"] <- "SL"


## No HC (shelter)

settlement$J.j1.hc_shelter_type1[settlement$F.hc_now != "yes"] <- "SL"
settlement$J.j1.hc_location[settlement$F.hc_now != "yes"] <- "SL"

## No IDP (shelter)

settlement$J.j2.idp_shelter_type1[settlement$F.idp_now != "yes"] <- "SL"
settlement$J.j2.idp_location[settlement$F.idp_now != "yes"] <- "SL"
settlement$J.shelter_open_yn[settlement$F.idp_now != "yes"] <- "SL"
settlement$J.shelter_open[settlement$J.shelter_open_yn != "yes"] <- "SL"


#returnees shelter info
settlement$J.j3.returnee_shelter_type1[settlement$F.hcdisp_now != "yes"] <- "SL"
settlement$J.j3.returnee_location[settlement$F.hcdisp_now != "yes"] <- "SL"

## No shelter damage
settlement$J.shelter_destroyed_percent[settlement$J.shelter_damage != "yes"] <- "SL"


settlement$J.nfi_need1[settlement$F.idp_now != "yes"] <- "SL"


##Markets

settlement$U.market_where_food[settlement$U.market_now != "yes_same"& settlement$U.market_now != "yes_other"] <- "SL"
settlement$U.cereal_market_county[settlement$U.market_now != "yes_same" & settlement$U.market_now !=  "yes_other"] <- "SL"
settlement$U.cereal_market_sett[settlement$U.market_now != "yes_same" & settlement$U.market_now !=  "yes_other"] <- "SL"

#not in the data
# settlement$U.cereal_market_type[settlement$U.market_now != "yes_same" & settlement$U.market_now !=  "yes_other"] <- "SL"


settlement$U.market_where_nfi[settlement$U.market_now != "yes_same" & settlement$U.market_now !=  "yes_other"] <- "SL"
settlement$U.nfi_market_county [settlement$U.market_now != "yes_same" & settlement$U.market_now !=  "yes_other"] <- "SL"
settlement$U.nfi_market_sett [settlement$U.market_now != "yes_same" & settlement$U.market_now !=  "yes_other"] <- "SL"


# settlement$U.nfi_market_type [settlement$U.market_now != "yes_same" & settlement$U.market_now !=  "yes_other"] <- "SL"


settlement$U.market_now_time [settlement$U.market_now != "yes_same" & settlement$U.market_now !=  "yes_other"] <- "SL"

# settlement$U.cerial_price_increase[settlement$U.market_now != "yes_same" & settlement$U.market_now !=  "yes_other"] <- "SL"




#Ebola is in town

settlement$T.ebola_message[settlement$A.base != "yambio" & settlement$A.base != "maridi" & settlement$A.base != "juba"]<- "SL"
settlement$T.main_info_source[(settlement$T.ebola_message != "yes") & (settlement$A.base != "yambio" & settlement$A.base != "maridi" & settlement$A.base != "juba")] <- "SL"
settlement$T.who_provided[(settlement$T.ebola_message != "yes") & (settlement$A.base != "yambio" & settlement$A.base != "maridi" & settlement$A.base != "juba")] <- "SL"
settlement$T.seek_treatment [settlement$A.base != "yambio" & settlement$A.base != "maridi" & settlement$A.base != "juba"]<- "SL"

## No boreholes
settlement$K.water_boreholes_functional[settlement$K.water_boreholes != "yes"] <- "SL"

## Latrine usage
settlement$K.latrine_usage[settlement$K.latrine_now != "yes"] <- "SL"
settlement$K.latrine_no_usage[settlement$K.latrine_usage == "more_half" | settlement$K.latrine_usage == "dontknow" | settlement$K.latrine_usage == "NC"| settlement$K.latrine_usage == ""] <- "SL"



## No education

settlement$M.edu_no_reason[settlement$M.edu_now != "no"] <- "SL"


settlement$M.attendance_no_reason1_girls[settlement$M.edu_now != "yes" | settlement$M.edu_girl_attendance == "more_half"] <- "SL"
settlement$M.attendance_no_reason1_boys[settlement$M.edu_now != "yes" | settlement$M.edu_boy_attendance == "more_half" ] <- "SL"

## No CCCM
settlement$R.idp_supported[settlement$F.idp_now != "yes"] <- "SL"
#settlement$R.community_leadership_groups[settlement$R.community_leadership != "yes"] <- "SL"
#settlement$R.leadership_meetings[settlement$R.community_leadership != "yes"] <- "SL"
settlement$R.idp_leadership[settlement$F.idp_now != "yes" | settlement$R.community_leadership != "yes"] <- "SL"


## No mines/UXOs
settlement$O.mine_areas[settlement$O.mines != "yes"] <- "SL"
settlement$O.mine_areas.housing[settlement$O.mines != "yes"] <- "SL"
settlement$O.mine_areas.school[settlement$O.mines != "yes"] <- "SL"
settlement$O.mine_areas.medical[settlement$O.mines != "yes"] <- "SL"
settlement$O.mine_areas.water_point[settlement$O.mines != "yes"] <- "SL"
settlement$O.mine_areas.river[settlement$O.mines != "yes"] <- "SL"
settlement$O.mine_areas.crop[settlement$O.mines != "yes"] <- "SL"
settlement$O.mine_areas.graze[settlement$O.mines != "yes"] <- "SL"
settlement$O.mine_areas.firewood[settlement$O.mines != "yes"] <- "SL"
settlement$O.mine_areas.roads[settlement$O.mines != "yes"] <- "SL"
settlement$O.mine_areas.other[settlement$O.mines != "yes"] <- "SL"
settlement$O.mine_areas.dontknow[settlement$O.mines != "yes"] <- "SL"

settlement$O.mine_acc_numb[settlement$O.mines != "yes"] <- "SL"


#AAP

settlement$Q.most_relevant [settlement$Q.assistance_now != "yes"] <- "SL"
settlement$Q.ha_satisfied [settlement$Q.assistance_now != "yes"] <- "SL"
settlement$Q.not_satisfied_reason [(settlement$Q.ha_satisfied != "no") | (settlement$Q.assistance_now != "yes")] <- "SL"

settlement %>% mutate(asdf= ifelse(Q.ha_satisfied!="no" & Q.assistance_now != "yes", "SL",Q.not_satisfied_reason)) %>% select(Q.ha_satisfied,Q.assistance_now,asdf) %>% data.frame()

settlement$Q.ha_inkind [settlement$Q.ha_type_acquire != "in_kind"] <- "SL"
settlement$Q.ha_cash [settlement$Q.ha_type_acquire != "cash"] <- "SL"
settlement$Q.ha_voucher [settlement$Q.ha_type_acquire != "vouchers"] <- "SL"
settlement$Q.complaint_awareness [settlement$Q.assistance_now != "yes"] <- "SL"
settlement$Q.ha_protection_concern [settlement$Q.assistance_now != "yes"] <- "SL"
settlement$Q.ha_fear [(settlement$Q.assistance_now != "yes") | (settlement$Q.ha_protection_concern != "yes")] <- "SL"




## Filling in all blank values

settlement[settlement == ""] <- "NA"

## Counting KI coverage per village!

ki_coverage <- d.f %>%
  select(c(D.info_state, D.info_county, D.info_settlement, B.disp_status)) %>%
  group_by_(.dots = c("D.info_state", "D.info_county", "D.info_settlement")) %>%
  summarise(length(B.disp_status))

## Combining settlement and county name for when we join to ArcGIS!! Also adding in the column for KI coverage

settlement <- settlement %>%
  ungroup() %>%
  mutate(D.settlecounty = paste0(D.info_settlement, D.info_county)) %>%
  mutate(D.ki_coverage = as.numeric(ki_coverage$`length(B.disp_status)`)) %>%
  select(D.info_state, D.info_county, D.info_settlement, D.settlecounty, D.ki_coverage, everything())

settlement<- rename(settlement,G.market_now = U.market_now, G.cerial_price_increase = U.cerial_price_increase)


## Adding KI coverage and month columns

settlement <- add_column(as.data.frame(settlement), month = rep(CURRENT_MONTH, len = nrow(settlement)), .before = 1)

## Writing the files, we are done!

write.csv(settlement, AGGREGATED_DATASET, na = "NA", row.names = FALSE)





# update settlements ------------------------------------------------------



settlements<-readr::read_csv("inputs/48_December_2019/SSD_Settlements_V37.csv")


df4<-df3 %>%
  mutate(
    settlement_county_sanitized= paste0(info_settlement_final, info_county) %>%
      trimws()%>%
      gsub("[[:punct:]]","",.) %>%
      tolower())
df4$settlement_county_sanitized

settlements<- settlements %>%
  mutate(settlement_county_sanitized= NAMECOUNTY %>%
           trimws() %>% gsub("[[:punct:]]","",.) %>%  tolower())

settlements$settlement_county_sanitized


aok_settlements_missing<-df4 %>% anti_join( settlements, by= "settlement_county_sanitized")


aok_settlements_missing %>% nrow()
fuzzy_join<-fuzzyjoin::stringdist_join(aok_settlements_missing%>% select(X_uuid, info_settlement_final,info_county,  settlement_county_sanitized), settlements%>% select(NAME, NAMEJOIN, NAMECOUNTY,settlement_county_sanitized), by = NULL, max_dist = 2, method = c("osa","lv", "dl", "hamming", "lcs", "qgram", "cosine", "jaccard", "jw","soundex"), mode = "inner", ignore_case = FALSE,distance_col = "string_dist")


fuzzy_join<-fuzzyjoin::stringdist_join(aok_settlements_missing%>% select(X_uuid, info_settlement_final,info_county,  settlement_county_sanitized), settlements%>% select(NAME, NAMEJOIN, NAMECOUNTY,settlement_county_sanitized), by = NULL, max_dist = 2, method = c("osa","lv", "dl", "hamming", "lcs", "qgram", "cosine", "jaccard", "jw","soundex"), mode = "left", ignore_case = FALSE,distance_col = "string_dist")


new_settlements_ao<- read.csv(file = "inputs/48_December_2019/5_Add_Mapped_Settlements/REACH_SSD_AoK_newly_mapped_settlements_December2019.csv")
new_settlements_ao<-new_settlements_ao %>% filter( !is.na(Latitude)& !is.na(Longitude))
new_settlements_ao$Longitude
new_settlements_ao_sf<- sf::st_as_sf(new_settlements_ao, coords= c("Longitude","Latitude"),crs= 4326)
settlements_spatial_full<-settlements %>% filter(!is.na(X) & !is.na(Y))
nrow(settlements_spatial_full); nrow(settlements)
settlements_sf<- sf::st_as_sf(settlements_spatial_full, coords=c("X", "Y"), crs=4326)



debugonce(butteR::closest_distance_rtree)
asdf<-butteR::closest_distance_rtree(sf1=new_settlements_ao_sf,sf2 = settlements_sf)


asdf<-butteR::match_closest_pt_rtree(new_settlements_ao_sf,sf2 = settlements_sf)

sf::st_coordinates(settlements_sf)

butteR::check_distances_from_target(dataset =new_settlements_ao_sf,target_points =settlements_sf  )
butteR::match_closest_pt_rtree()












write.csv(fuzzy_join, "adsf.csv")
aok_settlements_missing %>% nrow()
asdf %>% nrow()
asdf

# scrap -------------------------------------------------------------------




asdf<-aok_settlements_missing %>% fuzzyjoin::fuzzy_left_join(settlements, by = c("settlement_county_sanitized"), match_fun = str_detect)




data.frame(asdf$settlement_county_sanitized.x, asdf$settlement_county_sanitized.y)

aok_settlements_missing %>% select(settlement_county_sanitized)
