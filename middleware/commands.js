const { exec } = require('child_process');

/* To create new connection or peer */
function generateKeys(req, res, next) {
    let keys = {
        private: null,
        public: null
    }

    private()

    function private() {
        return new Promise((resolve, reject) => {
            exec('wg genkey', (error, stdout, stderr) => {
                if (error) {
                    reject(error.message);
                    return;
                }
                if (stderr) {
                    reject(stderr);
                    return;
                }
                keys.private = stdout.trim();
                console.log('Private Key:', stdout.trim());
                resolve()
            })
        })
        .then(() => {
            public(keys.private)
        })
        .catch((err) => {
            console.error(`Error: ${err}`);
            res.status(500).json({ error: err.message });
        })
    }

    function public(privateKey) {
        return new Promise((resolve, reject) => {
            exec(`echo "${privateKey}" | wg pubkey`, (error, stdout, stderr) => {
                if (error) {
                    reject(error.message);
                    return;
                }
                if (stderr) {
                    reject(stderr);
                    return;
                }
                keys.public = stdout.trim();
                console.log('Public Key:', stdout.trim());
                resolve()
            })
        })
        .then(() => {
            req.keys = keys
            next()
        })
        .catch((err) => {
            console.error(`Error: ${err}`);
            res.status(500).json({ error: err.message });
        })
    }
}

function addPeer(req, res, next) {
    let add = `wg set wg0 peer ${req.keys.public} endpoint 192.168.209.136:5182 allowed-ips 0.0.0.0/0,::/0 persistent-keepalive 25`;

    exec(add, (error, stdout, stderr) => {
        if (error) {
            console.error(`Error: ${error.message}`);
            return res.status(500).json({ error: error.message });
        }
        if (stderr) {
            console.error(`stderr: ${stderr}`);
            return res.status(500).json({ error: stderr });
        }
        console.log(stdout);  // Log the successful output
        next();  // Move to the next middleware
    });
}
/* To create new connection or peer */


function serverConfig(req, res, next) {
    let config = `
    bash -c 'cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = ${req.keys.private}
EOF
    '`;

    createFile()

    function createFile(){
        return new Promise((resolve, reject) => {
            exec(config, (error, stdout) => {
                if (error) {
                    reject(error.message)
                    return
                }
                console.log(stdout);  // Log the successful output
                resolve()
            })
        }).then(() => {
            runServer()
        }).catch((err) => {
            console.error(`Error: ${err}`);
            res.status(500).json({ error: err });
        })
    }

    function runServer(){
        return new Promise((resolve, reject) => {
            exec("wg-quick up wg0", (error, stdout) => {
                if (error) {
                    reject(error.message)
                    return
                }
                console.log(stdout);  // Log the successful output
                resolve()
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
}

function removePeer(req, res, next){
    let remove = `wg set wg0 peer ${req.body.peer} remove`

    exec(remove, (error, stdout, stderr) => {
        if (error) {
            console.error(`Error: ${error.message}`);
            return res.status(500).json({ error: error.message });
        }
        if (stderr) {
            console.error(`stderr: ${stderr}`);
            return res.status(500).json({ error: stderr });
        }
        console.log(stdout);
        next();
    });
}

module.exports = { generateKeys, addPeer, serverConfig, removePeer }