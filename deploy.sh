#!/bin/bash
docker run --rm -e TZ=Europe/Berlin -v .:/srv/jekyll:cached -v jekyll_data:/usr/local/bundle jekyll/jekyll:4 jekyll build
export SSHPASS=$(aws ssm get-parameter --name strato-masterpwd --with-decryption | jq -r .Parameter.Value)
echo "Upload files... please wait."
#sshpass -e scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r _site/* n-k.de@ssh.strato.de:/keycloak-dev-day/
sshpass -e scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r _site/index.html n-k.de@ssh.strato.de:/keycloak-dev-day/index.html
echo "Deployment done."
