use serde::{Deserialize, Serialize};

/// 2D spatial grid for ecological diffusion (oxygen, toxins, rot).
/// Stored flat (row-major): index = y * width + x
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct SpatialGrid {
    pub width: usize,
    pub height: usize,
    pub oxygen: Vec<f32>,
    pub toxins: Vec<f32>,
    pub rot: Vec<f32>,
}

impl SpatialGrid {
    pub fn new(w: usize, h: usize) -> Self {
        let n = w * h;
        Self {
            width: w,
            height: h,
            oxygen: vec![50.0; n],
            toxins: vec![0.0; n],
            rot: vec![0.0; n],
        }
    }

    pub fn tick(&mut self, dt_hours: f32) {
        let (w, h) = (self.width, self.height);
        let n = w * h;

        let mut new_o2  = self.oxygen.clone();
        let mut new_tox = self.toxins.clone();
        let mut new_rot = self.rot.clone();

        for y in 0..h {
            for x in 0..w {
                let idx = y * w + x;
                let neighbors = self.neighbor_indices(x, y, w, h);

                // ── diffusion: average with neighbors ──────────────
                let n_count = neighbors.len() as f32;
                let o2_sum: f32  = neighbors.iter().map(|&i| self.oxygen[i]).sum();
                let tox_sum: f32 = neighbors.iter().map(|&i| self.toxins[i]).sum();

                let diff_rate = 0.1 * dt_hours;
                new_o2[idx]  += (o2_sum  / n_count - self.oxygen[idx]) * diff_rate;
                new_tox[idx] += (tox_sum / n_count - self.toxins[idx]) * diff_rate;

                // ── rot advances from toxins ───────────────────────
                new_rot[idx] = (new_rot[idx] + self.toxins[idx] * 0.005 * dt_hours).min(1.0);

                // ── oxygen consumed by rot ─────────────────────────
                new_o2[idx] = (new_o2[idx] - new_rot[idx] * 0.01 * dt_hours).max(0.0);

                // ── clamp ──────────────────────────────────────────
                new_o2[idx]  = new_o2[idx].clamp(0.0, 100.0);
                new_tox[idx] = new_tox[idx].clamp(0.0, 100.0);
            }
        }

        self.oxygen = new_o2;
        self.toxins = new_tox;
        self.rot    = new_rot;
    }

    pub fn sample_at(&self, x: usize, y: usize) -> (f32, f32) {
        let idx = (y.min(self.height - 1)) * self.width + (x.min(self.width - 1));
        (self.oxygen[idx], self.toxins[idx])
    }

    fn neighbor_indices(&self, x: usize, y: usize, w: usize, h: usize) -> Vec<usize> {
        let mut out = Vec::with_capacity(4);
        if x > 0      { out.push(y * w + (x - 1)); }
        if x + 1 < w  { out.push(y * w + (x + 1)); }
        if y > 0      { out.push((y - 1) * w + x); }
        if y + 1 < h  { out.push((y + 1) * w + x); }
        out
    }
}
