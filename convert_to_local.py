import os
import requests
from urllib.parse import urlparse

# 创建保存下载文件的目录
def create_directory(directory):
    if not os.path.exists(directory):
        os.makedirs(directory)

# 下载URL内容到本地
def download_file(url, local_path):
    print(f"正在下载文件: {url} 到 {local_path}")
    response = requests.get(url)
    if response.status_code == 200:
        with open(local_path, 'wb') as f:
            f.write(response.content)
        return True
    else:
        print(f"下载失败: {url}")
        return False

# 合并重复的键
def merge_duplicate_keys(file_content):
    lines = file_content.splitlines()
    new_content = []
    section = None
    ruleset_accumulator = []  # 存储合并后的 ruleset 内容
    proxy_group_accumulator = []  # 存储合并后的 custom_proxy_group 内容

    for line in lines:
        if line.startswith("[custom]"):
            section = "custom"
            new_content.append(line)
        elif section == "custom":
            # 处理 ruleset 键的重复
            if line.startswith("ruleset="):
                ruleset_accumulator.append(line)
            # 处理 custom_proxy_group 键的重复
            elif line.startswith("custom_proxy_group="):
                proxy_group_accumulator.append(line)
            else:
                # 其他行直接加入
                if ruleset_accumulator:
                    new_content.append(f"ruleset={' '.join(ruleset_accumulator)}")
                    ruleset_accumulator = []
                if proxy_group_accumulator:
                    new_content.append(f"custom_proxy_group={' '.join(proxy_group_accumulator)}")
                    proxy_group_accumulator = []
                new_content.append(line)
        else:
            # 处理其他部分，直接加入
            if ruleset_accumulator:
                new_content.append(f"ruleset={' '.join(ruleset_accumulator)}")
                ruleset_accumulator = []
            if proxy_group_accumulator:
                new_content.append(f"custom_proxy_group={' '.join(proxy_group_accumulator)}")
                proxy_group_accumulator = []
            new_content.append(line)

    # 处理剩余的 ruleset 和 custom_proxy_group 合并
    if ruleset_accumulator:
        new_content.append(f"ruleset={' '.join(ruleset_accumulator)}")
    if proxy_group_accumulator:
        new_content.append(f"custom_proxy_group={' '.join(proxy_group_accumulator)}")

    return "\n".join(new_content)

# 处理custom部分的规则并保持其他部分原样
def process_txt_file(input_file, output_file):
    # 创建目标目录
    local_rule_url_dir = 'local_rule/url'
    create_directory(local_rule_url_dir)
    create_directory('local_rule')

    # 读取输入文件，指定编码
    print(f"读取文件 {input_file}...")
    with open(input_file, encoding='utf-8') as f:
        content = f.read()

    # 合并重复的键
    content = merge_duplicate_keys(content)

    # 打开输出文件，使用 utf-8 编码
    with open(output_file, 'w', encoding='utf-8') as output_f:
        print(f"开始写入文件 {output_file}...")
        # 处理整个文件内容，逐行复制并修改
        for line in content.splitlines():
            parts = line.split(',')

            # 如果第二部分是以 http 开头，则认为是 URL
            if len(parts) > 1 and (parts[1].strip().startswith('http://') or parts[1].strip().startswith('https://')):
                description = parts[0].strip()
                url = parts[1].strip()

                # 提取文件名和文件扩展名（从URL中获取）
                file_name = os.path.basename(urlparse(url).path)
                local_file_path = os.path.join(local_rule_url_dir, file_name)

                # 下载文件到本地
                if download_file(url, local_file_path):
                    # 用本地相对路径替换URL
                    relative_path = os.path.relpath(local_file_path, 'local_rule')
                    updated_value = f"{description},{relative_path},{','.join(parts[2:])}"
                    output_f.write(f"{updated_value}\n")
                else:
                    # 下载失败，保持原样
                    output_f.write(f"{line}\n")
            else:
                # 如果没有 URL，直接原样输出
                output_f.write(f"{line}\n")

# 主函数
def main():
    input_file = 'rule/ShellClash_Custom.ini'  # 输入文件路径
    output_file = 'local_rule/ShellClash_Custom_Local.ini'  # 输出文件路径
    try:
        process_txt_file(input_file, output_file)
        print("处理完成！")
    except Exception as e:
        print(f"发生错误: {e}")

if __name__ == '__main__':
    main()
