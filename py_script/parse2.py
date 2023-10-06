import argparse
from datetime import datetime

def hex_str_to_num(words: [str]) -> '[int]':
    out = []
    for word in words:
        if word.startswith("0x"):
            out.append(int(word[2:], 16))
        else:
            raise ValueError(f"hex_str_to_num: invalid word '{word}'")
    return out


def two_byte(bytes: [int]) -> int:
    return bytes[1] | (bytes[0] << 8)

def four_byte(bytes: [int]) -> int:
    return bytes[3] | (bytes[2] << 8) | (bytes[1] << 16) | (bytes[0] << 24)

def eight_byte(bytes: [int]) -> int:
    return (four_byte(bytes[0:4]) << 32) | four_byte(bytes[4:8])

class FmtTypes:
    CPLD = 0b010_01010
    MRD = 0b000_00000
    MWR = 0b010_00000
    MSGD = 0b011_10100

def fmt_type_to_str(val: int) -> str:
    match val:
        case FmtTypes.MSGD:
            return "MsgD"
        case 0b001_10000:
            return "Msg"
        case 0b001_10100:
            return "Msg"
        case 0b000_01010:
            return "Cpl"
        case FmtTypes.CPLD:
            return "CplD"
        case FmtTypes.MRD:
            return "MRd" #3DW
        case 0b001_00000:
            return "MRd_4DW"
        case FmtTypes.MWR:
            return "MWr" #3DW
        case 0b011_00000:
            return "MWr_4DW"
        case other:
            return f"??? 0b{val: b}"
        
def tlp_tag_to_slot(tag: int) -> int:
    # bit 4:0
    return tag & 0b11111


def tlp_tag_to_index(tag: int) -> int:
    # bit6:5
    return (tag & 0b1100000) >> 5


def tlp_tag_to_process(tag: int) -> int:
    # bit 7
    if ((tag & 0b1000_0000) == 0b1000_0000):
        # acyclic
        return "acyclic"
    else:
        return "cyclic"        


def parse_tlp(bytes: [int], packet: dict):
    fmt_type = bytes[0]
    packet['tlp_fmt_type'] = fmt_type
    if len(bytes) >= 4:
        length_dw = bytes[3] | ((bytes[2] & 0b11) << 8)
        length = length_dw * 4
        # if length_dw > 100:
        #     print(f"len_dw={length_dw} {bytes[2]} {bytes[3]}")
        packet['tlp_length_dw'] = length_dw
        if fmt_type == FmtTypes.CPLD:
            if len(bytes) > 11:
                byte_count = bytes[7] | ((bytes[6] & 0b1111) << 8)
                packet['tlp_byte_count'] = byte_count
                packet['tlp_tag'] = bytes[10]
                lower_addr = bytes[11] & 0b0111_1111
                packet['tlp_lower_addr'] = lower_addr
                idx_data_start = 12 + lower_addr
                packet['tlp_data'] = bytes[idx_data_start:(idx_data_start+byte_count)]
        elif fmt_type == FmtTypes.MRD:
            if len(bytes) >= 11:
                packet['tlp_addr'] = four_byte(bytes[8:12]) & 0b11111111_11111111_11111111_11111100
        elif fmt_type == FmtTypes.MWR:
            if len(bytes) >= 13:
                packet['tlp_data'] = bytes[12:(12+length)]
                packet['tlp_addr'] = four_byte(bytes[8:12]) & 0b11111111_11111111_11111111_11111100
                packet['tlp_first_be'] = bytes[7] & 0b1111
                packet['tlp_last_be'] = (bytes[7] >> 4) & 0b1111
                packet['tlp_be'] = bytes[7]
        elif fmt_type == FmtTypes.MSGD:
            idx_ts = 8
            idx_prop_delay = idx_ts + 8
            idx_after_prop_delay = idx_prop_delay + 4
            if len(bytes) >= idx_prop_delay:
                # packet['tlp_data'] = bytes[9:(9+8)] # timestamp master time
                packet['tlp_ts_master'] = eight_byte(bytes[idx_ts:idx_prop_delay]) # timestamp master time
            if len(bytes) >= idx_after_prop_delay:
                packet['tlp_prop_delay'] = four_byte(bytes[idx_prop_delay:idx_after_prop_delay]) # propagation delay
        else:
            packet['tlp_data'] = bytes[4:length]


def parse_file(filename: str):
    out = []
    with open(filename) as f:
        lines = f.readlines()
        for line in lines:
            # print(f"len={len(line)}")
            # print(line)
            words = line.split(", ")
            # print(f"words='{words}'")
            if len(words) >= 6:
                packet_type = hex_str_to_num([words[3]])[0]
                packet = {
                    "direction": words[0],
                    "ts": int(words[1]),
                    "type": packet_type,  # int(words[3][3:], 16),
                    "number": two_byte(hex_str_to_num(words[4:6])),
                }
                if packet_type == PacketTypes.TYPE_START_TLP and len(words) >= 7:
                    parse_tlp(hex_str_to_num(words[6:]), packet)
                out.append(packet)
    return out


class PacketTypes:
    TYPE_START_TLP = 0xfb
    TYPE_START_DLLP = 0x5c


def do_parse(filename: str):
    parsed = parse_file(filename)
    sortedlist = sorted(parsed,  key=lambda packet: packet["ts"], reverse=False)
    # print(sortedlist[0])
    return sortedlist


def type_to_str(type: int) -> 'str':
    match type:
        case PacketTypes.TYPE_START_TLP:
            return "TLP"
        case PacketTypes.TYPE_START_DLLP:
            return "DLLP"
        case other:
            return f"??? type=0x{type:x}"


def data_as_str(vals: [int]) -> str:
    out = "["
    str_vals = map(lambda val: f"0x{val:02x}", vals)
    out += ','.join(str_vals)
    out += "]"
    return out

def print_parsed(sortedlist: [dict]):
    last = 0
    for packet in sortedlist:
        delta_ts = packet['ts'] - last
        tlp_str = ""
        if 'tlp_fmt_type' in packet:
            tlp_str += f"{fmt_type_to_str(packet['tlp_fmt_type']):4} "
        if 'tlp_length_dw' in packet:
            tlp_str += f"lenDW={packet['tlp_length_dw']} "
        if 'tlp_byte_count' in packet:
            tlp_str += f"bytecount={packet['tlp_byte_count']} "
        if 'tlp_tag' in packet:
            tlp_str += f"tag=(slot={tlp_tag_to_slot(packet['tlp_tag'])} idx={tlp_tag_to_index(packet['tlp_tag'])} {tlp_tag_to_process(packet['tlp_tag'])}) "
        if 'tlp_addr' in packet:
            tlp_str += f"addr=0x{packet['tlp_addr']:08x} "
        if 'tlp_lower_addr' in packet:
            tlp_str += f"tlp_lower_addr=0x{packet['tlp_lower_addr']:02x} "
        if 'tlp_data' in packet:
            tlp_str += f"data={data_as_str(packet['tlp_data'])} "
        if 'tlp_first_be' in packet:
            tlp_str += f"1st_be=0b{packet['tlp_first_be']:04b} "
        if 'tlp_last_be' in packet:
            tlp_str += f"last_be=0b{packet['tlp_last_be']:04b} "
        if 'tlp_ts_master' in packet:
            # tlp_str += f"ts_master={packet['tlp_ts_master']} ({datetime.fromtimestamp(packet['tlp_ts_master']/1e9).strftime("%A, %B %d, %Y %I:%M:%S")}) "
            tlp_str += f"ts_master=0x{packet['tlp_ts_master']:016x} ts_master={packet['tlp_ts_master']} "
        if 'tlp_prop_delay' in packet:
            tlp_str += f"prop_delay=0x{packet['tlp_prop_delay']:08x} "            
            
        # if 'tlp_be' in packet:
        #     tlp_str += f"be=0x{packet['tlp_be']:02x} "

        print(f"{packet['direction']} {packet['ts']/1e6: 12.6f} {delta_ts: 10} {type_to_str(packet['type']):3} {packet['number']: 8} {tlp_str}")
        last = packet['ts']

def execute():
    """build a m100 io module initial package"""
    parser = argparse.ArgumentParser(
        prog='',
        description='',
        epilog=r'')
    parser.add_argument('record_csv')
    args = parser.parse_args()

    parsed = do_parse(args.record_csv)
    print_parsed(parsed)


if __name__ == "__main__":
    execute()