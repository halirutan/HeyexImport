Mathematica Import for HEYEX Raw Data (Heidelberg Spectralis OCT)
=======================

This is a *Mathematica* package which provides functionality to access the following content of HEYEX Raw files:
- The file header which contains meta data like patient ID's, scan sizes, etc.
- The scanned volume data as a numerical array
- The scanned volume as `Image3D`
- Slices or the whole volume as a list of `Image`s
- The *scanning laser ophthalmoscopy* (SLO) image
- The segmentation data for different retina layers (ILM, RPE) when provided in the HEYEX Raw file

##Installation

Download or clone the repository and copy the *inner* `HeyexImport` directoy with all content:

    HeyexImport
    ├── HeyexImport.m
    └── Kernel
        └── init.m

into your *Mathematica* search-path. A good place is your local *Mathematica* user directoy which can be extracted with the following code:

    FileNameJoin[{$UserBaseDirectory, "Applications"}]

After that, you should be able to load the package with

    <<HeyexImport`

Note that the package does only provide one function `HeyexEyePosition`. All the import functionality is directly incorporated into the
normal `Import` built-in function.

##Usage

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



##Tricks

###Import only a single image slice

     Import[file, {"Heyex", "Images", n}]

where `n` is an integer and `1 <= n <= Number of BScans`.

###Working with segmentation data

Getting the matrix of all *inner limiting membranes*

     "ILM" /. Import[file, {"Heyex", "SegmentationData"}]

Note that the segmentation data are measured distances *from above*. Therefore, they are upside down regarding the usual point of view in images:

    ListPlot["ILM" /. Import[file, {"Heyex", "SegmentationData"}],
      PlotRange -> {Automatic, {-100, 500}}]
    Import[file, {"Heyex", "Images", 1}]

![plot](http://i.stack.imgur.com/ZS1oL.png) ![OCT image](http://i.stack.imgur.com/3WBho.png)

Additionally, the segmentation data usually contains very large numbers at the border which indicate that the layers could not be detected.
Therefore, it is often necessary to filter the segmentation data before working with it.

###Extracting the eye position

That's currently the only additional function that the package provides. The usage is simple:

    HeyexEyePosition[file]

###Sub-specifying meta-data directly

When you know which meta-data from the file header you want, you can easily provide this directly in the `Import` call:

    Import[file, {"Heyex", "FileHeader", "NumBScans"}]

To specify several just use a list:

    Import[file, {"Heyex", "FileHeader", {"SizeX", "NumBScans", "SizeXSlo"}}]