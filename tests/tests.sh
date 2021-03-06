#!/usr/bin/env bash
total=0
failed=0
passed=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

function run_test {
    test_name=$1
    url=$2
    assert_request_allowed=$3
    test_passed=false

    echo -n "$test_name... "
    if [ "$assert_request_allowed" = true ]; then
        content=$(wget $url -q -O -)
        if [[ $content == *"Welcome to nginx!"* ]]; then
            test_passed=true
        fi
    else
        response=$(curl --write-out %{http_code} --silent --output /dev/null $url)
        if [ "403" = "$response" ]; then
            test_passed=true
        fi
    fi

    if [ "$test_passed" = true ]; then
        echo -e "${GREEN}PASSED${NC}"
        ((passed++))
    else
        echo -e "${RED}FAILED${NC}"
        ((failed++))
    fi
    ((total++))
}

# Tests with the default set up
run_test "Sending a normal request should succeed" "http://nginx-waf:8080" true #DevSkim: ignore DS137138
# using integer overflow attack
run_test "Sending a dodgy request should be forbidden" "http://nginx-waf:8080?arg=2147483648" false #DevSkim: ignore DS137138

# Tests with in DetectionOnly mode
run_test "Sending a normal request should succeed when in DetectionOnly mode" "http://nginx-waf:8081" true #DevSkim: ignore DS137138
# using integer overflow attack
run_test "Sending a dodgy request should succeed when in DetectionOnly mode" "http://nginx-waf:8081?arg=2147483648" true #DevSkim: ignore DS137138

echo
if [ $failed -eq 0 ]; then
    echo -n -e "$GREEN"
else
    echo -n -e "$RED"
fi
echo -n "PASSED: $passed | FAILED: $failed | TOTAL: $total"
echo -e "$NC"

exit $failed