require("../../providers/bind.js");

require("./production.js");


D("corpo.com",REG_NONE, DnsProvider(DSP_BIND),
  PROD_RECORDS
);

