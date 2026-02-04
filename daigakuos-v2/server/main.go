package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"math"
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

type UserStats struct {
	TotalPoints   float64 `json:"totalPoints"`
	Level         int     `json:"level"`
	Progress      float64 `json:"progress"` // 0.0 - 1.0 within current level
	PointsToNext  float64 `json:"pointsToNext"`
	DailyPoints   float64 `json:"dailyPoints"`
	DailyMinutes  int     `json:"dailyMinutes"`
	CurrentStreak int     `json:"currentStreak"` // Consecutive days
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
	CREATE TABLE IF NOT EXISTS nodes (
		id TEXT PRIMARY KEY,
		title TEXT,
		updated_at DATETIME
	);
	CREATE TABLE IF NOT EXISTS sessions (
		id TEXT PRIMARY KEY,
		node_id TEXT,
		draft_title TEXT,
		start_at DATETIME,
		minutes INTEGER,
		points REAL,
		focus INTEGER,
		FOREIGN KEY(node_id) REFERENCES nodes(id)
	);
	`
	_, err = db.Exec(schema)
	if err != nil {
		log.Fatal("Failed to create schema:", err)
	}
	// Migration for existing DB (idempotent-ish)
	db.Exec("ALTER TABLE sessions ADD COLUMN node_id TEXT")

	fmt.Println("Database initialized.")
}

func enableCors(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, DELETE")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		log.Printf("Request: %s %s", r.Method, r.URL.Path)

		next(w, r)
	}
}

func main() {
	initDB()
	fmt.Println("DaigakuOS v2 Server Starting on :8080...")

	http.HandleFunc("/api/health", enableCors(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
	}))

	// POST /api/sessions - Save Session
	http.HandleFunc("/api/sessions", enableCors(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			w.Header().Set("Content-Type", "application/json")
			rows, err := db.Query("SELECT id, draft_title, start_at, minutes, points, focus FROM sessions ORDER BY start_at DESC LIMIT 20")
			if err != nil {
				json.NewEncoder(w).Encode([]Session{})
				return
			}
			defer rows.Close()

			sessions := []Session{}
			for rows.Next() {
				var s Session
				if err := rows.Scan(&s.ID, &s.DraftTitle, &s.StartAt, &s.Minutes, &s.Points, &s.Focus); err == nil {
					sessions = append(sessions, s)
				}
			}
			json.NewEncoder(w).Encode(sessions)
			return
		}

		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		type SessionRequest struct {
			Session
			NodeID string `json:"nodeId"`
		}

		var req SessionRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}

		s := req.Session
		// ID Gen
		if s.ID == "" {
			s.ID = fmt.Sprintf("%d", time.Now().UnixNano())
		}

		// Node Handling
		var finalNodeID sql.NullString

		if req.NodeID != "" {
			finalNodeID.String = req.NodeID
			finalNodeID.Valid = true
			// Update Node Timestamp
			db.Exec("UPDATE nodes SET updated_at = ? WHERE id = ?", time.Now(), req.NodeID)
		} else if s.DraftTitle != "" {
			// Auto-create/find node from Title
			var existingID string
			err := db.QueryRow("SELECT id FROM nodes WHERE title = ?", s.DraftTitle).Scan(&existingID)
			if err == nil {
				finalNodeID.String = existingID
				finalNodeID.Valid = true
				db.Exec("UPDATE nodes SET updated_at = ? WHERE id = ?", time.Now(), existingID)
			} else {
				// Create New Node
				newNodeID := fmt.Sprintf("node_%d", time.Now().UnixNano())
				_, err := db.Exec("INSERT INTO nodes (id, title, updated_at) VALUES (?, ?, ?)", newNodeID, s.DraftTitle, time.Now())
				if err == nil {
					finalNodeID.String = newNodeID
					finalNodeID.Valid = true
				}
			}
		}

		_, err := db.Exec(
			"INSERT INTO sessions (id, node_id, draft_title, start_at, minutes, points, focus) VALUES (?, ?, ?, ?, ?, ?, ?)",
			s.ID, finalNodeID, s.DraftTitle, s.StartAt, s.Minutes, s.Points, s.Focus,
		)
		if err != nil {
			log.Println("Save error:", err)
			http.Error(w, "Database save failed: "+err.Error(), http.StatusInternalServerError)
			return
		}

		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(map[string]string{"result": "saved", "id": s.ID})
	}))

	// GET /api/user/stats - Gamification Stats
	http.HandleFunc("/api/user/stats", enableCors(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		today := time.Now().Format("2006-01-02")
		stats := UserStats{}

		// 1. Lifetime Points
		db.QueryRow("SELECT COALESCE(SUM(points), 0) FROM sessions").Scan(&stats.TotalPoints)

		// 2. Daily Stats
		db.QueryRow("SELECT COALESCE(SUM(points), 0), COALESCE(SUM(minutes), 0) FROM sessions WHERE date(start_at) = ?", today).Scan(&stats.DailyPoints, &stats.DailyMinutes)

		// 3. Level Calc (Simple Sqrt Curve)
		// Level = sqrt(Points / 100)
		// 100 pts = Lvl 1
		// 400 pts = Lvl 2
		// 900 pts = Lvl 3
		// ...
		// XP for Level L = 100 * L^2

		// 3. Level Calc (Quadratic Curve)
		// Level 1 = 0-100 pts
		// Level 2 = 100-400 pts (300 xp gap)
		// Level 3 = 400-900 pts (500 xp gap)
		// Formula: Points = 100 * Level^2  => Level = Sqrt(Points/100)

		val := stats.TotalPoints / 100.0
		if val < 0 {
			val = 0
		}
		rawLevel := math.Sqrt(val)
		stats.Level = int(rawLevel) + 1 // Start at Lvl 1

		currentBase := 100.0 * float64(stats.Level-1) * float64(stats.Level-1)
		nextBase := 100.0 * float64(stats.Level) * float64(stats.Level)

		stats.PointsToNext = nextBase - stats.TotalPoints
		rangeSpan := nextBase - currentBase
		if rangeSpan > 0 {
			stats.Progress = (stats.TotalPoints - currentBase) / rangeSpan
		} else {
			stats.Progress = 1.0 // Maxed?
		}

		// 4. Streak Calculation
		// Get all distinct days with activity
		rows, err := db.Query(`
			SELECT DISTINCT date(start_at) as day 
			FROM sessions 
			WHERE start_at >= date('now', '-60 days')
			ORDER BY day DESC
		`)

		stats.CurrentStreak = 0
		if err == nil {
			defer rows.Close()

			var days []string
			for rows.Next() {
				var day string
				if err := rows.Scan(&day); err == nil {
					days = append(days, day)
				}
			}

			// Calculate streak from today backwards
			today := time.Now().Format("2006-01-02")
			if len(days) > 0 {
				// Check if today has activity
				if days[0] == today {
					stats.CurrentStreak = 1

					// Check consecutive days backwards
					for i := 1; i < len(days); i++ {
						expectedDate := time.Now().AddDate(0, 0, -i).Format("2006-01-02")
						if days[i] == expectedDate {
							stats.CurrentStreak++
						} else {
							break
						}
					}
				} else {
					// Check if yesterday had activity (grace period)
					yesterday := time.Now().AddDate(0, 0, -1).Format("2006-01-02")
					if days[0] == yesterday {
						stats.CurrentStreak = 1
						for i := 1; i < len(days); i++ {
							expectedDate := time.Now().AddDate(0, 0, -(i + 1)).Format("2006-01-02")
							if days[i] == expectedDate {
								stats.CurrentStreak++
							} else {
								break
							}
						}
					}
				}
			}
		}

		json.NewEncoder(w).Encode(stats)
	}))

	// GET /api/aggs/daily - Get Stats for Today
	http.HandleFunc("/api/aggs/daily", enableCors(func(w http.ResponseWriter, r *http.Request) {
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
	}))

	// GET /api/aggs/weekly - Last 7 Days
	http.HandleFunc("/api/aggs/weekly", enableCors(func(w http.ResponseWriter, r *http.Request) {
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
	}))

	// GET /api/nodes/suggestions - Get Recent Nodes (Smart: Time-of-Day Aware)
	http.HandleFunc("/api/nodes/suggestions", enableCors(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		// 1. Get Current Hour
		hour := time.Now().Hour()

		// 2. Query: Find nodes active +/- 2 hours from now, weighted by frequency
		// If SQLite doesn't have good time functions, we might stick to raw string matching for 'HH' or use a simpler approximation.
		// SQLite `strftime('%H', start_at)` works.

		query := `
			SELECT n.id, n.title, COUNT(s.id) as freq
			FROM sessions s
			JOIN nodes n ON s.node_id = n.id
			WHERE CAST(strftime('%H', s.start_at) AS INTEGER) BETWEEN ? AND ?
			GROUP BY n.id
			ORDER BY freq DESC
			LIMIT 5
		`

		// Range: e.g. 14 -> 12 to 16
		startH := hour - 2
		endH := hour + 2

		rows, err := db.Query(query, startH, endH)
		nodes := []Node{}

		// 3. Fallback / Fill with Recent if logic fails or returns few results
		if err == nil {
			defer rows.Close()
			for rows.Next() {
				var n Node
				var freq int
				if err := rows.Scan(&n.ID, &n.Title, &freq); err == nil {
					nodes = append(nodes, n)
				}
			}
		}

		// Always append "Recent" to fill up to 8 slots
		if len(nodes) < 8 {
			excludedIDs := ""
			args := []interface{}{}
			for i, n := range nodes {
				if i > 0 {
					excludedIDs += ","
				}
				excludedIDs += "?"
				args = append(args, n.ID)
			}

			recentQuery := "SELECT id, title FROM nodes "
			if len(nodes) > 0 {
				recentQuery += fmt.Sprintf("WHERE id NOT IN (%s) ", excludedIDs)
			}
			recentQuery += "ORDER BY updated_at DESC LIMIT ?"
			args = append(args, 8-len(nodes))

			rows2, err2 := db.Query(recentQuery, args...)
			if err2 == nil {
				defer rows2.Close()
				for rows2.Next() {
					var n Node
					if err := rows2.Scan(&n.ID, &n.Title); err == nil {
						nodes = append(nodes, n)
					}
				}
			}
		}

		json.NewEncoder(w).Encode(nodes)
	}))

	// PUT /api/sessions/{id} - Edit Session
	http.HandleFunc("/api/sessions/", enableCors(func(w http.ResponseWriter, r *http.Request) {
		// Extract ID
		id := r.URL.Path[len("/api/sessions/"):]

		if r.Method == http.MethodDelete {
			if id == "" {
				http.Error(w, "Missing ID", http.StatusBadRequest)
				return
			}
			_, err := db.Exec("DELETE FROM sessions WHERE id = ?", id)
			if err != nil {
				http.Error(w, "Delete failed", http.StatusInternalServerError)
				return
			}
			w.WriteHeader(http.StatusOK)
			return
		}

		if r.Method == http.MethodPut {
			if id == "" {
				http.Error(w, "Missing ID", http.StatusBadRequest)
				return
			}

			type UpdateReq struct {
				DraftTitle string `json:"draftTitle"`
			}
			var req UpdateReq
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				http.Error(w, "Invalid JSON", http.StatusBadRequest)
				return
			}

			// Update Title only for now (simplest edit)
			_, err := db.Exec("UPDATE sessions SET draft_title = ? WHERE id = ?", req.DraftTitle, id)
			if err != nil {
				http.Error(w, "Update failed: "+err.Error(), http.StatusInternalServerError)
				return
			}
			w.WriteHeader(http.StatusOK)
			return
		}

		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}))

	log.Fatal(http.ListenAndServe(":8080", nil))
}
