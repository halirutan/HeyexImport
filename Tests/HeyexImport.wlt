
AppendTo[$Path, $projectDir];
Get["HeyexImport`"];
{valid, invalid} = FileNameJoin[{$projectDir, "Tests", #}] & /@ {"valid.vol", "invalid.vol"};


BeginTestSection["HeyexImport"]

VerificationTest[(* 1 *)
  Import[valid, List["Heyex", "Elements"]]
  ,
  List["Data", "DataSize", "FileHeader", "Image3D", "Images", "SegmentationData", "SLOImage"],
  TestID -> "My ID"
]

VerificationTest[(* 2 *)
  Import[valid, List["Heyex", "FileHeader", List["Version", "SizeX", "NumBScans", "SizeZ"]]]
  ,
  List["HSF-OCT-103", 768, 1, 496],
  TestID -> "My ID"
]

VerificationTest[(* 3 *)
  SameQ[Dimensions[Import[valid, List["Heyex", "Data"]]], Import[valid, List["Heyex", "DataSize"]]]
  ,
  True
]

VerificationTest[(* 4 *)
  Head[Import[valid, List["Heyex", "SLOImage"]]]
  ,
  Image
]

VerificationTest[(* 5 *)
  Import[invalid, List["Heyex", "DataSize"]]
  ,
  $Failed
  ,
  {HeyexImport::wrongHdr}
]

VerificationTest[(* 6 *)
  Import[invalid, List["Heyex", "FileHeader"]]
  ,
  $Failed
  ,
  {HeyexImport::wrongHdr}
]

EndTestSection[]
