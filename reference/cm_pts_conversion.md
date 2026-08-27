# Convert Between Centimeters and Points

Converts numeric values between centimeters (cm) and typographic points
(pt). One centimeter corresponds to approximately 28.35 points.

## Usage

``` r
cmToPts(x)

ptsToCm(x)
```

## Arguments

- x:

  A numeric vector.

## Value

A numeric vector of the same length as `x`, converted to the
corresponding unit.

## Details

The conversion is based on: \$\$1\\ \mathrm{cm} \approx 28.35\\
\mathrm{pt}\$\$

These functions are useful in graphical contexts (e.g., when specifying
dimensions in plotting systems).

## Examples

``` r
# Convert centimeters to points
cmToPts(1)
#> [1] 28.35

# Convert points to centimeters
ptsToCm(28.35)
#> [1] 1
```
