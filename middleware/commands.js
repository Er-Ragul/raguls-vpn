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
        console.log('Success at line no. 17 [middleware] - Keys generated')
        next()
    })
    .catch((err) => {
        console.log('Error at line no. 24 [middleware] - ', err)
        res.status(500).json({ error: err });
    })
}

/* To create or new peer */
function addPeer(req, res, next) {
    return new Promise((resolve, reject) => {
        let add = `wg set wg0 peer ${req.keys.public} endpoint ${process.env.SERVERIP}:5182 allowed-ips ${req.iptype.address}/32 persistent-keepalive 25`;

        try {
            execSync(add);
            resolve()
        } catch (err) {
            reject(err.message)
        }
    })
    .then(() => {
        console.log('Success at line no. 43 [middleware] - Peer added')
        next()
    })
    .catch((err) => {
        console.log('Error at line no. 47 [middleware] - ', err)
        res.status(500).json({ error: err });
    })
}

/* To configure and run the server */
function serverConfig(req, res, next) {

    return new Promise((resolve, reject) => {
        const wgConfig = `
        [Interface]
PrivateKey = ${req.keys.private}
Address = 10.0.0.1/24
ListenPort = 51820

# Enable IP forwarding and set up NAT using iptables
PostUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostUp = iptables -A FORWARD -o wg0 -j ACCEPT

# Clean up iptables rules on interface shutdown
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
PostDown = iptables -D FORWARD -o wg0 -j ACCEPT`

        fs.writeFile('/etc/wireguard/wg0.conf', wgConfig.trim(), { mode: 0o600 }, (err) => {
            if (err) {
                console.log('Error at line no. 74 [middleware] - ', err)
            } else {
                let run = `wg-quick up wg0`;

                try {
                    execSync(run);
                    resolve()
                } catch (err) {
                    reject(err.message)
                }
            }
        });
    })
    .then(() => {
        console.log('Success at line no. 89 [middleware] - Wireguard (wg0) started')
        next()
    })
    .catch((err) => {
        console.log('Error at line no. 92 [middleware] - ', err)
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
            console.log('Success at line no. 108 [middleware] - IP unblocked')
            next()
        })
        .catch((err) => {
            console.log('Error at line no. 111 [middleware] - ', err)
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
            console.log('Success at line no. 124 [middleware] - IP blocked')
            next()
        })
        .catch((err) => {
            console.log('Error at line no. 128 [middleware] - ', err)
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
        console.log('Success at line no. 143 [middleware] - Peer removed')
        next()
    })
    .catch((err) => {
        console.log('Error at line no. 147 [middleware] - ', err)
        res.status(500).json({ error: err });
    })
}

/* Reset peer's and ip pool */
function resetConnection(res, req, next){
    return new Promise((resolve, reject) => {
        try {
            execSync(`wg-quick down wg0`);
            console.log('wg0 set to down');
            execSync(`rm -rf /etc/wireguard/wg0.conf`);
            console.log('wg0 config removed');
            // execSync(`rm -rf /root/API/netdb`);
            // console.log('IP db wiped out');
            resolve()
        } catch (error) {
            console.error(`Error deleting folder: ${error.message}`);
        }
    })
    .then(() => {
        console.log('Success at line no. 168 [middleware] - Hard reset')
        next()
    })
    .catch((err) => {
        console.log('Error at line no. 172 [middleware] - ', err)
        res.status(500).json({ error: err });
    })
}

module.exports = { generateKeys, addPeer, serverConfig, managePeer, removePeer, resetConnection }