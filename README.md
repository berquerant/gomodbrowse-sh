# gomodbrowse-sh

```
❯ gomodbrowse.sh -h
NAME
  gomodbrowse.sh - Open the repository file downloaded with go mod in browser

SYNOPSIS
  gomodbrowse.sh [target]
  gomodbrowse.sh PATH opens the PATH of the repo.
  gomodbrowse.sh FILE:LINUM opens the line LINUM of the FILE of the repo.
  gomodbrowse.sh opens the directory of the repo.

ENVIRONMENT VARIABLES
  GMBROWSE_OPEN
    command to open file in browser

  GMBROWSE_CURL
    curl command

  GMBROWSE_TRY_URL_FAIL
    make url check fail for debug
```
