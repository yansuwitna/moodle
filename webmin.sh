#!/bin/bash

# Perbarui paket dan instal alat yang diperlukan
echo "Memperbarui daftar paket dan menginstal dependensi..."
apt update -y && apt install gnupg2 curl -y

# Unduh skrip untuk mengatur repositori Webmin
echo "Mengunduh skrip setup repositori Webmin..."
curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh

# Menjalankan skrip setup repositori Webmin
echo "Menjalankan skrip setup repositori Webmin..."
sh setup-repos.sh

# Perbarui daftar paket lagi
echo "Memperbarui daftar paket setelah menambahkan repositori Webmin..."
apt update -y

# Instal Webmin
echo "Menginstal Webmin beserta rekomendasinya..."
apt install webmin --install-recommends -y

# Periksa status layanan Webmin
echo "Memeriksa status layanan Webmin..."
service webmin status
