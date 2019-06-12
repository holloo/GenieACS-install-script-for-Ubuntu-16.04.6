#!/bin/sh
set -e

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt autoremove -y
sudo apt-get install -y  git curl tmux build-essential zlib1g-dev libsqlite3-dev redis-server mongodb npm ruby-bundler ruby-dev libxml2 libxml2-dev gcc g++ make

curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get install -y nodejs

git clone https://github.com/genieacs/genieacs.git
cd genieacs
git checkout $(git tag -l v1.1.* --sort=-v:refname | head -n 1)
sed -i 's/"libxmljs": "^0.18.8"/"libxmljs": "^0.19.5"/' package.json   
#           "dependencies": {
#           "later": "^1.2.0",
#           "libxmljs": "^0.18.8",   ----    "libxmljs": "^0.19.5"
#           "mongodb": "^2.2.36",
#           "seedrandom": "^2.4.4"
npm install
npm run compile

cd ..
git clone https://github.com/genieacs/genieacs-gui
cd genieacs-gui/
bundle

cp config/summary_parameters-sample.yml config/summary_parameters.yml
cp config/index_parameters-sample.yml config/index_parameters.yml
cp config/parameter_renderers-sample.yml config/parameter_renderers.yml
cp config/parameters_edit-sample.yml config/parameters_edit.yml
cp config/roles-sample.yml config/roles.yml
cp config/users-sample.yml config/users.yml
cp config/graphs-sample.json.erb config/graphs.json.erb
cd ~/genieacs-gui/db/migrate/

grep -rl "ActiveRecord::Migration$" *.rb | xargs sed -i 's/ActiveRecord::Migration/ActiveRecord::Migration[5.2]/g'
cd ~/genieacs-gui/
rake db:migrate

cd ..
cat << EOF > ./genieacs-start.sh
#!/bin/sh
if tmux has-session -t 'genieacs'; then
  echo "GenieACS is already running."
  echo "To stop it use: ./genieacs-stop.sh"
  echo "To attach to it use: tmux attach -t genieacs"
else
  tmux new-session -s 'genieacs' -d
  tmux send-keys './genieacs/bin/genieacs-cwmp' 'C-m'
  tmux split-window
  tmux send-keys './genieacs/bin/genieacs-nbi' 'C-m'
  tmux split-window
  tmux send-keys './genieacs/bin/genieacs-fs' 'C-m'
  tmux split-window
  tmux send-keys 'cd genieacs-gui' 'C-m'
  tmux send-keys 'rails server' 'C-m'
  tmux select-layout tiled 2>/dev/null
  tmux rename-window 'GenieACS'
  echo "GenieACS has been started in tmux session 'geneiacs'"
  echo "To attach to session, use: tmux attach -t genieacs"
  echo "To switch between panes use Ctrl+B-ArrowKey"
  echo "To deattach, press Ctrl+B-D"
  echo "To stop GenieACS, use: ./genieacs-stop.sh"
fi
EOF

cat << EOF > ./genieacs-stop.sh
#!/bin/sh
if tmux has-session -t 'genieacs' 2>/dev/null; then
  tmux kill-session -t genieacs 2>/dev/null
  echo "GenieACS has been stopped."
else
  echo "GenieACS is not running!"
fi
EOF

chmod +x genieacs-start.sh genieacs-stop.sh

echo
echo "DONE!"
echo "GenieACS has been sucessfully installed. Start/stop it using the following commands:"
echo "./genieacs-start.sh"
echo "./genieacs-stop.sh"
echo

cd ..
echo
