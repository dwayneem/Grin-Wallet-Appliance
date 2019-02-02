#!/bin/bash
userpass="grin:$(cat ~/.grin/main/.api_secret)"

# start grin server
screen -d -m -S grin-server ~/grin/target/release/grin server run

# start ngrok
screen -d -m -S ngrok ~/ngrok http -bind-tls=false 3415

echo "Waiting for Grin Server to be ready."
sleep 15

height1=$(curl -u $userpass -s "http://127.0.0.1:3413/v1/chain" | jq -r '.height')
height2=$(curl -u $userpass -s "http://127.0.0.1:3413/v1/peers/connected" | jq -r '.[0].height')

until [ "$height1" == "$height2" ]; do 
   echo "Still waiting for Grin Server to be ready."
   sleep 15
   height1=$(curl -u $userpass -s "http://127.0.0.1:3413/v1/chain" | jq -r '.height')
   height2=$(curl -u $userpass -s "http://127.0.0.1:3413/v1/peers/connected" | jq -r '.[0].height')
done 

echo "Grin Server is ready."

if [ ! -f ~/.grin/main/wallet_data/wallet.seed ]; then
    ~/grin/target/release/grin wallet init
fi

# start wallet listener
screen -d -m -S wallet-listener ~/grin/target/release/grin wallet listen

# show the address to specify when withdrawing
address=$(curl -s "http://127.0.0.1:4040/api/tunnels" | jq -r '.tunnels[0].public_url')

echo "Please address deposits to $address:80"
