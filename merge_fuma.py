# 将辅码中的”容错码“也拼到词库文件中

import re
import argparse
from collections import defaultdict
import string
import unicodedata

def parse_line(line):
    # 分离注释 - 注释前面应该有\t
    parts = line.strip().split('\t#', 1)
    main_content = parts[0]
    comment = f"\t#{parts[1]}" if len(parts) > 1 else ""

    # 分析主要内容
    parts = main_content.split('\t')
    if len(parts) != 3:
        return None

    char, code, weight = parts
    # 检查格式是否为 yy;xx
    if not re.match(r'^[a-z]+;[a-z]+$', code):
        return None

    try:
        weight = int(weight)
    except ValueError:
        return None

    yy, xx = code.split(';')
    return char, yy, xx, weight, comment


def process_chars(input_file, output_file):
    # 使用嵌套的defaultdict来存储数据
    char_dict = defaultdict(lambda: defaultdict(list))
    weights = defaultdict(lambda: defaultdict(set))
    comments = defaultdict(lambda: defaultdict(str))

    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            result = parse_line(line)
            if result is None:
                continue

            char, yy, xx, weight, comment = result
            char_dict[char][yy].append(xx)
            weights[char][yy].add(weight)
            if comment:
                comments[char][yy] = comment

    with open(output_file, 'w', encoding='utf-8') as f:
        for char in char_dict:
            for yy in char_dict[char]:
                if len(weights[char][yy]) > 1:
                    print(f"Warning: Multiple weights found for char '{char}' with yy '{yy}': {weights[char][yy]}")

                weight = list(weights[char][yy])[0]
                xx_combined = ';'.join(sorted(set(char_dict[char][yy])))
                comment = comments[char][yy]
                f.write(f"{char}\t{yy};{xx_combined}\t{weight}{comment}\n")


def is_punctuation(char):
    """
    检查字符是否为标点符号
    """
    if char in string.punctuation:
        return True
    if unicodedata.category(char).startswith('P'):
        return True
    return False


def build_char_code_map(chars_file):
    # 改用(字+音)作为键
    char_code_map = {}
    with open(chars_file, 'r', encoding='utf-8') as f:
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) >= 2:
                char = parts[0]
                codes = parts[1].split('#')[0].strip().split(';')
                phonetic = codes[0]
                char_code_key = f"{char}+{phonetic}"
                char_code_map[char_code_key] = ";".join(codes)
    return char_code_map


def process_words(chars_file, words_file, output_file):
    char_code_map = build_char_code_map(chars_file)
    missing_chars = set()

    with open(words_file, 'r', encoding='utf-8') as f_in, \
            open(output_file, 'w', encoding='utf-8') as f_out:
        for line_num, line in enumerate(f_in, 1):
            parts = line.strip().split('\t')
            if len(parts) < 3:
                print(f"Warning: Invalid format at line {line_num}: {line.strip()}")
                f_out.write(line)
                continue

            word, codes, freq = parts[:3]
            codes = codes.split()

            # 移除所有标点后再比较长度
            word_without_punct = ''.join(char for char in word if not is_punctuation(char))
            if len(word_without_punct) != len(codes):
                print(
                    f"Warning: Length mismatch at line {line_num}: {word} ({len(word_without_punct)} chars) vs {codes} ({len(codes)} codes)")
                f_out.write(line)
                continue

            # 转换每个字的编码
            new_codes = []
            has_missing = False
            code_index = 0

            for char in word:
                if is_punctuation(char):
                    continue

                # 使用字+音来查找编码
                char_code_key = f"{char}+{codes[code_index].split(';')[0]}"
                if char_code_key in char_code_map:
                    new_codes.append(char_code_map[char_code_key])
                else:
                    if not char.isspace():
                        missing_chars.add(f"{char}({codes[code_index]})")
                        has_missing = True
                    new_codes.append(codes[code_index])
                code_index += 1

            if not has_missing:
                f_out.write(f"{word}\t{' '.join(new_codes)}\t{freq}\n")
            else:
                f_out.write(line)

    if missing_chars:
        print("\nMissing characters summary:")
        print(f"Total unique missing characters: {len(missing_chars)}")
        print("Missing characters:", ', '.join(sorted(missing_chars)))

def main(args):
    if args.type == 'chars':
        process_chars(args.source, args.ouput)
    elif args.type == 'words':
        process_words(args.charsfile, args.source, args.ouput)
    else:
        raise ValueError(f"Invalid type: {args.type}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--charsfile', '-c' ,default='moran.chars.dict.yaml')
    parser.add_argument('--source', '-s')
    parser.add_argument('--ouput', '-o')
    parser.add_argument('--type', '-t')
    args = parser.parse_args()
    main(args)