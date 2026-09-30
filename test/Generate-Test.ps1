$outputFile = "stress_test_orders.xml"
# Using StreamWriter for high-performance file writing
$stream = [System.IO.StreamWriter]::new("$PWD\$outputFile")

# 1. Write UNA, UNB, and the Header segments
$header = "<edifact>UNA:+.? '`nUNB+UNOC:3+SENDER_ID:14+RECEIVER_ID:14+260820:0927+1001'`nUNH+10001+ORDERS:D:01B:UN:EAN010'`nBGM+220+PO-9923847+9'`nDTM+137:20260820:102'`nDTM+2:20260825:102'`nFTX+PUR+++PLEASE DELIVER TO DOCK 4'`nNAD+BY+7310000000016::9++ACME CORP+123 WIDGET WAY+HELSINKI++00100+FI'`nNAD+SU+6410000000018::9++GLOBAL SUPPLIES OY+456 INDUSTRIAL PKWY+TAMPERE++33100+FI'`nNAD+DP+7310000000016::9++ACME WAREHOUSE+789 LOGISTICS BLVD+NOKIA++37100+FI'`nCUX+2:EUR:4'"
$stream.WriteLine($header)

# Change this number to dial the memory stress up or down
$numberOfLines = 1000

# 2. Loop to generate the repetitive line items
for ($i = 1; $i -le $numberOfLines; $i++) {
    $stream.WriteLine("LIN+$i++1234567890123:SRV'`nIMD+F++:::WIDGET TYPE A'`nQTY+21:100'`nPRI+AAA:10.50::NTP'")
}

# 3. Dynamically calculate the UNT segment count 
# (Header = 9 segments, each LIN loop = 4 segments, Footer = 3 segments including UNT itself)
$segmentCount = 9 + ($numberOfLines * 4) + 3

# 4. Write Summary and Footer
$footer = "UNS+S'`nMOA+86:24782.50'`nUNT+$segmentCount+10001'`nUNZ+1+1001'"
$stream.WriteLine($footer)
$stream.WriteLine("</edifact>")

$stream.Close()
Write-Host "Successfully generated $numberOfLines lines in $outputFile."