var getRawBody = require('raw-body');
var getFormBody = require('body/form');
var body = require('body');
const OSS = require('ali-oss');

/*
To enable the initializer feature (https://help.aliyun.com/document_detail/156876.html)
please implement the initializer function as below：
exports.initializer = (context, callback) => {
  console.log('initializing');
  callback(null, '');
};
*/

exports.handler = (req, resp, context) => {
    console.log('request started');

    if(req.queries.filename == null || req.queries.filename ==""){
        resp.setStatusCode(400)
        resp.send("")
    }
    function isAuthorized(req){
     /*
         add code to check if user is authorized
     */
        console.log(req.headers)
        return req.headers["authorization"] != null
    }
   if(!isAuthorized(req) ){
        resp.setStatusCode(403)
        resp.send("")
    }
    //read secret from enviornment variables
    var endpoint = process.env['endpoint'];
    var bucketname = process.env['bucketname'];
    var ak = process.env['ak'];
    var sk = process.env['sk'];
    const client = new OSS({
        endpoint: endpoint,
        accessKeyId: ak,
        accessKeySecret: sk,
        bucket: bucketname
    });
    const presignedurl = client.signatureUrl(req.queries.filename, {
        expires: 300,
        method: 'PUT'
    });
    console.log("generated presigned url");
    resp.send(JSON.stringify({url:presignedurl}));

}