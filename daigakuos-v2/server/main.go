package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"
)

// Session represents a work session (Zero Input)
type Session struct {
	ID         string    `json:"id"`
	NodeID     *string   `json:"nodeId"`
	DraftTitle string    `json:"draftTitle,omitempty"` // For ad-hoc
	StartAt    time.Time `json:"startAt"`
	EndAt      time.Time `json:"endAt"`
	Minutes    int       `json:"minutes"`
	Points     float64   `json:"points"`
	Focus      int       `json:"focus"`
}

func main() {
	fmt.Println("DaigakuOS v2 Server Starting on :8080...")

	http.HandleFunc("/api/health", func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
	})

	// Basic Session Ingestion Endpoint
	http.HandleFunc("/api/sessions", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}
		var session Session
		if err := json.NewDecoder(r.Body).Decode(&session); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}

		// TODO: Save to DB
		fmt.Printf("Received Session: %+v\n", session)

		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(map[string]string{"result": "saved"})
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
