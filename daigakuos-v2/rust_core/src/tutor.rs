use windows_sys::Win32::System::SystemServices::LockWorkStation;

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct EnforcementDirective {
    pub title: String,
    pub message: String,
    pub level: u8, // 0: None, 1: Gentle, 2: Warning, 3: Strict Lock
}

pub struct TutorEngine;

impl TutorEngine {
    pub fn audit(state: &mut BioState, activity: UserActivityCategory) -> EnforcementDirective {
        let cortisol = state.physiology.hormones.adrenaline; // Use adrenaline surge as trigger
        let stress = state.physiology.organ_stress.get("neural").unwrap_or(&0.0);
        
        // 🧪 1. Diagnostic Correlation (Enhanced for PID proxy)
        if (*stress > 0.7 || cortisol > 0.8) && activity == UserActivityCategory::SocialMedia {
            EnforcementDirective {
                title: "【強制執行】極度の神経負荷検知".to_string(),
                message: "個体が激高状態にあり、SNSの閲覧が負荷を悪化させています。システム保護のためロックダウンを開始しもこ。".to_string(),
                level: 3,
            }
        } else if activity == UserActivityCategory::Entertainment && *stress > 0.5 {
             EnforcementDirective {
                title: "【指示】鎮静化優先".to_string(),
                message: "個体のストレス値が上昇中。娱乐アプリの終了を推奨しもこ。".to_string(),
                level: 2,
            }
        } else {
            EnforcementDirective {
                title: "【安定】".to_string(),
                message: "個体は安定しているもこ。".to_string(),
                level: 0,
            }
        }
    }

    pub fn execute_directive(directive: &EnforcementDirective) {
        #[cfg(windows)]
        unsafe {
            if directive.level >= 3 {
                // 🔐 Hard Lock: Lock the workstation
                LockWorkStation();
            }
        }
    }
}
