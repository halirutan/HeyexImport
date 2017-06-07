Mathematica Import for HEYEX Raw Data
=======================
<img src="http://i.imgur.com/SL2U0qU.png" align="right" vspace="10" hspace="20" alt="Text?">


This is a *Mathematica* package to access HEYEX Raw files which can e.g. created from Optical Coherence Tomography scans of [*Heidelberg Spectralis* products](http://www.heidelbergengineering.com/us/products/spectralis-models/).

The package incorporates its functionality directly into the [`Import`-framework of *Mathematica*](http://reference.wolfram.com/language/ref/Import.html). Therefore, Heyex Raw files can be loaded by calling `Import` as specified in the [Usage section](#Usage).

Various information of the Heyex files can be accessed:

- The file header which contains meta data like patient ID's, scan sizes, etc.
- The scanned volume data as a numerical array
- The scanned volume as [`Image3D`](http://reference.wolfram.com/language/ref/Image3D.html)
- Slices or the whole volume as a list of [`Images`](http://reference.wolfram.com/language/ref/Image.html)
- The [*scanning laser ophthalmoscopy* (SLO)](http://en.wikipedia.org/wiki/Scanning_laser_ophthalmoscopy) image
- The segmentation data for different retina layers ([ILM][ilm], [RPE](rpe)) when provided in the HEYEX Raw file

[ilm]: http://en.wikipedia.org/wiki/Inner_limiting_membrane
[rpe]: http://en.wikipedia.org/wiki/Retinal_pigment_epithelium

## ![Install Icon](http://i.imgur.com/ayLRwo3.png) Installation

[Download](https://github.com/halirutan/HeyexImport/archive/master.zip) or clone the repository and copy the *inner* `HeyexImport` directoy with all content:

    HeyexImport
    ├── HeyexImport.m
    └── Kernel
        └── init.m

into your *Mathematica* search-path. A good place is your local *Mathematica* user directoy which can be extracted with the following code:

    FileNameJoin[{$UserBaseDirectory, "Applications"}]

After that, you should be able to load the package with

    <<HeyexImport`

Note that the package does only provide one function `HeyexEyePosition`. All the import functionality is directly incorporated into the normal `Import` built-in function.

## ![Usage Icon](http://i.imgur.com/iZbiTUl.png) Usage

The [`Tests` directory of this repository](https://github.com/halirutan/HeyexImport/tree/master/Tests) contains a test scan that can be used.
Please adapt the `file` directory and note that the test-scan has only one slice:

    file = "path/to/download/HeyexImport/Tests/valid.vol";

In general, you only have to specify `"Heyex"` when calling import. A plain call to

    Import[file, "Heyex"]

will return the scanned volume in the form `"Data"-> volume`. Usually, you should use sub-specifiers to import specific content.
To get a list of all possible import specifiers use

    Import[file, {"Heyex", "Elements"}]

The returned list has the following entries:

- `"Data"`: the scanned volume as 3d matrix
- `"DataSize"`: the dimension of the volume. This is a fast operation since it does **not** load the volume! Therefore, it is especially
much faster than calling `Dimensions[Import[file,{"Heyex","Data"}]]`!
- `"FileHeader"`: returns a list of properties like scaling factors, sizes, scan-patterns, etc.
- `"Image3D"`: returns the volume as `Image3D`.
- `"Images"`: returns the volume as list of images.
- `"SegmentationData"`: returns a list where each element is the segmentation data for one scan-line.
- `"SLOImage"`: returns the scanning laser ophthalmoscopy image.



## ![Ticks Icon](http://i.imgur.com/pyo372r.png) Tricks

### Import only a single image slice

     Import[file, {"Heyex", "Images", n}]

where `n` is an integer and `1 <= n <= Number of BScans`.

### Working with segmentation data

Getting the matrix of all *inner limiting membranes*

     "ILM" /. Import[file, {"Heyex", "SegmentationData"}]

Note that the segmentation data are measured distances *from above*. Therefore, they are upside down regarding the usual point of view in images:

    ListPlot["ILM" /. Import[file, {"Heyex", "SegmentationData"}],
      PlotRange -> {Automatic, {-100, 500}}]
    Import[file, {"Heyex", "Images", 1}]

![plot](http://i.stack.imgur.com/ZS1oL.png) ![OCT image](http://i.stack.imgur.com/3WBho.png)

Additionally, the segmentation data usually contains very large numbers at the border which indicate that the layers could not be detected.
Therefore, it is often necessary to filter the segmentation data before working with it.

### Extracting the eye position

That's currently the only additional function that the package provides. The usage is simple:

    HeyexEyePosition[file]

### Sub-specifying meta-data directly

When you know which meta-data from the file header you want, you can easily provide this directly in the `Import` call:

    Import[file, {"Heyex", "FileHeader", "NumBScans"}]

To specify several just use a list:

    Import[file, {"Heyex", "FileHeader", {"SizeX", "NumBScans", "SizeXSlo"}}]

## ![Contact Icon](http://i.imgur.com/f15dshA.png) Contact

If you find bugs or experience unusual behavior you might want to [open an issue](https://github.com/halirutan/HeyexImport/issues) and describe your problems. If you like to contact me for other reasons, please write me an email. For my mail-address please evaluate the following *Mathematica* code

    Uncompress["1:eJxTTMoPCpZmYGAoKE7OSM1MSnUoKcrVK83L1M1JzSyoykzXS0kFAM0/DBs="]

If you have more *Mathematica* question, you are probably interested in some of [my answers on Mathematica.stackexchange.com](http://mathematica.stackexchange.com/users/187/halirutan?tab=answers&sort=votes).
