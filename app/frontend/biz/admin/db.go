package admin

import (
	"fmt"
	"os"
	"sync"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

var (
	db     *gorm.DB
	dbErr  error
	dbOnce sync.Once
)

func getDB() (*gorm.DB, error) {
	dbOnce.Do(func() {
		user := getEnvOr("MYSQL_USER", "root")
		password := getEnvOr("MYSQL_PASSWORD", "041212")
		host := getEnvOr("MYSQL_HOST", "127.0.0.1")
		dsn := fmt.Sprintf("%s:%s@tcp(%s:3306)/product?charset=utf8mb4&parseTime=True&loc=Local", user, password, host)
		db, dbErr = gorm.Open(mysql.Open(dsn), &gorm.Config{
			PrepareStmt:            true,
			SkipDefaultTransaction: true,
		})
	})
	return db, dbErr
}

func getEnvOr(key, fallback string) string {
	v := os.Getenv(key)
	if v == "" {
		return fallback
	}
	return v
}
