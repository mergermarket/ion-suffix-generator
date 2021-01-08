task_id=$(grep TaskARN $ECS_CONTAINER_METADATA_FILE | awk -F'"' '{print $4}')

while true
do
    i=0
    while [ $i -lt $DESIRED_COUNT ]
    do
        let suffix=$START_SUFFIX+$i
        row=$(aws dynamodb get-item --table-name ${SUFFIX_TABLE} --key "{\"suffix\": {\"S\": \"$suffix\"}}" --region eu-west-1)

        if [ -z "${row}" ] ; then
            aws dynamodb put-item \
              --table-name ${SUFFIX_TABLE} \
              --item "{\"suffix\": {\"S\": \"${suffix}\"},\"taskid\": {\"S\": \"${task_id}\"}}" \
              --condition-expression "attribute_not_exists(taskid)" \
              --region eu-west-1
            if [ $? -eq 0 ] ; then
                echo "${task_id}:GOT SUFFIX '${suffix}', adding new row"
                break 2
            fi
        else
            saved_task_id=$(echo ${row} | jq '.Item.taskid.S' | sed 's/"//g')
        fi

        all_tasks=$(aws ecs list-tasks --service-name  ${ENV_NAME}-ion-xtract-router --region eu-west-1)
        if ! echo "${all_tasks}" | grep -q ${saved_task_id} ; then
            aws dynamodb put-item \
              --table-name ${SUFFIX_TABLE} \
              --item "{\"suffix\": {\"S\": \"${suffix}\"},\"taskid\": {\"S\": \"${task_id}\"}}" \
              --condition-expression "taskid = :t" \
              --expression-attribute-values "{\":t\": {\"S\": \"${saved_task_id}\"}}" \
              --region eu-west-1
            if [ $? -eq 0 ] ; then
                echo "${task_id}:GOT SUFFIX '${suffix}', replacing old id '${saved_task_id}'"
                break 2
            fi
        fi
        let i=$i+1
    done
done

return suffix