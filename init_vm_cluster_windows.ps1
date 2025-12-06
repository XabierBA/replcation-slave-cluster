$URL_BASE="http://cda.drordas.info"
$DIR_BASE="C:\CDA2526"



function Extraer-ZIP($file, $destination) {
  $shell = new-object -com shell.application
  $zip = $shell.NameSpace($file)
  $shell.NameSpace($destination).copyhere($zip.items())
}


function Preparar-Imagen($nombre_imagen, $url_base_origen, $dir_base_destino) {
  if(!(Test-Path -Path "$dir_base_destino\$nombre_imagen.vdi"))  {
      if(!(Test-Path -Path "$dir_base_destino\$nombre_imagen.vdi.zip"))  {
           Write-Host "Iniciando descarga de $url_base_origen/$nombre_imagen.vdi.zip ..."
           # Invoke-WebRequest "$url_base_origen\$nombre_imagen.vdi.zip"-OutFile "$dir_base_destino\$nombre_imagen.vdi.zip"
           $web_client = New-Object System.Net.WebClient
           $web_client.DownloadFile("$url_base_origen/$nombre_imagen.vdi.zip", "$dir_base_destino/$nombre_imagen.vdi.zip")
      }
      Write-Host "Descomprimiendo $dir_base_destino\$nombre_imagen.vdi.zip ..."
      Extraer-Zip "$dir_base_destino\$nombre_imagen.vdi.zip" "$dir_base_destino"
      Remove-Item "$dir_base_destino\$nombre_imagen.vdi.zip"
  }
}

function Registrar-Imagen($nombre_imagen, $dir_base_destino, $tipo, $vboxmanage) {
  if(!(Test-Path -Path "$dir_base_destino\CDA_NO_BORRAR"))  {
     Start-Process $vboxmanage  "createvm  --name CDA_NO_BORRAR --basefolder `"$dir_base_destino`" --register " -NoNewWindow -Wait    
     Start-Process $vboxmanage  "storagectl CDA_NO_BORRAR --name STORAGE_CDA_NO_BORRAR  --add sata  --portcount 4   " -NoNewWindow -Wait     
  } 
  $IMAGEN = "$dir_base_destino\$nombre_imagen.vdi"
  Start-Process $vboxmanage  "storageattach CDA_NO_BORRAR --storagectl STORAGE_CDA_NO_BORRAR --port 0 --device 0 --type hdd --medium `"$IMAGEN`" --mtype normal " -NoNewWindow -Wait
  Start-Process $vboxmanage  "storageattach CDA_NO_BORRAR --storagectl STORAGE_CDA_NO_BORRAR --port 0 --device 0 --type hdd --medium none " -NoNewWindow -Wait
  Start-Process $vboxmanage  "modifymedium `"$IMAGEN`" --type $tipo " -NoNewWindow -Wait 
}

####
####   MAIN
####

if(!(Test-Path -Path $DIR_BASE))  {
   New-Item $DIR_BASE -itemtype directory
}

Preparar-Imagen "swap1GB"      "$URL_BASE" "$DIR_BASE"
Preparar-Imagen "base_cda"     "$URL_BASE" "$DIR_BASE"

Write-Host ">> CDA 2025/26 -- -- Ejercicios sistemas de ficheros"
$ID = Read-Host ">> Introducir identificador de las MVs (sin espacios) "


$BASE_VBOX = $env:VBOX_MSI_INSTALL_PATH
if ([string]::IsNullOrEmpty($BASE_VBOX)) {
   $BASE_VBOX = $env:VBOX_INSTALL_PATH
}
if ([string]::IsNullOrEmpty($BASE_VBOX)) {
   $READ_BASE_VBOX = Read-Host ">> Introducir directorio de instalacion de VirtualBox (habitualente `"C:\\Program Files\Oracle\VirtualBox`") :"
   if ([string]::IsNullOrEmpty($READ_BASE_VBOX)) {
      $READ_BASE_VBOX = "`"C:\\Program Files\Oracle\VirtualBox`""
   }
   $BASE_VBOX = $READ_BASE_VBOX
}

$VBOX_MANAGE = "$BASE_VBOX\VBoxManage.exe"

echo $VBOX_MANAGE

Registrar-Imagen "base_cda" "$DIR_BASE" "multiattach" $VBOX_MANAGE
Registrar-Imagen "swap1GB" "$DIR_BASE" "immutable" $VBOX_MANAGE

Write-Host ">> Configurando maquinas virtuales ..."



# Crear/arrancar imagenes
$MV_CDA="DATOS_$ID"
if (!(Test-Path -Path "$DIR_BASE\$MV_CDA"))  {

  # Solo 1 vez
  Start-Process $VBOX_MANAGE  "createvm  --name $MV_CDA --basefolder `"$DIR_BASE`" --ostype Debian_64 --register " -NoNewWindow -Wait    
  Start-Process $VBOX_MANAGE  "storagectl $MV_CDA --name STORAGE_$MV_CDA  --add sata  --portcount 8   " -NoNewWindow -Wait     
  Start-Process $VBOX_MANAGE  "storageattach $MV_CDA --storagectl STORAGE_$MV_CDA --port 0 --device 0 --type hdd --medium `"$DIR_BASE\base_cda.vdi`"     --mtype multiattach" -NoNewWindow -Wait 
  Start-Process $VBOX_MANAGE  "storageattach $MV_CDA --storagectl STORAGE_$MV_CDA --port 1 --device 0 --type hdd --medium `"$DIR_BASE\swap1GB.vdi`" --mtype immutable" -NoNewWindow -Wait 
  Start-Process $VBOX_MANAGE  "modifyvm $MV_CDA --cpus 2 --memory 512 --pae on --vram 16  --graphicscontroller vboxsvga " -NoNewWindow -Wait
  Start-Process $VBOX_MANAGE  "modifyvm $MV_CDA --nic1 nat --macaddress1 080027111111 --cableconnected1 on --nictype1 82540EM" -NoNewWindow -Wait  

  Start-Process $VBOX_MANAGE  "guestproperty set $MV_CDA /DSBOX/num_interfaces 1"       -NoNewWindow -Wait
  Start-Process $VBOX_MANAGE  "guestproperty set $MV_CDA /DSBOX/eth/0/type static"       -NoNewWindow -Wait
  Start-Process $VBOX_MANAGE  "guestproperty set $MV_CDA /DSBOX/eth/0/address 10.0.2.15" -NoNewWindow -Wait
  Start-Process $VBOX_MANAGE  "guestproperty set $MV_CDA /DSBOX/eth/0/netmask 24"        -NoNewWindow -Wait
  Start-Process $VBOX_MANAGE  "guestproperty set $MV_CDA /DSBOX/default_gateway 10.0.2.2"   -NoNewWindow -Wait
  Start-Process $VBOX_MANAGE  "guestproperty set $MV_CDA /DSBOX/host_name datos.cda.net"    -NoNewWindow -Wait
  Start-Process $VBOX_MANAGE  "guestproperty set $MV_CDA /DSBOX/default_nameserver 8.8.8.8" -NoNewWindow -Wait
  Start-Process $VBOX_MANAGE  "guestproperty set $MV_CDA /DSBOX/etc_hosts_dump `"datos.cda.net:10.0.2.15`" " -NoNewWindow -Wait
}


if (!(Test-Path -Path "$DIR_BASE\DISCO_$MV_CDA.vdi"))  {
  Start-Process $VBOX_MANAGE "createhd --filename `"$DIR_BASE\LVM1_$MV_CDA.vdi`" --size 100 --format VDI " -NoNewWindow -Wait    
  Start-Process $VBOX_MANAGE  "storageattach $MV_CDA --storagectl STORAGE_$MV_CDA --port 2 --device 0 --type hdd --medium `"$DIR_BASE\LVM1_$MV_CDA.vdi`" " -NoNewWindow -Wait 
}


# Cada vez que se quiera arrancar (o directamente desde el interfaz grafico)
Write-Host "Arrancando maquinas virtuales ..."
Start-Process $VBOX_MANAGE  "startvm $MV_CDA" -NoNewWindow -Wait

Write-Host "Maquinas virtuales arrancadas"
Start-Process $VBOX_MANAGE  "controlvm  $MV_CDA clipboard mode bidirectional" -NoNewWindow -Wait
