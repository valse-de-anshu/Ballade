import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Flow {
    id: root
    Layout.fillWidth: true
    spacing: 6

    property list<string> options: []
    property var currentValue: null
    property color shapeColor: Appearance.colors.colPrimary
    property color backgroundColor: Appearance.colors.colLayer1

    signal selected(var newValue)

    function getShape(name) {
        switch (name) {
            case "Free":          return MaterialShape.Shape.Square
            case "VerticalRectangle": return MaterialShape.Shape.Square
            case "Circle":        return MaterialShape.Shape.Circle
            case "Square":        return MaterialShape.Shape.Square
            case "Slanted":       return MaterialShape.Shape.Slanted
            case "Arch":          return MaterialShape.Shape.Arch
            case "Fan":           return MaterialShape.Shape.Fan
            case "Arrow":         return MaterialShape.Shape.Arrow
            case "SemiCircle":    return MaterialShape.Shape.SemiCircle
            case "Oval":          return MaterialShape.Shape.Oval
            case "Pill":          return MaterialShape.Shape.Pill
            case "Triangle":      return MaterialShape.Shape.Triangle
            case "Diamond":       return MaterialShape.Shape.Diamond
            case "ClamShell":     return MaterialShape.Shape.ClamShell
            case "Pentagon":      return MaterialShape.Shape.Pentagon
            case "Gem":           return MaterialShape.Shape.Gem
            case "Sunny":         return MaterialShape.Shape.Sunny
            case "VerySunny":     return MaterialShape.Shape.VerySunny
            case "Cookie4Sided":  return MaterialShape.Shape.Cookie4Sided
            case "Cookie6Sided":  return MaterialShape.Shape.Cookie6Sided
            case "Cookie7Sided":  return MaterialShape.Shape.Cookie7Sided
            case "Cookie9Sided":  return MaterialShape.Shape.Cookie9Sided
            case "Cookie12Sided": return MaterialShape.Shape.Cookie12Sided
            case "Ghostish":      return MaterialShape.Shape.Ghostish
            case "Clover4Leaf":   return MaterialShape.Shape.Clover4Leaf
            case "Clover8Leaf":   return MaterialShape.Shape.Clover8Leaf
            case "Burst":         return MaterialShape.Shape.Burst
            case "SoftBurst":     return MaterialShape.Shape.SoftBurst
            case "Boom":          return MaterialShape.Shape.Boom
            case "SoftBoom":      return MaterialShape.Shape.SoftBoom
            case "Flower":        return MaterialShape.Shape.Flower
            case "Puffy":         return MaterialShape.Shape.Puffy
            case "PuffyDiamond":  return MaterialShape.Shape.PuffyDiamond
            case "PixelCircle":   return MaterialShape.Shape.PixelCircle
            case "PixelTriangle": return MaterialShape.Shape.PixelTriangle
            case "Bun":           return MaterialShape.Shape.Bun
            case "Heart":         return MaterialShape.Shape.Heart
            default:              return MaterialShape.Shape.Cookie4Sided
        }
    }

    Repeater {
        model: root.options
        delegate: RippleButton {
            id: shapeButton
            required property string modelData
            required property int index

            property bool isSelected: root.currentValue === modelData

            implicitWidth: 38
            implicitHeight: 38
            buttonRadius: Appearance.rounding.medium ?? 12

            colBackground: isSelected
                ? Appearance.colors.colPrimaryContainer
                : ColorUtils.transparentize(Appearance.colors.colSurfaceContainerHigh, 0.4)
            colBackgroundHover: isSelected
                ? Appearance.colors.colPrimaryContainerHover
                : Appearance.colors.colSurfaceContainerHighest
            colRipple: isSelected
                ? Appearance.colors.colPrimaryActive
                : Appearance.colors.colSecondaryContainerActive

            border: isSelected
            borderWidth: 2
            colBorder: Appearance.colors.colPrimary

            StyledToolTip {
                text: shapeButton.modelData
            }

            contentItem: MaterialShape {
                anchors.centerIn: parent
                implicitSize: 20
                shape: root.getShape(shapeButton.modelData)
                color: shapeButton.isSelected
                    ? Appearance.colors.colPrimary
                    : Appearance.colors.colOnSurfaceVariant
                Behavior on color {
                    ColorAnimation { duration: 180 }
                }
            }

            downAction: () => root.selected(shapeButton.modelData)
        }
    }
}