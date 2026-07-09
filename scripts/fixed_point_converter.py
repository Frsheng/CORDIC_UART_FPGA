import math

# ================= Q15.16 (常被称为 Q16.16) 常量说明 =================
# 格式：1位符号位 + 15位整数位 + 16位小数位 = 32位
# 实际数值 = 有符号32位整数 / 65536
# 范围：-32768 ~ 65535.9999847412109375
# 二进制/十六进制输入时，直接解释为补码表示的32位有符号整数，再除以65536。
SCALE = 1 << 16          # 65536
INT_BITS = 16            # 包含符号位，实际有效整数位为15
FRAC_BITS = 16
MAX_UNSIGNED_INT = (1 << INT_BITS) - 1   # 65535 (整数部分最大正值)
MIN_SIGNED_INT = - (1 << (INT_BITS - 1)) # -32768

def float_to_q16_16(x: float) -> int:
    """浮点数 -> Q16.16 定点整数（有符号32位）"""
    if x < MIN_SIGNED_INT or x > MAX_UNSIGNED_INT + 1 - 1/SCALE:
        raise ValueError(f"数值 {x} 超出 Q16.16 范围")
    return int(round(x * SCALE))

def q16_16_to_float(fixed: int) -> float:
    """Q16.16 定点整数 -> 浮点数"""
    return fixed / SCALE

def hex_to_q16_16(hex_str: str) -> int:
    """十六进制字符串 -> 有符号32位整数"""
    s = hex_str.strip().lstrip('0x').lstrip('0X')
    if not s:
        raise ValueError("空十六进制字符串")
    s = s.zfill(8)          # 补全到8位十六进制（32位）
    val = int(s, 16)
    if val & 0x80000000:    # 最高位为1，解释为负数
        return val - 0x100000000
    return val

def q16_16_to_hex(fixed: int) -> str:
    """有符号32位整数 -> 十六进制（补码表示）"""
    if fixed < 0:
        fixed += 0x100000000
    return f"{fixed:08X}"

def bin_to_q16_16(bin_str: str) -> int:
    """二进制字符串 -> 有符号32位整数（自动截取低32位）"""
    s = bin_str.strip().lstrip('0b')
    if not s:
        raise ValueError("空二进制字符串")
    if len(s) > 32:
        s = s[-32:]        # 只取最后32位（相当于从高位依次截取）
    else:
        s = s.zfill(32)
    val = int(s, 2)
    if val & 0x80000000:
        return val - 0x100000000
    return val

def q16_16_to_bin(fixed: int) -> str:
    """有符号32位整数 -> 32位二进制字符串（补码）"""
    if fixed < 0:
        fixed += 0x100000000
    return f"{fixed:032b}"

def angle_to_radians(value: float, unit: str) -> float:
    if unit == 'rad':
        return value
    elif unit == 'deg':
        return math.radians(value)
    else:
        raise ValueError(f"未知角度单位: {unit}")

def radians_to_angle(rad: float, unit: str) -> float:
    if unit == 'rad':
        return rad
    elif unit == 'deg':
        return math.degrees(rad)
    else:
        raise ValueError(f"未知角度单位: {unit}")

def convert_single_value(value_str: str, input_type: str, angle_unit: str = None) -> dict:
    if input_type == 'float':
        float_val = float(value_str)
        fixed_int = float_to_q16_16(float_val)
        rad_val = float_val
    elif input_type == 'angle':
        if angle_unit is None:
            raise ValueError("角度转换必须指定单位 (deg/rad)")
        angle_val = float(value_str)
        rad_val = angle_to_radians(angle_val, angle_unit)
        float_val = rad_val
        fixed_int = float_to_q16_16(float_val)
    elif input_type == 'hex':
        fixed_int = hex_to_q16_16(value_str)
        float_val = q16_16_to_float(fixed_int)
        rad_val = float_val
    elif input_type == 'bin':
        fixed_int = bin_to_q16_16(value_str)
        float_val = q16_16_to_float(fixed_int)
        rad_val = float_val
    else:
        raise ValueError(f"不支持的输入类型: {input_type}")

    result = {
        'input_raw': value_str,
        'fixed_int': fixed_int,
        'float': float_val,
        'hex': q16_16_to_hex(fixed_int),
        'bin': q16_16_to_bin(fixed_int),
        'radians': rad_val,
        'degrees': math.degrees(rad_val)
    }
    return result

def print_result(result: dict):
    print(f"\n  输入值: {result['input_raw']}")
    print(f"  Q15.16 (常称Q16.16) 整数: {result['fixed_int']}")
    print(f"  十六进制 (补码32位): 0x{result['hex']}")
    print(f"  二进制 (补码32位): {result['bin']}")
    print(f"  浮点数 (弧度): {result['float']:.10f}")
    print(f"  角度 (度): {result['degrees']:.10f}°")

def show_help():
    print("\n" + "="*60)
    print("                      帮助说明")
    print("="*60)
    print("本工具处理定点数格式：")
    print("  - 32位有符号定点数，最高位(bit31)为符号位")
    print("  - 剩余31位中，高15位为整数部分，低16位为小数部分")
    print("  - 实际数值 = 有符号32位整数 / 65536")
    print("  - 该格式通常称为 Q16.16（含符号位）或 Q15.16（不含符号位）")
    print("  - 二进制/十六进制输入时，直接当作补码表示的32位有符号整数处理")
    print("\n支持输入类型：")
    print("  1. 浮点数：直接输入小数，如 3.14159")
    print("  2. 角度：先选择单位(deg/rad)，再输入数值，如 45")
    print("  3. 十六进制：支持 0x1234ABCD 或 1234ABCD，可多个空格分隔")
    print("  4. 二进制：32位二进制串，可多个空格分隔")
    print("\n多个值输入：用空格分隔，每个值独立转换并输出所有表示")
    print("二进制截取规则：若输入超过32位，只取最后32位（低位）")
    print("十六进制截取规则：若输入少于8位，左补0至8位；多于8位将报错")
    print("="*60)

def show_menu():
    print("\n" + "="*60)
    print("Q15.16 (常称Q16.16) 定点数万能转换器")
    print("="*60)
    print("请选择输入类型：")
    print("1. 浮点数（小数）")
    print("2. 角度（度或弧度）")
    print("3. 十六进制 Q16.16 (8位十六进制数，支持多个，空格分隔)")
    print("4. 二进制 Q16.16 (32位二进制数，支持多个，空格分隔)")
    print("h. 查看帮助")
    print("0. 退出")
    print("-"*60)

def get_angle_unit():
    while True:
        unit = input("请选择角度单位 (deg/rad): ").strip().lower()
        if unit in ('deg', 'rad'):
            return unit
        print("单位只能是 deg 或 rad，请重新输入。")

def process_multiple(values_str: str, input_type: str, angle_unit=None):
    raw_list = values_str.strip().split()
    if not raw_list:
        print("未输入任何值。")
        return
    for idx, raw in enumerate(raw_list, 1):
        try:
            print(f"\n--- 第 {idx} 个值 ---")
            result = convert_single_value(raw, input_type, angle_unit)
            print_result(result)
        except Exception as e:
            print(f"  错误: {e}")

def main():
    while True:
        show_menu()
        choice = input("请输入选项 (0-4/h): ").strip().lower()
        if choice == '0':
            print("再见！")
            break
        elif choice == 'h':
            show_help()
            continue
        elif choice == '1':
            values = input("请输入浮点数（可多个，空格分隔）: ")
            process_multiple(values, 'float')
        elif choice == '2':
            unit = get_angle_unit()
            values = input(f"请输入角度值（单位{unit}，可多个，空格分隔）: ")
            process_multiple(values, 'angle', unit)
        elif choice == '3':
            values = input("请输入十六进制数（如 0x1234ABCD 或 1234ABCD，可多个，空格分隔）: ")
            process_multiple(values, 'hex')
        elif choice == '4':
            values = input("请输入二进制数（32位，可多个，空格分隔）: ")
            process_multiple(values, 'bin')
        else:
            print("无效选项，请重新输入。")

if __name__ == "__main__":
    main()
