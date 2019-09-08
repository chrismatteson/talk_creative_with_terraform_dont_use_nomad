<powershell>
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
New-NetFirewallRule -DisplayName 'HTTP(S) Inbound' -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('80', '443')

choco install nssm -y
mkdir /ProgramData/consul/config
$IPADDRESS=(Invoke-WebRequest -Uri http://instance-data/latest/meta-data/local-ipv4 -UseBasicParsing | Select-Object -ExpandProperty Content)
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

choco install dotnetcore-sdk -y
choco install mssqlserver2014-sqllocaldb -y
$env:Path += & 'C:\Program Files\dotnet\dotnet.exe'

mkdir /ProgramData/nomad/conf
$NomadConfig="data_dir = `"/ProgramData/nomad/data`"
bind_addr = `"$IPADDRESS`"
name = `"nomad@$IPADDRESS`"

# Enable the client
client {
  enabled = true
}

plugin `"raw_exec`" {
  config {
    enabled = true
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
choco install nomad -y
echo $NomadConfig
echo $NomadConfig | Out-File C:\ProgramData\nomad\conf\client.hcl -Encoding ASCII
Restart-Service -name nomad

</powershell>
