package main

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"time"

	"github.com/go-redis/redis/v8"
	_ "github.com/go-sql-driver/mysql"
)

func main() {
	redisHost := os.Getenv("REDIS_HOST")
	if redisHost == "" {
		redisHost = "localhost"
	}

	redisPort := os.Getenv("REDIS_PORT")
	if redisPort == "" {
		redisPort = "6379"
	}

	redisQueue := os.Getenv("REDIS_QUEUE")
	if redisQueue == "" {
		redisQueue = "count_queue"
	}

	redisClient := redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%s", redisHost, redisPort),
		Password: "", // Set the Redis password if required
		DB:       0,  // Select the appropriate Redis database
	})

	ctx := context.TODO()

	dbHost := os.Getenv("DB_HOST")
	if dbHost == "" {
		dbHost = "localhost"
	}

	dbPort := os.Getenv("DB_PORT")
	if dbPort == "" {
		dbPort = "3306"
	}

	dbUser := os.Getenv("DB_USER")
	if dbUser == "" {
		dbUser = "root"
	}

	dbPassword := os.Getenv("DB_PASSWORD")
	if dbPassword == "" {
		dbPassword = "password"
	}

	dbName := os.Getenv("DB_NAME")
	if dbName == "" {
		dbName = "your_database_name"
	}

	db, err := sql.Open("mysql", fmt.Sprintf("%s:%s@tcp(%s:%s)/%s", dbUser, dbPassword, dbHost, dbPort, dbName))
	if err != nil {
		fmt.Printf("Error connecting to MySQL: %s\n", err.Error())
		return
	}
	defer db.Close()

	for {
		result, err := redisClient.BLPop(ctx, 0*time.Second, redisQueue).Result()
		if err != nil {
			fmt.Printf("Error: %s\n", err.Error())
			continue
		}

		countValue := result[1]
		fmt.Printf("Consumed count value: %s\n", countValue)

		// Insert the count value into the MySQL table
		insertQuery := "INSERT INTO count (id, count_value) VALUES (?, ?)"
		_, err = db.Exec(insertQuery, nil, countValue)
		if err != nil {
			fmt.Printf("Error inserting count into MySQL: %s\n", err.Error())
		}

		time.Sleep(5 * time.Second) // Sleep for 5 seconds
	}
}
