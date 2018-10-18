module WinApi

###### Begin Constants #####

###### Window Messages #####
const WM_CLOSE   = convert(Cuint,0x0010)
const WM_DESTROY = convert(Cuint,0x0002)
const WM_LBUTTONDOWN = convert(Cuint, 0x0201)

##### Extended Window Styles #####
const WS_EX_CLIENTEDGE = convert(Culong,0x00000200)
const WS_EX_WINDOWEDGE = convert(Culong,0x00000100)
const WS_EX_TOOLWINDOW = convert(Culong,0x00000080)
const WS_EX_TOPMOST = convert(Culong,0x00000008)
const WS_EX_OVERLAPPEDWINDOW = WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE
const WS_EX_PALETTEWINDOW = WS_EX_WINDOWEDGE | WS_EX_TOOLWINDOW | WS_EX_TOPMOST

##### Window Styles #####
const WS_OVERLAPPED = convert(Culong,0x00000000)
const WS_CAPTION = convert(Culong,0x00C00000)
const WS_SYSMENU = convert(Culong,0x00080000)
const WS_THICKFRAME = convert(Culong,0x00040000)
const WS_MINIMIZEBOX = convert(Culong,0x00020000)
const WS_MAXIMIZEBOX = convert(Culong,0x00010000)
const WS_OVERLAPPEDWINDOW = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX

##### ShowWindow Parameters #####
const SW_SHOWDEFAULT = convert(Cint,10)

##### CreateWindow Parameters #####
const CW_USEDEFAULT = convert(Cint,-2147483648)

##### WinApi Error Codes #####
const ERROR_INVALID_WINDOW_HANDLE = convert(Culong,0x00000578)
const ERROR_CLASS_ALREADY_EXISTS = convert(Culong,0x00000582)

##### End Constants #####

##### Begin Structs #####

mutable struct WNDCLASSEXW
    cbSize::Cuint
    style::Cuint
    lpfnWndProc::Ptr{Cvoid}
    cbClsExtra::Cint
    cbWndExtra::Cint
    hInstance::Ptr{Cvoid}
    hIcon::Ptr{Cvoid}
    hCursor::Ptr{Cvoid}
    hbrBackground::Ptr{Cvoid}
    lpszMenuName::Cwstring
    lpszClassName::Cwstring
    hIconSm::Ptr{Cvoid}
end

mutable struct POINT
    x::Clong
    y::Clong
end

mutable struct MSG
    hwnd::Ptr{Cvoid}
    message::Cuint
    wParam::Culonglong
    lParam::Clonglong
    time::Culong
    pt::POINT
end

MSG(hwnd, msg, wParam, lParam) = MSG(hwnd, msg, wParam, lParam, 0, POINT(0, 0))
MSG() = MSG(C_NULL,0,0,0)

##### End Structs #####

macro winproc(proc)
    return :( @cfunction($proc, Clonglong, (Ptr{Cvoid},Cuint,Culonglong,Clonglong,)) )
end

function cwstring(val)
    val == C_NULL || isa(val, Cwstring) ? val :
        Base.unsafe_convert(Cwstring,Base.cconvert(Cwstring,string(val)))
end

function getlasterror()
    ccall((:GetLastError, "kernel32"), Culong, ())
end

function defwindowproc(hwnd, msg, wParam, lParam)
    ccall((:DefWindowProcW,"user32"),Clonglong,(Ptr{Cvoid},Cuint,Culonglong,Clonglong),hwnd,msg,wParam,lParam)
end

function destroywindow(hwnd)
    ret = ccall((:DestroyWindow,"user32"),Cint,(Ptr{Cvoid},),hwnd)
    error = ret == C_NULL ? getlasterror() : 0
    (ret, error)
end

function post_quitmessage(exitcode)
    ccall((:PostQuitMessage,"user32"),Cvoid,(Cint,),exitcode)
end

function windowproc(hwnd, msg, wParam, lParam)
    if msg == WM_CLOSE
        destroywindow(hwnd)
    elseif msg == WM_DESTROY
        post_quitmessage(0)
    else
        return defwindowproc(hwnd, msg, wParam, lParam)
    end
    return 0
end

windowproc_c = @winproc(windowproc)

function registerclass(classname;
    proc = C_NULL,
    instance = C_NULL,
    icon = C_NULL,
    cursor = C_NULL,
    bg = C_NULL,
    menu = C_NULL,
    iconSm = C_NULL)

    wcex = WNDCLASSEXW(
        sizeof(WNDCLASSEXW),
        0,
        proc == C_NULL ? windowproc_c : proc,
        0,
        0,
        instance,
        icon,
        cursor,
        bg,
        cwstring(menu),
        cwstring(classname),
        iconSm
    )

    atom = ccall((:RegisterClassExW, "user32"), Cushort, (Ptr{WNDCLASSEXW},), pointer_from_objref(wcex))
    error = atom == 0 ? getlasterror() : 0

    (atom, error)
end

function unregisterclass(classname)
    ret = ccall((:UnregisterClassW, "user32"), Cint, (Cwstring, Ptr{Cvoid}), classname, C_NULL)
    error = ret == 0 ? getlasterror() : 0
    (ret, error)
end

function createwindow(;
    classname = :WC_DEFAULT,
    title = "Untitled",
    x = CW_USEDEFAULT,
    y = CW_USEDEFAULT,
    width = CW_USEDEFAULT,
    height = CW_USEDEFAULT,
    exStyle = 0,
    style = WS_OVERLAPPEDWINDOW)

    # If the window is created with the default class, that class is auto-registered
    if classname == :WC_DEFAULT
        (_, err) = registerclass(:WC_DEFAULT)
        if err != 0 && err != ERROR_CLASS_ALREADY_EXISTS
            return (0, err)
        end
    end

    hwnd = ccall(
        (:CreateWindowExW, "user32"),
        Ptr{Cvoid},
        (Culong, Cwstring, Cwstring, Culong, Cint, Cint, Cint, Cint, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
        convert(Culong,exStyle),
        string(classname),
        string(title),
        convert(Culong,style),
        convert(Cint,x),
        convert(Cint,y),
        convert(Cint,width),
        convert(Cint,height),
        C_NULL,
        C_NULL,
        C_NULL,
        C_NULL)

    error = hwnd == C_NULL ? getlasterror() : 0

    (hwnd, error)
end

function showwindow(hwnd, nCmdShow = SW_SHOWDEFAULT)
    ccall((:ShowWindow, "user32"), Cint, (Ptr{Cvoid}, Cint), hwnd, nCmdShow)
end

function updatewindow(hwnd)
    ccall((:UpdateWindow, "user32"), Cint, (Ptr{Cvoid},), hwnd)
end

function getmessage(ptr_msg, hwnd = C_NULL)
    ccall((:GetMessageW,"user32"),Cint,(Ptr{MSG},Ptr{Cvoid},Cuint,Cuint),ptr_msg,C_NULL,0,0)
end

function translatemessage(ptr_msg)
    ccall((:TranslateMessage,"user32"),Cint,(Ptr{MSG},),ptr_msg)
end

function dispatchmessage(ptr_msg)
    ccall((:DispatchMessageW,"user32"),Clonglong,(Ptr{MSG},),ptr_msg)
end

function iswindow(hwnd)
    ret = ccall((:IsWindow, "user32"), Cint, (Ptr{Cvoid},), hwnd)
    ret != 0
end

function showwindow_wait(hwnd)
    if !iswindow(hwnd)
        return (0, ERROR_INVALID_WINDOW_HANDLE)
    end

    showwindow(hwnd)
    updatewindow(hwnd)

    msg = MSG()
    ptr_msg = pointer_from_objref(msg)
    while getmessage(ptr_msg) > 0
        translatemessage(ptr_msg)
        dispatchmessage(ptr_msg)
    end
    return (msg.wParam, 0)
end

function openwindow(;kwargs...)
    (hwnd, err) = createwindow(;kwargs...)

    if err != 0
        return (hwnd, err)
    end

    showwindow_wait(hwnd)
end

end
