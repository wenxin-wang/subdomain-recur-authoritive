# About

This repo contains a lua script for PowerDNS and a sample test setup.

The script implements a "recursive cname" function. With a specified "recursive
subdomain", e.g. "re.example.com", all names in that subdomain (e.g.
"a.b.re.example.com") are handled as follows:

1. "name" part is extracted from the query (e.g. "a.b")
2. if "name" part is an IPv4 address, return that address for type A query, and
   nodata for all other types
3. else return a CNAME record pointing to "name" part as a domain (e.g. "a.b.")

# Test

```bash
cd subdomain-recur-cname-authorative/
pdns_server --config-dir=. 
dig -p 5333 @::1 A    re.example.com
dig -p 5333 @::1 A    www.google.com.re.example.com
dig -p 5333 @::1 AAAA www.google.com.re.example.com
dig -p 5333 @::1 A    1.1.1.1.re.example.com
dig -p 5333 @::1 AAAA 1.1.1.1.re.example.com
dig -p 5333 @::1 A    1.1.1.1111.re.example.com
```
