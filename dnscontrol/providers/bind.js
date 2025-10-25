var REG_NONE = NewRegistrar("none", "NONE");

var  DSP_BIND = NewDnsProvider("bind", "BIND", {
  directory: "zones_output",
     "default_soa": {
        "master": "ns1.corpo.com.",
        "mbox": "spamtrap.corpo.com.",
        "refresh": 3600,
        "retry": 600,
        "expire": 604800,
        "minttl": 1440,
    },
    "default_ns": [
 //       "ns1.corpo.com.",
 //       "ns2.corpo.com.",

    ]
});

