import Foundation

/// Convenience extension for localized strings
extension String {
    /// Returns a localized version of the string
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    /// Returns a localized version with format arguments
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}

/// Centralized string keys for type-safe localization
enum L10n {
    // MARK: - App
    static var appName: String { "app_name".localized }
    static var appTagline: String { "app_tagline".localized }
    
    // MARK: - Navigation
    static var navPlay: String { "nav_play".localized }
    static var navStats: String { "nav_stats".localized }
    static var navFriends: String { "nav_friends".localized }
    static var navSettings: String { "nav_settings".localized }
    
    // MARK: - Game Screen
    static var gameTitle: String { "game_title".localized }
    static var gameDailyPuzzle: String { "game_daily_puzzle".localized }
    static var gamePathLength: String { "game_path_length".localized }
    static var gameOptimal: String { "game_optimal".localized }
    static var gameScore: String { "game_score".localized }
    static var gameCalculating: String { "game_calculating".localized }
    static func gameValidMoves(_ count: Int) -> String { "game_valid_moves".localized(with: count) }
    static var gameNoValidMoves: String { "game_no_valid_moves".localized }
    
    // MARK: - Game Actions
    static var actionUndo: String { "action_undo".localized }
    static var actionRestart: String { "action_restart".localized }
    static var actionFinish: String { "action_finish".localized }
    static var actionShare: String { "action_share".localized }
    static var actionGiveUp: String { "action_give_up".localized }
    
    // MARK: - Results
    static var resultPerfect: String { "result_perfect".localized }
    static var resultAmazing: String { "result_amazing".localized }
    static var resultGreat: String { "result_great".localized }
    static var resultGood: String { "result_good".localized }
    static var resultComplete: String { "result_complete".localized }
    static var resultYourPath: String { "result_your_path".localized }
    static var resultOptimalPath: String { "result_optimal_path".localized }
    static func resultTryOtherSize(_ size: String) -> String { "result_try_other_size".localized(with: size) }
    static var resultClose: String { "result_close".localized }
    
    // MARK: - Result Subtitles
    static var resultSubtitlePerfect: String { "result_subtitle_perfect".localized }
    static var resultSubtitleAmazing: String { "result_subtitle_amazing".localized }
    static var resultSubtitleGreat: String { "result_subtitle_great".localized }
    static var resultSubtitleDefault: String { "result_subtitle_default".localized }
    
    // MARK: - Stats Screen
    static var statsTitle: String { "stats_title".localized }
    static var statsOverview: String { "stats_overview".localized }
    static var statsAchievements: String { "stats_achievements".localized }
    static var statsHistory: String { "stats_history".localized }
    static var statsGamesPlayed: String { "stats_games_played".localized }
    static var statsPerfectGames: String { "stats_perfect_games".localized }
    static var statsCurrentStreak: String { "stats_current_streak".localized }
    static var statsBestStreak: String { "stats_best_streak".localized }
    static var statsAverageScore: String { "stats_average_score".localized }
    static var statsPerfectRate: String { "stats_perfect_rate".localized }
    static var statsNoGames: String { "stats_no_games".localized }
    static var statsStartPlaying: String { "stats_start_playing".localized }
    static var stats5x5Stats: String { "stats_5x5_stats".localized }
    static var stats7x7Stats: String { "stats_7x7_stats".localized }
    static var statsGames: String { "stats_games".localized }
    static var statsPerfect: String { "stats_perfect".localized }
    static var statsAvg: String { "stats_avg".localized }
    static var statsDistribution: String { "stats_distribution".localized }
    static var statsScoreDistribution: String { "stats_score_distribution".localized }
    static var statsGamesDistribution: String { "stats_games_distribution".localized }
    static var statsAchievementProgress: String { "stats_achievement_progress".localized }
    static var statsAll: String { "stats_all".localized }
    static var statsNoHistory: String { "stats_no_history".localized }
    static var statsCompleteToSeeHistory: String { "stats_complete_to_see_history".localized }
    static var gameSize5x5: String { "game_size_5x5".localized }
    static var gameSize7x7: String { "game_size_7x7".localized }
    
    // MARK: - Friends Screen
    static var friendsTitle: String { "friends_title".localized }
    static var friendsActivity: String { "friends_activity".localized }
    static var friendsChallenges: String { "friends_challenges".localized }
    static var friendsTodayLeaderboard: String { "friends_today_leaderboard".localized }
    static var friendsAllFriends: String { "friends_all_friends".localized }
    static var friendsNoFriends: String { "friends_no_friends".localized }
    static var friendsAddFriendsDesc: String { "friends_add_friends_desc".localized }
    static var friendsAddFriends: String { "friends_add_friends".localized }
    static var friendsNoRecentGames: String { "friends_no_recent_games".localized }
    static var friendsChallenge: String { "friends_challenge".localized }
    static var friendsRemove: String { "friends_remove".localized }
    static var friendsNoActivity: String { "friends_no_activity".localized }
    static var friendsNoChallenges: String { "friends_no_challenges".localized }
    static var friendsChallengeDesc: String { "friends_challenge_desc".localized }
    static func friendsChallengedYou(_ name: String) -> String { "friends_challenged_you".localized(with: name) }
    static func friendsTheirScore(_ score: Int, _ optimal: Int) -> String { "friends_their_score".localized(with: score, optimal) }
    static var friendsAccept: String { "friends_accept".localized }
    static var friendsDecline: String { "friends_decline".localized }
    static var friendsGameCenterPrompt: String { "friends_game_center_prompt".localized }
    static var friendsGameCenterDesc: String { "friends_game_center_desc".localized }
    static var friendsSignIn: String { "friends_sign_in".localized }
    static var friendsOpenGameCenter: String { "friends_open_game_center".localized }
    static var friendsFromGameCenter: String { "friends_from_game_center".localized }
    
    // MARK: - Settings Screen
    static var settingsTitle: String { "settings_title".localized }
    static var settingsGame: String { "settings_game".localized }
    static var settingsDefaultGrid: String { "settings_default_grid".localized }
    static var settingsShowOptimal: String { "settings_show_optimal".localized }
    static var settingsShowOptimalDesc: String { "settings_show_optimal_desc".localized }
    static var settingsFeedback: String { "settings_feedback".localized }
    static var settingsHaptic: String { "settings_haptic".localized }
    static var settingsHapticDesc: String { "settings_haptic_desc".localized }
    static var settingsSound: String { "settings_sound".localized }
    static var settingsSoundDesc: String { "settings_sound_desc".localized }
    static var settingsNotifications: String { "settings_notifications".localized }
    static var settingsDailyReminder: String { "settings_daily_reminder".localized }
    static var settingsDailyReminderDesc: String { "settings_daily_reminder_desc".localized }
    static var settingsReminderTime: String { "settings_reminder_time".localized }
    static var settingsAppearance: String { "settings_appearance".localized }
    static var settingsTheme: String { "settings_theme".localized }
    static var settingsThemeSystem: String { "settings_theme_system".localized }
    static var settingsThemeLight: String { "settings_theme_light".localized }
    static var settingsThemeDark: String { "settings_theme_dark".localized }
    static var settingsHighContrast: String { "settings_high_contrast".localized }
    static var settingsHighContrastDesc: String { "settings_high_contrast_desc".localized }
    static var settingsData: String { "settings_data".localized }
    static var settingsSyncNow: String { "settings_sync_now".localized }
    static var settingsResetStats: String { "settings_reset_stats".localized }
    static var settingsResetStatsDesc: String { "settings_reset_stats_desc".localized }
    static var settingsAbout: String { "settings_about".localized }
    static var settingsHowToPlay: String { "settings_how_to_play".localized }
    static var settingsAboutPath: String { "settings_about_path".localized }
    static var settingsVisitWebsite: String { "settings_visit_website".localized }
    static func settingsVersion(_ version: String) -> String { "settings_version".localized(with: version) }
    static var settingsGameCenter: String { "settings_game_center".localized }
    static func settingsSignedIn(_ name: String) -> String { "settings_signed_in".localized(with: name) }
    static var settingsNotSignedIn: String { "settings_not_signed_in".localized }
    static var settingsGameCenterDashboard: String { "settings_game_center_dashboard".localized }
    
    // MARK: - Reset Alert
    static var resetTitle: String { "reset_title".localized }
    static var resetMessage: String { "reset_message".localized }
    static var resetCancel: String { "reset_cancel".localized }
    static var resetConfirm: String { "reset_confirm".localized }
    
    // MARK: - Tutorial / Help
    static var helpTitle: String { "help_title".localized }
    static var helpDone: String { "help_done".localized }
    static var helpPage1Title: String { "help_page1_title".localized }
    static var helpPage1Desc: String { "help_page1_desc".localized }
    static var helpPage1Detail1: String { "help_page1_detail1".localized }
    static var helpPage1Detail2: String { "help_page1_detail2".localized }
    static var helpPage1Detail3: String { "help_page1_detail3".localized }
    static var helpPage2Title: String { "help_page2_title".localized }
    static var helpPage2Desc: String { "help_page2_desc".localized }
    static var helpPage2Detail1: String { "help_page2_detail1".localized }
    static var helpPage2Detail2: String { "help_page2_detail2".localized }
    static var helpPage2Detail3: String { "help_page2_detail3".localized }
    static var helpPage3Title: String { "help_page3_title".localized }
    static var helpPage3Desc: String { "help_page3_desc".localized }
    static var helpPage3Detail1: String { "help_page3_detail1".localized }
    static var helpPage3Detail2: String { "help_page3_detail2".localized }
    static var helpPage3Detail3: String { "help_page3_detail3".localized }
    static var helpPage4Title: String { "help_page4_title".localized }
    static var helpPage4Desc: String { "help_page4_desc".localized }
    static var helpPage4Detail1: String { "help_page4_detail1".localized }
    static var helpPage4Detail2: String { "help_page4_detail2".localized }
    static var helpPage4Detail3: String { "help_page4_detail3".localized }
    static var helpReadyTitle: String { "help_ready_title".localized }
    static var helpReadyDesc: String { "help_ready_desc".localized }
    static var helpStartPlaying: String { "help_start_playing".localized }
    
    // MARK: - Onboarding
    static var onboardingWelcome: String { "onboarding_welcome".localized }
    static var onboardingWelcomeDesc: String { "onboarding_welcome_desc".localized }
    static var onboardingFindWay: String { "onboarding_find_way".localized }
    static var onboardingFindWayDesc: String { "onboarding_find_way_desc".localized }
    static var onboardingChallenge: String { "onboarding_challenge".localized }
    static var onboardingChallengeDesc: String { "onboarding_challenge_desc".localized }
    static var onboardingBegin: String { "onboarding_begin".localized }
    static var onboardingReady: String { "onboarding_ready".localized }
    static var onboardingPlayNow: String { "onboarding_play_now".localized }
    static var onboardingNext: String { "onboarding_next".localized }
    static var onboardingSkip: String { "onboarding_skip".localized }
    static var onboardingGetStarted: String { "onboarding_get_started".localized }
    
    // MARK: - Leaderboard
    static var leaderboardTitle: String { "leaderboard_title".localized }
    static var leaderboard5x5Best: String { "leaderboard_5x5_best".localized }
    static var leaderboard7x7Best: String { "leaderboard_7x7_best".localized }
    static var leaderboardStreak: String { "leaderboard_streak".localized }
    static var leaderboardPerfects: String { "leaderboard_perfects".localized }
    static var leaderboardToday: String { "leaderboard_today".localized }
    static var leaderboardWeek: String { "leaderboard_week".localized }
    static var leaderboardAllTime: String { "leaderboard_all_time".localized }
    static var leaderboardYourRank: String { "leaderboard_your_rank".localized }
    static var leaderboardNoEntries: String { "leaderboard_no_entries".localized }
    static var leaderboardBeFirst: String { "leaderboard_be_first".localized }
    static var leaderboardSignInPrompt: String { "leaderboard_sign_in_prompt".localized }
    static var leaderboardYou: String { "leaderboard_you".localized }
    
    // MARK: - About
    static var aboutTitle: String { "about_title".localized }
    static var aboutCreatedBy: String { "about_created_by".localized }
    static var aboutBuiltWith: String { "about_built_with".localized }
    static var aboutWebsite: String { "about_website".localized }
    
    // MARK: - Share
    static func shareTitle(_ date: String) -> String { "share_title".localized(with: date) }
    static var sharePlayAt: String { "share_play_at".localized }
    
    // MARK: - Tooltips / Walkthrough
    static var tooltipUndo: String { "tooltip_undo".localized }
    static var tooltipRestart: String { "tooltip_restart".localized }
    static var tooltipFinish: String { "tooltip_finish".localized }
    static var tooltipShare: String { "tooltip_share".localized }
    static var tooltipGridToggle: String { "tooltip_grid_toggle".localized }
    static var tooltipHelp: String { "tooltip_help".localized }
    static var tooltipSettings: String { "tooltip_settings".localized }
    
    // MARK: - Grid Legend
    static var legendCurrent: String { "legend_current".localized }
    static var legendValid: String { "legend_valid".localized }
    static var legendVisited: String { "legend_visited".localized }
    static var legendStart: String { "legend_start".localized }
    
    // MARK: - Help Example
    static var helpExampleCurrent: String { "help_example_current".localized }
    static var helpLegendCurrent: String { "help_legend_current".localized }
    static var helpLegendValid: String { "help_legend_valid".localized }
    
    // MARK: - Accessibility
    static func a11yCellValue(_ value: Int) -> String { "a11y_cell_value".localized(with: value) }
    static func a11yCellCurrent(_ value: Int) -> String { "a11y_cell_current".localized(with: value) }
    static func a11yCellValid(_ value: Int) -> String { "a11y_cell_valid".localized(with: value) }
    static func a11yCellVisited(_ value: Int) -> String { "a11y_cell_visited".localized(with: value) }
    static var a11yUndoButton: String { "a11y_undo_button".localized }
    static var a11yRestartButton: String { "a11y_restart_button".localized }
    static var a11yFinishButton: String { "a11y_finish_button".localized }
    static var a11yShareButton: String { "a11y_share_button".localized }
    
    // MARK: - Give Up Dialog
    static var giveUpTitle: String { "give_up_title".localized }
    static var giveUpMessage: String { "give_up_message".localized }
    static var giveUpConfirm: String { "give_up_confirm".localized }
    static var giveUpCancel: String { "give_up_cancel".localized }
    
    // MARK: - Unlock Modal
    static var unlockCongrats: String { "unlock_congrats".localized }
    static var unlockMastered5x5: String { "unlock_mastered_5x5".localized }
    static var unlockShareResults: String { "unlock_share_results".localized }
    static var unlockNotNow: String { "unlock_not_now".localized }
    static var unlockLetsGo: String { "unlock_lets_go".localized }
    
    // MARK: - Archive Modal
    static var archiveCompletedToday: String { "archive_completed_today".localized }
    static var archiveTitle: String { "archive_title".localized }
    static var archiveClose: String { "archive_close".localized }
}
