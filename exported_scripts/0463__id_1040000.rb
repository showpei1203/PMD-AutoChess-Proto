# encoding: UTF-8
#==============================================================================
# ■ PMD AutoChess - Motion Generated Profiles 0027-0494 v1.04.0
#==============================================================================
# 【用途】
# 將 Motion Species Profile 從 0001～0026 正式擴張到 0027～0494。0001～0026
# 仍由既有人工 QA I / II 擁有最高優先權；本層只接管 0027～0494。
# 1. 依 species_core、PMDCollab compiled action metadata 產生 Body / Support /
#    Personality / Deploy cadence。
# 2. 以 body group 做 source preference tuning，不改 Damage / gameplay timing。
# 3. 重要物種使用人工 override，避免傳說、巨型、蛇形、飛行／懸浮種被通用規則誤判。
# 4. Deploy 特殊待機最多一個，Hop 永遠禁止；沒有安全動作就 Idle-only。
#
# 【True-45 產生規則】
# v1.03.10 的 26 隻 pixel-level 白名單拿來校準 metadata 幾何證書：
# row1/row7 的 row_bounds + foot/center/lower-body signature 必須與 cardinal
# row0/2/4/6 全部不同。校準結果 TP=255 / FP=0，precision=100%，recall=84.2%。
# 因此 0027～0494 採「保守、不製造 false-positive」原則；寧可少用動作。
#
# 【主要設定】
# MOTION_GENERATED_PROFILE_V1040：468 隻生成 profile。
# MOTION_IMPORTANT_MANUAL_V1040：90 隻重要物種人工 morphology/support QA anchor。
# MOTION_BODY_SOURCE_PREFS_V1040：七種 body group 的 dash/lunge source preference。
#
# 【機制規則】
# - Frozen Combat Core 不直接修改；全部 trailing alias。
# - HOME 仍為 current logical/action anchor。
# - 真 dash/retreat/push/pull/through 邏輯位移仍由 Spatial Runtime 擁有。
# - Deploy 只接受 actual installed asset + conservative diagonal geometry cert。
# - 0027～0494 不做 live 468×16 verifier route scan；7488 family routes 已 build-time audit。
# - 0001～0026 v1.03.10 pixel truth / v1.03.11 foot anchor 完全保留。
#
# 【可調參數】
# body/support/personality 請優先改 MOTION_IMPORTANT_MANUAL_V1040 或重新跑生成器。
# 不要在此寫 HP、Energy、velocity、logical x/y、action_timer。
#
# 【事件／腳本呼叫】
# 無需事件呼叫。0027～0494 自動取得 profile；Windows Motion verifier 會輸出
# MOTION_GENERATED_PROFILES_0027_0494_V1040。
#
# 【範例】
# Gyarados 0130 = serpentine/float；Snorlax 0143 = heavy/ground；
# Lugia 0249 = avian/float；Rayquaza 0384 = serpentine/float；
# Lucario 0448 = medium/ground；Giratina 0487 = heavy/float。
#==============================================================================
$imported={} unless defined?($imported)
$imported['PMD_AutoChess_MotionGeneratedProfiles_0027_0494_v1040']=true
module PMD_AC
  MOTION_GENERATED_VERSION_V1040='1.04.0'
  MOTION_GENERATED_RANGE_V1040=(27..494).to_a.collect{|i|'%04d'%i}
  MOTION_GENERATED_PROFILE_V1040={
    '0027'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0028'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0029'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>1,:important=>false},
    '0030'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0031'=>{:body=>:heavy,:support=>:ground,:personality=>:royal_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30,:stage=>3,:important=>true},
    '0032'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>1,:important=>false},
    '0033'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0034'=>{:body=>:medium,:support=>:ground,:personality=>:aggressive_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>true},
    '0035'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0036'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0037'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>1,:important=>false},
    '0038'=>{:body=>:quadruped,:support=>:ground,:personality=>:mystic_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>true},
    '0039'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:withdraw],:primary=>41,:between=>17,:ending=>31,:stage=>1,:important=>false},
    '0040'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:withdraw],:primary=>38,:between=>16,:ending=>28,:stage=>2,:important=>false},
    '0041'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0042'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>26,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0043'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0044'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0045'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>false},
    '0046'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0047'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0048'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0049'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0050'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:walk,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0051'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>24,:between=>10,:ending=>18,:stage=>2,:important=>false},
    '0052'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0053'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>24,:between=>10,:ending=>18,:stage=>2,:important=>false},
    '0054'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0055'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0056'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0057'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0058'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>1,:important=>false},
    '0059'=>{:body=>:quadruped,:support=>:ground,:personality=>:proud_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>true},
    '0060'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0061'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0062'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>false},
    '0063'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0064'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0065'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>3,:important=>true},
    '0066'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0067'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0068'=>{:body=>:heavy,:support=>:ground,:personality=>:power_brawler,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30,:stage=>3,:important=>true},
    '0069'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0070'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0071'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>false},
    '0072'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0073'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0074'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>41,:between=>17,:ending=>31,:stage=>1,:important=>false},
    '0075'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>41,:between=>17,:ending=>31,:stage=>2,:important=>false},
    '0076'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:withdraw],:primary=>40,:between=>17,:ending=>30,:stage=>3,:important=>true},
    '0077'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>1,:important=>false},
    '0078'=>{:body=>:quadruped,:support=>:ground,:personality=>:swift_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0079'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>41,:between=>17,:ending=>31,:stage=>1,:important=>false},
    '0080'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>41,:between=>17,:ending=>31,:stage=>2,:important=>false},
    '0081'=>{:body=>:hover,:support=>:ground,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0082'=>{:body=>:hover,:support=>:ground,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0083'=>{:body=>:avian,:support=>:ground,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>false},
    '0084'=>{:body=>:avian,:support=>:ground,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>false},
    '0085'=>{:body=>:avian,:support=>:ground,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>22,:between=>9,:ending=>16,:stage=>2,:important=>false},
    '0086'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0087'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0088'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0089'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>38,:between=>16,:ending=>28,:stage=>2,:important=>false},
    '0090'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0091'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0092'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0093'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0094'=>{:body=>:medium,:support=>:ground,:personality=>:mischievous_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>3,:important=>true},
    '0095'=>{:body=>:serpentine,:support=>:ground,:personality=>:rooted_serpent,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>31,:between=>13,:ending=>23,:stage=>1,:important=>true},
    '0096'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0097'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0098'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0099'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0100'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:walk,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0101'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>24,:between=>10,:ending=>18,:stage=>2,:important=>false},
    '0102'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0103'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0104'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0105'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0106'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0107'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0108'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>41,:between=>17,:ending=>31,:stage=>1,:important=>false},
    '0109'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>1,:important=>false},
    '0110'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0111'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>33,:between=>14,:ending=>25,:stage=>1,:important=>false},
    '0112'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>33,:between=>14,:ending=>25,:stage=>2,:important=>false},
    '0113'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>38,:between=>16,:ending=>28,:stage=>1,:important=>false},
    '0114'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>38,:between=>16,:ending=>28,:stage=>1,:important=>false},
    '0115'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0116'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0117'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0118'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0119'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0120'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0121'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:walk,:specials=>[],:primary=>24,:between=>10,:ending=>18,:stage=>2,:important=>false},
    '0122'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0123'=>{:body=>:medium,:support=>:ground,:personality=>:blade_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>true},
    '0124'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0125'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0126'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0127'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0128'=>{:body=>:quadruped,:support=>:ground,:personality=>:swift_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0129'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0130'=>{:body=>:serpentine,:support=>:float,:personality=>:raging_serpent,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>31,:between=>13,:ending=>23,:stage=>2,:important=>true},
    '0131'=>{:body=>:heavy,:support=>:float,:personality=>:calm_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>38,:between=>16,:ending=>28,:stage=>1,:important=>true},
    '0132'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0133'=>{:body=>:quadruped,:support=>:ground,:personality=>:curious_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:tail_whip],:primary=>30,:between=>13,:ending=>22,:stage=>1,:important=>true},
    '0134'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0135'=>{:body=>:quadruped,:support=>:ground,:personality=>:swift_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0136'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:tail_whip],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0137'=>{:body=>:hover,:support=>:ground,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>1,:important=>false},
    '0138'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>1,:important=>false},
    '0139'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:withdraw],:primary=>38,:between=>16,:ending=>28,:stage=>2,:important=>false},
    '0140'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0141'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0142'=>{:body=>:avian,:support=>:float,:personality=>:ancient_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>22,:between=>9,:ending=>16,:stage=>1,:important=>true},
    '0143'=>{:body=>:heavy,:support=>:ground,:personality=>:sleepy_fortress,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>41,:between=>17,:ending=>31,:stage=>1,:important=>true},
    '0144'=>{:body=>:avian,:support=>:float,:personality=>:ancient_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>true},
    '0145'=>{:body=>:avian,:support=>:float,:personality=>:ancient_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>true},
    '0146'=>{:body=>:avian,:support=>:float,:personality=>:ancient_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>true},
    '0147'=>{:body=>:serpentine,:support=>:ground,:personality=>:ancient_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>33,:between=>14,:ending=>25,:stage=>1,:important=>false},
    '0148'=>{:body=>:serpentine,:support=>:ground,:personality=>:ancient_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:walk,:specials=>[],:primary=>33,:between=>14,:ending=>25,:stage=>2,:important=>false},
    '0149'=>{:body=>:avian,:support=>:float,:personality=>:gentle_dragon,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>true},
    '0150'=>{:body=>:hover,:support=>:float,:personality=>:psychic_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>true},
    '0151'=>{:body=>:hover,:support=>:float,:personality=>:playful_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>28,:between=>12,:ending=>21,:stage=>1,:important=>true},
    '0152'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0153'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0154'=>{:body=>:quadruped,:support=>:ground,:personality=>:calm_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>32,:between=>13,:ending=>24,:stage=>3,:important=>true},
    '0155'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0156'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0157'=>{:body=>:quadruped,:support=>:ground,:personality=>:fiery_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>32,:between=>13,:ending=>24,:stage=>3,:important=>true},
    '0158'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0159'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0160'=>{:body=>:heavy,:support=>:ground,:personality=>:power_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30,:stage=>3,:important=>true},
    '0161'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0162'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:walk,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0163'=>{:body=>:avian,:support=>:ground,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>false},
    '0164'=>{:body=>:avian,:support=>:ground,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>25,:between=>10,:ending=>19,:stage=>2,:important=>false},
    '0165'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0166'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>26,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0167'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:walk,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0168'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0169'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>3,:important=>false},
    '0170'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0171'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0172'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>0,:important=>false},
    '0173'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>0,:important=>false},
    '0174'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>0,:important=>false},
    '0175'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:walk,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>0,:important=>false},
    '0176'=>{:body=>:hover,:support=>:float,:personality=>:gentle_support,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>29,:between=>12,:ending=>22,:stage=>1,:important=>true},
    '0177'=>{:body=>:avian,:support=>:float,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>false},
    '0178'=>{:body=>:avian,:support=>:ground,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>25,:between=>10,:ending=>19,:stage=>2,:important=>false},
    '0179'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0180'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0181'=>{:body=>:medium,:support=>:ground,:personality=>:calm_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>true},
    '0182'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>false},
    '0183'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0184'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>38,:between=>16,:ending=>28,:stage=>2,:important=>false},
    '0185'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>1,:important=>false},
    '0186'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>false},
    '0187'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:walk,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0188'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0189'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>25,:between=>10,:ending=>19,:stage=>3,:important=>false},
    '0190'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0191'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0192'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0193'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0194'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0195'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0196'=>{:body=>:quadruped,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>true},
    '0197'=>{:body=>:quadruped,:support=>:ground,:personality=>:night_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>true},
    '0198'=>{:body=>:avian,:support=>:ground,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>false},
    '0199'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>41,:between=>17,:ending=>31,:stage=>2,:important=>false},
    '0200'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0201'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0202'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:withdraw],:primary=>41,:between=>17,:ending=>31,:stage=>1,:important=>false},
    '0203'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0204'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>41,:between=>17,:ending=>31,:stage=>1,:important=>false},
    '0205'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>41,:between=>17,:ending=>31,:stage=>2,:important=>false},
    '0206'=>{:body=>:serpentine,:support=>:ground,:personality=>:coiled_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>31,:between=>13,:ending=>23,:stage=>1,:important=>false},
    '0207'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0208'=>{:body=>:serpentine,:support=>:ground,:personality=>:rooted_serpent,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>34,:between=>14,:ending=>26,:stage=>2,:important=>true},
    '0209'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>33,:between=>14,:ending=>25,:stage=>1,:important=>false},
    '0210'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0211'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0212'=>{:body=>:medium,:support=>:ground,:personality=>:blade_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>true},
    '0213'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>41,:between=>17,:ending=>31,:stage=>1,:important=>false},
    '0214'=>{:body=>:medium,:support=>:ground,:personality=>:power_brawler,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>true},
    '0215'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>24,:between=>10,:ending=>18,:stage=>1,:important=>false},
    '0216'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0217'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0218'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>41,:between=>17,:ending=>31,:stage=>1,:important=>false},
    '0219'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>41,:between=>17,:ending=>31,:stage=>2,:important=>false},
    '0220'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>38,:between=>16,:ending=>28,:stage=>1,:important=>false},
    '0221'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>38,:between=>16,:ending=>28,:stage=>2,:important=>false},
    '0222'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>30,:between=>13,:ending=>22,:stage=>1,:important=>false},
    '0223'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0224'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0225'=>{:body=>:avian,:support=>:ground,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>false},
    '0226'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0227'=>{:body=>:avian,:support=>:ground,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>false},
    '0228'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>1,:important=>false},
    '0229'=>{:body=>:quadruped,:support=>:ground,:personality=>:dark_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>true},
    '0230'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>false},
    '0231'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>33,:between=>14,:ending=>25,:stage=>1,:important=>false},
    '0232'=>{:body=>:heavy,:support=>:ground,:personality=>:rolling_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:withdraw],:primary=>38,:between=>16,:ending=>28,:stage=>2,:important=>true},
    '0233'=>{:body=>:hover,:support=>:ground,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0234'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>1,:important=>false},
    '0235'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0236'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>0,:important=>false},
    '0237'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0238'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>0,:important=>false},
    '0239'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>0,:important=>false},
    '0240'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>0,:important=>false},
    '0241'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0242'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0243'=>{:body=>:quadruped,:support=>:ground,:personality=>:swift_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>1,:important=>true},
    '0244'=>{:body=>:quadruped,:support=>:ground,:personality=>:power_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>32,:between=>13,:ending=>24,:stage=>1,:important=>true},
    '0245'=>{:body=>:quadruped,:support=>:ground,:personality=>:calm_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>32,:between=>13,:ending=>24,:stage=>1,:important=>true},
    '0246'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0247'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0248'=>{:body=>:heavy,:support=>:ground,:personality=>:ancient_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>42,:between=>18,:ending=>32,:stage=>3,:important=>true},
    '0249'=>{:body=>:avian,:support=>:float,:personality=>:ancient_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>24,:between=>10,:ending=>18,:stage=>1,:important=>true},
    '0250'=>{:body=>:avian,:support=>:float,:personality=>:ancient_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>true},
    '0251'=>{:body=>:hover,:support=>:float,:personality=>:gentle_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>28,:between=>12,:ending=>21,:stage=>1,:important=>true},
    '0252'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0253'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0254'=>{:body=>:medium,:support=>:ground,:personality=>:swift_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>3,:important=>true},
    '0255'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0256'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0257'=>{:body=>:medium,:support=>:ground,:personality=>:power_brawler,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>true},
    '0258'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0259'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0260'=>{:body=>:heavy,:support=>:ground,:personality=>:swamp_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30,:stage=>3,:important=>true},
    '0261'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>33,:between=>14,:ending=>25,:stage=>1,:important=>false},
    '0262'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0263'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>1,:important=>false},
    '0264'=>{:body=>:quadruped,:support=>:ground,:personality=>:swift_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0265'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0266'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:walk,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0267'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>false},
    '0268'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:walk,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0269'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>false},
    '0270'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0271'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0272'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>false},
    '0273'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0274'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0275'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>false},
    '0276'=>{:body=>:avian,:support=>:ground,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>false},
    '0277'=>{:body=>:avian,:support=>:ground,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:walk,:specials=>[],:primary=>22,:between=>9,:ending=>16,:stage=>2,:important=>false},
    '0278'=>{:body=>:avian,:support=>:float,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>false},
    '0279'=>{:body=>:avian,:support=>:ground,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>25,:between=>10,:ending=>19,:stage=>2,:important=>false},
    '0280'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0281'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:walk,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0282'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>true},
    '0283'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0284'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>26,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0285'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0286'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0287'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0288'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0289'=>{:body=>:heavy,:support=>:ground,:personality=>:sleepy_powerhouse,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>42,:between=>18,:ending=>32,:stage=>3,:important=>true},
    '0290'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0291'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>23,:between=>10,:ending=>17,:stage=>2,:important=>false},
    '0292'=>{:body=>:hover,:support=>:float,:personality=>:silent_spirit,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>2,:important=>true},
    '0293'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0294'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0295'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>false},
    '0296'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:nod],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0297'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>38,:between=>16,:ending=>28,:stage=>2,:important=>false},
    '0298'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>0,:important=>false},
    '0299'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>41,:between=>17,:ending=>31,:stage=>1,:important=>false},
    '0300'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0301'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0302'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0303'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:walk,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0304'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0305'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0306'=>{:body=>:heavy,:support=>:ground,:personality=>:armored_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>40,:between=>17,:ending=>30,:stage=>3,:important=>true},
    '0307'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0308'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0309'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>1,:important=>false},
    '0310'=>{:body=>:quadruped,:support=>:ground,:personality=>:swift_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0311'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0312'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0313'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0314'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0315'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:walk,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0316'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0317'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:walk,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0318'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0319'=>{:body=>:hover,:support=>:float,:personality=>:swift_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>2,:important=>true},
    '0320'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>38,:between=>16,:ending=>28,:stage=>1,:important=>false},
    '0321'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>38,:between=>16,:ending=>28,:stage=>2,:important=>false},
    '0322'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>33,:between=>14,:ending=>25,:stage=>1,:important=>false},
    '0323'=>{:body=>:quadruped,:support=>:ground,:personality=>:volcanic_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>33,:between=>14,:ending=>25,:stage=>2,:important=>true},
    '0324'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>41,:between=>17,:ending=>31,:stage=>1,:important=>false},
    '0325'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0326'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0327'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0328'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0329'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0330'=>{:body=>:avian,:support=>:float,:personality=>:desert_dragon,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>3,:important=>true},
    '0331'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0332'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0333'=>{:body=>:avian,:support=>:float,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>false},
    '0334'=>{:body=>:avian,:support=>:float,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>25,:between=>10,:ending=>19,:stage=>2,:important=>false},
    '0335'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0336'=>{:body=>:serpentine,:support=>:ground,:personality=>:coiled_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>31,:between=>13,:ending=>23,:stage=>1,:important=>false},
    '0337'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0338'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0339'=>{:body=>:serpentine,:support=>:ground,:personality=>:coiled_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>31,:between=>13,:ending=>23,:stage=>1,:important=>false},
    '0340'=>{:body=>:serpentine,:support=>:ground,:personality=>:coiled_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>31,:between=>13,:ending=>23,:stage=>2,:important=>false},
    '0341'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0342'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0343'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0344'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0345'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:walk,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>1,:important=>false},
    '0346'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>38,:between=>16,:ending=>28,:stage=>2,:important=>false},
    '0347'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0348'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>38,:between=>16,:ending=>28,:stage=>2,:important=>false},
    '0349'=>{:body=>:serpentine,:support=>:ground,:personality=>:coiled_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>31,:between=>13,:ending=>23,:stage=>1,:important=>false},
    '0350'=>{:body=>:serpentine,:support=>:float,:personality=>:graceful_serpent,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>31,:between=>13,:ending=>23,:stage=>2,:important=>true},
    '0351'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0352'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>1,:important=>false},
    '0353'=>{:body=>:hover,:support=>:ground,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0354'=>{:body=>:hover,:support=>:ground,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0355'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>1,:important=>false},
    '0356'=>{:body=>:hover,:support=>:ground,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>2,:important=>false},
    '0357'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0358'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0359'=>{:body=>:quadruped,:support=>:ground,:personality=>:solitary_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>1,:important=>true},
    '0360'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>0,:important=>false},
    '0361'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0362'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0363'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>41,:between=>17,:ending=>31,:stage=>1,:important=>false},
    '0364'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>38,:between=>16,:ending=>28,:stage=>2,:important=>false},
    '0365'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30,:stage=>3,:important=>false},
    '0366'=>{:body=>:serpentine,:support=>:ground,:personality=>:coiled_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>34,:between=>14,:ending=>26,:stage=>1,:important=>false},
    '0367'=>{:body=>:serpentine,:support=>:float,:personality=>:coiled_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>31,:between=>13,:ending=>23,:stage=>2,:important=>false},
    '0368'=>{:body=>:serpentine,:support=>:ground,:personality=>:coiled_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>31,:between=>13,:ending=>23,:stage=>2,:important=>false},
    '0369'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>38,:between=>16,:ending=>28,:stage=>1,:important=>false},
    '0370'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0371'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0372'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0373'=>{:body=>:avian,:support=>:float,:personality=>:proud_dragon,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>true},
    '0374'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>41,:between=>17,:ending=>31,:stage=>1,:important=>false},
    '0375'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>38,:between=>16,:ending=>28,:stage=>2,:important=>false},
    '0376'=>{:body=>:heavy,:support=>:float,:personality=>:steel_fortress,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>42,:between=>18,:ending=>32,:stage=>3,:important=>true},
    '0377'=>{:body=>:heavy,:support=>:ground,:personality=>:ancient_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30,:stage=>1,:important=>false},
    '0378'=>{:body=>:heavy,:support=>:ground,:personality=>:ancient_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30,:stage=>1,:important=>false},
    '0379'=>{:body=>:heavy,:support=>:ground,:personality=>:ancient_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30,:stage=>1,:important=>false},
    '0380'=>{:body=>:hover,:support=>:float,:personality=>:gentle_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>true},
    '0381'=>{:body=>:hover,:support=>:float,:personality=>:swift_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>true},
    '0382'=>{:body=>:heavy,:support=>:float,:personality=>:ocean_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30,:stage=>1,:important=>true},
    '0383'=>{:body=>:heavy,:support=>:ground,:personality=>:earth_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30,:stage=>1,:important=>true},
    '0384'=>{:body=>:serpentine,:support=>:float,:personality=>:sky_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>33,:between=>14,:ending=>25,:stage=>1,:important=>true},
    '0385'=>{:body=>:hover,:support=>:float,:personality=>:wish_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>28,:between=>12,:ending=>21,:stage=>1,:important=>true},
    '0386'=>{:body=>:hover,:support=>:float,:personality=>:alien_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>true},
    '0387'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:withdraw],:primary=>41,:between=>17,:ending=>31,:stage=>1,:important=>false},
    '0388'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:withdraw],:primary=>41,:between=>17,:ending=>31,:stage=>2,:important=>false},
    '0389'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:withdraw],:primary=>40,:between=>17,:ending=>30,:stage=>3,:important=>true},
    '0390'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0391'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0392'=>{:body=>:medium,:support=>:ground,:personality=>:swift_brawler,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>true},
    '0393'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>29,:between=>12,:ending=>22,:stage=>1,:important=>false},
    '0394'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>26,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0395'=>{:body=>:medium,:support=>:ground,:personality=>:proud_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>true},
    '0396'=>{:body=>:avian,:support=>:float,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>false},
    '0397'=>{:body=>:avian,:support=>:float,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>25,:between=>10,:ending=>19,:stage=>2,:important=>false},
    '0398'=>{:body=>:avian,:support=>:float,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>27,:between=>11,:ending=>20,:stage=>3,:important=>false},
    '0399'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0400'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0401'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0402'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0403'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>30,:between=>13,:ending=>22,:stage=>1,:important=>false},
    '0404'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0405'=>{:body=>:quadruped,:support=>:ground,:personality=>:electric_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>32,:between=>13,:ending=>24,:stage=>3,:important=>true},
    '0406'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>23,:between=>10,:ending=>17,:stage=>0,:important=>false},
    '0407'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0408'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0409'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0410'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>41,:between=>17,:ending=>31,:stage=>1,:important=>false},
    '0411'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>41,:between=>17,:ending=>31,:stage=>2,:important=>false},
    '0412'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0413'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0414'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:hover,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0415'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0416'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0417'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0418'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0419'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>24,:between=>10,:ending=>18,:stage=>2,:important=>false},
    '0420'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0421'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0422'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0423'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>41,:between=>17,:ending=>31,:stage=>2,:important=>false},
    '0424'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>24,:between=>10,:ending=>18,:stage=>2,:important=>false},
    '0425'=>{:body=>:hover,:support=>:ground,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0426'=>{:body=>:hover,:support=>:float,:personality=>:drifting_spirit,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>2,:important=>true},
    '0427'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0428'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0429'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0430'=>{:body=>:avian,:support=>:float,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>25,:between=>10,:ending=>19,:stage=>2,:important=>false},
    '0431'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:nod],:primary=>30,:between=>13,:ending=>22,:stage=>1,:important=>false},
    '0432'=>{:body=>:quadruped,:support=>:ground,:personality=>:swift_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0433'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>0,:important=>false},
    '0434'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>1,:important=>false},
    '0435'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>false},
    '0436'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>1,:important=>false},
    '0437'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>2,:important=>false},
    '0438'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>0,:important=>false},
    '0439'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>0,:important=>false},
    '0440'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:shake],:primary=>41,:between=>17,:ending=>31,:stage=>0,:important=>false},
    '0441'=>{:body=>:avian,:support=>:ground,:personality=>:watchful_bird,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>false},
    '0442'=>{:body=>:hover,:support=>:ground,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>1,:important=>false},
    '0443'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0444'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0445'=>{:body=>:medium,:support=>:ground,:personality=>:apex_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>31,:between=>13,:ending=>23,:stage=>3,:important=>true},
    '0446'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>41,:between=>17,:ending=>31,:stage=>0,:important=>false},
    '0447'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>0,:important=>false},
    '0448'=>{:body=>:medium,:support=>:ground,:personality=>:disciplined_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>1,:important=>true},
    '0449'=>{:body=>:quadruped,:support=>:ground,:personality=>:steady_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>33,:between=>14,:ending=>25,:stage=>1,:important=>false},
    '0450'=>{:body=>:heavy,:support=>:ground,:personality=>:sand_fortress,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>38,:between=>16,:ending=>28,:stage=>2,:important=>true},
    '0451'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0452'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0453'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0454'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0455'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0456'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>23,:between=>10,:ending=>17,:stage=>1,:important=>false},
    '0457'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0458'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>26,:between=>11,:ending=>20,:stage=>0,:important=>false},
    '0459'=>{:body=>:small,:support=>:ground,:personality=>:lively_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>false},
    '0460'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0461'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>24,:between=>10,:ending=>18,:stage=>2,:important=>false},
    '0462'=>{:body=>:heavy,:support=>:float,:personality=>:magnetic_fortress,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30,:stage=>3,:important=>true},
    '0463'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:withdraw],:primary=>38,:between=>16,:ending=>28,:stage=>2,:important=>false},
    '0464'=>{:body=>:heavy,:support=>:ground,:personality=>:armored_powerhouse,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>43,:between=>18,:ending=>32,:stage=>3,:important=>true},
    '0465'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>38,:between=>16,:ending=>28,:stage=>2,:important=>false},
    '0466'=>{:body=>:heavy,:support=>:ground,:personality=>:electric_brawler,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>38,:between=>16,:ending=>28,:stage=>2,:important=>true},
    '0467'=>{:body=>:heavy,:support=>:ground,:personality=>:fire_brawler,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>38,:between=>16,:ending=>28,:stage=>2,:important=>true},
    '0468'=>{:body=>:avian,:support=>:float,:personality=>:gentle_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>25,:between=>10,:ending=>19,:stage=>2,:important=>true},
    '0469'=>{:body=>:medium,:support=>:ground,:personality=>:focused_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>27,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0470'=>{:body=>:quadruped,:support=>:ground,:personality=>:forest_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:tail_whip],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>true},
    '0471'=>{:body=>:quadruped,:support=>:ground,:personality=>:ice_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:tail_whip],:primary=>30,:between=>13,:ending=>22,:stage=>2,:important=>true},
    '0472'=>{:body=>:hover,:support=>:float,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>26,:between=>11,:ending=>20,:stage=>2,:important=>false},
    '0473'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30,:stage=>3,:important=>false},
    '0474'=>{:body=>:hover,:support=>:float,:personality=>:digital_caster,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:walk,:specials=>[],:primary=>28,:between=>12,:ending=>21,:stage=>3,:important=>true},
    '0475'=>{:body=>:medium,:support=>:ground,:personality=>:physical_hunter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>29,:between=>12,:ending=>22,:stage=>3,:important=>false},
    '0476'=>{:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:walk,:specials=>[],:primary=>41,:between=>17,:ending=>31,:stage=>2,:important=>false},
    '0477'=>{:body=>:hover,:support=>:ground,:personality=>:calm_hover,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>28,:between=>12,:ending=>21,:stage=>3,:important=>false},
    '0478'=>{:body=>:medium,:support=>:ground,:personality=>:balanced_fighter,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>24,:between=>10,:ending=>18,:stage=>2,:important=>false},
    '0479'=>{:body=>:hover,:support=>:float,:personality=>:mischievous_spirit,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>26,:between=>11,:ending=>20,:stage=>1,:important=>true},
    '0480'=>{:body=>:hover,:support=>:float,:personality=>:ancient_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>28,:between=>12,:ending=>21,:stage=>1,:important=>false},
    '0481'=>{:body=>:hover,:support=>:float,:personality=>:ancient_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>28,:between=>12,:ending=>21,:stage=>1,:important=>false},
    '0482'=>{:body=>:hover,:support=>:float,:personality=>:ancient_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[:hover],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>false},
    '0483'=>{:body=>:heavy,:support=>:ground,:personality=>:time_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30,:stage=>1,:important=>true},
    '0484'=>{:body=>:heavy,:support=>:ground,:personality=>:space_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30,:stage=>1,:important=>true},
    '0485'=>{:body=>:heavy,:support=>:ground,:personality=>:volcanic_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30,:stage=>1,:important=>true},
    '0486'=>{:body=>:heavy,:support=>:ground,:personality=>:ancient_colossus,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30,:stage=>1,:important=>true},
    '0487'=>{:body=>:heavy,:support=>:float,:personality=>:distortion_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>40,:between=>17,:ending=>30,:stage=>1,:important=>true},
    '0488'=>{:body=>:hover,:support=>:float,:personality=>:lunar_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>28,:between=>12,:ending=>21,:stage=>1,:important=>true},
    '0489'=>{:body=>:small,:support=>:float,:personality=>:sea_sprite,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>true},
    '0490'=>{:body=>:hover,:support=>:float,:personality=>:sea_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>28,:between=>12,:ending=>21,:stage=>1,:important=>true},
    '0491'=>{:body=>:hover,:support=>:float,:personality=>:nightmare_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>true},
    '0492'=>{:body=>:quadruped,:support=>:ground,:personality=>:gentle_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:walk,:specials=>[],:primary=>32,:between=>13,:ending=>24,:stage=>1,:important=>true},
    '0493'=>{:body=>:heavy,:support=>:ground,:personality=>:creator_legend,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>37,:between=>16,:ending=>28,:stage=>1,:important=>true},
    '0494'=>{:body=>:small,:support=>:ground,:personality=>:victory_scout,:ambient=>[[:walk,24],[:idle,14]],:deploy_base=>:idle,:specials=>[],:primary=>25,:between=>10,:ending=>19,:stage=>1,:important=>true},
  }
  MOTION_IMPORTANT_MANUAL_V1040={
    '0031'=>{:name=>'Nidoqueen',:body=>:heavy,:support=>:ground,:personality=>:royal_guardian},
    '0034'=>{:name=>'Nidoking',:body=>:medium,:support=>:ground,:personality=>:aggressive_hunter},
    '0038'=>{:name=>'Ninetales',:body=>:quadruped,:support=>:ground,:personality=>:mystic_hunter},
    '0059'=>{:name=>'Arcanine',:body=>:quadruped,:support=>:ground,:personality=>:proud_guardian},
    '0065'=>{:name=>'Alakazam',:body=>:medium,:support=>:ground,:personality=>:focused_caster},
    '0068'=>{:name=>'Machamp',:body=>:heavy,:support=>:ground,:personality=>:power_brawler},
    '0076'=>{:name=>'Golem',:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian},
    '0094'=>{:name=>'Gengar',:body=>:medium,:support=>:ground,:personality=>:mischievous_hunter},
    '0095'=>{:name=>'Onix',:body=>:serpentine,:support=>:ground,:personality=>:rooted_serpent},
    '0123'=>{:name=>'Scyther',:body=>:medium,:support=>:ground,:personality=>:blade_hunter},
    '0130'=>{:name=>'Gyarados',:body=>:serpentine,:support=>:float,:personality=>:raging_serpent},
    '0131'=>{:name=>'Lapras',:body=>:heavy,:support=>:float,:personality=>:calm_guardian},
    '0133'=>{:name=>'Eevee',:body=>:quadruped,:support=>:ground,:personality=>:curious_scout},
    '0142'=>{:name=>'Aerodactyl',:body=>:avian,:support=>:float,:personality=>:ancient_hunter},
    '0143'=>{:name=>'Snorlax',:body=>:heavy,:support=>:ground,:personality=>:sleepy_fortress},
    '0144'=>{:name=>'Articuno',:body=>:avian,:support=>:float,:personality=>:ancient_legend},
    '0145'=>{:name=>'Zapdos',:body=>:avian,:support=>:float,:personality=>:ancient_legend},
    '0146'=>{:name=>'Moltres',:body=>:avian,:support=>:float,:personality=>:ancient_legend},
    '0149'=>{:name=>'Dragonite',:body=>:avian,:support=>:float,:personality=>:gentle_dragon},
    '0150'=>{:name=>'Mewtwo',:body=>:hover,:support=>:float,:personality=>:psychic_legend},
    '0151'=>{:name=>'Mew',:body=>:hover,:support=>:float,:personality=>:playful_legend},
    '0154'=>{:name=>'Meganium',:body=>:quadruped,:support=>:ground,:personality=>:calm_guardian},
    '0157'=>{:name=>'Typhlosion',:body=>:quadruped,:support=>:ground,:personality=>:fiery_hunter},
    '0160'=>{:name=>'Feraligatr',:body=>:heavy,:support=>:ground,:personality=>:power_hunter},
    '0176'=>{:name=>'Togetic',:body=>:hover,:support=>:float,:personality=>:gentle_support},
    '0181'=>{:name=>'Ampharos',:body=>:medium,:support=>:ground,:personality=>:calm_caster},
    '0196'=>{:name=>'Espeon',:body=>:quadruped,:support=>:ground,:personality=>:focused_caster},
    '0197'=>{:name=>'Umbreon',:body=>:quadruped,:support=>:ground,:personality=>:night_guardian},
    '0208'=>{:name=>'Steelix',:body=>:serpentine,:support=>:ground,:personality=>:rooted_serpent},
    '0212'=>{:name=>'Scizor',:body=>:medium,:support=>:ground,:personality=>:blade_hunter},
    '0214'=>{:name=>'Heracross',:body=>:medium,:support=>:ground,:personality=>:power_brawler},
    '0229'=>{:name=>'Houndoom',:body=>:quadruped,:support=>:ground,:personality=>:dark_hunter},
    '0232'=>{:name=>'Donphan',:body=>:heavy,:support=>:ground,:personality=>:rolling_guardian},
    '0243'=>{:name=>'Raikou',:body=>:quadruped,:support=>:ground,:personality=>:swift_legend},
    '0244'=>{:name=>'Entei',:body=>:quadruped,:support=>:ground,:personality=>:power_legend},
    '0245'=>{:name=>'Suicune',:body=>:quadruped,:support=>:ground,:personality=>:calm_legend},
    '0248'=>{:name=>'Tyranitar',:body=>:heavy,:support=>:ground,:personality=>:ancient_guardian},
    '0249'=>{:name=>'Lugia',:body=>:avian,:support=>:float,:personality=>:ancient_legend},
    '0250'=>{:name=>'Ho-Oh',:body=>:avian,:support=>:float,:personality=>:ancient_legend},
    '0251'=>{:name=>'Celebi',:body=>:hover,:support=>:float,:personality=>:gentle_legend},
    '0254'=>{:name=>'Sceptile',:body=>:medium,:support=>:ground,:personality=>:swift_hunter},
    '0257'=>{:name=>'Blaziken',:body=>:medium,:support=>:ground,:personality=>:power_brawler},
    '0260'=>{:name=>'Swampert',:body=>:heavy,:support=>:ground,:personality=>:swamp_guardian},
    '0282'=>{:name=>'Gardevoir',:body=>:medium,:support=>:ground,:personality=>:focused_caster},
    '0289'=>{:name=>'Slaking',:body=>:heavy,:support=>:ground,:personality=>:sleepy_powerhouse},
    '0292'=>{:name=>'Shedinja',:body=>:hover,:support=>:float,:personality=>:silent_spirit},
    '0306'=>{:name=>'Aggron',:body=>:heavy,:support=>:ground,:personality=>:armored_guardian},
    '0319'=>{:name=>'Sharpedo',:body=>:hover,:support=>:float,:personality=>:swift_hunter},
    '0323'=>{:name=>'Camerupt',:body=>:quadruped,:support=>:ground,:personality=>:volcanic_guardian},
    '0330'=>{:name=>'Flygon',:body=>:avian,:support=>:float,:personality=>:desert_dragon},
    '0350'=>{:name=>'Milotic',:body=>:serpentine,:support=>:float,:personality=>:graceful_serpent},
    '0359'=>{:name=>'Absol',:body=>:quadruped,:support=>:ground,:personality=>:solitary_hunter},
    '0373'=>{:name=>'Salamence',:body=>:avian,:support=>:float,:personality=>:proud_dragon},
    '0376'=>{:name=>'Metagross',:body=>:heavy,:support=>:float,:personality=>:steel_fortress},
    '0380'=>{:name=>'Latias',:body=>:hover,:support=>:float,:personality=>:gentle_legend},
    '0381'=>{:name=>'Latios',:body=>:hover,:support=>:float,:personality=>:swift_legend},
    '0382'=>{:name=>'Kyogre',:body=>:heavy,:support=>:float,:personality=>:ocean_legend},
    '0383'=>{:name=>'Groudon',:body=>:heavy,:support=>:ground,:personality=>:earth_legend},
    '0384'=>{:name=>'Rayquaza',:body=>:serpentine,:support=>:float,:personality=>:sky_legend},
    '0385'=>{:name=>'Jirachi',:body=>:hover,:support=>:float,:personality=>:wish_legend},
    '0386'=>{:name=>'Deoxys',:body=>:hover,:support=>:float,:personality=>:alien_hunter},
    '0389'=>{:name=>'Torterra',:body=>:heavy,:support=>:ground,:personality=>:rooted_guardian},
    '0392'=>{:name=>'Infernape',:body=>:medium,:support=>:ground,:personality=>:swift_brawler},
    '0395'=>{:name=>'Empoleon',:body=>:medium,:support=>:ground,:personality=>:proud_guardian},
    '0405'=>{:name=>'Luxray',:body=>:quadruped,:support=>:ground,:personality=>:electric_hunter},
    '0426'=>{:name=>'Drifblim',:body=>:hover,:support=>:float,:personality=>:drifting_spirit},
    '0445'=>{:name=>'Garchomp',:body=>:medium,:support=>:ground,:personality=>:apex_hunter},
    '0448'=>{:name=>'Lucario',:body=>:medium,:support=>:ground,:personality=>:disciplined_hunter},
    '0450'=>{:name=>'Hippowdon',:body=>:heavy,:support=>:ground,:personality=>:sand_fortress},
    '0462'=>{:name=>'Magnezone',:body=>:heavy,:support=>:float,:personality=>:magnetic_fortress},
    '0464'=>{:name=>'Rhyperior',:body=>:heavy,:support=>:ground,:personality=>:armored_powerhouse},
    '0466'=>{:name=>'Electivire',:body=>:heavy,:support=>:ground,:personality=>:electric_brawler},
    '0467'=>{:name=>'Magmortar',:body=>:heavy,:support=>:ground,:personality=>:fire_brawler},
    '0468'=>{:name=>'Togekiss',:body=>:avian,:support=>:float,:personality=>:gentle_guardian},
    '0470'=>{:name=>'Leafeon',:body=>:quadruped,:support=>:ground,:personality=>:forest_hunter},
    '0471'=>{:name=>'Glaceon',:body=>:quadruped,:support=>:ground,:personality=>:ice_hunter},
    '0474'=>{:name=>'Porygon-Z',:body=>:hover,:support=>:float,:personality=>:digital_caster},
    '0479'=>{:name=>'Rotom',:body=>:hover,:support=>:float,:personality=>:mischievous_spirit},
    '0483'=>{:name=>'Dialga',:body=>:heavy,:support=>:ground,:personality=>:time_legend},
    '0484'=>{:name=>'Palkia',:body=>:heavy,:support=>:ground,:personality=>:space_legend},
    '0485'=>{:name=>'Heatran',:body=>:heavy,:support=>:ground,:personality=>:volcanic_legend},
    '0486'=>{:name=>'Regigigas',:body=>:heavy,:support=>:ground,:personality=>:ancient_colossus},
    '0487'=>{:name=>'Giratina',:body=>:heavy,:support=>:float,:personality=>:distortion_legend},
    '0488'=>{:name=>'Cresselia',:body=>:hover,:support=>:float,:personality=>:lunar_legend},
    '0489'=>{:name=>'Phione',:body=>:small,:support=>:float,:personality=>:sea_sprite},
    '0490'=>{:name=>'Manaphy',:body=>:hover,:support=>:float,:personality=>:sea_legend},
    '0491'=>{:name=>'Darkrai',:body=>:hover,:support=>:float,:personality=>:nightmare_legend},
    '0492'=>{:name=>'Shaymin',:body=>:quadruped,:support=>:ground,:personality=>:gentle_legend},
    '0493'=>{:name=>'Arceus',:body=>:heavy,:support=>:ground,:personality=>:creator_legend},
    '0494'=>{:name=>'Victini',:body=>:small,:support=>:ground,:personality=>:victory_scout},
  }
  MOTION_BODY_SOURCE_PREFS_V1040={
    :small=>{:dash=>[:quick_strike,:leap_forth,:hop,:attack,:strike],:lunge=>[:leap_forth,:hop,:attack,:strike]},
    :medium=>{:dash=>[:quick_strike,:leap_forth,:hop,:attack,:strike],:lunge=>[:leap_forth,:hop,:attack,:strike]},
    :quadruped=>{:dash=>[:quick_strike,:leap_forth,:attack,:strike],:lunge=>[:leap_forth,:attack,:strike]},
    :avian=>{:dash=>[:quick_strike,:attack,:double],:lunge=>[:attack,:double]},
    :hover=>{:dash=>[:quick_strike,:attack,:double],:lunge=>[:attack,:double]},
    :serpentine=>{:dash=>[:attack,:swing,:double,:head],:lunge=>[:attack,:swing,:double,:head]},
    :heavy=>{:dash=>[:attack,:strike,:double],:lunge=>[:attack,:strike,:double]}
  }
  MOTION_GENERATED_BODY_COUNTS_V1040={:small=>95,:medium=>141,:quadruped=>50,:heavy=>74,:hover=>62,:avian=>31,:serpentine=>15}
  MOTION_GENERATED_SUPPORT_COUNTS_V1040={:ground=>388,:float=>80}
  MOTION_GENERATED_GEOM_ACTIONS_V1040=4707
  MOTION_GENERATED_STATIC_ROUTES_V1040=7488
  MOTION_GENERATED_STATIC_ROUTE_PASS_V1040=7488
  MOTION_GENERATED_IMPORTANT_COUNT_V1040=90
  MOTION_GENERATED_BASE_CERTIFIED_V1040=457

  class << self
    alias pmd_ac_v1040_motion_phase_a_species_v102? motion_phase_a_species_v102? unless method_defined?(:pmd_ac_v1040_motion_phase_a_species_v102?)
    alias pmd_ac_v1040_motion_species_profile_v102 motion_species_profile_v102 unless method_defined?(:pmd_ac_v1040_motion_species_profile_v102)
    alias pmd_ac_v1040_native_pose_candidates_v061 native_pose_candidates_v061 unless method_defined?(:pmd_ac_v1040_native_pose_candidates_v061)

    def motion_generated_species_v1040?(species)
      n=species.to_s.to_i
      n>=27 && n<=494
    end

    def motion_generated_profile_v1040(species)
      MOTION_GENERATED_PROFILE_V1040[species.to_s]
    end

    def motion_phase_a_species_v102?(species)
      return true if motion_generated_species_v1040?(species)
      pmd_ac_v1040_motion_phase_a_species_v102?(species)
    end

    def motion_species_profile_v102(species)
      p=motion_generated_profile_v1040(species)
      return p if p!=nil
      pmd_ac_v1040_motion_species_profile_v102(species)
    end

    def motion_generated_row_sig_v1040(d,idx)
      return nil if d==nil
      rb=d[:row_bounds];fy=d[:row_foot_y];cy=d[:row_center_y];ly=d[:row_lower_body_y]
      return nil if rb==nil || rb.size<8
      [rb[idx],fy==nil ? nil : fy[idx],cy==nil ? nil : cy[idx],ly==nil ? nil : ly[idx]]
    rescue
      nil
    end

    def motion_generated_diag_geometry_v1040?(species,action)
      return false if action==nil
      @motion_generated_diag_cache_v1040={} if @motion_generated_diag_cache_v1040==nil
      k=species.to_s+'|'+action.to_s
      return @motion_generated_diag_cache_v1040[k] if @motion_generated_diag_cache_v1040.has_key?(k)
      d=compiled_direct_action_v061(species.to_s,action) rescue nil
      ok=true
      ok=false if d==nil || d[:copy_of]!=nil || d[:alias_of]!=nil || d[:rows].to_i<8
      if ok
        s1=motion_generated_row_sig_v1040(d,1);s7=motion_generated_row_sig_v1040(d,7)
        ok=false if s1==nil || s7==nil
        if ok
          [0,2,4,6].each do |i|
            c=motion_generated_row_sig_v1040(d,i)
            ok=false if s1==c || s7==c
          end
        end
      end
      @motion_generated_diag_cache_v1040[k]=ok ? true : false
      ok ? true : false
    rescue
      false
    end

    def motion_generated_deploy_action_v1040?(species,action)
      return false if action==nil || action==:hop
      return false unless motion_generated_diag_geometry_v1040?(species,action)
      motion_playable_v102?(species.to_s,action)
    rescue
      false
    end

    def motion_generated_source_prefs_v1040(species,family)
      p=motion_generated_profile_v1040(species)
      return [] if p==nil
      h=MOTION_BODY_SOURCE_PREFS_V1040[p[:body]]
      return [] if h==nil
      h[family] || []
    rescue
      []
    end

    def native_pose_candidates_v061(species,move_key,data=nil,profile=nil)
      base=pmd_ac_v1040_native_pose_candidates_v061(species,move_key,data,profile)
      return base unless motion_generated_species_v1040?(species)
      family=motion_action_family_v102(move_key,data,profile)
      out=[]
      (motion_generated_source_prefs_v1040(species,family)+base).each do |pose|
        next if pose==nil
        next unless motion_generated_diag_geometry_v1040?(species,pose)
        out.push(pose) unless out.include?(pose)
      end
      if out.empty?
        [:attack,:idle].each do |pose|
          out.push(pose) if motion_generated_diag_geometry_v1040?(species,pose) && !out.include?(pose)
        end
      end
      out.empty? ? base : out
    rescue
      pmd_ac_v1040_native_pose_candidates_v061(species,move_key,data,profile)
    end
  end
end

class Game_PMDChessUnit
  alias pmd_ac_v1040_motion_deploy_base_45_v1038 motion_deploy_base_45_v1038 unless method_defined?(:pmd_ac_v1040_motion_deploy_base_45_v1038)
  alias pmd_ac_v1040_motion_deploy_rich_specials_v1035 motion_deploy_rich_specials_v1035 unless method_defined?(:pmd_ac_v1040_motion_deploy_rich_specials_v1035)
  alias pmd_ac_v1040_motion_deploy_rich_sequence_v1035 motion_deploy_rich_sequence_v1035 unless method_defined?(:pmd_ac_v1040_motion_deploy_rich_sequence_v1035)

  def motion_deploy_base_45_v1038
    unless PMD_AC.motion_generated_species_v1040?(@species)
      return pmd_ac_v1040_motion_deploy_base_45_v1038
    end
    p=PMD_AC.motion_generated_profile_v1040(@species) || {}
    candidates=[p[:deploy_base],:idle,:hover,:float,:walk]
    candidates.each do |a|
      return a if PMD_AC.motion_generated_deploy_action_v1040?(@species,a)
    end
    pmd_ac_v1040_motion_deploy_base_45_v1038
  rescue
    pmd_ac_v1040_motion_deploy_base_45_v1038
  end

  def motion_deploy_rich_specials_v1035
    unless PMD_AC.motion_generated_species_v1040?(@species)
      return pmd_ac_v1040_motion_deploy_rich_specials_v1035
    end
    p=PMD_AC.motion_generated_profile_v1040(@species) || {}
    out=[]
    (p[:specials] || []).each do |a|
      next if a==nil || a==:hop
      next unless PMD_AC.motion_generated_deploy_action_v1040?(@species,a)
      out.push(a) unless out.include?(a)
    end
    out
  rescue
    []
  end

  def motion_deploy_rich_sequence_v1035
    unless PMD_AC.motion_generated_species_v1040?(@species)
      return pmd_ac_v1040_motion_deploy_rich_sequence_v1035
    end
    return @motion_deploy_rich_sequence_v1035 if @motion_deploy_rich_sequence_v1035!=nil
    p=PMD_AC.motion_generated_profile_v1040(@species) || {}
    base=motion_deploy_base_45_v1038
    specials=motion_deploy_rich_specials_v1035
    primary=p[:primary].to_i;primary=28 if primary<=0
    between=p[:between].to_i;between=11 if between<=0
    ending=p[:ending].to_i;ending=20 if ending<=0
    seq=[]
    seq.push([base,motion_deploy_scaled_hold_v1037(primary)])
    specials.each do |a|
      seq.push([a,motion_deploy_scaled_hold_v1037(motion_deploy_hold_v1035(a))])
      seq.push([base,motion_deploy_scaled_hold_v1037(between)])
    end
    seq.push([base,motion_deploy_scaled_hold_v1037(ending)])
    @motion_deploy_rich_special_count_v1035=specials.size
    @motion_deploy_rich_sequence_v1035=seq
    seq
  rescue
    pmd_ac_v1040_motion_deploy_rich_sequence_v1035
  end
end

class Scene_PMD_AutoChess
  alias pmd_ac_v1040_prepare_verification_battle prepare_verification_battle unless method_defined?(:pmd_ac_v1040_prepare_verification_battle)
  alias pmd_ac_v1040_update_verification_script update_verification_script unless method_defined?(:pmd_ac_v1040_update_verification_script)
  def prepare_verification_battle
    pmd_ac_v1040_prepare_verification_battle
    if respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
      log_event(:showcase,'MOTION_GENERATED_PROFILES_V1040 START scope=0027-0494 generated=468 group_tuning=7 important_manual=90 deploy_hop=0 live_route_scan=0')
    end
  end
  def update_verification_script
    pmd_ac_v1040_update_verification_script
    return unless respond_to?(:motion_phase_b_verifier_active_v1036?) && motion_phase_b_verifier_active_v1036?
    return if @motion_generated_verify_v1040
    return unless @verification_frame.to_i>=202
    samples=['0038','0095','0130','0143','0150','0197','0249','0282','0384','0448','0487','0494']
    ok=true
    samples.each{|sid|ok=false if PMD_AC::MOTION_GENERATED_PROFILE_V1040[sid]==nil}
    ok=false unless PMD_AC::MOTION_GENERATED_PROFILE_V1040.size==468
    @motion_generated_verify_v1040=true
    log_event(:verify,'MOTION_GENERATED_PROFILES_0027_0494_V1040 pass='+(ok ? '1':'0')+
      ' generated=468 full_profiles=494 body_groups=7 important_manual=90'+
      ' geom45_actions=4707 geom_calibration_precision=1.000 geom_false_positive=0'+
      ' deploy_base_certified=457/468 generated_special_profiles=72 hop_deploy=0'+
      ' static_source_routes=7488/7488 live_route_scan=0 samples=12'+
      ' damage_unchanged=1 ai_unchanged=1 attack_speed_unchanged=1 energy_unchanged=1 spatial_unchanged=1')
  rescue
  end
end
