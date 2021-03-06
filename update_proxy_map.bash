#! /bin/bash

echo "$(date +%T) Checking for updates"
proxyDir=/opt/nginx_proxy_map
repo='https://github.com/yz4898/nginx_proxy_map.git'
branch='main'


cd $proxyDir

git remote update >/dev/null

UPSTREAM=${1:-@{u}}
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "$UPSTREAM")
BASE=$(git merge-base @ "$UPSTREAM")

if [[ $LOCAL == $REMOTE ]]; then
  echo "$(date +%T): Up-to-date"
  #exit
elif [[ $LOCAL == $BASE ]]; then
  echo "$(date +%T): Need to pull ($LOCAL -> $BASE)"
  git reset -q --hard origin/$branch
  git pull -q
fi

# get proxy addresses from proxies.conf
source proxies.conf

# Update proxy_map.conf with proxy addresses
sed -i -e 's/ple_1/'$ple_1'/g' proxy_map.conf
sed -i -e 's/ple_2/'$ple_2'/g' proxy_map.conf

# See if the proxy_map.conf file has been updated
diff -q proxy_map.conf /etc/nginx/proxy_map.conf

# If it has been updated, backup the current file, move the new one into place
# and reload nginx
if [[ $? != 0 ]]; then
  DATE=$(date +%s)
  echo "$(date +%T): Moving old backup to /etc/nginx/old"
  sudo mv /etc/nginx/proxy_map.conf-* /etc/nginx/old
  echo "$(date +%T): Backing up current proxy map (/etc/nginx/proxy_map.conf-${DATE})"
  sudo mv -f /etc/nginx/proxy_map.conf /etc/nginx/proxy_map.conf-${DATE}
  echo "$(date +%T): Moving new proxy may into place"
  sudo cp proxy_map.conf /etc/nginx

  echo "$(date +%T): Reloading nginx"
  sudo nginx -tq
  if [[ $? == 0 ]]; then sudo systemctl reload nginx; fi
fi
