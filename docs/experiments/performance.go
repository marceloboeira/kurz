package main

import (
	"database/sql"
	"fmt"
	_ "github.com/lib/pq"
	"log"
	"time"
)

const (
	gophers = 20
	entries = 10000
)

func main() {
	var sStmt = "select nextval('hash99')"

	for i := 0; i < gophers; i++ {
		go gopher(i, sStmt)
	}

	var input string
	fmt.Scanln(&input)
}

func gopher(id int, sStmt string) {
	db, err := sql.Open("postgres", "user=postgres dbname=marcelo password='docker' port=5434 sslmode=disable")
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("Gopher Id: %v || StartTime: %v\n", id, time.Now())

	for i := 0; i < entries; i++ {
		stmt, err := db.Prepare(sStmt)
		if err != nil {
			log.Fatal(err)
		}

		res, err := stmt.Exec()
		if err != nil || res == nil {
			log.Fatal(err)
		}

		stmt.Close()

	}
	db.Close()

	fmt.Printf("Gopher Id: %v || StopTime: %v\n", id, time.Now())
}
