package main

import (
	"io"
	"log"
	"os"
	"text/template"

	"github.com/sap/gorfc/gorfc"
	"gopkg.in/yaml.v3"
)

type Config struct {
	Connection gorfc.ConnectionParameters        `yaml:"CONNECTION"`
	Functions  map[string]map[string]interface{} `yaml:"FUNCTIONS"`
}

func collect(configName string) (map[string]interface{}, error) {
	result := map[string]interface{}{}
	content, err := os.ReadFile(configName)
	if err != nil {
		return result, err
	}

	config := Config{}
	err = yaml.Unmarshal(content, &config)
	if err != nil {
		return result, err
	}

	connection, err := gorfc.ConnectionFromParams(config.Connection)
	if err != nil {
		return result, err
	}
	defer connection.Close()

	result["CONNECTION"], err = connection.GetConnectionAttributes()
	if err != nil {
		return result, err
	}

	for funcName, params := range config.Functions {
		result[funcName], err = connection.Call(funcName, params)
		if err != nil {
			return result, err
		}
	}
	return result, nil
}

func format(templateName string, result map[string]interface{}, writer io.Writer) (err error) {
	content, err := os.ReadFile(templateName)
	if err != nil {
		return err
	}

	tmpl, err := template.New("output").Funcs(getFunctions()).Parse(string(content))
	if err != nil {
		return err
	}

	err = tmpl.Execute(writer, result)
	return err
}

func main() {
	result, err := collect("config.yaml")
	if err != nil {
		result["ERROR"] = err.Error()
	}

	// output, err := yaml.Marshal(&result)
	// if err != nil {
	// 	log.Fatal(err)
	// }
	// log.Print(string(output))

	err = format("template.json.tmpl", result, log.Writer())
	if err != nil {
		log.Fatal(err)
	}
}
