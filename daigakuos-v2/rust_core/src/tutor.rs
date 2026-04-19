use serde::{Deserialize, Serialize};
use crate::state::{BioState, BehaviorMode};
use crate::proxy::UserActivityCategory;

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct EnforcementDirective {
    pub title: String,
    pub message: String,
    pub level: u8, // 0: None, 1: Gentle, 2: Warning, 3: Strict Lock
}

pub struct TutorEngine;

impl TutorEngine {
    pub fn audit(state: &mut BioState, activity: UserActivityCategory) -> EnforcementDirective {
        let cortisol = state.physiology.hormones.cortisol;
        let burden = state.infectious_burden;
        let is_enraged = state.behavior_mode == BehaviorMode::Enraged;
        
        // 🧪 1. Diagnostic Correlation
        if (cortisol > 0.8 || burden > 0.5) && activity == UserActivityCategory::SocialMedia {
            EnforcementDirective {
                title: "【強制警告】有害摂食の遮断".to_string(),
                message: "個体の神経ストレスが閾値を超えています。SNSの閲覧はドーパミンを過剰消費し、回復を阻害します。直ちに作業を停止し、安静を保ってください。".to_string(),
                level: 3,
            }
        } else if is_enraged && activity == UserActivityCategory::Entertainment {
             EnforcementDirective {
                title: "【指示】交感神経の抑制".to_string(),
                message: "個体が激高状態にあります。刺激的なエンターテインメントは避け、自律神経の安定に努めてください。".to_string(),
                level: 2,
            }
        } else if state.metabolism.atp_reserves < 0.2 {
            EnforcementDirective {
                title: "【通知】代謝不全".to_string(),
                message: "エネルギー残量が乏しいもこ。無理な作業は個体の死を招きます。".to_string(),
                level: 1,
            }
        } else {
            EnforcementDirective {
                title: "【安定】".to_string(),
                message: "シミュレーションは正常に継続中もこ。".to_string(),
                level: 0,
            }
        }
    }
}
