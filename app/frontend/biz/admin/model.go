package admin

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"strings"
)

type StringArray []string

func (sa StringArray) Value() (driver.Value, error) {
	return json.Marshal(sa)
}

func (sa *StringArray) Scan(value interface{}) error {
	bytes, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("failed to scan StringArray: %v", value)
	}
	return json.Unmarshal(bytes, sa)
}

type Product struct {
	Id          uint32      `gorm:"column:id;primaryKey;autoIncrement"`
	Name        string      `gorm:"column:name"`
	Description string      `gorm:"column:description"`
	Picture     string      `gorm:"column:picture"`
	Price       float32     `gorm:"column:price"`
	Categories  StringArray `gorm:"column:categories;type:json"`
}

func (Product) TableName() string {
	return "products"
}

func parseCategories(raw string) StringArray {
	if strings.TrimSpace(raw) == "" {
		return StringArray{}
	}
	parts := strings.Split(raw, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		v := strings.TrimSpace(p)
		if v != "" {
			out = append(out, v)
		}
	}
	return out
}

func categoriesToInput(categories StringArray) string {
	if len(categories) == 0 {
		return ""
	}
	return strings.Join(categories, ", ")
}
