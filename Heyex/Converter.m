(* Mathematica Source File  *)
(* Created by Mathematica Plugin for IntelliJ IDEA *)
(* :Author: patrick *)
(* :Date: 2015-09-14 *)

Begin["System`Convert`HeyexDump`"];

HeyexImport::wrongHdr = "Error importing OCT data. Broken/Wrong file?";
HeyexImport::range = "The specified image number is invalid.";

If[Quiet[Check[TrueQ[Compile[{}, 0, CompilationTarget -> "C"][] == 0], False]],
    $compileTarget = CompilationTarget -> "C",
    $compileTarget = CompilationTarget -> "MVM"
];


(*
    Helper function which reads data from a stream. This is
    only a unification so I can map the read function over a
    list.
*)
read[{id_String, type_String}, str_] :=
        id -> BinaryRead[str, type];
read[{type_String, n_Integer}, str_] := BinaryReadList[str, type, n];
read[{id_String, {type_String, n_Integer}}, str_] := id -> BinaryReadList[str, type, n];
(*
    Note that when reading bytes explicitly I convert them to
    a string and remove any zeroes at the end.
*)
read[{id_String, { "Byte" , n_Integer}}, str_] :=
        id -> StringJoin[
            FromCharacterCode /@ (Rest[
                NestList[BinaryRead[str, "Byte" ] &, Null,
                    n]] /. {chars___Integer, Longest[0 ...]} :> {chars})];

(*
    The layout of a file exported with "Raw Export"

    *****************
    *   File Header *
    *****************
    *   SLO Image   *
    *****************
    *   B-Scan #0   *
    *****************
    *   .....       *
    *****************
    *   B-Scan #n-1 *
    *****************
*)

With[{i = "Integer32", f = "Real32", d = "Real64", b = "Byte"},

    $fileHeaderInfo = Transpose[{
        {
            "Version" , "SizeX" , "NumBScans" , "SizeZ" , "ScaleX" , "Distance" ,
            "ScaleZ" , "SizeXSlo" , "SizeYSlo" , "ScaleXSlo" , "ScaleYSlo" ,
            "FieldSizeSlo" , "ScanFocus" , "ScanPosition" , "ExamTime" ,
            "ScanPattern" , "BScanHdrSize" , "ID" , "ReferenceID" , "PID" ,
            "PatientID" , "Padding" , "DOB" , "VID" , "VisitID" , "VisitDate" ,
            "Spare"
        },
        {
            {b, 12}, i, i, i, d, d, d, i, i, d, d, i, d, {b, 4}, {i, 2}, i, i,
            {b, 16}, {b, 16}, i, {b, 21}, {b, 3}, d, i, {b, 24}, d, {b, 1840}
        }
    }];

    $bScanHeaderInfo = Transpose[{
        {
            "Version" , "BScanHdrSize" , "StartX" , "StartY" , "EndX" , "EndY" ,
            "NumSeg" , "OffSeg" , "Quality" , "Spare"
        },
        {{b, 12}, i, d, d, d, d, i, i, f, {b, 196}}
    }];
];


isHeyexRawFormat[{"Version" -> version_String, "SizeX" -> _Integer, "NumBScans" -> _Integer, _Rule..}] /; StringMatchQ[version, "HSF-OCT" ~~ __] := True ;
isHeyexRawFormat[___] := False;

readFileHeader[str_InputStream] := With[{hdr = Quiet[read[#, str]] & /@ $fileHeaderInfo},
    hdr /; TrueQ[isHeyexRawFormat[hdr]]
];
(* Note the Throw here! Usually, you should never do this, because I never catch this myself and it would be possible *)
(* that the throw ends in the users face. On the other hand, the Import framework seems to catch this and it is an easy *)
(* way to return from deep in the code without carrying the fail through each sub-function. *)
readFileHeader[___] := (Message[HeyexImport::wrongHdr]; Throw[$Failed]);


(*  Reads the camera image of the retina. Note that you must have the
    information from the fileheader and you must be at the right position
    of the file stream for this.*)
readSLOImage[str_InputStream, fileHdr : {(_String -> _) ..}] :=
        Image[Partition[
            BinaryReadList[str, "Byte" , "SizeXSlo" * "SizeYSlo" /. fileHdr],
            "SizeXSlo" /. fileHdr], "Byte" ];

skipSLOImage[str_InputStream, fileHdr : {(_String -> _) ..}] :=
        Skip[str, "Byte" , "SizeXSlo" * "SizeYSlo" /. fileHdr];


(*  One single BScan consists itself again of a header and a data part *)
readBScanHeader[str_InputStream, fileHdr : {(_String -> _) ..}] :=
        Module[{i = "Integer32", f = "Real32", d = "Real64", b = "Byte",
            bScanHdr},
            bScanHdr = read[#, str] & /@ Transpose[{
                { "Version" , "BScanHdrSize" , "StartX" , "StartY" , "EndX" , "EndY" ,
                    "NumSeg" , "OffSeg" , "Quality" , "Spare" },
                {{b, 12}, i, d, d, d, d, i, i, f, {b, 196}}}
            ];
            AppendTo[bScanHdr,
                read[{ "SegArray" , { "Real32" ,
                    "NumSeg" * "SizeX" /. bScanHdr /. fileHdr}}, str]
            ];
            (*
      This is horrible slow, therefore I just skip the fillbytes

      AppendTo[bScanHdr,
       read[{"Fillbytes", {"Byte",
          "BScanHdrSize" - 256 - "NumSeg"*"SizeX"*4 /. bScanHdr /.
           fileHdr}}, str]
       ]
   *)
            Skip[str, "Byte" , "BScanHdrSize" - 256 - "NumSeg" * "SizeX" * 4 /. bScanHdr /. fileHdr];
            AppendTo[bScanHdr, "FillBytes" -> None]
        ]

skipBScanHeader[str_InputStream, fileHdr : {(_String -> _) ..}] :=
        Skip[str, "Byte" , "BScanHdrSize" /. fileHdr];

readBScanData[str_InputStream, fileHdr : {(_String -> _) ..}] :=
        Module[{},
            Developer`ToPackedArray[
                Partition[read[{ "Real32" , "SizeX" * "SizeZ" /. fileHdr}, str],
                    "SizeX" /. fileHdr]]
        ];

skipBScanData[str_InputStream, fileHdr : {(_String -> _) ..}] :=
        Skip[str, "Byte" , "SizeX" * "SizeZ" * 4 /. fileHdr];

skipBScanBlocks[str_InputStream, fileHdr : {(_String -> _) ..}, n_Integer] :=
        Skip[str, "Byte" , n * ("BScanHdrSize" + "SizeX" * "SizeZ" * 4) /. fileHdr];


importHeader[filename_String, ___] := Module[
    {str, header},
    str = OpenRead[filename, BinaryFormat -> True];
    header = readFileHeader[str];
    Close[str];
    "FileHeader" -> header
];


(* Imports the dimension of the scanned volume. *)
importDataSize[filename_String, r___] := Module[{header = importHeader[filename]},
    "DataSize" -> ({"NumBScans", "SizeZ", "SizeXSlo"} /. ("FileHeader" /. header))
]

importSLOImage[filename_String, ___] := Module[
    {str, header, slo},
    str = OpenRead[filename, BinaryFormat -> True];
    header = readFileHeader[str];
    slo = readSLOImage[str, header];
    Close[str];
    "SLOImage" -> slo
]

importData[filename_String, ___] := Module[
    {str, header, nx, n, data},
    str = OpenRead[filename, BinaryFormat -> True];
    header = readFileHeader[str];
    {nx, n} = { "SizeX" , "SizeX" * "SizeZ"} /. header;
    skipSLOImage[str, header];
    data = Table[
        skipBScanHeader[str, header];
        Partition[read[{ "Real32" , n}, str], nx],
        {"NumBScans" /. header}
    ];
    Close[str];
    "Data" -> Developer`ToPackedArray[data]
];

importData[num_Integer][filename_String, ___] := Module[
    {str, header, nx, n, data, imgCount},
    str = OpenRead[filename, BinaryFormat -> True];
    header = readFileHeader[str];
    {nx, n, imgCount} = { "SizeX" , "SizeX" * "SizeZ", "NumBScans"} /. header;
    If[TrueQ[num < 1 || num > imgCount],
        Message[HeyexImport::range];
        Throw[$Failed]
    ];
    skipSLOImage[str, header];
    skipBScanBlocks[str, header, Max[Min["NumBScans" /. header, num - 1], 0] ];
    skipBScanHeader[str, header];
    data = Partition[read[{ "Real32" , n}, str], nx];
    Close[str];
    {"Data" -> {num -> Developer`ToPackedArray[data]}}
];

(*
    As suggested in the Heidelberg OCT Manual the importer will adjust
    the graylevels when importing images. Since this is very time-consuming
    for the whole scanned volume, I use an optimized version of this function.
*)
With[{$compileTarget = $compileTarget}, $adjustGraylevelFunc := ($adjustGraylevelFunc = Compile[{{values, _Real, 2}},
    Map[Floor[255.0 * Min[Max[0.0, #], 1.0]^(0.25) + 0.5] &, values, {2}],
    RuntimeAttributes -> {Listable},
    Parallelization -> True,
    RuntimeOptions -> "Speed",
    $compileTarget
])];

importImages[filename_String, ___] := Module[
    {data},
    data = "Data" /. importData[filename];
    "Images" -> (Image[#, "Byte" ]& /@ $adjustGraylevelFunc[data])
]

importImages[imageNumber_Integer][filename_String, ___] := Module[
    {data},
    data = {imageNumber /. ("Data" /. importData[imageNumber][filename])};
    {"Images" -> {imageNumber -> (Image[#, "Byte" ]& @@ $adjustGraylevelFunc[data])}}
];

importSegmentation[filename_String, ___] := Module[
    {str, header, data, currentHeader},
    str = OpenRead[filename, BinaryFormat -> True];
    header = readFileHeader[str];
    skipSLOImage[str, header];
    data = Table[
        currentHeader = readBScanHeader[str, header];
        skipBScanData[str, header];
        currentHeader, {"NumBScans" /. header}
    ];
    Close[str];
    (*
      The BScanHeaderData contain the segmentation vectors as a single list
      of numbers. Before returning the result, I check how many segmentations
      there are inside the BScan an I transform the segmentation value list
      into separate vectors and call them "ILM", "RPE" and "NFL" like described
      in the manual
      *)
    "SegmentationData" -> Function[{bhdr},
        Block[{numVecs = "NumSeg" /. bhdr, vecNames, nx = "SizeX" /. header},
            If[numVecs > 0,
                vecNames = Take[{ "ILM" , "RPE" , "NFL" }, numVecs];
                bhdr /. ("SegArray" -> vec_) :> Sequence @@ (Rule @@@ Transpose[{vecNames, Partition[vec, nx]} ]),
                bhdr
            ]
        ]] /@ data
];

importSegmentation[num_Integer][filename_String, ___] := Module[
    {str, header, bhdr},
    str = OpenRead[filename, BinaryFormat -> True];
    header = readFileHeader[str];
    skipSLOImage[str, header];
    skipBScanBlocks[str, header, Max[Min["NumBScans" /. header, num - 1], 0] ];
    bhdr = readBScanHeader[str, header];
    Close[str];
    (* See doc above *)
    {"SegmentationData" -> {num -> Block[
        {numVecs = "NumSeg" /. bhdr, vecNames, nx = "SizeX" /. header},
        If[ numVecs > 0,
            vecNames = Take[{ "ILM" , "RPE" , "NFL" }, numVecs];
            bhdr /. ("SegArray" -> vec_) :> Sequence @@ (Rule @@@ Transpose[{vecNames, Partition[vec, nx]} ]),
            bhdr
        ]
    ]
    }}
];

(* Extracts which eye was scanned. This is stored in the header of the file *)
(* OD stands for oculus dexter which is latin for "right eye" and OS stands
   for oculus sinister which is latin for "left eye" *)
HeyexEyePosition[header_] := Module[{position},
    Check[
        position = "ScanPosition" /. header;
        Switch[
            position,
            "OD" ,
            Right,
            "OS" ,
            Left,
            _,
            $Failed
        ],
        $Failed
    ]
];

End[];
