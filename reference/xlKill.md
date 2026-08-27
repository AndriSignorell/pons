# Terminate all Microsoft Excel processes

Forcefully terminates all running Microsoft Excel processes on Windows.

## Usage

``` r
xlKill()
```

## Value

invisibly, the exit status returned by `taskkill`.

## Details

This function calls the Windows `taskkill` command with the `/F` option.
All running Excel processes are terminated immediately, and unsaved
changes are lost.

## Note

This function is available on Windows only.

## Examples

``` r
if (FALSE) { # \dontrun{
xlKill()
} # }
```
