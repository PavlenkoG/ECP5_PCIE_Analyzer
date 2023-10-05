from spidev import SpiDev

'''
def bits(f):
    bytes = (ord(b) for b in f.read())
    for b in bytes:
        for i in xrange(8):
            yield(b>>i) & 1

def read_packets(mem_num, address):
    msg = [0x03]
    msg.append(mem_num)
    first_b = address.to_bytes(2,'big')
    msg.append(int(first_b[0]))
    msg.append(int(first_b[1]))
    print(msg)
#   answer = spi.readbytes(33)
    print(msg[0].peek(0))

def create_list(answer):
    flag = answer[33]
    for i in range(8):
        if i & (1 << (flag - 1)):

'''


spi = SpiDev()
msg = [0x03, 0x01, 0x00, 0x00]

spi.open(0, 0)
spi.max_speed_hz = 10000000
spi.mode = 1

spi.writebytes(msg)
raw_input("press")
answer = spi.readbytes(33)
print(answer)

spi.close()
