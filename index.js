const http = require("http")
const fs = require('fs')

const host = 'localhost';
const port = process.env.PORT || 80;

const requestListener = function (req, res) {

    const { headers, method, url } = req
    console.log(`requestListener: got request method=${method}, url=${url}`)


    res.statusCode = 200;
    res.setHeader('Content-Type', 'text/plain');
    console.log(`${Date.now()} - Sending response`)
    res.end('Hello World - from my feature branch - 0011\n');

};

const server = http.createServer(requestListener);
server.listen(port, () => {
    console.log(`Server is running on http://${host}:${port}`);

});