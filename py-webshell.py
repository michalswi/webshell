from flask import Flask, request
import logging
import os
import subprocess
import json

app = Flask(__name__)
SERVICE_PORT = 5000

file_handler = logging.FileHandler('/tmp/server.log')
app.logger.addHandler(file_handler)
app.logger.setLevel(logging.DEBUG)

def commandGetValidate(command):
    commandList = command.split(",")
    cmd = ["/usr/bin/which", commandList[0]]
    getBin = subprocess.Popen(cmd, stdout = subprocess.PIPE, stderr=subprocess.PIPE)
    out = (getBin.communicate()[0].strip()).decode("utf-8")
    if len(out) > 0:
        return (out + " " + " ".join(commandList[1:]))
    else:
        # if not specified or wrong always return 'dir'
        return "dir"

def commandPostValidate(data):
    command = data.get("command")
    commandList = command.split(" ")
    cmd = ["/usr/bin/which", commandList[0]]
    getBin = subprocess.Popen(cmd, stdout = subprocess.PIPE, stderr=subprocess.PIPE)
    out = (getBin.communicate()[0].strip()).decode("utf-8")
    if len(out) > 0:
        return (out + " " + " ".join(commandList[1:]))
    else:
        # if not specified or wrong always return 'dir'
        return "dir"  

def commandExecute(command):
    f = os.popen(command)
    return f.read()

@app.route('/<command>', methods = ['GET'])
def getCommand(command = None):
    # curl -X GET localhost:5000/ps,-aux
    # curl -X GET localhost:5000/python,-c,\'print\(\"foo\"\)\'
    if request.method == "GET" and command != None:
        validateComm = commandGetValidate(command)
        return commandExecute(validateComm)      
    else:
        return "try again!\n"


@app.route('/', methods = ['POST'])
def postCommand():
    # curl -X POST localhost:5000/ -d '{"command":"python test.py"}'
    # curl -X POST localhost:5000/ -d '{"command":"python3 -c \"print(\\\"foo\\\")\" "}'
    if request.method == "POST":
        data = request.get_json(force=True)
        validateComm = commandPostValidate(data)
        return commandExecute(validateComm) 


def main():
    app.run(host = '0.0.0.0', port = SERVICE_PORT, debug = False)

if __name__ == '__main__':
    main()
