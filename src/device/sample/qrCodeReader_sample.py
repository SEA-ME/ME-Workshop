#              .';:cc;.
#            .,',;lol::c.
#            ;';lddddlclo
#            lcloxxoddodxdool:,.
#            cxdddxdodxdkOkkkkkkkd:.
#          .ldxkkOOOOkkOO000Okkxkkkkx:.
#        .lddxkkOkOOO0OOO0000Okxxxxkkkk:
#       'ooddkkkxxkO0000KK00Okxdoodxkkkko
#      .ooodxkkxxxOO000kkkO0KOxolooxkkxxkl
#      lolodxkkxxkOx,.      .lkdolodkkxxxO.
#      doloodxkkkOk           ....   .,cxO;
#      ddoodddxkkkk:         ,oxxxkOdc'..o'
#      :kdddxxxxd,  ,lolccldxxxkkOOOkkkko,
#       lOkxkkk;  :xkkkkkkkkOOO000OOkkOOk.
#        ;00Ok' 'O000OO0000000000OOOO0Od.
#         .l0l.;OOO000000OOOOOO000000x,
#            .'OKKKK00000000000000kc.
#               .:ox0KKKKKKK0kdc,.
#                      ...
#
# Author: peppe8o
# Date: Aug 2nd, 2021
# Blog: https://peppe8o.com
# Version: 1.0

import cv2
import pyzbar.pyzbar as pyzbar
from datetime import datetime

#width = 2592
#height = 1944

camera = cv2.VideoCapture(0)
#camera.set(3,width)
#camera.set(4,height)

def decodeCam(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    barcodes = pyzbar.decode(gray)
    print('reading...', end='\r')
    for barcode in barcodes:
        barcodeData = barcode.data.decode()
        barcodeType = barcode.type
        print("["+str(datetime.now())+"] Type:{} | Data: {}".format(barcodeType, barcodeData))
    return image

try:
 while True:
# Read current frame
  ret, frame = camera.read()
  im=decodeCam(frame)
except KeyboardInterrupt:
 print('interrupted!')
