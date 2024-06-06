#!/bin/bash
#=========================================
# 顏色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[0;33m'
NC='\033[0m' # 重置颜色

target_days=0 # 初始化目標天數
pwd=$(dirname "$0")

show_class() {
    hour=$(echo $1 | cut -d: -f1 | sed 's/^0*//')
    minute=$(echo $1 | cut -d: -f2)
    total_minutes=$((hour * 60 + minute))
    late_minutes=$((total_minutes - 570))

    if ((total_minutes <= 495)); then
        class="08:00-17:00"
        real_end_time="17:00"
        late_status=""
        late_tip=""
    elif ((total_minutes <= 525)); then
        class="08:30-17:30"
        real_end_time="17:30"
        late_status=""
        late_tip=""
    elif ((total_minutes <= 555)); then
        class="09:00-18:00"
        real_end_time="18:00"
        late_status=""
        late_tip=""
    elif ((total_minutes <= 585)); then
        class="09:30-18:30"
        real_end_time="18:30"
        late_status=""
        late_tip=""
    else
        class="09:30-18:30"
        real_end_time="18:30"
        late_status="${RED}已遲到${NC} + "
        if ((late_minutes <= 60)); then
            late_tip=" | 遲到 [ ${YELLOW}$late_minutes${NC} 分鐘 ] ，需要請假 ${PURPLE}09:30 ~ 10:30${NC}"
        elif ((late_minutes <= 120)); then
            late_tip=" | 遲到 [ ${YELLOW}$late_minutes${NC} 分鐘 ] ，需要請假 ${PURPLE}09:30 ~ 11:30${NC}"
        else
            late_tip=" | 遲到 [ ${YELLOW}$late_minutes${NC} 分鐘 ] ，回家睡覺好了 ─=≡Σ((( つ•̀ω•́)つ"
        fi
    fi
}

calculate_minutes() {
    real_hour=$(echo $1 | cut -d: -f1 | sed 's/^0*//')
    real_minute=$(echo $1 | cut -d: -f2 | sed 's/^0*//')
    end_hour=$(echo $2 | cut -d: -f1 | sed 's/^0*//')
    end_minute=$(echo $2 | cut -d: -f2 | sed 's/^0*//')

    real_total_minutes=$((real_hour * 60 + real_minute))
    end_total_minutes=$((end_hour * 60 + end_minute))
    time_diff=$((end_total_minutes - real_total_minutes))

    hours=$((time_diff / 60))
    minutes=$((time_diff % 60))

    if ((time_diff < 0)); then
        status=$late_status"${RED}尚未達到下班${NC}"
        overtime_caption=""
        overtime_tip=""
    elif ((time_diff == 0)); then
        status=$late_status"${GREEN}已達到可下班${NC}"
        overtime_caption=""
        overtime_tip=""
    elif ((time_diff < 10)); then
        status=$late_status"${YELLOW}可報加班${NC}"
        overtime_caption="\n| 可報時段：${PURPLE}$real_end_time ~ $2${NC} [ ${YELLOW}${time_diff}${NC} 分鐘 ]   |"
        overtime_tip=" (可以再等等，超過 60 分鐘，有 90 元誤餐費 xD)           |"
    elif ((time_diff < 60)); then
        status=$late_status"${YELLOW}可報加班${NC}"
        overtime_caption="\n| 可報時段：${PURPLE}$real_end_time ~ $2${NC} [ ${YELLOW}${time_diff}${NC} 分鐘 ]  |"
        overtime_tip=" (可以再等等，超過 60 分鐘，有 90 元誤餐費 xD)           |"
    elif ((time_diff >= 60)); then
        status=$late_status"${YELLOW}可報加班${NC}"
        overtime_caption="\n| 可報時段：${PURPLE}$real_end_time ~ $2${NC} [ ${YELLOW}${time_diff}${NC} 分鐘 ]  |"
        overtime_tip=""
    elif ((time_diff >= 100)); then
        status=$late_status"${YELLOW}可報加班${NC}"
        overtime_caption="\n| 可報時段：${PURPLE}$real_end_time ~ $2${NC} [ ${YELLOW}${time_diff}${NC} 分鐘 ] |"
        overtime_tip=""
    fi
}

# 從文件取得每日工作時間
while IFS=$'\t' read -r date start_time end_time || [ -n "${start_time}" ]; do
    # 如果 start_time 或 end_time 為空白，跳過該行
    if [ -z "${start_time}" ] && [ -z "${end_time}" ]; then
        continue
    fi
    ((target_days++)) # 每迭代一次增加一天

    # 如果 end_time 為空白，則帶入當下時間
    if [ -z "${end_time}" ]; then
        end_time=$(date +"%H:%M")
        end_time_tip=" (Now)"
    else
        # 去除時間後面的括號
        end_time=$(echo "${end_time}" | sed 's/([^)]*)//g')
    fi
    # 去除時間後面的括號
    start_time=$(echo "${start_time}" | sed 's/([^)]*)//g')

    show_class ${start_time} # 顯示班別

    calculate_minutes "${real_end_time}" "${end_time}"

    echo -e "| $date 上班打卡時間：${start_time} | 下班打卡時間：${end_time}${end_time_tip} | 班別：${class} | \
能夠下班時間：${GREEN}${real_end_time}${NC} |\n| 目前狀態：${status}$late_tip | ${overtime_caption}${overtime_tip} \n"

done < <(awk '{a[i++]=$0} END {for (j=i-1; j>=0;) print a[j--] }' $pwd/work_time.txt)
