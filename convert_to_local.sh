#!/bin/bash

# 创建保存下载文件的目录
create_directory() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
    fi
}

# 下载URL内容到本地
download_file() {
    url="$1"
    local_path="$2"
    echo "正在下载文件: $url 到 $local_path"
    curl -s -o "$local_path" "$url"
    if [ $? -eq 0 ]; then
        return 0
    else
        echo "下载失败: $url"
        return 1
    fi
}

# 处理INI文件
process_ini_file() {
    input_file="$1"
    output_file="$2"

    # 创建目录
    local_rule_url_dir="local_rule/url"
    create_directory "$local_rule_url_dir"
    create_directory "local_rule"

    # 读取输入文件
    echo "读取文件 $input_file..."
    echo '' > "$output_file"  # 先清空输出文件，确保每次覆盖

    while IFS= read -r line; do
        # 如果该行包含 URL（假设 URL 在逗号后的部分）
        if [[ "$line" =~ ^ruleset=.+,https?:// ]]; then
            # 提取描述和 URL
            description=$(echo "$line" | cut -d',' -f1 | sed 's/^ruleset=//')
            url=$(echo "$line" | cut -d',' -f2)
            # 提取文件名
            file_name=$(basename "$url")
            local_file_path="$local_rule_url_dir/$file_name"

            # 下载文件
            if download_file "$url" "$local_file_path"; then
                # 下载成功，替换为相对路径
                relative_path=$(realpath --relative-to="local_rule" "$local_file_path")
                updated_value="$description,$relative_path"
                echo "$updated_value" >> "$output_file"
            else
                # 下载失败，保持原样
                echo "$line" >> "$output_file"
            fi
        else
            # 其他行原样输出
            echo "$line" >> "$output_file"
        fi
    done < "$input_file"
}

# 主函数
main() {
    input_ini_file="rule/ShellClash_Custom.ini"  # 输入文件路径
    output_ini_file="local_rule/ShellClash_Custom_Local.ini"  # 输出文件路径
    echo "输出文件: $output_ini_file"
    process_ini_file "$input_ini_file" "$output_ini_file"
    echo "处理完成！"
}

# 执行主函数
main
