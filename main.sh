#!/bin/bash

# Begüm Akyüz
# 2420191005
# https://www.btkakademi.gov.tr/portal/certificate/validate?certificateId=ax1hrLLaVO
# https://www.btkakademi.gov.tr/portal/certificate/validate?certificateId=rKjhambNY4
# https://credsverse.com/credentials/a24f0e32-f0d1-4c3e-aa9f-85b500e90a14


# "report.log" dosyası oluşturur, ISO formatında tarih ve saat yazdırılır. 
echo "$(date -Iseconds | awk -F "T" '{print $1 , "-" , $2}' )" > report.log 

# İşletim sistemi kontrolü sağlamak için.
OS=$(uname)

# Linux sistemini kontrol eder ve belirlenen bilgileri 'report.log' dosyasına yazar.
if [[ "$OS" == *"Linux"* ]]; then
    echo "---CPU bilgileri---">> report.log
    lscpu | grep "Model name:" | awk -F ": *" '{print "Model ismi: "$2}'>>report.log
    lscpu | grep "Architecture:" | awk -F ": *" '{print "Mimari: "$2}'>>report.log
    lscpu | grep "^CPU(s):" | awk -F ": *" '{print "Thread sayısı: "$2}'>>report.log
    lscpu | grep "^CPU max MHz:" | awk -F ": *" '{print "Max MHz: "$2}'>>report.log
    echo "---Anakart bilgileri---">> report.log
    sudo dmidecode -t baseboard | grep -E "Manufacturer"| awk -F ": " '{print "Anakart üreticisi: " $2}'>> report.log
    sudo dmidecode -t baseboard | grep -E "Product"| awk -F ": " '{print "Anakart ismi: " $2}'>> report.log
    sudo dmidecode -t baseboard | grep -E "Serial"| awk -F ": " '{print "Anakart seri numarası: " $2}'>> report.log
    echo "---UUID---">> report.log
    sudo dmidecode -t system | grep -E "UUID"| awk -F ": " '{print "UUID: " $2}'>> report.log
    echo "---RAM bilgileri---">> report.log
    sudo dmidecode -t memory | grep "Size:" | head -n 1 |awk -F ": " '{print "Ram boyutu: " $2}'>>report.log
    sudo dmidecode -t memory | grep "Manufacturer:" | head -n 1 |awk -F ": " '{print "Ram üreticisi: " $2}'>>report.log
    echo "---Disk bilgileri---">> report.log
    lsblk -do MODEL,SERIAL,SIZE,NAME>>report.log
    echo "---MAC adresi---">> report.log
    ifconfig | grep "ether" | awk '{print "Mac adresi: " $2}'>>report.log

# Windows sistemini kontrol eder ve belirlenen bilgileri 'report.log' dosyasına yazar.
elif [[ "$OS" == *"MINGW"* || "$OS" == *"CYGWIN"* ]]; then
    echo "---CPU bilgileri---">>report.log
    echo -n "İşlemci ismi: ">>report.log
    wmic cpu get Name | grep -v "Name" | tr -d '\r' | grep . >>report.log
    echo -n "Mimari: ">>report.log
    wmic cpu get AddressWidth | grep -v "AddressWidth" | tr -d '\r' | grep . >>report.log
    echo -n "Thread sayısı: ">>report.log
    wmic cpu get NumberOfLogicalProcessors | grep -v "NumberOfLogicalProcessors" | tr -d '\r' | grep . >>report.log
    echo -n "Max MHz: ">>report.log
    wmic cpu get MaxClockSpeed | grep -v "MaxClockSpeed" | tr -d '\r' | grep . >>report.log
    
    echo "---Anakart bilgileri---">> report.log
    wmic baseboard get Manufacturer,Product,SerialNumber /format:list | tr -d '\r' | grep . >>report.log
    
    echo "---UUID---">>report.log
    wmic csproduct get UUID /format:list | tr -d '\r' | grep . >>report.log
    
    echo "---RAM bilgileri---">> report.log
    wmic memorychip get Capacity,Manufacturer,Speed,PartNumber,SerialNumber /format:list | tr -d '\r' | grep . >>report.log
    
    echo "---Disk bilgileri---">> report.log
    wmic diskdrive get Model,SerialNumber,Size,MediaType /format:list | tr -d '\r' | grep . >>report.log
    
    echo "---MAC adresi---">> report.log
    getmac /nh | head -n 1 | awk '{print "MAC: " $1}' >>report.log
else 
    echo "-------------------------------*Bilinmeyen Işletim Sistemi*-------------------------------">>report.log 
fi

# Kullanıcıdan 'report.log' dosyasını şifrelemesi için parola istenir ve 'PAROLA' değişkenine atanır.
echo "Lütfen script şifresini giriniz:"
read -s PAROLA

# Arka planda gizli karakter doğrulama testi (MYO+202)
if [ "${#PAROLA}" -eq 7 ] && [ "${PAROLA:0:3}" = "MYO" ] && [ "${PAROLA:3:1}" = "+" ] && [ "${PAROLA:4:3}" = "202" ]; then
    :
else
    echo "Hatalı parola! İşlem iptal edildi."
    rm -f report.log
    exit 1
fi

# 'PAROLA' değişkeni GPG ile şifrelemek için kullanılır.
echo "$PAROLA" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 report.log

# 'report.log' dosyası kaldırılır.
rm -f report.log 

# Sistem belleğinde 'PAROLA' değişkeni tamamen silinir.
unset PAROLA
echo "İşlem başarıyla tamamlandı. Eksiksiz report.log.gpg oluşturuldu."