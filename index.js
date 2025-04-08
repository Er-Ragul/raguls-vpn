const express = require('express');
const cors = require('cors');
const app = express();
const { Level } = require('level');
const { generateKeys, serverConfig, addPeer, removePeer } = require('./middleware/commands');

app.use(cors());
app.use(express.json());

const db = new Level('leveldb', { valueEncoding: 'json' })

database()
async function database() {
    let address = await db.get('ip_pool')
    let reusable = await db.get('reusable_ip')

    if(address == undefined){
        console.log("IP Pool Created")
        await db.put('ip_pool', '10.0.0.1');
    }
    
    if(reusable == undefined){
        console.log("Reusable IP Initiated")
        await db.put('reusable_ip', [])
    }
}

async function addRecord(name, ip, private, public) {
    await db.put(ip, {name, ip, private, public})
    const value = await db.get(ip)
    console.log(value)
}

async function deleteRecord(address){
    await db.del(address)
    let reuse = await db.get('reusable_ip')
    reuse.push(address)
    await db.put('reusable_ip', reuse)
}


app.get('/', (req, res) => {
    res.send("Ragul's VPN API Server")
});

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
                addRecord(req.body.name, allocated, req.keys.private, req.keys.public)
                res.status(200).json({ status: 'success', ip: allocated, keys: req.keys, message: 'Added new peer connection' });
            }
            else{
                let address = await db.get('ip_pool')
                address = address.split('.')
            
                if(parseInt(address[3]) <= 255){
                    address = `${address[0]}.${address[1]}.${address[2]}.${parseInt(address[3])+1}`
                    await db.put('ip_pool', address);
                    addRecord(req.body.name, address, req.keys.private, req.keys.public)
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
                if(value.key != 'ip_pool' && value.key != 'reusable_ip'){
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

app.listen(3000, () => {
    console.log(`Ragul's VPN API Server Running on Port: 3000`);
});