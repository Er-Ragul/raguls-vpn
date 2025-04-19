const express = require('express');
const cors = require('cors');
const app = express();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { Level } = require('level');
const QRCode = require('qrcode');
const fs = require('fs');
const path = require('path');
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

async function setUser(req, res, next) {

    let { email, password } = req.body

    try{
        bcrypt.hash(password, 10, async function(err, hash) {
            let uid = new Date().getTime()
            req.uid = uid
            await userdb.put(uid, {email, hash, uid})
            next()
        });
    }
    catch(err){
        res.status(500).json({status: 'failed', message: 'Failed to create user.'})
    }
}

async function getUser(req, res, next) {

    let { uid, password } = req.body

    const value = await userdb.get(uid)

    bcrypt.compare(password, value.hash, async function(err, result){
        if(result){
            const token = jwt.sign({ userid: value['uid'] }, 'SECRET_KEY', { expiresIn: '1h' });
            req.token = token
            next()
        }
        else{
            console.log(err);
            res.status(401).json({status: 'failed', uid, message: 'Invalid password'});
        }
    });
}

async function createQr(req, res, next) {
    try{
        let clientKey = await netdb.get(req.body.ip)
        let serverKey = await netdb.get('10.0.0.1')
    
    let template = `[Interface]
PrivateKey = ${clientKey['private']}
Address = ${req.body.ip}/24

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
        
        QRCode.toFile(`qrcode/${req.body.ip}.png`, template, function (err) {
            if(err) {
                res.status(500).json({status: 'failed', message: 'Failed to create QR'})
            }
            
            const fileData = fs.readFileSync(`qrcode/${req.body.ip}.png`);

            const base64String = fileData.toString('base64');

            const ext = path.extname(`qrcode/${req.body.ip}.png`).substring(1); // remove dot
            const mimeType = `image/${ext}`;

            req.qrcode = `data:${mimeType};base64,${base64String}`

            next()
        });
    }
    catch(err){
        console.log(err);
        res.status(500).json({status: 'failed', message: 'Failed to create QR'})
    }
}

/* Verify token */
function verifyToken(req, res, next){
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ status: 'failed', message: "No token provided" });
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(token, 'SECRET_KEY');
        next()
    } catch (err) {
        res.status(401).json({ message: "Invalid token" });
    }
}

/* Reserver or reuse ip address */
async function reserveIP(req, res, next){
    try{
        let reuseip = await netdb.get('reusable_ip')
        console.log(reuseip);
        if(reuseip.length != 0){
            let allocated = reuseip.shift()
            await netdb.put('reusable_ip', reuseip)

            let iptype = {
                address: allocated,
                type: 'reuse'
            }

            req.iptype = iptype

            addRecord(req.body.name, allocated, req.keys.private, req.keys.public, true)
            next()
        }
        else{
            let allocated = await netdb.get('ip_pool')
            allocated = allocated.split('.')
        
            if(parseInt(allocated[3]) <= 255){
                allocated = `${allocated[0]}.${allocated[1]}.${allocated[2]}.${parseInt(allocated[3])+1}`
                await netdb.put('ip_pool', allocated);

                let iptype = {
                    address: allocated,
                    type: 'pool'
                }

                req.iptype = iptype

                addRecord(req.body.name, allocated, req.keys.private, req.keys.public, true)
                next()
            }
        }
    }
    catch(err){
        console.log(err);
        res.status(500).json({ status: 'failed', message: 'Internal server error' });
    }
}

/* Get all peers */
async function getAllPeers(req, res, next) {
    try {
        let result = []
        for await (const [key, value] of netdb.iterator()) {
            result.push({key, value})
        }
        
        let respond = []
        result.map((value) => {
            if(value.key != 'ip_pool' && value.key != 'reusable_ip' && value.key != '10.0.0.1'){
                respond.push(value.value)
            }
        })
        req.peers = respond
        next()
    } catch (err) {
        console.error('Error while reading data:', err);
        res.status(500).json({ status: 'failed', message: 'Internal server error' });
    }
}

app.get('/', (req, res) => {
    res.send("Ragul's VPN API Server")
});

app.post('/signup', setUser, (req, res) => {
    res.status(200).json({status: 'success', uid: req.uid, message: 'User created successfully'});
})

app.post('/login', getUser, (req, res) => {
    res.status(200).json({status: 'success', uid: req.uid, token: req.token, message: 'User authenticated successfully'});
})

/* Runs wireguard server */
app.get('/init', generateKeys, serverConfig, (req, res) => {
    addRecord('Server', '10.0.0.1', req.keys.private, req.keys.public)
    res.status(200).json({ status: 'success', message: 'Wireguard server started successfully'});
});


/* Add new connection */
app.post('/add', verifyToken, generateKeys, reserveIP, addPeer, (req, res) => {
    console.log(req.name, req.headers.authorization);
    res.status(200).json({ status: 'success', ip: req.iptype.address, keys: req.keys, message: 'Added new peer connection' });
});

/* Enable & disable connection */
app.post('/switch', verifyToken, managePeer, (req, res) => {
    try{
        updateRecord(req.body.ip, req.body.cmd)
        res.status(200).json({status: 'success', message: `connection set to ${req.body.cmd}`})
    }
    catch(err){
        res.status(500).json({ status: 'failed', message: 'Internal server error' });
    }
})

/* Remove the connection */
app.post('/remove', verifyToken, removePeer, (req, res) => {
    try{
        deleteRecord(req.body.ip)
        res.status(200).json({ status: 'success', ip: req.body.ip, message: `Removed peer connection: ${req.body.ip}` })
    }
    catch(err){
        res.status(500).json({ status: 'failed', message: 'Internal server error' });
    }
})

/* List peers */
app.get('/peers', verifyToken, getAllPeers, (req, res) => {
    res.status(200).json({ status: 'success', peers: req.peers });
})

app.post('/qr', createQr, (req, res) => {
    res.status(200).json({status: 'success', qr: req.qrcode, message: 'QR created successfully'})
})

app.listen(process.env.PORT, () => {
    console.log(`Ragul's VPN API Server Running on Port: ${process.env.PORT}`);
});