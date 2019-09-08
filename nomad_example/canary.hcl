job "eShop" {
  datacenters = ["dc1"]
  group "eShop" {
     count = 5
  task "eShop" {
  driver = "raw_exec"

  config {
    command = "dotnet.exe ef database update -c catalogcontext -p ../Infrastructure/Infrastructure.csproj -s Web.csproj; dotnet.exe ef database update -c appidentitydbcontext -p ../Infrastructure/Infrastructure.csproj -s Web.csproj; dotnet.exe run"
  }

  artifact {
    source = "https://github.com/chrismatteson/eShopOnWeb/archive/master.zip"
    destination = "local/eshop"
  }
}
}
}
