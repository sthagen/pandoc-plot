<!--
The file README.md is automatically generated by the tools/mkreadme script 
Do not edit manually
-->

# pandoc-plot 

## A Pandoc filter to generate figures from code blocks in documents

[![Hackage version](https://img.shields.io/hackage/v/pandoc-plot.svg)](http://hackage.haskell.org/package/pandoc-plot) [![Stackage version (nightly)](http://stackage.org/package/pandoc-plot/badge/nightly)](http://stackage.org/nightly/package/pandoc-plot) [![Build status](https://ci.appveyor.com/api/projects/status/mmgiuk52j356e6jp?svg=true)](https://ci.appveyor.com/project/LaurentRDC/pandoc-plot) [![Build Status](https://dev.azure.com/laurentdecotret/pandoc-plot/_apis/build/status/LaurentRDC.pandoc-plot?branchName=master)](https://dev.azure.com/laurentdecotret/pandoc-plot/_build/latest?definitionId=5&branchName=master) [![license](https://img.shields.io/badge/license-GPLv2+-lightgray.svg)](https://www.gnu.org/licenses/gpl.html) [![Conda Version](https://img.shields.io/conda/vn/conda-forge/pandoc-plot.svg)](https://anaconda.org/conda-forge/pandoc-plot)

`pandoc-plot` turns code blocks present in your documents (Markdown, LaTeX, etc.) into embedded figures, using your plotting toolkit of choice, including Matplotlib, ggplot2, MATLAB, Mathematica, and more.

-   [Overview](#overview)
-   [Supported toolkits](#supported-toolkits)
-   [Features](#features)
    -   [Captions](#captions)
    -   [Link to source code](#link-to-source-code)
    -   [Preamble scripts](#preamble-scripts)
    -   [Performance](#performance)
    -   [Compatibility with
        pandoc-crossref](#compatibility-with-pandoc-crossref)
-   [Configuration](#configuration)
    -   [Executables](#executables)
    -   [Toolkit-specific options](#toolkit-specific-options)
-   [Detailed usage](#detailed-usage)
    -   [As a filter](#as-a-filter)
    -   [Cleaning output](#cleaning-output)
    -   [Configuration template](#configuration-template)
    -   [As a Haskell library](#as-a-haskell-library)
-   [Installation](#installation)
    -   [Binaries and Installers](#binaries-and-installers)
    -   [conda](#conda)
    -   [From Hackage/Stackage](#from-hackagestackage)
    -   [From source](#from-source)
-   [Warning](#warning)

Overview
--------

This program is a [Pandoc](https://pandoc.org/) filter. It can therefore
be used in the middle of conversion from input format to output format,
replacing code blocks with figures.

The filter recognizes code blocks with classes that match plotting
toolkits. For example, using the `matplotlib` toolkit:

```` {.markdown}
# My document

This is a paragraph.

```{.matplotlib}
import matplotlib.pyplot as plt

plt.figure()
plt.plot([0,1,2,3,4], [1,2,3,4,5])
plt.title('This is an example figure')
```
````

Putting the above in `input.md`, we can then generate the plot and embed
it in an HTML page:

``` {.bash}
pandoc --filter pandoc-plot input.md --output output.html
```

*Note that pandoc-plot only works with pandoc \>= 2.8 because of some
breaking changes in pandoc's API.*

Supported toolkits
------------------

`pandoc-plot` currently supports the following plotting toolkits
(**installed separately**):

-   `matplotlib`: plots using the [matplotlib](https://matplotlib.org/)
    Python library;
-   `plotly_python` : plots using the [plotly](https://plot.ly/python/)
    Python library;
-   `matlabplot`: plots using [MATLAB](https://www.mathworks.com/);
-   `mathplot` : plots using
    [Mathematica](https://www.wolfram.com/mathematica/);
-   `octaveplot`: plots using [GNU
    Octave](https://www.gnu.org/software/octave/);
-   `ggplot2`: plots using [ggplot2](https://ggplot2.tidyverse.org/);
-   `gnuplot`: plots using [gnuplot](http://www.gnuplot.info/);

To know which toolkits are useable on *your machine* (and which ones are
not available), you can check with the `--toolkits/-t` flag:

``` {.bash}
pandoc-plot --toolkits
```

**Wish your plotting toolkit of choice was available? Please [raise an
issue](https://github.com/LaurentRDC/pandoc-plot/issues)!**

Features
--------

### Captions

You can also specify a caption for your image. This is done using the
optional `caption` parameter.

**Markdown**:

```` {.markdown}
```{.matlabplot caption="This is a simple figure with a **Markdown** caption"}
x  = 0: .1 : 2*pi;
y1 = cos(x);
y2 = sin(x);

figure
plot(x, y1, 'b', x, y2, 'r-.', 'LineWidth', 2)
```
````

**LaTex**:

``` {.latex}
\begin{minted}[caption=This is a simple figure with a caption]{matlabplot}
x  = 0: .1 : 2*pi;
y1 = cos(x);
y2 = sin(x);

figure
plot(x, y1, 'b', x, y2, 'r-.', 'LineWidth', 2)
\end{minted}
```

Caption formatting unfortunately cannot be determined automatically. To
specify a caption format (e.g. "markdown", "LaTeX", etc.), see
[Configuration](#configuration).

### Link to source code

In case of an output format that supports links (e.g. HTML), the
embedded image generated by `pandoc-plot` can show a link to the source
code which was used to generate the file. Therefore, other people can
see what code was used to create your figures.

You can turn this on via the `source=true` key:

**Markdown**:

```` {.markdown}
```{.mathplot source=true}
...
```
````

**LaTex**:

``` {.latex}
\begin{minted}[source=true]{mathplot}
...
\end{minted}
```

or via a [configuration file](#Configuration).

### Preamble scripts

If you find yourself always repeating some steps, inclusion of scripts
is possible using the `preamble` parameter. For example, if you want all
Matplotlib plots to have the
[`ggplot`](https://matplotlib.org/tutorials/introductory/customizing.html#sphx-glr-tutorials-introductory-customizing-py)
style, you can write a very short preamble `style.py` like so:

``` {.python}
import matplotlib.pyplot as plt
plt.style.use('ggplot')
```

and include it in your document as follows:

```` {.markdown}
```{.matplotlib preamble=style.py}
plt.figure()
plt.plot([0,1,2,3,4], [1,2,3,4,5])
plt.title('This is an example figure')
```
````

Which is equivalent to writing the following markdown:

```` {.markdown}
```{.matplotlib}
import matplotlib.pyplot as plt
plt.style.use('ggplot')

plt.figure()
plt.plot([0,1,2,3,4], [1,2,3,4,5])
plt.title('This is an example figure')
```
````

The equivalent LaTeX usage is as follows:

``` {.latex}
\begin{minted}[include=style.py]{matplotlib}

\end{minted}
```

This `preamble` parameter is perfect for longer documents with many
plots. Simply define the style you want in a separate script! You can
also import packages this way, or define functions you often use.

### Performance

`pandoc-plot` minimizes work, only generating figures if it absolutely
must, i.e. if the content has changed. `pandoc-plot` will save the hash
of the source code used to generate a figure in its filename. Before
generating a figure, `pandoc-plot` will check it this figure already
exists based on the hash of its source! This also means that there is no
way to directly name figures.

Moreover, starting with version 0.5.0.0, `pandoc-plot` takes advantage
of multicore CPUs, rendering figures **in parallel**.

Therefore, you can confidently run the filter on very large documents
containing hundreds of figures, like a book or a thesis.

### Compatibility with pandoc-crossref

[`pandoc-crossref`](https://github.com/lierdakil/pandoc-crossref) is a
pandoc filter that makes it effortless to cross-reference objects in
Markdown documents.

You can use `pandoc-crossref` in conjunction with `pandoc-plot` for the
ultimate figure-making pipeline. You can combine both in a figure like
so:

```` {.markdown}
```{#fig:myexample .plotly_python caption="This is a caption"}
# Insert figure script here
```

As you can see in @fig:myexample, ...
````

If the above source is located in file `myfile.md`, you can render the
figure and references by applying `pandoc-plot` **first**, and then
`pandoc-crossref`. For example:

``` {.bash}
pandoc --filter pandoc-plot --filter pandoc-crossref -i myfile.md -o myfile.html
```

Configuration
-------------

To avoid repetition, `pandoc-plot` can be configured using simple YAML
files. `pandoc-plot` will look for a `.pandoc-plot.yml` file in the
current working directory. Here are **all** the possible parameters:

``` {.yaml}
# This is an example configuration. Everything in this file is optional.
# Please refer to the documentation to know about the parameters herein.
#
# The `executable` parameter for all toolkits can be either the
# executable name (if it is present on the PATH), or
# the full path to the executable.
# E.g.:
#  executable: python3
#  executable: "C:\Python37\Scripts\python.exe"
#
# Note that this file should be re-named to ".pandoc-plot.yml" before pandoc-plot 
# notices it.

# The following parameters affect all toolkits
# Directory where to save the plots. The path can be relative to this file, or absolute.
directory: plots/

# Whether or not to include a link to the source script in the caption. 
# Particularly useful for HTML output.
source: false

# Default density of figures in dots per inches (DPI). 
# This can be changed in the document specifically as well.
dpi: 80

# Default format in which to save the figures. This can be specified individually as well.
format: PNG

# Text format for the captions. Unfortunately, there is no way to detect this automatically.
# You can use the same notation as Pandoc's --from parameter, specified here:
# https://pandoc.org/MANUAL.html#option--from
# Example: markdown, rst+raw_tex
caption_format: markdown+tex_math_dollars

# The possible parameters for the Matplotlib toolkit
matplotlib:
  # preamble: matplotlib.py
  tight_bbox: false
  transparent: false
  executable: python

# The possible parameters for the MATLAB toolkit
matlabplot:
  # preamble: matlab.m
  executable: matlab

# The possible parameters for the Plotly/Python toolkit
plotly_python:
  # preamble: plotly-python.py
  executable: python

# The possible parameters for the Mathematica toolkit
mathplot:
  # preamble: mathematica.m
  executable: math

# The possible parameters for the GNU Octave toolkit
octaveplot:
  # preamble: octave.m
  executable: octave

# The possible parameters for the ggplot2 toolkit
ggplot2:
  # preamble: ggplot2.r
  executable: Rscript

# The possible parameters for the gnuplot toolkit
gnuplot:
  # preamble: gnuplot.gp
  executable: gnuplot
```

A file like the above sets the **default** values; you can still
override them in documents directly.

Using `pandoc-plot write-example-config` will write the default
configuration to a file which you can then customize.

### Executables

The `executable` parameter for all toolkits can be either the executable
name (if it is present on the PATH), or the full path to the executable.

Examples:

``` {.yaml}
matplotlib:
  executable: python3
```

``` {.yaml}
matlabplot:
  executable: "C:\Program Files\Matlab\R2019b\bin\matlab.exe"
```

### Toolkit-specific options

#### Matplotlib

-   `tight_bbox` is a boolean that determines whether to use
    `bbox_inches="tight"` or not when saving Matplotlib figures. For
    example, `tight_bbox: true`. See
    [here](https://matplotlib.org/api/_as_gen/matplotlib.pyplot.savefig.html)
    for details.
-   `transparent` is a boolean that determines whether to make
    Matplotlib figure background transparent or not. This is useful, for
    example, for displaying a plot on top of a colored background on a
    web page. High-resolution figures are not affected. For example,
    `transparent: true`.

Detailed usage
--------------

`pandoc-plot` is a command line executable with a few functions. You can
take a look at the help using the `-h`/`--help` flag:

``` {.bash}
pandoc-plot - generate figures directly in documents using your plotting toolkit
of choice.

Usage: pandoc-plot.exe ([-v|--version] | [--full-version] | [-m|--manual] |
                       [-t|--toolkits]) [COMMAND] [AST]
  This pandoc filter generates plots from code blocks using a multitude of
  possible renderers. This allows to keep documentation and figures in perfect
  synchronicity.

Available options:
  -v,--version             Show version number and exit.
  --full-version           Show full version information and exit.
  -m,--manual              Open the manual page in the default web browser and
                           exit.
  -t,--toolkits            Show information on toolkits and exit. Executables
                           from the configuration file will be used, if a
                           '.pandoc-plot.yml' file is in the current directory.
  -h,--help                Show this help text

Available commands:
  clean                    Clean output directories where figures from FILE
                           might be stored. WARNING: All files in those
                           directories will be deleted.
  write-example-config     Write example configuration to a file.

More information can be found via the manual (pandoc-plot --manual) or the repository README, located at
    https://github.com/LaurentRDC/pandoc-plot

```

### As a filter

The most common use for `pandoc-plot` is as a pandoc filter, in which
case it should be called without arguments. For example:

``` {.bash}
pandoc --filter pandoc-plot -i input.md -o output.html
```

If `pandoc-plot` fails to render a code block into a figure, the
filtering will not stop. Your code blocks will stay unchanged.

You can chain other filters with it (e.g.,
[`pandoc-crossref`](https://github.com/lierdakil/pandoc-crossref)) like
so:

``` {.bash}
pandoc --filter pandoc-plot --filter pandoc-crossref -i input.md -o output.html
```

### Cleaning output

Figures produced by `pandoc-plot` can be placed in a few different
locations. You can set a default location in the
[Configuration](#configuration), but you can also re-direct specific
figures in other directories if you use the `directory=...` argument in
code blocks. These figures will build up over time. You can use the
`clean` command to scan documents and delete the associated
`pandoc-plot` output files. For example, to delete the figures generated
from the `input.md` file:

``` {.bash}
pandoc-plot clean input.md
```

This sill remove all directories where a figure *could* have been
placed. **WARNING**: all files will be removed.

### Configuration template

Because `pandoc-plot` supports a few toolkits, there are a lot of
configuration options. Don't start from scratch! The
`write-example-config` command will create a file for you, which you can
then modify:

``` {.bash}
pandoc-plot write-example-config
```

You will need to re-name the file to `.pandoc-ploy.yml` to be able to
use it, so don't worry about overwriting your own configuration.

### As a Haskell library

To include the functionality of `pandoc-plot` in a Haskell package, you
can use the `makePlot` function (for single blocks) or `plotTransform`
function (for entire documents). [Take a look at the documentation on
Hackage](https://hackage.haskell.org/package/pandoc-plot).

#### Usage with Hakyll

In case you want to use the filter with your own Hakyll setup, you can
use a transform function that works on entire documents:

``` {.haskell}
import Text.Pandoc.Filter.Plot (plotTransform, defaultConfiguration)

import Hakyll

-- Unsafe compiler is required because of the interaction
-- in IO (i.e. running an external script).
makePlotPandocCompiler :: Compiler (Item String)
makePlotPandocCompiler = 
  pandocCompilerWithTransformM
    defaultHakyllReaderOptions
    defaultHakyllWriterOptions
    (unsafeCompiler . plotTransform defaultConfiguration)
```

Installation
------------

### Binaries and Installers

Windows, Linux, and Mac OS binaries are available on the [GitHub release
page](https://github.com/LaurentRDC/pandoc-plot/releases). There are
also Windows installers.

### conda

Like `pandoc`, `pandoc-plot` is available as a package installable with
[`conda`](https://docs.conda.io/en/latest/). [Click here to see the
package page](https://anaconda.org/conda-forge/pandoc-plot).

To install in the current environment:

``` {.sh}
conda install -c conda-forge pandoc-plot
```

### From Hackage/Stackage

`pandoc-plot` is available on
[Hackage](http://hackage.haskell.org/package/pandoc-plot) and
[Stackage](https://www.stackage.org/nightly/package/pandoc-plot). Using
the [`cabal-install`](https://www.haskell.org/cabal/) tool:

``` {.bash}
cabal update
cabal install pandoc-plot
```

or

``` {.bash}
stack update
stack install pandoc-plot
```

### From source

Building from source can be done using
[`stack`](https://docs.haskellstack.org/en/stable/README/) or
[`cabal`](https://www.haskell.org/cabal/):

``` {.bash}
git clone https://github.com/LaurentRDC/pandoc-plot
cd pandoc-plot
stack install # Alternatively, `cabal install`
```

Warning
-------

Do not run this filter on unknown documents. There is nothing in
`pandoc-plot` that can stop a script from performing **evil actions**.
