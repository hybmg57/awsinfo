load ../../awsinfo
load ../../test-helpers/bats-assert/load

LOG_STREAM_NAME_1=test-log-stream-$RANDOM
LOG_STREAM_NAME_2=test-log-stream-$RANDOM

LOG_MESSAGE_TIMESTAMP=$(($(date -u +%s)*1000))

create_log_message(){
    awsie $(stack_name) logs create-log-stream --log-group-name cf:AWSInfoTestLogGroup: --log-stream-name $1
    awsie $(stack_name) logs put-log-events --log-group-name cf:AWSInfoTestLogGroup: --log-stream-name $1 --log-events timestamp=$LOG_MESSAGE_TIMESTAMP,message=TestMessage-$2
}
setup(){
    deploy_stack
    create_log_message $LOG_STREAM_NAME_1 1
    create_log_message $LOG_STREAM_NAME_2 2
}

@test "getting log messages" {
    # Default Logging Setup
    run awsinfo logs LogGroup
    assert_success
    assert_output -p "TestMessage-1"
    assert_output -p "TestMessage-2"
    assert_output -p "$LOG_STREAM_NAME_1"
    assert_output -p "$LOG_STREAM_NAME_2"
    assert_output -p "AWSInfoTestLogGroup"

    # Without LogStream
    run awsinfo logs LogGroup -S
    assert_success
    assert_output -p "TestMessage"
    assert_output -p "AWSInfoTestLogGroup"
    refute_output -p "$LOG_STREAM_NAME_1"
    refute_output -p "$LOG_STREAM_NAME_2"

    # Without LogGroup
    run awsinfo logs LogGroup -G
    assert_success
    assert_output -p "TestMessage-1"
    assert_output -p "$LOG_STREAM_NAME_1"
    refute_output -p "AWSInfoTestLogGroup"

    # Filtering messages
    run awsinfo logs LogGroup -f "TestMessage-1"
    assert_success
    assert_output -p "TestMessage-1"
    assert_output -p "$LOG_STREAM_NAME_1"

    refute_output -p "$LOG_STREAM_NAME_2"
    refute_output -p "TestMessage-2"

    run awsinfo logs LogGroup -e now -s -10minutes
    assert_success
    assert_output -p "TestMessage-1"
    assert_output -p "$LOG_STREAM_NAME_1"
}

teardown(){
    remove_stack
}