[Unit]
Description=SvobodaNET config HTTP server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m http.server {{HTTP_PORT}} --bind 0.0.0.0 --directory {{OUTPUT_DIR}}
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
