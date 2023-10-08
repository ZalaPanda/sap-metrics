package main

import (
	"strings"
	"text/template"
	"time"
)

func unique(property string, collection []interface{}) int {
	uniqueItems := make(map[interface{}]bool)
	for _, item := range collection {
		if value, ok := item.(map[string]interface{})[property]; ok {
			if hasValue(value) {
				uniqueItems[value] = true
			}
		}
	}
	return len(uniqueItems)
}

func min(property string, collection []interface{}) interface{} {
	var min interface{} = nil
	for _, item := range collection {
		if value, ok := item.(map[string]interface{})[property]; ok {
			if min == nil || isGreater(min, value) {
				min = value
			}
		}
	}
	return min
}

func max(property string, collection []interface{}) interface{} {
	var max interface{} = nil
	for _, item := range collection {
		if value, ok := item.(map[string]interface{})[property]; ok {
			if max == nil || isGreater(value, max) {
				max = value
			}
		}
	}
	return max
}

func sum(property string, collection []interface{}) interface{} {
	var sum interface{} = nil
	for _, item := range collection {
		if value, ok := item.(map[string]interface{})[property]; ok {
			sum, _ = sumUp(value, sum)
		}
	}
	return sum
}

func fallback(fallback interface{}, value interface{}) interface{} {
	if hasValue(value) {
		return value
	}
	return fallback
}

func hasValue(v interface{}) bool {
	switch v := v.(type) {
	case float64, float32, int32, int16:
		return v != 0
	case string:
		return v != ""
	case time.Time:
		return !v.IsZero()
	default:
		return false
	}
}

func isGreater(a, b interface{}) bool {
	switch a := a.(type) {
	case float64:
		return a > b.(float64)
	case float32:
		return a > b.(float32)
	case int32:
		return a > b.(int32)
	case int16:
		return a > b.(int16)
	case string:
		return strings.Compare(a, b.(string)) > 0
	case time.Time:
		return a.After(b.(time.Time))
	default:
		return false
	}
}

func sumUp(a, b interface{}) (interface{}, bool) {
	switch a := a.(type) {
	case float64:
		b, ok := b.(float64)
		return a + b, ok
	case float32:
		b, ok := b.(float32)
		return a + b, ok
	case int32:
		b, ok := b.(int32)
		return a + b, ok
	case int16:
		b, ok := b.(int16)
		return a + b, ok
	default:
		return a, false
	}
}

func getFunctions() template.FuncMap {
	return template.FuncMap{
		"fallback": fallback,
		"unique":   unique,
		"min":      min,
		"max":      max,
		"sum":      sum,
	}
}
