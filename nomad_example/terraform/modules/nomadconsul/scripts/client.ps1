<powershell>
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install nssm -y
mkdir /ProgramData/consul/config
$IPADDRESS=(curl http://instance-data/latest/meta-data/local-ipv4)
$DNSRECURSER=(Get-DnsClientServerAddress | Select-Object –ExpandProperty ServerAddresses -first 1)
$ConsulConfig = "
{
  `"ui`": true,
  `"log_level`": `"INFO`",
  `"data_dir`": `"/ProgramData/consul/data`",
  `"bind_addr`": `"0.0.0.0`",
  `"client_addr`": `"0.0.0.0`",
  `"advertise_addr`": `"$IPADDRESS`",
  `"recursors`": [`"$DNSRECURSER`"],
  `"connect`": {
    `"enabled`": true
  },
  `"retry_join`": [`"provider=aws tag_key=ConsulAutoJoin tag_value=nomad-multi_job_demo region=us-east-1`"]
}"
echo $ConsulConfig
echo $ConsulConfig | Out-File C:\ProgramData\consul\config\config.json -Encoding ASCII
choco install consul -y -params '-config-file="%ProgramData%\consul\config\config.json"'

$NOMAD_CONFIG="data_dir = `"/ProgramData/nomad/data`"
bind_addr = `"$IPADDRESS`"
name = `"nomad@$IPADDRESS`"

# Enable the client
client {
  enabled = true
  options = {
    driver.java.enable = `"1`"
    docker.cleanup.image = false
  }
}

consul {
  address = `"$IPADDRESS:8500`"
}

telemetry {
  publish_allocation_metrics = true
  publish_node_metrics       = true
}

acl {
  enabled = true
}"
echo $NomadConfig
echo $NomadConfig | Out-File C:\ProgramData\nomad\conf\nomad.hcl -Encoding ASCII
</powershell>
choco install nomad -y -params '-config-file="%PROGRAMDATA%\nomad\conf\nomad.hcl'
