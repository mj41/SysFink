if [ -z "$1" ]; then
  echo "start-server-dev.sh 1 .. normal Engine"
  echo "start-server-dev.sh 2 .. normal Prefork::Engine"
  exit
fi

export DBIC_TRACE=1
export CATALYST_PORT=5000

if [ "$1" = "2" ]; then
  export CATALYST_ENGINE='HTTP::Prefork'
fi

perl script/sysfink_web_server.pl -r -d
