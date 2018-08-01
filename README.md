# DocGeth

Docker image that helps in creating/running a local Geth node for testing.

## Quick-Start

 1. Clone this repo, or download just the `./bin/docgeth.sh` script
 2. Init a new node with  
    ```shell
    ./bin/docgeth.sh init
    ```  
    _**OR**_  
    Init a new node with 2 accounts, 555 ether each, and the password 's3cr3t'
    ```shell
    %  ACCOUNT_NUM=2 ACCOUNT_BALANCE=555 ACCOUNT_PASSWORD=s3cr3t ./bin/docgeth.sh init
    ```
 3. Run Geth  
    ```shell
    % ./bin/docgeth.sh
    ```

