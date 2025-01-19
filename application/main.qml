import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Window {
    visible: true
    width: 800
    height: 700
    title: "Life Expectancy Predictor demo"

    // Define the features with names (including units) and their options
    property var features: [
        {
            name: "GDP (USD$ per capita)",
            options: [
                { label: "Undeveloped Countries: 5000", value: 5000 },
                { label: "Lesser Developed Countries: 12000", value: 12000 },
                { label: "Developed Countries: 25000", value: 25000 },
                { label: "Highly Developed Countries: 45000", value: 45000 },
                { label: "Custom", value: "Custom" }
            ]
        },
        {
            name: "Mortality Rate (Adult, per 1000 people)",
            options: [
                { label: "Undeveloped Countries: 500", value: 500 },
                { label: "Lesser Developed Countries: 300", value: 300 },
                { label: "Developed Countries: 150", value: 150 },
                { label: "Highly Developed Countries: 50", value: 50 },
                { label: "Custom", value: "Custom" }
            ]
        },
        {
            name: "Access to Clean Fuels (% of population)",
            options: [
                { label: "Undeveloped Countries: 10%", value: 10 },
                { label: "Lesser Developed Countries: 30%", value: 30 },
                { label: "Developed Countries: 60%", value: 60 },
                { label: "Highly Developed Countries: 90%", value: 90 },
                { label: "Custom", value: "Custom" }
            ]
        },
        {
            name: "Under-Five Deaths (per 1000 live births)",
            options: [
                { label: "Undeveloped Countries: 75", value: 75 },
                { label: "Lesser Developed Countries: 50", value: 50 },
                { label: "Developed Countries: 30", value: 30 },
                { label: "Highly Developed Countries: 10", value: 10 },
                { label: "Custom", value: "Custom" }
            ]
        },
        {
            name: "Fertility Rate (Births per Woman)",
            options: [
                { label: "Undeveloped Countries: 7", value: 7 },
                { label: "Lesser Developed Countries: 4", value: 4 },
                { label: "Developed Countries: 2.5", value: 2.5 },
                { label: "Highly Developed Countries: 1.5", value: 1.5 },
                { label: "Custom", value: "Custom" }
            ]
        },
        {
            name: "Access to Basic Sanitation (% of population)",
            options: [
                { label: "Undeveloped Countries: 35%", value: 35 },
                { label: "Lesser Developed Countries: 50%", value: 50 },
                { label: "Developed Countries: 70%", value: 70 },
                { label: "Highly Developed Countries: 95%", value: 95 },
                { label: "Custom", value: "Custom" }
            ]
        },
        {
            name: "Rural Electricity Access (% of rural population)",
            options: [
                { label: "Undeveloped Countries: 30%", value: 30 },
                { label: "Lesser Developed Countries: 50%", value: 50 },
                { label: "Developed Countries: 80%", value: 80 },
                { label: "Highly Developed Countries: 95%", value: 95 },
                { label: "Custom", value: "Custom" }
            ]
        },
        {
            name: "Health Expenditure (USD$ per capita)",
            options: [
                { label: "Undeveloped Countries: 50", value: 50 },
                { label: "Lesser Developed Countries: 150", value: 150 },
                { label: "Developed Countries: 500", value: 500 },
                { label: "Highly Developed Countries: 2000", value: 2000 },
                { label: "Custom", value: "Custom" }
            ]
        }
    ]

    // Main vertical layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20
        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop

        // Title Text
        Text {
            text: "Enter model Values"
            font.pixelSize: 24
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }

        // Form Fields Container
        ColumnLayout {
            id: formContainer
            spacing: 5
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 1000

            // Repeater for form fields
            Repeater {
                model: features
                delegate: ColumnLayout {
                    spacing: 10
                    Layout.alignment: Qt.AlignHCenter

                    // Row for Label and ComboBox
                    RowLayout {
                        spacing: 10
                        Layout.alignment: Qt.AlignHCenter

                        Text {
                            text: modelData.name
                            Layout.preferredWidth: 250
                            font.pixelSize: 16
                            wrapMode: Text.WordWrap
                        }

                        ComboBox {
                            id: comboBox
                            Layout.preferredWidth: 200
                            model: modelData.options
                            textRole: "label"
                            currentIndex: 2 // Set default selection as "Developed Countries"
                            onCurrentTextChanged: {
                                customInputField.visible = (currentText === "Custom")
                                if (currentText === "Custom") {
                                    customInputField.text = ""
                                }
                            }
                        }
                    }

                    // TextField for Custom Input
                    TextField {
                        id: customInputField
                        text: ""
                        placeholderText: "Enter custom value e.g. (" + modelData.options[modelData.options.length - 2].value + ")"
                        Layout.preferredWidth: 400
                        visible: false
                        // Restrict input to numbers
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        validator: DoubleValidator { bottom: 0 }
                    }
                }
            }
        }

        // Submit Button
        Button {
            text: "Submit"
            width: 150
            Layout.alignment: Qt.AlignHCenter
            onClicked: {
                var inputs = []
                var fields = formContainer.children

                for (var i = 0; i < fields.length; i++) {
                    var field = fields[i]
                    if (field instanceof ColumnLayout) {
                        var row = field.children[0] // RowLayout
                        var comboBox = row.children[1] // ComboBox
                        var selectedOption = comboBox.model[comboBox.currentIndex].value
                        var customField = field.children[1] // TextField

                        var inputValue
                        if (selectedOption === "Custom") {
                            inputValue = parseFloat(customField.text)
                            if (isNaN(inputValue)) {
                                predictedLifeExpectancy.text = "Error: Please enter a valid number for " + row.children[0].text
                                return
                            }
                        } else {
                            inputValue = selectedOption
                        }

                        inputs.push(inputValue)
                    }
                }

                // Call the Python backend's predictLifeExpectancy function
                var prediction = backend.predictLifeExpectancy(inputs)

                if (prediction === "Invalid input data") {
                    predictedLifeExpectancy.text = "Error: Invalid input data. Please check your entries."
                } else if (prediction.startsWith("Error")) {
                    predictedLifeExpectancy.text = prediction
                } else {
                    predictedLifeExpectancy.text = "Predicted Life Expectancy: " + prediction + " years"
                }
            }
        }

        // Predicted Life Expectancy Text
        Text {
            id: predictedLifeExpectancy
            text: "Predicted Life Expectancy: N/A"
            font.pixelSize: 18
            color: "blue"
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }
}