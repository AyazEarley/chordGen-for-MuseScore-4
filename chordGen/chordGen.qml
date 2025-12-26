import MuseScore 3.0
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import FileIO 3.0

MuseScore {
    version: "1.0"
    description: qsTr("Chord Generator")
    pluginType: "dialog"
    menuPath: "Plugins.UI"
    title: "Chord Generator Plugin"
    thumbnailName: "icon.png"
    width: 800
    height: 150

    Dialog {
        id: mainDialog
        width: 800
        height: 150
        visible: true
        
        background: Rectangle {
            color: "#323c4d"
            radius: 0
        }

        function generate(key, mode, length) {
            var realLen = 0;
            switch(length) {
                case "Short": realLen = 4; break;
                case "Medium": realLen = 6; break;
                case "Long": realLen = 8; break;
            }
            return getChords(mode, realLen);
        }

        //markov chain table
        function getChords(mode, length) {
            var majorTable = {
                'I' : {"V6": 15, "V64 I6": 5, "V": 10, "IV": 20, "IV64 I": 5, "IV6": 5, "ii": 10, "ii6": 10, "vi": 10, "iii": 3, "iii64 IV6":1, "iii64 vi":1},
                'I6': {"V64 I":5, "V":10, "IV":45, "ii":10, "ii6":25, "viio6 I":5},

                'ii': {"V":90, "I6 ii6":10},
                'ii6': {"V":90, "I6 ii":10},

                'iii': {"IV":80, "vi":20},

                'IV': {"I":20, "I6":20, "V":40, "ii":15, "ii6":5},
                'IV6': {"I":10, "V":40, "V6":30, "ii6":15, "ii":5},
                
                'V': {"I":80, "I6":10, "vi":10},
                'V6': {"I":100},
                'vi': {"IV":30, "ii":50, "I":5, "V":15}
            };

            var minorTable = {
                'i': {"V6":15,"V64 i6":5,"V":10,"iv":20,"iv64 i":5,"iv6":5,"iio":10,"iio6":10,"VI":5,"VII":5,"v6":5},
                'i6': {"V64 i":5,"V":10,"iv":45,"iio":10,"iio6":25,"viio6 i":5},
                'iio': {"V":90,"i6 iio6":10},

                'iio6': {"V":90,"i6 iio":10},

                'III': {"iv":80,"iio6":20},

                'iv': {"i":20,"i6":20,"V":40,"iio":15,"iio6":5},
                'iv6': {"i":10,"V":40,"V6":30,"iio6":15,"iio":5},

                'V': {"i":80,"i6":10,"VI":10},
                'V6': {"i":100},
                'VI': {"iv":30,"iio":50,"i":5,"V":15},

                'v6': {"iv6":80,"VI":20},

                'VII': {"III":90,"VI":10}
            };

            var useTable = (mode === "Major") ? majorTable : minorTable;
            var first = (mode === "Major") ? "I" : "i";

            //generate one token using the previous token's probability dist
            function weightedChoice(weightMap) {
                const entries = Object.entries(weightMap);
                const totalWeight = entries.reduce((sum, [, weight]) => sum + weight, 0);
                let r = Math.random() * totalWeight;
                for (const [key, weight] of entries) {
                    r -= weight;
                    if (r <= 0) return key;
                }
            }

            var chords = first;
            for (let i = 0; i < length; i++) {
                var previous = chords.split(" ").pop();
                var distribution = useTable[previous];
                var next = weightedChoice(distribution);
                chords += " " + next;
            }
            
            //ensure we end on a I/i chord
            while (true) {
                var previous = chords.split(" ").pop();
                if (previous === "I" || previous === "i") break;
                chords += " " + weightedChoice(useTable[previous]);
            }

            return chords;
        }


        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Label {
                text: "Chord Generator"
                font.family: "Corbel"
                color: "white"
                font.pixelSize: 40
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignHCenter 

                ComboBox { id: keyBox; model: ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"] }
                ComboBox { id: modeBox; model: ["Major", "Minor"] }
                ComboBox { id: lengthBox; model: ["Short","Medium","Long"] }
                ComboBox { id: durationBox; model: ["Quarter","Half","Whole"] }

                Button {
                    text: "Generate Chords"
                    onClicked: {
                        try {
                            if (!curScore) {
                                errorBox.text += "No score open!\n";
                                return;
                            }

                            var chords = mainDialog.generate(keyBox.currentText, modeBox.currentText, lengthBox.currentText);

                            //pitches of each chord
                            var midiTableMajor = {
                                'I': [60,64,67], 
                                'I6':[64,67,72],
                                'ii':[62,65,69], 
                                'ii6':[65,69,74],
                                'iii':[64,67,71], 
                                'iii6':[67,71,76],
                                'IV':[65,69,72], 
                                'IV6':[69,72,77],
                                'V':[67,71,74], 
                                'V6':[71,74,79], 
                                'V64':[74,79,83],
                                'vi':[69,72,76], 
                                'viio':[71,74,77], 
                                'viio6':[74,77,83],


                                'i':[60,63,67], 
                                'i6':[63,67,72],
                                'iio':[62,65,68], 
                                'iio6':[65,68,74],
                                'VII' : [58, 62, 65],
                                'III':[63,67,70], 
                                'III6':[67,70,75],
                                'iv':[65,68,72], 
                                'iv6':[68,72,77],
                                'V':[67,71,74], 
                                'V6':[71,74,79], 
                                'V64':[74,79,83],
                                'VI':[68,72,75], 
                                'viio':[71,74,77], 
                                'viio6':[74,77,83]
                            };


                            var chordArray = chords.trim().split(" ");
                            var cursor = curScore.newCursor();
                            cursor.rewind(1);
                            if (!cursor.segment) {
                                errorBox.text += "Cursor segment not found!\n";
                                return;
                            }
                            var transpose = keyBox.currentIndex;
                            curScore.startCmd();

                            var durIndex = durationBox.currentIndex;
                            var duration = 4;
                            switch(durIndex){
                                case 0:
                                    duration = 4;
                                    break;
                                case 1:
                                    duration = 2;
                                    break;
                                case 2:
                                    duration = 1;
                                    break;
                            }
                            cursor.setDuration(1,duration);
                            
                            for (var chord of chordArray) {
                                var pitches = midiTableMajor[chord];
                                if (!pitches) {
                                    errorBox.text += "Unknown chord: " + chord + "\n";
                                    continue;
                                }
                                cursor.addNote(pitches[0] + transpose, false);
                                for (var i = 1; i < pitches.length; i++)
                                    cursor.addNote(pitches[i] + transpose, true);
                            }
                            curScore.endCmd();

                            //errorBox.text += "Generated chords: " + chords + "\n";

                        } catch(e) {
                            //errorBox.text += "Error: " + e.message + "\n";
                        }
                    }
                }
            }
            //previously used for bug testing. Incredibly useful to print errors and console messages to a textbox on the plugin
            /*
            TextArea {
                id: errorBox
                readOnly: true
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.fillHeight: true
                font.pixelSize: 14
                color: "white"
                background: Rectangle { color: "#323c4d"; radius: 5 }
            }
            */
        }
    }
}
