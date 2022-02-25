//simulate client side code */
//run: npm install request
//run: npm install readline

const request = require('request');
const readline = require("readline");

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
});

rl.question("file name? ", function (object_to_upload) {
    rl.question("file content?", function (content) {
        rl.close();
        run(object_to_upload, content)
    });

});

function run(object_to_upload, content) {
    var fc_url = "{replace-by-fc-endpoint}/get?filename=" + object_to_upload
    const options1 = {
        url: fc_url,
        headers: { "authorization": "yes" }
    };
    request.get(options1, (err, res, body) => {
        if (err) {
            return console.log(err);
        }
        console.log('Status Code:', res.statusCode);
        if(res.statusCode == 400 || res.statusCode == 403){
            console.log('failed to get presigned url, server returns', res.statusCode);
            return
        }
        var presignedurl = JSON.parse(res.body).url
        console.log('presigned url from server:', presignedurl);
        const options = {
            url: presignedurl,
            body: content
        };
        request.put(options, (err, res, body) => {
            if (err) {
                return console.log(err);
            }
            console.log('uploaded using presigned url');
            console.log('Status Code:', res.statusCode);
        });
    });
}
