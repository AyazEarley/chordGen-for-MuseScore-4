import MuseScore 3.0
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import FileIO 3.0

MuseScore {
    version: "1.0"
    description: qsTr("This plugin takes text as input, and encodes it in the score as morse code")
    pluginType: "dialog"
    menuPath: "Plugins.UI"
    title: "chordGen Plugin"
    thumbnailName: "morseImage.png"
    width: 600
    height: 150
    Dialog {
        id: mainDialog
        width: 600
        height: 150
        visible: true

        // This makes the entire background white
        background: Rectangle {
            color: "#323c4d"
            radius: 0
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Label {
                text: "Chord Generator 1.0"
                font.family: "Corbel"
                color: "white"
                font.pixelSize: 40
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignHCenter 
                ComboBox {
                    id: keyBox; model: ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B","C"] 
                }
                ComboBox { 
                    id: modeBox; model: ["Major", "Minor"] 
                }
                ComboBox {
                    id: lengthBox; model: ["Short","Medium","Long"] 
                }
                Button {
                    text: "Generate Chords"; 
                    onClicked: {

                        var cursor = curScore.newCursor();
                        cursor.rewind(1);

                        var seg = cursor.segment;
                        if (!seg) return;

                        curScore.startCmd();

                        cursor.setDuration(1, 8);
                        cursor.addNote(65);

                        curScore.endCmd();
                    }
                }
            }
        }
        function generate(key, mode, length){
            var realLen = 0;
            switch(length){
                case "Short":
                    realLen = 4;
                    break;
                case "Medium":
                    realLen = 6;
                    break;
                case "Long":
                    realLen = 8;
                    break;
            }
            var chords = getChords(mode, realLen);

            var midiTableMajor = {
                'I' : [48, 52, 55,],
                'I6' : [42, 55, 60, ],

                'ii' : [50, 53, 57],
                'ii6' : [53, 57, 62],

                'iii' : [52, 55, 57],
                'iii64' : [47, 52, 55],

                'IV' : [53, 57, 60],
                'IV6' : [45, 48, 53],

                'V6' : [47, 50, 55],
                'V' : [55, 59, 62],

                'vi' : [45, 48, 52],

                'viio6' : [50, 53, 59]
            }


            if (!curScore) {
                console.log("No score open!");
                return;
            }

            var cursor = curScore.newCursor();
            cursor.rewind(1); // go to first segment of first measure
            cursor.staffIdx = 0; // top staff

            var seg = cursor.segment;
            if (!seg) return;

            curScore.startCmd();

            cursor.setDuration(1, 8);
            cursor.addNote(60);
            console.log("Added dot");

            curScore.endCmd();

        }
        function getChords(mode, length) {
            var majorTable = {
            'I' : {"V6": 15, "V64 I6": 5, "V": 10,
                "IV": 20, "IV64 I" : 5, "IV6": 5,
                    "ii" : 10, "ii6" : 10,
                    "vi" : 10,
                    "iii" : 3, "iii64 IV6": 1, "iii64 vi" : 1},
            'I6' : {"V64 I" : 5, "V": 10,
                    "IV": 45,
                    "ii": 10, "ii6": 25,
                    "vii06 I": 5},
            
            'ii' : {"V" : 90, "I6 ii6" : 10},
            'ii6' : {"V" : 90, "I6 ii" : 10},

            'iii': {"IV" : 80, "vi" : 20},

            'IV' : {"I" : 20, "I6" : 20, "V" : 40, "ii" : 15, "ii6" : 5},
            'IV6' : {"I" : 10, "V" : 40, "V6": 30, "ii6" : 15, "ii": 5},

            'V' : {"I" : 80, "I6": 10, "vi" : 10},
            'V6' : {"I" : 100},

            'vi' : {"IV" : 30, "ii" : 50, "I": 5, "V": 15 }
            }

            var minorTable = {
            'i' : {"V6": 15, "V64 i6": 5, "V": 10,
                "iv": 20, "iv64 i" : 5, "iv6": 5,
                    "iio" : 10, "iio6" : 10,
                    "VI" : 5,
                    "VII" : 5,
                    "v6" : 5},
            'i6' : {"V64 i" : 5, "V": 10,
                    "iv": 45,
                    "iio": 10, "iio6": 25,
                    "vii06 i": 5},
            
            'iio' : {"V" : 90, "i6 iio6" : 10},
            'iio6' : {"V" : 90, "i6 iio" : 10},

            'III': {"iv" : 80, "iio6" : 20},

            'iv' : {"i" : 20, "i6" : 20, "V" : 40, "iio" : 15, "iio6" : 5},
            'iv6' : {"i" : 10, "V" : 40, "V6": 30, "iio6" : 15, "iio": 5},

            'V' : {"i" : 80, "i6": 10, "VI" : 10},
            'V6' : {"i" : 100},

            'VI' : {"iv" : 30, "iio" : 50, "i": 5, "V": 15 },

            'v6' : {"iv6" : 80, "VI" : 20},
            'VII' : {"III" : 90, "VI" : 10}
            }

            if(mode === "Major"){
                var useTable = majorTable;
                var first = "I";
            }
            else{
                var useTable = minorTable;
                var first = "i";
            }

            function weightedChoice(weightMap) {
                const entries = Object.entries(weightMap);
                
                const totalWeight = entries.reduce(
                    (sum, [, weight]) => sum + weight,
                    0
                );

                let r = Math.random() * totalWeight;

                for (const [key, weight] of entries) {
                    r -= weight;
                    if (r <= 0) {
                        return key;
                    }
                }
            }

            var chords = first
            for(let i = 0; i <length; i++){
                var previous = chords.split(" ").pop();
                var distribution = useTable[previous];
                var next = weightedChoice(distribution);
                chords += " " + next;
            }

            while (true) {
                const previous = chords.split(" ").pop();
                if (previous === "I" || previous === "i"){
                    break;
                } 
                

                const next = weightedChoice(useTable[previous]);
                chords += " " + next;
            }
        
            return chords;
        }
    }
    
}
