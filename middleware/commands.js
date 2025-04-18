const { exec, execSync } = require('child_process');
const fs = require('fs');

/* To generate private and public key */
function generateKeys(req, res, next) {
    return new Promise((resolve, reject) => {
        const privateKey = execSync('wg genkey').toString().trim();

        const publicKey = execSync(`echo ${privateKey} | wg pubkey`).toString().trim();

        let keys = {
            private: privateKey,
            public: publicKey
        }

        req.keys = keys
        resolve()
    })
    .then(() => {
        console.log(req.keys);
        next()
    })
    .catch((err) => {
        console.error(`Error: ${err}`);
        res.status(500).json({ error: err });
    })
}

/* To create or new peer */
function addPeer(req, res, next) {
    return new Promise((resolve, reject) => {
        let add = `wg set wg0 peer ${req.keys.public} endpoint ${process.env.SERVERIP}:5182 allowed-ips ${req.iptype.address}/32 persistent-keepalive 25`;

        try {
            execSync(add);
            console.log('Peer added successfully.');
            resolve()
        } catch (err) {
            reject()
            console.error('Failed to add peer:', err.message);
        }
    })
    .then(() => {
        next()
    })
    .catch((err) => {
        console.error(`Error: ${err}`);
        res.status(500).json({ error: err });
    })
}

/* To configure and run the server */
function serverConfig(req, res, next) {

    return new Promise((resolve, reject) => {
        const wgConfig = `
        [Interface]
PrivateKey = ${req.keys.private}
Address = 10.0.0.1/32
ListenPort = 51820`

        fs.writeFile('/etc/wireguard/wg0.conf', wgConfig.trim(), { mode: 0o600 }, (err) => {
            if (err) {
                console.error('Failed to write wg0.conf:', err.message);
            } else {
                let run = `wg-quick up wg0`;

                try {
                    execSync(run);
                    console.log('Wireguard (wg0) started successfully');
                    resolve()
                } catch (err) {
                    reject()
                    console.error('Failed to start wg0:', err.message);
                }
            }
        });
    })
    .then(() => {
        next()
    })
    .catch((err) => {
        console.error(`Error: ${err}`);
        res.status(500).json({ error: err });
    })
}

/* To block or unblock the peer */
function managePeer(req, res, next){

    if(req.body.cmd == true){
        let cmd = `wg set wg0 peer ${req.body.peer} allowed-ips ${req.body.ip}/32`

        return new Promise((resolve, reject) => {
            execSync(cmd);
            resolve()
        })
        .then(() => {
            next()
        })
        .catch((err) => {
            console.error(`Error: ${err}`);
            res.status(500).json({ error: err });
        })
    }
    else{
        let cmd = `wg set wg0 peer ${req.body.peer} allowed-ips 0.0.0.0/32`

        return new Promise((resolve, reject) => {
            execSync(cmd);
            resolve()
        })
        .then(() => {
            next()
        })
        .catch((err) => {
            console.error(`Error: ${err}`);
            res.status(500).json({ error: err });
        })
    }
}

/* To remove the peer */
function removePeer(req, res, next){
    let remove = `wg set wg0 peer ${req.body.peer} remove`

    return new Promise((resolve, reject) => {
        execSync(remove);
        resolve()
    })
    .then(() => {
        next()
    })
    .catch((err) => {
        console.error(`Error: ${err}`);
        res.status(500).json({ error: err });
    })
}

module.exports = { generateKeys, addPeer, serverConfig, managePeer, removePeer }