{
  "agent": {
    "metrics_collection_interval": 60,
    "region": "${region}",
    "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log",
    "debug": true
  },
  "metrics": {
    "metrics_collected": {
      "collectd": {},
      "netstat": {
        "measurement": [
          "tcp_established",
          "tcp_syn_sent",
          "tcp_close"
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          "used_percent",
          "free",
          "total",
          "used"
        ],
        "resources": [
          "*"
        ],
        "drop_device": true
      },
      "swap": {
        "measurement": [
          "free",
          "used",
          "used_percent"
        ]
      },
      "mem": {
        "measurement": [
          "active",
          "available",
          "cached",
          "free",
          "buffered"
        ]
      },
      "processes": {
        "measurement": [
          "running",
          "sleeping",
          "dead"
        ]
      }
    },
    "append_dimensions": {
      "ImageId": "$${aws:ImageId}",
      "InstanceId": "$${aws:InstanceId}"
    },
    "aggregation_dimensions": [
      [
        "InstanceId"
      ],
      []
    ]
  }
}
