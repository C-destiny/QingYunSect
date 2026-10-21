#!/bin/bash
# 逐个运行 tests/test_*.gd，按 docs 要求三重校验：退出码 / PASS 文本 / 无错误日志
# 用法: bash tests/run_all_tests.sh            # 默认档，跳过超长时测试
#       bash tests/run_all_tests.sh --all       # 含30分钟真实时运行测试
GODOT="/c/Tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe"
PROJ="C:/Users/72736/Documents/GitHub/QingYunSect"
LOGDIR="$PROJ/tests/_logs"
mkdir -p "$LOGDIR"

RUN_ALL=0
[ "$1" = "--all" ] && RUN_ALL=1

PASS=0; FAIL=0; SKIP=0; FAILED_LIST=""; SKIPPED_LIST=""

for f in "$PROJ"/tests/test_*.gd; do
  name=$(basename "$f" .gd)

  # test_real_time_stability 需真实运行 30 分钟，默认档跳过
  if [ "$name" = "test_real_time_stability" ] && [ "$RUN_ALL" -eq 0 ]; then
    printf "SKIP  %-42s 需真实运行 30 分钟，用 --all 参数执行\n" "$name"
    SKIP=$((SKIP+1)); SKIPPED_LIST="$SKIPPED_LIST $name"
    continue
  fi

  log="$LOGDIR/$name.log"
  # --quit-after 按帧计；每秒约60帧，留足余量；外层 timeout 留更大冗余
  timeout 2700 "$GODOT" --headless --path "$PROJ" --log-file "$log" --quit-after 200000 -s "res://tests/$name.gd" >/dev/null 2>&1
  code=$?

  has_pass=$(grep -c "PASS" "$log" 2>/dev/null | head -1)
  has_err=$(grep -cE "SCRIPT ERROR|Parse Error|Assertion failed|^ERROR:|CRASH" "$log" 2>/dev/null | head -1)
  [ -z "$has_pass" ] && has_pass=0
  [ -z "$has_err" ] && has_err=0

  if [ "$code" -eq 0 ] && [ "$has_pass" -gt 0 ] && [ "$has_err" -eq 0 ]; then
    printf "PASS  %-42s exit=%s pass=%s err=%s\n" "$name" "$code" "$has_pass" "$has_err"
    PASS=$((PASS+1))
  else
    printf "FAIL  %-42s exit=%s pass=%s err=%s\n" "$name" "$code" "$has_pass" "$has_err"
    FAIL=$((FAIL+1))
    FAILED_LIST="$FAILED_LIST $name"
  fi
done

echo ""
echo "========================================"
echo "PASS=$PASS  FAIL=$FAIL  SKIP=$SKIP"
[ -n "$FAILED_LIST" ] && echo "失败列表:$FAILED_LIST"
[ -n "$SKIPPED_LIST" ] && echo "跳过列表:$SKIPPED_LIST"
echo "========================================"