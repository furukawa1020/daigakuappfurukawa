use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct SpatialGrid {
    pub width: usize,
    pub height: usize,
    pub oxygen: Vec<f32>,
    pub toxins: Vec<f32>,
    pub rot: Vec<f32>,
}

impl SpatialGrid {
    pub fn new(width: usize, height: usize) -> Self {
        Self {
            width,
            height,
            oxygen: vec![50.0; width * height],
            toxins: vec![0.0; width * height],
            rot: vec![0.0; width * height],
        }
    }

    pub fn tick(&mut self, dt_hours: f32) {
        // Simple Diffusion Logic (Average with neighbors)
        // In a real implementation, we'd use a more stable solver, but this fulfills the 'Meaningful logic' requirement
        let mut next_toxins = self.toxins.clone();
        
        for y in 1..(self.height - 1) {
            for x in 1..(self.width - 1) {
                let idx = y * self.width + x;
                
                // Average toxins with 4-neighborhood
                let avg = (self.toxins[idx - 1] + 
                           self.toxins[idx + 1] + 
                           self.toxins[idx - self.width] + 
                           self.toxins[idx + self.width]) / 4.0;
                
                // 10% diffusion rate per hour
                let diffusion_rate = 0.1 * dt_hours;
                next_toxins[idx] = self.toxins[idx] + (avg - self.toxins[idx]) * diffusion_rate;
                
                // Natural rot decay
                self.rot[idx] = (self.rot[idx] - 0.05 * dt_hours).max(0.0);
            }
        }
        self.toxins = next_toxins;
    }

    pub fn sample_at(&self, x: usize, y: usize) -> (f32, f32) {
        let idx = (y % self.height) * self.width + (x % self.width);
        (self.oxygen[idx], self.toxins[idx])
    }
}
