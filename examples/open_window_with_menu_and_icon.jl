include("../winapi.jl")
using Main.WinApi

include("about_dialog.jl")

const ID_FILE_EXIT = 9001
const ID_STUFF_GO = 9002

iconPath = "$(@__DIR__)/ico-design.ico"
(hicon, err) = loadimage(iconPath, IMAGE_ICON, 0, 0, LR_DEFAULTSIZE | LR_LOADFROMFILE)

if err != 0; error("Failed loading icon from $(iconPath). Error code: $(err)"); end

function dlgproc(hwnd, msg, wParam, lParam)    
    if msg == WM_INITDIALOG
        return 1
    elseif msg == 513
        return ccall((:EndDialog, "user32"), Cint, (Ptr{Cvoid},Clonglong), hwnd, IDOK)
    elseif msg == WM_COMMAND
        if loword(wParam) == IDOK
            #ret = ccall((:EndDialog, "user32"), Cint, (Ptr{Cvoid},Clonglong), hwnd, IDOK)
            #println("EndDialog return value: $(ret)")
            #if (ret == 0)
            #    println("Error occurred: $(getlasterror())")
            #end
            #return ret
            #destroywindow(hwnd)
        end
    else
        return 0
    end
end

dlgproc_c = @winproc dlgproc

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
        if loword(wParam) == ID_FILE_EXIT
            destroywindow(hwnd)
        elseif loword(wParam) == ID_STUFF_GO
            templateData = create_about_dialog()
            result = ccall((:DialogBoxIndirectParamW, "user32"), Cvoid,
                (Ptr{Cvoid},Ptr{Cvoid},Ptr{Cvoid},Ptr{Cvoid},Clonglong),
                C_NULL,
                pointer(templateData),
                hwnd,
                dlgproc_c,
                0)
            if result == nothing || result == 0 || result == -1
                error = getlasterror()
                println("Error creating dialog: ", error)
            else
                println("Dialog result: ", result)
            end
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
