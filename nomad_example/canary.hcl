job "eShop" {
  datacenters = ["dc1"]
  spread {
    attribute = "${node.unique.name}"
  }
  type = "service"
  group "eShop" {
    count = 3
    task "eShop" {
      driver = "raw_exec"

      artifact {
        source = "https://github.com/chrismatteson/eShopOnWeb/archive/master.zip"
        destination = "local/eshop"
      }
      config {
        args = [
          "-c",
          "cd local/eshop/eShopOnWeb-master/src/web; & 'c:\\Program Files\\dotnet\\dotnet.exe' ef database update -c catalogcontext -p ../Infrastructure/Infrastructure.csproj -s Web.csproj; & 'c:\\Program Files\\dotnet\\dotnet.exe' ef database update -c appidentitydbcontext -p ../Infrastructure/Infrastructure.csproj -s Web.csproj; & 'c:\\Program Files\\dotnet\\dotnet.exe' run"
        ]
        command = "powershell.exe"
      }
      service {
        port = "https"

        check {
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
      }
      resources {
        network {
          port "https" {
          static = 443
          }
        }
      }
    }
  }
}
