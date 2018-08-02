# DocGeth

Docker image that helps in creating/running a local Geth node for testing.

## Quick-Start

 1. Clone this repo, or download just the `./bin/docgeth.sh` script  
    ```shell
    curl -L https://github.com/juztin/docgeth/raw/master/bin/docgeth.sh > ~/bin/docgeth.sh && chmod +x ~/bin/docgeth.sh
    ```
 2. Initialize a new node with  
    ```shell
    ./bin/docgeth.sh init
    ```  
    _**OR**_  
    Init a new node with 2 accounts, 555 ether each, and setting passwords as 's3cr3t'
    ```shell
    %  DOCGETH_ACCOUNT_NUM=2 DOCGETH_ACCOUNT_BALANCE=555 DOCGETH_ACCOUNT_PASSWORD=s3cr3t ./bin/docgeth.sh init
    ```
 3. Run Geth  
    ```shell
    % ./bin/docgeth.sh
    ```


#### Print Docker Commands

If you want to customize the generated Docker commands, or simply view what is generate without invocation:

```shell
PRINT_CMD=true ./bin/docgeth.sh run
```
