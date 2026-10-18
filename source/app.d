import dlangui;
import std.file : readText, write;

mixin APP_ENTRY_POINT;

class Notepad : VerticalLayout
{
    EditLine pathField;
    EditBox editor;

    this()
    {
        parseML(q{
        {
            padding: 8px;
            layoutWidth: FILL;
            layoutHeight: FILL;

            VerticalLayout {
                layoutWidth: FILL;
                layoutHeight: FILL;


                EditBox {
                    id: editor;
                    layoutWidth: FILL;
                    layoutHeight: FILL
                }


            }
        }
        }, "", this);

        pathField = childById!EditLine("path");
        editor = childById!EditBox("editor");



    }
}

extern (C) int UIAppMain(string[] args)
{
    auto window = Platform.instance.createWindow("SGA Notepad (sgtxt)", null);
    window.mainWidget = new Notepad();
    window.show();
    return Platform.instance.enterMessageLoop();
}
