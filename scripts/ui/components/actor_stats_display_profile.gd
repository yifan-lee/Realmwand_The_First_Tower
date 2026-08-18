class_name ActorStatsDisplayProfile
extends RefCounted

enum FpDisplayMode {
	PROGRESS_BAR,
	RECOVERY_SPEED,
	HIDDEN,
}

enum AtbDisplayMode {
	HIDDEN,
	BAR,
	EXTERNAL,
}

var fp_display_mode: FpDisplayMode = FpDisplayMode.PROGRESS_BAR
var atb_display_mode: AtbDisplayMode = AtbDisplayMode.HIDDEN
var show_portrait: bool = true
var show_name: bool = true
var show_description: bool = true
var show_progression: bool = true
var show_buffs: bool = true
var show_cp: bool = false
var obey_feature_unlocks: bool = true


static func hud() -> ActorStatsDisplayProfile:
	var profile := ActorStatsDisplayProfile.new()
	profile.fp_display_mode = FpDisplayMode.RECOVERY_SPEED
	profile.atb_display_mode = AtbDisplayMode.HIDDEN
	profile.show_progression = true
	profile.show_buffs = true
	profile.show_cp = false
	profile.obey_feature_unlocks = true
	return profile


static func menu() -> ActorStatsDisplayProfile:
	var profile := ActorStatsDisplayProfile.new()
	profile.fp_display_mode = FpDisplayMode.RECOVERY_SPEED
	profile.atb_display_mode = AtbDisplayMode.HIDDEN
	profile.show_progression = true
	profile.show_buffs = true
	profile.show_cp = false
	profile.obey_feature_unlocks = true
	return profile


static func battle_player() -> ActorStatsDisplayProfile:
	var profile := ActorStatsDisplayProfile.new()
	profile.fp_display_mode = FpDisplayMode.PROGRESS_BAR
	profile.atb_display_mode = AtbDisplayMode.EXTERNAL
	profile.show_progression = true
	profile.show_buffs = true
	profile.show_cp = false
	profile.obey_feature_unlocks = true
	return profile


static func battle_enemy() -> ActorStatsDisplayProfile:
	var profile := ActorStatsDisplayProfile.new()
	profile.fp_display_mode = FpDisplayMode.PROGRESS_BAR
	profile.atb_display_mode = AtbDisplayMode.EXTERNAL
	profile.show_progression = false
	profile.show_buffs = false
	profile.show_cp = true
	profile.obey_feature_unlocks = true
	return profile


static func progression() -> ActorStatsDisplayProfile:
	var profile := ActorStatsDisplayProfile.new()
	profile.fp_display_mode = FpDisplayMode.RECOVERY_SPEED
	profile.atb_display_mode = AtbDisplayMode.HIDDEN
	profile.show_progression = true
	profile.show_buffs = false
	profile.show_cp = false
	profile.obey_feature_unlocks = true
	return profile
