package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	_ "modernc.org/sqlite"
)

// Session represents a work session
type Session struct {
	ID         string    `json:"id"`
	DraftTitle string    `json:"draftTitle"`
	StartAt    time.Time `json:"startAt"`
	Minutes    int       `json:"minutes"`
	Points     float64   `json:"points"`
	Focus      int       `json:"focus"`
}

// DailyAgg represents daily statistics
type DailyAgg struct {
	Date         string  `json:"date"` // YYYY-MM-DD
	TotalPoints  float64 `json:"totalPoints"`
	TotalMinutes int     `json:"totalMinutes"`
	SessionCount int     `json:"sessionCount"`
}

var db *sql.DB

func initDB() {
	var err error
	db, err = sql.Open("sqlite", "daigakuos.db")
	if err != nil {
		log.Fatal(err)
	}

	// Create Tables
	schema := `
	CREATE TABLE IF NOT EXISTS sessions (
		id TEXT PRIMARY KEY,
		draft_title TEXT,
		start_at DATETIME,
		minutes INTEGER,
		points REAL,
		focus INTEGER
	);
	`
	_, err = db.Exec(schema)
	if err != nil {
		log.Fatal("Failed to create schema:", err)
	}
	fmt.Println("Database initialized.")
}

func main() {
	initDB()
	fmt.Println("DaigakuOS v2 Server Starting on :8080...")

	http.HandleFunc("/api/health", func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
	})

	// POST /api/sessions - Save Session
	http.HandleFunc("/api/sessions", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}
		var s Session
		// Basic ID generation if missing (real app should use UUID lib)
		if err := json.NewDecoder(r.Body).Decode(&s); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}
		if s.ID == "" {
			s.ID = fmt.Sprintf("%d", time.Now().UnixNano())
		}

		_, err := db.Exec(
			"INSERT INTO sessions (id, draft_title, start_at, minutes, points, focus) VALUES (?, ?, ?, ?, ?, ?)",
			s.ID, s.DraftTitle, s.StartAt, s.Minutes, s.Points, s.Focus,
		)
		if err != nil {
			http.Error(w, "Database save failed: "+err.Error(), http.StatusInternalServerError)
			return
		}

		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(map[string]string{"result": "saved", "id": s.ID})
	})

	// GET /api/aggs/daily - Get Stats for Today
	http.HandleFunc("/api/aggs/daily", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		// Query: Sum of total stats
		rows, err := db.Query("SELECT points, minutes FROM sessions")
		if err != nil {
			http.Error(w, "Query failed", http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		agg := DailyAgg{
			Date: time.Now().Format("2006-01-02"),
		}

		for rows.Next() {
			var p float64
			var m int
			if err := rows.Scan(&p, &m); err == nil {
				agg.TotalPoints += p
				agg.TotalMinutes += m
				agg.SessionCount++
			}
		}

		json.NewEncoder(w).Encode(agg)
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
