#==============================================================================
# 【PMD AutoChess 中文維護說明】
# 腳本：PMD AutoChess Skill Visual Data v0.30
# 分類：技能視覺
#
# 【用途／機制】
# 定義技能 Beam／Projectile／Impact 等映射與特效資產。
#
# 【怎麼調整】
# 新增視覺時先建立資料映射，再讓 Runtime 讀取；Projectile 與 Target FX 的 anchor 規則不要混用。
#
# 【本腳本主要設定常數／資料表】
# - SKILL_VISUAL_MANIFEST_V030 / SKILL_VISUAL_BEAM_V030 / SKILL_VISUAL_PROJECTILE_V030 / SKILL_VISUAL_IMPACT_V030
# - SKILL_VISUAL_MOVE_V030
#
# 【維護規則】
# - RPG Maker VX / RGSS2 / Ruby 1.8 相容。
# - instance_uid 才是 Pokémon 個體身份；Actor ID 只是容器。
# - 新增行為優先沿用既有 helper／Data 表；避免破壞已 Freeze 的舊核心。
# - 本專案新腳本也必須保留同等級的中文說明與實際範例。
#==============================================================================
#==============================================================================
# ■ PMD AutoChess Skill Visual Data v0.30 - GENERATED
#==============================================================================
module PMD_AC
  SKILL_VISUAL_MANIFEST_V030 = {:schema_version=>"1.0",:content_version=>"0.30.0",:source=>"user_supplied_pokemon_ranger3_attack_effects",:beam_profile_count=>4,:projectile_profile_count=>4,:impact_profile_count=>5,:mapped_move_visual_count=>10,:asset_count=>13,:runtime_checksum32=>1661535670,:principles=>["beam_head_body_tail","element_motion_profiles","animated_projectiles","projectile_trails","target_centered_hit","cache_safe_rgss2"]}
  SKILL_VISUAL_BEAM_V030 = {:electric=>{:body=>"Ranger_098",:sheet_w=>136,:frame_h=>40,:frames=>7,:frame_wait=>2,:body_src_x=>0,:body_src_w=>136,:thickness=>0.52,:motion=>:jitter,:blend=>1},:fire=>{:body=>"Ranger_107",:sheet_w=>136,:frame_h=>40,:frames=>4,:frame_wait=>2,:body_src_x=>0,:body_src_w=>136,:thickness=>0.62,:motion=>:burn,:blend=>1},:water=>{:body=>"Ranger_105",:sheet_w=>136,:frame_h=>40,:frames=>4,:frame_wait=>3,:body_src_x=>0,:body_src_w=>136,:thickness=>0.62,:motion=>:flow,:blend=>0,:head=>"Ranger_109",:head_sheet_w=>136,:head_frame_h=>40,:head_frames=>4,:head_src_x=>68,:head_src_w=>68,:head_display_w=>42,:head_zoom_y=>0.7},:ice=>{:body=>"Ranger_102",:sheet_w=>136,:frame_h=>40,:frames=>4,:frame_wait=>3,:body_src_x=>0,:body_src_w=>136,:thickness=>0.54,:motion=>:crystal,:blend=>1}}
  SKILL_VISUAL_PROJECTILE_V030 = {:electric=>{:sheet=>"Ranger_097",:frame_w=>72,:frame_h=>72,:frames=>4,:frame_wait=>3,:display_w=>34,:display_h=>34,:trail=>true,:blend=>1},:fire=>{:sheet=>"Ranger_174",:frame_w=>72,:frame_h=>72,:frames=>4,:frame_wait=>3,:display_w=>38,:display_h=>38,:trail=>true,:blend=>1},:water=>{:sheet=>"Ranger_160",:frame_w=>45,:frame_h=>40,:frames=>4,:frame_wait=>3,:display_w=>32,:display_h=>30,:trail=>true,:blend=>0},:seed=>{:sheet=>"Ranger_173",:frame_w=>72,:frame_h=>72,:frames=>3,:frame_wait=>4,:display_w=>30,:display_h=>30,:trail=>true,:blend=>0}}
  SKILL_VISUAL_IMPACT_V030 = {:electric=>{:sheet=>"Ranger_090",:frame_w=>72,:frame_h=>64,:frames=>5,:frame_wait=>3,:zoom=>0.72,:blend=>1},:fire=>{:sheet=>"Ranger_222",:frame_w=>48,:frame_h=>48,:frames=>4,:frame_wait=>3,:zoom=>0.9,:blend=>1},:water=>{:sheet=>"Ranger_160",:frame_w=>45,:frame_h=>40,:frames=>4,:frame_wait=>3,:zoom=>1.05,:blend=>0},:ice=>{:sheet=>"Ranger_221",:frame_w=>40,:frame_h=>40,:frames=>4,:frame_wait=>3,:zoom=>1.05,:blend=>1},:sound=>{:sheet=>"Ranger_190",:frame_w=>72,:frame_h=>72,:frames=>4,:frame_wait=>3,:zoom=>0.82,:blend=>1}}
  SKILL_VISUAL_MOVE_V030 = {:flamethrower=>{:visual_kind=>:beam,:style=>:fire},:hydro_pump=>{:visual_kind=>:beam,:style=>:water},:ice_beam=>{:visual_kind=>:beam,:style=>:ice},:thunderbolt=>{:visual_kind=>:beam,:style=>:electric},:ember=>{:visual_kind=>:projectile,:style=>:fire},:thunder_shock=>{:visual_kind=>:projectile,:style=>:electric},:bubble_beam=>{:visual_kind=>:projectile,:style=>:water},:cotton_spore=>{:visual_kind=>:projectile,:style=>:seed},:stun_spore=>{:visual_kind=>:projectile,:style=>:seed},:screech=>{:visual_kind=>:target_hit,:style=>:sound}}
end
