//
//  main.swift
//  PDBtoUSD
//
//  Created by Jana on 10/24/23.

import Foundation

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

struct Atom {
    var type: String
    var x: Float
    var y: Float
    var z: Float
}

var atoms: Array<Atom> = []

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
let fileName: String = "protein.pdb"
var file = ""

let dir = URL(fileURLWithPath: "/Users/jana/LocalDesktop/PDBtoUSD")
let fileURL = dir.appending(path: fileName)


func write(text: String, to fileNamed: String, folder: String = "SavedFiles") {
    guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return }
    guard let writePath = NSURL(fileURLWithPath: path).appendingPathComponent(folder) else { return }
    try? FileManager.default.createDirectory(atPath: writePath.path, withIntermediateDirectories: true)
    let file = writePath.appendingPathComponent(fileNamed + ".txt")
    try? text.write(to: file, atomically: false, encoding: String.Encoding.utf8)
}

var strings: [String] = []
var newLine: [Float] = []
var atom: String = ""

////reading
do {
    file = try String(contentsOf: fileURL, encoding: .utf8)
    let lines = file.split(whereSeparator: \.isNewline)
    
    for line in lines {
        if (line.prefix(4) == "ATOM") {
            
            strings = line.components(separatedBy: .whitespaces).filter({ s in s != "" })
            atom = strings[strings.count - 1]
            /// convert values to floats
            newLine = strings.map{
                ($0 as NSString).floatValue
            }
            atoms.append(.init(
                type: atom,
                x: newLine[6],
                y: newLine[7],
                z: newLine[8]
            ))
        }
    }
} catch {
    print("The file reading failed with error: \(error)")
}

var Body: String =
"""
#usda 1.0
(
upAxis = "Z"
)

class Xform "O"
{
    def Sphere "Mesh" (
        active = true
    )
    {
        double radius = 5
       color3f[] primvars:displayColor = [(1.0, 0.0, 0.0)]
    }
}

class Xform "Cl"
{
    def Sphere "Mesh" (
        active = true
    )
    {
        double radius = 5
       color3f[] primvars:displayColor = [(0.0, 1.0, 0.0)]
    }
}

class Xform "N"
{
    def Sphere "Mesh" (
    active = true
    prepend apiSchemas = ["MaterialBindingAPI"]
    )
    {
       double radius = 5
       color3f[] primvars:displayColor = [(0.0, 0.0, 1.0)]
    }
}

class Xform "C"
{
    def Sphere "Mesh" (
        active = true
    )
    {
        double radius = 5
       color3f[] primvars:displayColor = [(0.5, 0.5, 0.5)]
    }
}

class Xform "S"
{
    def Sphere "Mesh" (
        active = true
    )
    {
        double radius = 5
       color3f[] primvars:displayColor = [(1.0, 1.0, 0.0)]
    }
}

class Xform "P"
{
    def Sphere "Mesh" (
        active = true
    )
    {
        double radius = 5
       color3f[] primvars:displayColor = [(1.0, 0.5, 0.0)]
    }
}

class Xform "Shiny"
{
def Sphere "Mesh" (
    active = true
    prepend apiSchemas = ["MaterialBindingAPI"]
)
{
    rel material:binding = </C/Mesh/DefaultMaterial>
    double radius = 5

    def Material "DefaultMaterial"
    {
        token outputs:mtlx:surface
        token outputs:realitykit:vertex
        prepend token outputs:surface.connect = </C/Mesh/DefaultMaterial/DefaultSurfaceShader.outputs:surface>
        float2 ui:nodegraph:realitykit:subgraphOutputs:pos = (0, 109.5)
        float2 ui:nodegraph:realitykit:subgraphOutputs:size = (182, 99)

        def Shader "DefaultSurfaceShader"
        {
            uniform token info:id = "UsdPreviewSurface"
            float inputs:clearcoat = 0
            float inputs:clearcoatRoughness = 0
            color3f inputs:diffuseColor = (0.9856873, 1, 0.9883573) (
                colorSpace = "srgb_texture"
            )
            float inputs:ior = 0
            float inputs:metallic = 1
            float inputs:occlusion = 1
            float inputs:roughness = 0.5
            token outputs:surface
        }
    }
}
}

def Xform "Atoms" (
)
{
""";

var ith: Int = 0
var atomType: String = ""
var scale: Float = 0.0

for atom in atoms {
    if atom.type == "O" {
        // Oxygen = Red
        atomType = "</O>"
        scale = 0.1
    }
    if atom.type == "Cl" {
        // Chlorine = Green
        atomType = "</Cl>"
        scale = 0.25
    }
    if atom.type == "N" {
        // Nitrogen = Blue
        atomType = "</N>"
        scale = 0.15
    }
    if atom.type == "C" {
        // Carbon = Gray
        atomType = "</C>"
        scale = 0.25
    }
    if atom.type == "S" {
        // Sulphur = Yellow
        atomType = "</S>"
        scale = 0.4
    }
    if atom.type == "P" {
        // Phosphorus = Orange
        atomType = "</P>"
        scale = 0.45
    }
    Body += """
    \ndef "Ball_\(ith)" (
        instanceable = true
        inherits = \(atomType)
    )
    {
        float3 xformOp:scale = (\(scale), \(scale), \(scale))
        double3 xformOp:translate = (\(atom.x), \(atom.y), \(atom.z))
        uniform token[] xformOpOrder = ["xformOp:translate", "xformOp:scale"]
    }
"""
    ith += 1
}
Body += "\n}"

// save file to Documents directory
func saveFile(with name: String) throws {
     let fileManager = FileManager.default
     let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
     let fileURL = documentDirectory.appendingPathComponent(name)
     try? Body.write(to: fileURL, atomically: false, encoding: .utf8)
 }

let exportArray = fileName.components(separatedBy: ".")
let exportName: String = exportArray[0]
let exportFileName = exportName + ".usd"
try saveFile(with: exportFileName)
 

