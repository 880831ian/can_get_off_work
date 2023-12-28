#!/bin/bash
#=========================================
# 顏色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # 重置颜色

total_minutes=0
target_days=0 # 初始化目標天數
last_end_time=0
extra_minutes=0
today_5_30=$(date -jf "%H:%M" "17:30" +%s) # 最早下班的時間

calculate_minutes() {
    start_time=$1
    end_time=$2

    # 計算分鐘差
    start_minutes=$(date -jf "%H:%M" "${start_time}" +%s)
    end_minutes=$(date -jf "%H:%M" "${end_time}" +%s)
    minutes=$(((end_minutes - start_minutes) / 60))

    echo ${minutes}
}

# 從文件取得每日工作時間
while IFS=$'\t' read -r date start_time end_time || [ -n "${start_time}" ]; do
    # 如果 start_time 或 end_time 為空白，跳過該行
    if [ -z "${start_time}" ] && [ -z "${end_time}" ]; then
        continue
    fi
    ((target_days++)) # 每迭代一次增加一天

    # 如果 end_time 為空白，設定為預設值 18:00
    if [ -z "${end_time}" ]; then
        end_time=$(date +"%H:%M")
        end_time_tip=" (當下時間)"
    fi

    # 紀錄每次的 end_time
    last_end_time=${end_time}
    daily_minutes=$(calculate_minutes "${start_time}" "${end_time}")

    # 將剩餘分鐘數轉換成小時和分鐘
    calc_daily_hours=$((daily_minutes / 60))
    calc_daily_minutes=$((daily_minutes % 60))

    # 格式化小時和分鐘，確保為兩位數
    formatted_hours=$(printf "%02d" ${calc_daily_hours})
    formatted_minutes=$(printf "%02d" ${calc_daily_minutes})

    color_code=""
    if [ $((daily_minutes - 540)) -gt 0 ]; then
        # 綠色
        color_code=${GREEN}
    elif [ $((daily_minutes - 540)) -lt 0 ]; then
        # 紅色
        color_code=${RED}
    fi

    echo -e "| $date 上班打卡：${start_time} | 下班打卡：${end_time}${end_time_tip} | 工作時長：${formatted_hours}:${formatted_minutes} | 時間差： ${color_code}$(($daily_minutes - 540))${NC} |"
    end_time_tip=""

    # 累加總分鐘數
    total_minutes=$((total_minutes + daily_minutes))

    # 多餘的分鐘數
    extra_minutes=$(((daily_minutes - 540) + ${extra_minutes}))
done < <(awk '{a[i++]=$0} END {for (j=i-1; j>=0;) print a[j--] }' work_time.txt)

target_hours=$((target_days * 9))
target_minutes=$((target_hours * 60))

# 判斷是否已達到或超過目標工作時數
if [ $total_minutes -ge $target_minutes ]; then
    echo -e "${GREEN}已達到或超過 ${target_hours} 小時 (${target_days} 天)，已多出 ${extra_minutes} 分鐘。${NC}"
else
    # 計算還差多少分鐘
    remaining_minutes=$((target_minutes - total_minutes))

    # 計算最後一天的下班時間
    last_end_seconds=$(date -jf "%H:%M" "${last_end_time}" +%s)
    remaining_seconds=$((remaining_minutes * 60))
    last_end_seconds=$((last_end_seconds + remaining_seconds))

    if [ "$last_end_seconds" -lt "$today_5_30" ]; then
        last_extra_seconds=$((today_5_30 - last_end_seconds))
    fi

    last_day_end_time=$(date -jf "%s" "${last_end_seconds}" +"%H:%M")
    today_5_30_time=$(date -jf "%s" "${today_5_30}" +"%H:%M")
    last_extra_time=$((last_extra_seconds / 60))

    echo -e "\n總工時還差 ${YELLOW}${remaining_minutes}${NC} 分鐘達到 ${target_hours} 小時 (${target_days} 天) 。"
    echo -e "最後一天還需 ${YELLOW}${remaining_minutes}${NC} 分鐘，才能打卡，最後一天打卡應該為：${GREEN}${last_day_end_time}${NC} (//●⁰౪⁰●)//"
    if [ "$last_end_seconds" -lt "$today_5_30" ]; then
        echo -e "最後一天還多 ${YELLOW}${last_extra_time}${NC} 分鐘，最後一天打卡應該為：${GREEN}${today_5_30_time}${NC} (//●⁰౪⁰●)//"
    fi
fi
