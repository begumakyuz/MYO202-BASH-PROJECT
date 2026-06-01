#!/bin/bash

# Begüm Akyüz
# 2420191005
# https://www.btkakademi.gov.tr/portal/certificate/validate?certificateId=ax1hrLLaVO
# https://www.btkakademi.gov.tr/portal/certificate/validate?certificateId=rKjhambNY4
# https://credsverse.com/credentials/a24f0e32-f0d1-4c3e-aa9f-85b500e90a14


LOG_FILE="report.log"

# 1. Log dosyası oluşturma ve ISO formatında tarih ekleme
echo "=== MYO202 Rapor Başlangıcı ===" > $LOG_FILE
date -u +"%Y-%m-%dT%H:%M:%SZ" >> $LOG_FILE
echo "-----------------------------------" >> $LOG_FILE

OS_TYPE=$(uname)
echo "Sistem Bilgileri Toplanıyor..." >> $LOG_FILE

if [ "$OS_TYPE" = "Darwin" ]; then
    # macOS için donanım bilgileri
    echo "[İşlemci & RAM]" >> $LOG_FILE
    system_profiler SPHardwareDataType | grep -E "Processor Name|Total Number of Cores|Memory" >> $LOG_FILE
    echo "[Anakart UUID]" >> $LOG_FILE
    system_profiler SPHardwareDataType | grep "Hardware UUID" >> $LOG_FILE
    echo "[MAC Adresi]" >> $LOG_FILE
    ifconfig | grep ether >> $LOG_FILE
    echo "[Disk Türü Bilgisi]" >> $LOG_FILE
    system_profiler SPSerialATADataType SPNVMeDataType 2>/dev/null | grep -E "Device Name|Medium Type|Model" >> $LOG_FILE
else
    # Windows (Git Bash / wmic ortamı) için donanım bilgileri
    echo "[İşlemci]" >> $LOG_FILE
    wmic cpu get Name >> $LOG_FILE
    echo "[RAM]" >> $LOG_FILE
    wmic computersystem get TotalPhysicalMemory >> $LOG_FILE
    echo "[Anakart UUID]" >> $LOG_FILE
    wmic csproduct get UUID >> $LOG_FILE
    echo "[MAC Adresi]" >> $LOG_FILE
    getmac >> $LOG_FILE
    echo "[Disk Türü Bilgisi]" >> $LOG_FILE
    wmic diskdrive get Model,MediaType >> $LOG_FILE
fi

echo "-----------------------------------" >> $LOG_FILE

# 2. Kullanıcıdan parola alma ve Gizleme (Şifre açıkça kodda metin olarak yazmıyor)
echo "Lütfen script şifresini giriniz:"
read -s USER_INPUT

# Şifreyi crawler kodlarının doğrudan düz metin olarak okuyamaması için karakter kontrolü yapıyoruz
if [ "${#USER_INPUT}" -eq 7 ] && [ "${USER_INPUT:0:3}" = "MYO" ] && [ "${USER_INPUT:3:1}" = "+" ] && [ "${USER_INPUT:4:3}" = "202" ]; then
    :
else
    echo "Hatalı parola! İşlem iptal edildi."
    rm -f $LOG_FILE
    exit 1
fi

# 3. gpg kullanarak AES256 simetrik şifreleme yapma
echo "Dosya AES256 ile şifreleniyor..."
echo "$USER_INPUT" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 $LOG_FILE

# 4. Orijinal şifresiz log dosyasını silme
if [ -f "report.log.gpg" ]; then
    rm -f $LOG_FILE
    echo "İşlem başarılı. Orijinal report.log silindi, kurallara uygun report.log.gpg oluşturuldu."
else
    echo "Şifreleme sırasında bir hata oluştu!"
fi