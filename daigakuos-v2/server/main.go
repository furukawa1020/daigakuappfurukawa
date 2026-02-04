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

// Node represents a task/project
type Node struct {
	ID        string    `json:"id"`
	Title     string    `json:"title"`
	UpdatedAt time.Time `json:"updatedAt"`
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

		today := time.Now().Format("2006-01-02")

		rows, err := db.Query("SELECT points, minutes FROM sessions WHERE date(start_at) = ?", today)
		if err != nil {
			http.Error(w, "Query failed: "+err.Error(), http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		agg := DailyAgg{
			Date: today,
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

	// GET /api/aggs/weekly - Last 7 Days
	http.HandleFunc("/api/aggs/weekly", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		rows, err := db.Query(`
			SELECT date(start_at) as day, sum(points), sum(minutes) 
			FROM sessions 
			WHERE start_at >= date('now', '-7 days')
			GROUP BY day
			ORDER BY day ASC
		`)
		if err != nil {
			http.Error(w, "Query failed: "+err.Error(), http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		type DayStat struct {
			Day     string  `json:"day"`
			Points  float64 `json:"points"`
			Minutes int     `json:"minutes"`
		}
		stats := []DayStat{}

		for rows.Next() {
			var s DayStat
			if err := rows.Scan(&s.Day, &s.Points, &s.Minutes); err == nil {
				stats = append(stats, s)
			}
		}
		json.NewEncoder(w).Encode(stats)
	})

	// GET /api/nodes/suggestions - Get Recent Nodes (Context Aware)
	http.HandleFunc("/api/nodes/suggestions", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		// MVP Context Logic:
		// If OnCampus, we could prioritize nodes used OnCampus? (Needs schema change to track context in sessions)
		// For now, let's just return recent nodes.
		// Future: JOIN sessions s ON s.node_id = n.id WHERE s.context = 'CAMPUS' ...

		rows, err := db.Query("SELECT id, title FROM nodes ORDER BY updated_at DESC LIMIT 5")
		if err != nil {
			http.Error(w, "Query failed", http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		nodes := []Node{}
		for rows.Next() {
			var n Node
			if err := rows.Scan(&n.ID, &n.Title); err == nil {
				nodes = append(nodes, n)
			}
		}
		json.NewEncoder(w).Encode(nodes)
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
