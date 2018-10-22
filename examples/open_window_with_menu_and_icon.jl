include("../winapi.jl")
using Main.WinApi

const ID_FILE_EXIT = 9001
const ID_STUFF_GO = 9002

iconPath = "$(@__DIR__)/ico-design.ico"
(hicon, err) = loadimage(iconPath, IMAGE_ICON, 0, 0, LR_DEFAULTSIZE | LR_LOADFROMFILE)

if err != 0; error("Failed loading icon from $(iconPath). Error code: $(err)"); end

function mywinproc(hwnd, msg, wParam, lParam)
    if msg == WM_CREATE
        (hmenu, _) = createmenu()

        (hsubmenu1, _) = createpopupmenu()
        appendmenu(hsubmenu1, MF_STRING, ID_FILE_EXIT, "E&xit")
        appendmenu(hmenu, MF_STRING | MF_POPUP, hsubmenu1, "&File")

        (hsubmenu2, _) = createpopupmenu()
        appendmenu(hsubmenu2, MF_STRING, ID_STUFF_GO, "&Go")
        appendmenu(hmenu, MF_STRING | MF_POPUP, hsubmenu2, "&Stuff")

        setmenu(hwnd, hmenu)
    elseif msg == WM_DESTROY
        post_quitmessage(0)
    elseif msg == WM_COMMAND
        if wParam & 0xffff == ID_FILE_EXIT
            destroywindow(hwnd)
        end
    else
        return defwindowproc(hwnd, msg, wParam, lParam)
    end
    return 0
end

mywinproc_c = @winproc mywinproc

(_, err) = registerclass("mywindowclass";
    icon = hicon,
    iconSm = hicon,
    proc = mywinproc_c)

if err != 0; error("Failed registering mywindowclass. Error code: $(err)"); end

(hwnd, err) = createwindow(classname="mywindowclass")

if err != 0; error("Failed creating window. Error code: $(err)"); end

showwindow_wait(hwnd)
