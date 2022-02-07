import os
import timeit
if (os.name == "posix"):
    from spidev import SpiDev

# Print iterations progress
def printProgressBar (iteration, total, prefix = '', suffix = '', decimals = 1, length = 100, fill = '█', printEnd = "\r"):
     '''
     Call in a loop to create terminal progress bar
     @params:
         iteration   - Required  : current iteration (Int)
         total       - Required  : total iterations (Int)
         prefix      - Optional  : prefix string (Str)
         suffix      - Optional  : suffix string (Str)
         decimals    - Optional  : positive number of decimals in percent complete (Int)
         length      - Optional  : character length of bar (Int)
         fill        - Optional  : bar fill character (Str)
         printEnd    - Optional  : end character (e.g. "\r", "\r\n") (Str)
     '''
     percent = ("{0:." + str(decimals) + "f}").format(100 * (iteration / float(total)))
     filledLength = int(length * iteration // total)
     bar = fill * filledLength + '-' * (length - filledLength)
     print(f'\r{prefix} |{bar}| {percent}% {suffix}', end = printEnd)
     # Print New Line on Complete
     if iteration == total: 
         print()

def writePacket (file, msg, direction):
    flag = int(msg[len(byteArray)-1])
    data = []
    for i in range(8):
        if (flag >> i & 1):
            timestamp = 0
            #data = []
            for j in range(4):
                timestamp = timestamp + (msg[i*4+j])*(256**(3-j))
            timestamp = timestamp * 4
            f.write('\n')
            f.write(direction)
            f.write(str(timestamp))
            f.write(', ns')
        else:
            for j in range(4):
                f.write(", 0x")
                f.write(hex(msg[i*4+j])[2:].zfill(2) )
                #data.append(msg[i*4+j])

def parseMem(testfile):
    byteArray = []
    flags = 0
    for linesIter in range(8):
        #read line from stim file
        testline = testfile.readline()
        
        #flag indicates timestamp
        flags = flags + int(testline[0])*(2**linesIter)
        for byteIter in range(4):
            byte = 0
            #get byte end
            endByte = 35 - (3 - byteIter) * 9
            for bitIter in range(8):
                byte = byte + int(testline[(endByte-bitIter)])*(2**bitIter)
            byteArray.append(byte)
    byteArray.append(flags)
    msg = byteArray
    return msg

def read_packets(spi, mem_num, address):
    msg = [0x03]
    msg.append(mem_num)
    first_b = address.to_bytes(2,'big')
    msg.append(int(first_b[0]))
    #msg.append(0)
    msg.append(int(first_b[1]))
    #msg.append(address)
    spi.writebytes(msg)
    #print(msg)
    answer = spi.readbytes(33)
    return answer

start = timeit.default_timer()
if os.path.exists("out.csv"):
    os.remove("out.csv")
    print("file removed")
    
f = open("out.csv","a")

lineBytes = []

if (os.name == "nt"):
    testfile = open("up_memory.mem","r")
    testfile1 = open("down_memory.mem","r")

if (os.name == "posix"):
    spi = SpiDev()
    spi.open(0,0)
    spi.max_speed_hz = 6000000
    spi.mode = 1

byte = 0
byteArray = []
packet = {}

flags = 0
lineCounter = 0
addr = 0
#printProgressBar(0, 2048, prefix = 'Progress:', suffix = 'Complete', length = 50)

for lines in range(2048):
#   printProgressBar(lines + 1, 2048, prefix = 'Progress line up:   ', suffix = 'Complete', length = 50)
    if (os.name == "nt"):
        msg = parseMem(testfile)
        writePacket (f, msg, "->, ")
    if (os.name == "posix"):
        msg = read_packets(spi,0,addr)
        writePacket (f, msg, "->, ")
        addr = addr + 32

addr = 0
#printProgressBar(0, 2048, prefix = 'Progress:', suffix = 'Complete', length = 50)    
for lines in range(2048):
#   printProgressBar(lines + 1, 2048, prefix = 'Progress line down: ', suffix = 'Complete', length = 50)
    if (os.name == "nt"):
        msg = parseMem(testfile1)
        writePacket (f, msg, "<-, ")
    if (os.name == "posix"):
        msg = read_packets(spi,1,addr)
        writePacket (f, msg, "->, ")
        addr = addr + 32
    
stop = timeit.default_timer()
print('Time: ', stop - start, 's') 
    