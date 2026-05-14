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
    group_part="$3"
    rules_part="$4"

    local_rule_dir='local_rule'
    local_rule_url_dir='local_rule/url'
    create_directory "$local_rule_dir"
    create_directory "$local_rule_url_dir"

    # 先清空输出文件，确保每次覆盖
    echo '' > "$output_file"
    echo '' > "$group_part"
    echo '' > "$rules_part"
    rm -rf "${local_rule_url_dir}"/*

    # 读取输入文件
    echo "读取文件 $input_file..."
    while IFS= read -r line; do
        # 如果该行包含 URL（假设 URL 在逗号后的部分）
        if [[ "$line" =~ ^ruleset=.+,https?:// ]]; then
            # 获取下载链接
            url=$(echo "$line" | cut -d',' -f2)
            # 提取文件名
            file_name=$(basename "$url")
            #下载位置
            local_file_path="$local_rule_url_dir/$file_name"

            # 下载文件
            if download_file "$url" "$local_file_path"; then
                # 下载成功，将url替换为相对路径，这种写法不需要考虑定界符冲突，也不需要调用外部 sed 进程
                updated_value="${line//"$url"/"$local_file_path"}"
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
    
    # 分离 group 和 rule
    while IFS= read -r line; do
        if [[ "$line" =~ ^custom_proxy_group=.+ ]]; then
           echo "$line" >> "$group_part"
        fi
        if [[ "$line" =~ ^ruleset=.+ ]]; then
           echo "$line" >> "$rules_part"
        fi
    done < "$output_file"

}

# 主函数
main() {
    # 转换
    input_ini_file="rule/ShellClash_Custom.ini"               # 输入文件路径
    output_ini_file="local_rule/ShellClash_Custom_Local.ini"  # 输出文件路径
    groups="local_rule/groups.ini"
    rulesets="local_rule/rulesets.ini"
    echo "输出文件: $output_ini_file"
    process_ini_file "$input_ini_file" "$output_ini_file" "$groups" "$rulesets"
    echo "处理完成！"
}

# 执行主函数
main
