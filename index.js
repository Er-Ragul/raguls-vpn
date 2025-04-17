const express = require('express');
const cors = require('cors');
const app = express();
const bcrypt = require('bcrypt');
const { Level } = require('level');
const QRCode = require('qrcode');
const { generateKeys, serverConfig, addPeer, managePeer, removePeer } = require('./middleware/commands');

app.use(cors());
app.use(express.json());

const netdb = new Level('netdb', { valueEncoding: 'json' })
const userdb = new Level('userdb', { valueEncoding: 'json' })

database()
async function database() {
    let address = await netdb.get('ip_pool')
    let reusable = await netdb.get('reusable_ip')

    if(address == undefined){
        console.log("IP Pool Created")
        await netdb.put('ip_pool', '10.0.0.1');
    }
    
    if(reusable == undefined){
        console.log("Reusable IP Initiated")
        await netdb.put('reusable_ip', [])
    }
}

async function addRecord(name, ip, private, public, enabled) {
    await netdb.put(ip, {name, ip, private, public, enabled})
    const value = await netdb.get(ip)
    console.log(value)
}

async function deleteRecord(address){
    await netdb.del(address)
    let reuse = await netdb.get('reusable_ip')
    reuse.push(address)
    await netdb.put('reusable_ip', reuse)
}

async function updateRecord(address, cmd){
    let value = await netdb.get(address)
    value['enabled'] = cmd
    await netdb.put(address, value)
}

/* To create/add new user */
async function addUser(email, password, uid) {
    await userdb.put(email, {email, password, uid})
}

async function getUser(req, res, next) {

    let { email, password } = req.body

    const value = await userdb.get(email)

    bcrypt.compare(password, value['password'], async function(err, result){
        if(result){
            let uid = new Date().getTime()
            req.uid = uid
            console.log(uid);
            await userdb.put(email, {email, password: value['password'], uid})
            next()
        }
        else{
            res.status(401).json({status: 'failed', uid, message: 'Invalid password'});
        }
    });
}

async function createQr(address) {

    let clientKey = await netdb.get(address)
    let serverKey = await netdb.get('10.0.0.1')

let template = `[Interface]
PrivateKey = ${clientKey['private']}
Address = ${address}/24

[Peer]
PublicKey = ${serverKey['public']}
AllowedIPs = 0.0.0.0/0,::/0
PersistentKeepalive = 25
Endpoint = ${process.env.SERVERIP}:51820`

    console.log(template);

    // QRCode.toString(template, { type: 'terminal' }, function (err, url) {
    //     if (err) return console.error(err);
    //     console.log(url);
    // });
    
    QRCode.toFile(`qrcode/${address}.png`, template, function (err) {
        if (err) throw err;
        console.log('QR code saved to qrcode.png');
    });
}

app.get('/', (req, res) => {
    res.send("Ragul's VPN API Server")
});


app.post('/signup', (req, res) => {

    let { email, password } = req.body

    try{
        bcrypt.hash(password, 10, function(err, hash) {
            let uid = new Date().getTime()
            addUser(email, hash, uid);
            res.status(200).json({status: 'success', uid, message: 'User created successfully'});
        });
    }
    catch(err){
        res.status(500).json({status: 'failed', message: 'Failed to create user.'})
    }
})

app.post('/login', getUser, (req, res) => {
    console.log(req.uid);
    res.status(200).json({status: 'success', uid: req.uid, message: 'User authenticated successfully'});
})

/* Runs wireguard server */
app.get('/init', generateKeys, serverConfig, (req, res) => {
    addRecord('Server', '10.0.0.1', req.keys.private, req.keys.public)
    res.status(200).json({ status: 'success', message: 'Wireguard server started successfully'});
});


/* Add new connection */
app.post('/add', generateKeys, addPeer, (req, res) => {
    async function reserveIP(){
        try{
            let reuseip = await db.get('reusable_ip')
            console.log(reuseip);
            if(reuseip.length != 0){
                let allocated = reuseip.shift()
                await db.put('reusable_ip', reuseip)
                addRecord(req.body.name, allocated, req.keys.private, req.keys.public, true)
                res.status(200).json({ status: 'success', ip: allocated, keys: req.keys, message: 'Added new peer connection' });
            }
            else{
                let address = await db.get('ip_pool')
                address = address.split('.')
            
                if(parseInt(address[3]) <= 255){
                    address = `${address[0]}.${address[1]}.${address[2]}.${parseInt(address[3])+1}`
                    await db.put('ip_pool', address);
                    addRecord(req.body.name, address, req.keys.private, req.keys.public, true)
                    res.status(200).json({ status: 'success', ip: address, keys: req.keys, message: 'Added new peer connection' });
                }
            }
        }
        catch(err){
            console.log(err);
            res.status(500).json({ status: 'failed', message: 'Internal server error' });
        }
    }
    reserveIP()
});

/* Remove the connection */
app.post('/remove', removePeer, (req, res) => {
    try{
        deleteRecord(req.body.ip)
        res.status(200).json({ status: 'success', ip: req.body.ip, message: `Removed peer connection: ${req.body.ip}` })
    }
    catch(err){
        res.status(500).json({ status: 'failed', message: 'Internal server error' });
    }
})

/* Enable & disable connection */
app.post('/switch', managePeer, (req, res) => {
    try{
        updateRecord(req.body.ip, req.body.cmd)
        res.status(200).json({status: 'success', message: `connection ${req.body.cmd}`})
    }
    catch(err){
        res.status(500).json({ status: 'failed', message: 'Internal server error' });
    }
})

/* Active connection */
app.get('/peers', (req, res) => {
    async function readAllData() {
        try {
            let result = []
            for await (const [key, value] of db.iterator()) {
                result.push({key, value})
            }
            
            let respond = []
            result.map((value) => {
                if(value.key != 'ip_pool' && value.key != 'reusable_ip' && value.key != '10.0.0.1'){
                    respond.push(value.value)
                }
            })
            res.status(200).json({ status: 'success', peers: respond })
        } catch (err) {
            console.error('Error while reading data:', err);
            res.status(500).json({ status: 'failed', message: 'Internal server error' });
        }
    }
    readAllData();
})

app.post('/qr', (req, res) => {
    try{
        createQr(req.body.ip)
        res.status(200).json({status: 'success', message: 'QR created successfully'})
    }
    catch(err){
        res.status(500).json({status: 'failed', message: 'Failed to create QR'})
    }
})

app.listen(process.env.PORT, () => {
    console.log(`Ragul's VPN API Server Running on Port: ${process.env.PORT}`);
});