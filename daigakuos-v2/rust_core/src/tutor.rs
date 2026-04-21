use serde::{Deserialize, Serialize};
use crate::state::{BioState, BehaviorMode};

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct EnforcementDirective {
    pub title: String,
    pub message: String,
    pub level: u8,
}

use crate::proxy::UserActivityCategory;

pub struct TutorEngine;

impl TutorEngine {
    pub fn audit(state: &BioState, activity: UserActivityCategory) -> EnforcementDirective {
        let neural_stress = state.physiology.organ_stress
            .get("neural")
            .copied()
            .unwrap_or(0.0);
        let adrenaline = state.physiology.hormones.adrenaline;

        if (neural_stress > 0.7 || adrenaline > 0.8)
            && activity == UserActivityCategory::SocialMedia
        {
            EnforcementDirective {
                title: "【強制執行】極度の神経負荷検知".to_string(),
                message: "SNS閲覧が個体の神経崩壊を加速しています。ロックダウン開始。".to_string(),
                level: 3,
            }
        } else if activity == UserActivityCategory::Entertainment && neural_stress > 0.5 {
            EnforcementDirective {
                title: "【指示】鎮静化優先".to_string(),
                message: "ストレス値が上昇中。娯楽アプリの終了を推奨。".to_string(),
                level: 2,
            }
        } else {
            EnforcementDirective {
                title: "【安定】".to_string(),
                message: "シミュレーション正常継続中。".to_string(),
                level: 0,
            }
        }
    }

    pub fn execute_directive(directive: &EnforcementDirective) {
        #[cfg(windows)]
        unsafe {
            if directive.level >= 3 {
                windows_sys::Win32::System::SystemServices::LockWorkStation();
            }
        }
    }
}
