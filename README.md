# ion-suffix-generator

This repo is used by the ION components to assign a unique suffix

No pipeline required - the shell script is pulled into the Docker images built during the ION component pipeline

### give_me_a_suffix.sh

will output a suffix unique suffix on stdout

The suffix is based on the DESIRED_COUNT and START_SUFFIX environment variables.  
The SUFFIX_TABLE environment variable is also required to define which table in dynamodb to use for working out the suffixes.  
It also expects to run in ECS (and therefore the ECS_CONTAINER_METADATA_FILE environment variable to be set and the file to exist that it points to).

### register_suffix_in_dns.sh

Will register a DNS entry using the SUFFIX enironment variable.  
The ACCOUNT_ALIAS environment variable also needs to be set, which is the name of the AWS account in which the changes will be made.  
It also expects to run in ECS (and therefore the ECS_CONTAINER_METADATA_FILE environment variable to be set and the file to exist that it points to).

You could generate and st SUFFIX that with give_me_a_suffix.sh like so:  
SUFFIX=$(give_me_a_suffix.sh)

The resultant record will look like &lt;service name&gt;-&lt;suffix&gt;.&lt;aws account name&gt;.acurisbackend.com