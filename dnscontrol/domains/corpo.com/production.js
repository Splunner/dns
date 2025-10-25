PROD_RECORDS = [
  A("@", "192.0.2.30"),
  CNAME("www", "@"),
  A("automate", "172.10.0.11"),
  A("wwwserver", "172.10.51.20"),
  A("ns1.corpo.com.", "172.10.60.10"),
  A("ns2.corpo.com.", "172.10.60.20"),
  A("admin.corpo.com.", "172.10.0.150"),
  NAMESERVER("ns1.corpo.com."), // Glue records
  NAMESERVER("ns2.corpo.com."), // Glue records
];