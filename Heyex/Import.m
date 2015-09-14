(* Mathematica Source File  *)
(* Created by Mathematica Plugin for IntelliJ IDEA *)
(* :Title: Importer for the RAW data-format of the Heidelberg Eye Explorer (known as HEYEX) *)
(* :Author: Patrick Scheibe pscheibe@trm.uni-leipzig.de *)
(* :Mathematica Version: 9+ *)
(* :Copyright: Patrick Scheibe, 2013-2015 *)

(* :Discussion: This package registers a new importer which can load the RAW data-format exported by a
                Heidelberg Spectralis OCT. The import-functionality can access different information contained
                in a file:
                1. The file header which contains meta data like when the patient was scanned etc
                2. The scanned volume data
                3. Images which represent slices of the scanned volume
                4. The Scanning laser ophthalmoscopy (SLO) image which is taken with every scanned patient
                5. The segmentation data for different retina layers provided by the software

*)

(* :Keywords: Import, Heyex, OCT, Spectralis, Heidelberg Engineering *)

Begin["System`Convert`HeyexDump`"];

ImportExport`RegisterImport[
    "Heyex" ,
    {
        "FileHeader" :> importHeader,
        { "Data" , n_Integer} :> (importData[n][##]&),
        "Data" :> importData,
        { "Images" , n_Integer} :> (importImages[n][##]&),
        "Images" :> importImages,
        "SLOImage" :> importSLOImage,
        "SegmentationData" :> importSegmentation,
        { "SegmentationData" , n_Integer} :> (importSegmentation[n][##]&),
        "DataSize" :> importDataSize,
        "EyePosition" :> (HeyexEyePosition[importHeader[##]]&),
        importData
    },

    {
        "Image3D" :> (Image3D["Data" /. #1]&)
    },

    "AvailableElements" -> {"FileHeader", "Data", "DataSize", "Images", "SLOImage", "SegmentationData", "EyePosition", "Image3D"}
];

Begin["System`Convert`HeyexDump`"];
