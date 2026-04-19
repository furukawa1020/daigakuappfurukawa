use serde::{Deserialize, Serialize};
use windows_sys::Win32::UI::WindowsAndMessaging::{GetForegroundWindow, GetWindowTextW};

#[derive(Serialize, Deserialize, Debug, Clone, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum UserActivityCategory {
    Work,
    SocialMedia,
    Entertainment,
    Idle,
    Unknown,
}

pub struct ProxyKernel;

impl ProxyKernel {
    pub fn get_active_window_category() -> UserActivityCategory {
        #[cfg(windows)]
        unsafe {
            let hwnd = GetForegroundWindow();
            if hwnd == 0 {
                return UserActivityCategory::Idle;
            }

            let mut buffer = [0u16; 512];
            let length = GetWindowTextW(hwnd, buffer.as_mut_ptr(), 512);
            
            if length == 0 {
                return UserActivityCategory::Unknown;
            }

            let title = String::from_utf16_lossy(&buffer[..length as usize]);
            Self::categorize_title(&title)
        }

        #[cfg(not(windows))]
        {
            UserActivityCategory::Unknown
        }
    }

    fn categorize_title(title: &str) -> UserActivityCategory {
        let t = title.to_lowercase();
        if t.contains("visual studio code") || t.contains("latex") || t.contains("rust") || t.contains("github") {
            UserActivityCategory::Work
        } else if t.contains("youtube") || t.contains("netflix") || t.contains("twitch") {
            UserActivityCategory::Entertainment
        } else if t.contains("twitter") || t.contains("facebook") || t.contains("discord") || t.contains("x") {
            UserActivityCategory::SocialMedia
        } else {
            UserActivityCategory::Unknown
        }
    }
}
