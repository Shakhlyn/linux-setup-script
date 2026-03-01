## Bugs:

1. (highest) No log for warn.
2. (highest) Browser bash script doesn't handle the pop os.
3. (highest) Snap and snapd should be checked and installed before starting installing any apps. Extract from the brave and create a standalone installer.



---  
---
 

## Improvement

- Should include the file name(possibly the function name) that logs errors and warns.
- Only confirm should create log. `success` can be used in normal cases where log is not required. When an operation is complete, a `confirm` log should be created.
- s


## Code improvement:

- For vscode installer, `set_gpg_key_n_code_repo_on_fedora` should be in the corresponding `installer function`.