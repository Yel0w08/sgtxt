import dlangui;
import dlangui.graphics.ftfonts : FreeTypeFontManager;
import dlangui.widgets.controls : TextWidget;
import sga_font_data : SGA_SMOOTH_FONT_BASE64;
import std.base64 : Base64;
import std.file : exists, getSize, mkdirRecurse, readText, tempDir, thisExePath, write;
import std.path : buildPath, dirName;
import std.utf : toUTF8, toUTF32;

mixin APP_ENTRY_POINT;

enum SGA_FACE = "SGA Smooth";

string locateSgaFont()
{
    foreach (candidate; [
        buildPath("source", "fonts", "SgaSmooth-Regular.ttf"),                       
        buildPath(dirName(thisExePath), "source", "fonts", "SgaSmooth-Regular.ttf"), 
        buildPath(dirName(thisExePath), "fonts", "SgaSmooth-Regular.ttf"),         
    ])
    {
        if (exists(candidate))
            return candidate;
    }
    try
    {
        auto path = buildPath(tempDir(), "sgtxt", "SgaSmooth-Regular.ttf");
        mkdirRecurse(dirName(path));
        auto data = Base64.decode(SGA_SMOOTH_FONT_BASE64);
        if (!exists(path) || getSize(path) != data.length)
            write(path, data);
        return path;
    }
    catch (Exception e)
        return null;
}

bool registerSgaFont()
{
    auto path = locateSgaFont();
    if (!path.length)
        return false;
    auto ftMan = cast(FreeTypeFontManager) FontManager.instance;
    if (ftMan is null)
        return false;
    return ftMan.registerFont(path);
}

class Notepad : VerticalLayout
{
    EditLine pathField;
    EditBox editor;
    TextWidget status;
    Button sgaButton;

    string _plainFace;      
    bool _sgaAvailable;
    bool _sgaEnabled;

    this(string initialPath = "", bool sgaAvailable = false)
    {
        parseML(q{
        {
            padding: 8px;
            layoutWidth: FILL;
            layoutHeight: FILL;

            VerticalLayout {
                layoutWidth: FILL;
                layoutHeight: FILL;

                HorizontalLayout {
                    layoutWidth: FILL;
                    layoutHeight: WRAP;

                    EditLine {
                        id: path;
                        layoutWidth: FILL;
                    }
                    Button {
                        id: open;
                        text: "Open";
                    }
                    Button {
                        id: save;
                        text: "Save";
                    }
                    Button {
                        id: sga;
                        text: "SGA: On";
                    }
                }

                EditBox {
                    id: editor;
                    layoutWidth: FILL;
                    layoutHeight: FILL;
                }

                TextWidget {
                    id: status;
                    layoutWidth: FILL;
                    text: "Ready.";
                }
            }
        }
        }, "", this);

        pathField = childById!EditLine("path");
        editor = childById!EditBox("editor");
        status = childById!TextWidget("status");
        sgaButton = childById!Button("sga");

        childById!Button("open").click.connect(&onOpenClicked);
        childById!Button("save").click.connect(&onSaveClicked);
        sgaButton.click.connect(&onToggleSga);

        _plainFace = editor.fontFace;
        _sgaAvailable = sgaAvailable;
        _sgaEnabled = sgaAvailable;
        applyFont();

        if (initialPath.length)
        {
            pathField.text = toUTF32(initialPath);
            openFile();
        }
    }

    bool onOpenClicked(Widget w)
    {
        openFile();
        return true;
    }

    bool onSaveClicked(Widget w)
    {
        saveFile();
        return true;
    }

    bool onToggleSga(Widget w)
    {
        if (!_sgaAvailable)
        {
            setStatus("SGA Smooth font is not available.");
            return true;
        }
        _sgaEnabled = !_sgaEnabled;
        applyFont();
        return true;
    }

 
    void applyFont()
    {
        editor.fontFace = _sgaEnabled ? SGA_FACE : _plainFace;
        sgaButton.text = _sgaEnabled ? "SGA: On"d : "SGA: Off"d;
        editor.requestLayout();
        editor.invalidate();
        if (_sgaEnabled)
        {
            auto f = editor.font;
            setStatus(f.isNull ? "SGA font could not be loaded."
                               : "Displaying Standard Galactic (" ~ f.face ~ ").");
        }
        else
        {
            setStatus("SGA OFF");
        }
    }

    void openFile()
    {
        string path = toUTF8(pathField.text);
        if (!path.length)
        {
            setStatus("Enter a file path...");
            return;
        }
        try
        {
            editor.text = toUTF32(readText(path));
            setStatus("Opened " ~ path);
        }
        catch (Exception e)
        {
            setStatus("I cant open" ~ path ~ ": " ~ e.msg);
        }
    }

    void saveFile()
    {
        string path = toUTF8(pathField.text);
        if (!path.length)
        {
            setStatus("Enter a file path...");
            return;
        }
        try
        {
            write(path, toUTF8(editor.text));
            setStatus("Saved " ~ path);
        }
        catch (Exception e)
        {
            setStatus("Cant save " ~ path ~ ": " ~ e.msg);
        }
    }

    void setStatus(string message)
    {
        status.text = toUTF32(message);
    }
}

extern (C) int UIAppMain(string[] args)
{
    bool sgaReady = registerSgaFont();

    auto window = Platform.instance.createWindow("SGTXT - Standard Galactic Notepad",
                                                 null, WindowFlag.Resizable, 800, 600);
    window.mainWidget = new Notepad(args.length > 1 ? args[1] : "", sgaReady);
    window.show();
    return Platform.instance.enterMessageLoop();
}
