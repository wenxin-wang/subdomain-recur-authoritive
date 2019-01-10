-- Well, I don't know how this is working. Try add some logging and you will understand me

dns_dnssec = false
recurdomain = "re.example.com."
ttl = 600

soa_data = { hostmaster = "admin.re.example.com.",
             nameserver = "ns1.test.com.",
             serial = 2019011001,
             refresh = 3600,
             retry = 3600,
             expire = 2419200,
             default_ttl = 86400,
             ttl = ttl }
soa = soa_data["nameserver"].." "..soa_data["hostmaster"].." "..soa_data["serial"].." "..soa_data["refresh"].." "..soa_data["retry"].." "..soa_data["expire"].." "..soa_data["default_ttl"]

function isDomain(name)
  if name:len() < recurdomain:len() or name:sub(-recurdomain:len(), -1) ~= recurdomain then
    return false
  end
  local i = recurdomain:len() + 1
  return name:len() == recurdomain:len() or name:sub(-i, -i) == "."
end

function getNamePart(name)
  return name:sub(1, (name:len() - recurdomain:len() - 1))
end

function list(target, domain_id)
  return false
end

local q_type, q_name, got

function isIpAddress(ip)
  if not ip then return false end
  local a,b,c,d = ip:match("^(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)$")
  a = tonumber(a)
  b = tonumber(b)
  c = tonumber(c)
  d = tonumber(d)
  if not a or not b or not c or not d then return false end
  if a < 0 or 255 < a then return false end
  if b < 0 or 255 < b then return false end
  if c < 0 or 255 < c then return false end
  if d < 0 or 255 < d then return false end
  return true
end

function lookup(qtype, qname, domain_id)
  q_type = qtype -- Most of the time qtype == "ANY"
  q_name = qname
  got = false
end

function get()
  if not isDomain(q_name) then
    return false
  end

  if got then
    return false
  end
  got = true

  if q_type == "SOA" then
    return { name = q_name, type = "SOA", content = soa, ttl = ttl, domain_id = 11 }
  elseif q_name == recurdomain then
    return false
  else
    local name = getNamePart(q_name)
    if isIpAddress(name) then
      if q_type == "A" or q_type == "ANY" then
        return { name = q_name, type = "A", content = name, ttl = ttl, domain_id = 11 }
      else
        return {}
      end
    else
      return { name = q_name, type = "CNAME", content = name, ttl = ttl, domain_id = 11 }
    end
  end
end

function getsoa(name)
  if isDomain(name) then
    return soa_data
  end
end
